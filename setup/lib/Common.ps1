# Shared helpers for the windows4seniors setup scripts.
#
# Dot-source this file (". $PSScriptRoot\lib\Common.ps1") rather than importing it as a
# module: dot-sourced functions inherit the calling script's -WhatIf, modules don't.
#
# Every change goes through Set-W4SRegistryValue or Set-W4SPowerIndex so that:
#   - -WhatIf shows what would change without changing anything;
#   - the value from before our *first* change is saved to a backup file, so
#     Restore-Settings.ps1 can put everything back as it was.

$script:W4SBackup = $null
$script:W4SBackupPath = $null
$script:W4SChangeCount = 0

function Get-W4SBackupPath {
    param([Parameter(Mandatory)][ValidateSet('User', 'Machine')][string]$Scope)

    if ($Scope -eq 'User') {
        Join-Path $env:LOCALAPPDATA 'windows4seniors\original-user-settings.json'
    } else {
        Join-Path $env:ProgramData 'windows4seniors\original-machine-settings.json'
    }
}

function Initialize-W4SBackup {
    param([Parameter(Mandatory)][string]$Path)

    $script:W4SBackupPath = $Path
    $script:W4SBackup = [ordered]@{}
    $script:W4SChangeCount = 0

    # Keep entries from earlier runs: they hold the true original values.
    if (Test-Path -LiteralPath $Path) {
        $entries = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
        foreach ($entry in $entries) {
            $script:W4SBackup[$entry.Key] = $entry
        }
    }
}

function Add-W4SBackupEntry {
    param(
        [Parameter(Mandatory)][string]$Key,
        [Parameter(Mandatory)][hashtable]$Entry
    )

    if ($script:W4SBackup.Contains($Key)) { return }

    $Entry['Key'] = $Key
    $script:W4SBackup[$Key] = [pscustomobject]$Entry

    # Save after every entry, so a run that stops halfway can still be undone.
    $dir = Split-Path -Parent $script:W4SBackupPath
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force -WhatIf:$false | Out-Null
    }
    ConvertTo-Json -InputObject @($script:W4SBackup.Values) -Depth 5 |
        Set-Content -LiteralPath $script:W4SBackupPath -Encoding UTF8 -WhatIf:$false
}

function Write-W4SStatus {
    param(
        [Parameter(Mandatory)][ValidateSet('ok', 'changed', 'skipped', 'info', 'warning')][string]$State,
        [Parameter(Mandatory)][string]$Message
    )

    $colors = @{ ok = 'DarkGray'; changed = 'Green'; skipped = 'DarkYellow'; info = 'Cyan'; warning = 'Yellow' }
    Write-Host ('  [{0,-7}] {1}' -f $State, $Message) -ForegroundColor $colors[$State]
}

function Write-W4SSection {
    param([Parameter(Mandatory)][string]$Title)

    Write-Host ''
    Write-Host $Title -ForegroundColor White
}

function Test-W4SAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-W4SProfile {
    param([Parameter(Mandatory)][string]$Person)

    $path = Join-Path $PSScriptRoot "..\profiles\$Person.psd1"
    if (-not (Test-Path -LiteralPath $path)) {
        $available = (Get-ChildItem (Join-Path $PSScriptRoot '..\profiles') -Filter *.psd1).BaseName -join ', '
        throw "No profile named '$Person'. Available profiles: $available"
    }
    Import-PowerShellDataFile -LiteralPath $path
}

# --- Registry -------------------------------------------------------------------------

function Get-W4SRegistryValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    $result = [pscustomobject]@{ Exists = $false; Kind = $null; Value = $null }
    if (Test-Path -LiteralPath $Path) {
        $key = Get-Item -LiteralPath $Path
        if ($key.GetValueNames() -contains $Name) {
            $result.Exists = $true
            $result.Kind = $key.GetValueKind($Name).ToString()
            $result.Value = $key.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
        }
    }
    $result
}

function Set-W4SRegistryValue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('DWord', 'String')][string]$Type = 'DWord',
        [Parameter(Mandatory)][string]$Description
    )

    $current = Get-W4SRegistryValue -Path $Path -Name $Name
    if ($current.Exists -and $current.Kind -eq $Type -and "$($current.Value)" -eq "$Value") {
        Write-W4SStatus ok $Description
        return
    }

    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set to '$Value' ($Description)")) {
        Add-W4SBackupEntry -Key "Registry|$Path|$Name" -Entry @{
            Kind    = 'Registry'
            Path    = $Path
            Name    = $Name
            Existed = $current.Exists
            Type    = $current.Kind
            Value   = $current.Value
        }
        try {
            if (-not (Test-Path -LiteralPath $Path)) {
                New-Item -Path $Path -Force | Out-Null
            }
            New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
        } catch {
            # Some settings are protected on newer Windows builds. Carry on with the rest.
            Write-W4SStatus warning "$Description (couldn't change it: $($_.Exception.Message) Set it by hand.)"
            return
        }
        $script:W4SChangeCount++
        Write-W4SStatus changed $Description
    }
}

# --- Power settings (powercfg) ----------------------------------------------------------

# Returns the plugged-in (AC) value of a power setting in the active plan, or $null.
# powercfg's labels are translated (Spanish Windows says "Indice de configuracion..."), so
# instead of matching labels this relies on the AC and DC values being the last two hex
# numbers in the output.
function Get-W4SPowerIndex {
    param(
        [Parameter(Mandatory)][string]$Subgroup,
        [Parameter(Mandatory)][string]$Setting
    )

    $output = & powercfg.exe /query SCHEME_CURRENT $Subgroup $Setting 2>$null
    if ($LASTEXITCODE -ne 0) { return $null }

    $hex = [regex]::Matches(($output -join "`n"), '0x([0-9a-fA-F]{8})')
    if ($hex.Count -lt 2) { return $null }
    [long][Convert]::ToUInt32($hex[$hex.Count - 2].Groups[1].Value, 16)
}

function Set-W4SPowerIndex {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Subgroup,
        [Parameter(Mandatory)][string]$Setting,
        [Parameter(Mandatory)][long]$Value,
        [Parameter(Mandatory)][string]$Description
    )

    $current = Get-W4SPowerIndex -Subgroup $Subgroup -Setting $Setting
    if ($current -eq $Value) {
        Write-W4SStatus ok $Description
        return
    }

    if ($PSCmdlet.ShouldProcess("power plan setting $Subgroup/$Setting", "Set plugged-in value to $Value ($Description)")) {
        if ($null -ne $current) {
            Add-W4SBackupEntry -Key "Power|$Subgroup|$Setting" -Entry @{
                Kind     = 'Power'
                Subgroup = $Subgroup
                Setting  = $Setting
                Value    = $current
            }
        }
        & powercfg.exe /setacvalueindex SCHEME_CURRENT $Subgroup $Setting $Value
        if ($LASTEXITCODE -ne 0) {
            Write-W4SStatus warning "$Description (powercfg failed; set it by hand)"
            return
        }
        & powercfg.exe /setactive SCHEME_CURRENT
        $script:W4SChangeCount++
        Write-W4SStatus changed $Description
    }
}
