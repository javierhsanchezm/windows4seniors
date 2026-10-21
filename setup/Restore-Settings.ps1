#Requires -Version 5.1
<#
.SYNOPSIS
    Puts back the settings that Set-UserSettings.ps1 or Set-MachineSettings.ps1 changed.

.DESCRIPTION
    Reads the backup file written by the setup scripts and restores every setting to the
    value it had before the setup scripts first changed it.

    -Scope User:    run while signed in as the senior, in a normal PowerShell window.
    -Scope Machine: run from an administrator account, with "Run as administrator".

    After a successful restore the backup file is renamed, so running the setup
    scripts again starts a fresh backup.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Restore-Settings.ps1 -Scope User -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][ValidateSet('User', 'Machine')][string]$Scope
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Common.ps1')

if ($Scope -eq 'Machine' -and -not (Test-W4SAdmin)) {
    throw 'Restoring PC settings needs an administrator. Open PowerShell with "Run as administrator" and run it again.'
}

$backupPath = Get-W4SBackupPath -Scope $Scope
if (-not (Test-Path -LiteralPath $backupPath)) {
    Write-Host "Nothing to restore: no backup at $backupPath"
    return
}

Write-Host ''
Write-Host "windows4seniors: restoring $($Scope.ToLower()) settings from $backupPath" -ForegroundColor White

$failures = 0
foreach ($entry in (Get-Content -LiteralPath $backupPath -Raw | ConvertFrom-Json)) {
    try {
        if ($entry.Kind -eq 'Registry') {
            $target = "$($entry.Path)\$($entry.Name)"
            if ($entry.Existed) {
                $value = $entry.Value
                if ($entry.Type -eq 'Binary') { $value = [byte[]]$entry.Value }
                if ($entry.Type -eq 'MultiString') { $value = [string[]]$entry.Value }
                if ($PSCmdlet.ShouldProcess($target, "Restore to '$value'")) {
                    New-ItemProperty -LiteralPath $entry.Path -Name $entry.Name -Value $value -PropertyType $entry.Type -Force | Out-Null
                    Write-W4SStatus changed "$target restored"
                }
            } elseif ((Get-W4SRegistryValue -Path $entry.Path -Name $entry.Name).Exists) {
                if ($PSCmdlet.ShouldProcess($target, 'Remove (it did not exist before)')) {
                    Remove-ItemProperty -LiteralPath $entry.Path -Name $entry.Name
                    Write-W4SStatus changed "$target removed"
                }
            }
        } elseif ($entry.Kind -eq 'Power') {
            $target = "power plan setting $($entry.Subgroup)/$($entry.Setting)"
            if ($PSCmdlet.ShouldProcess($target, "Restore plugged-in value to $($entry.Value)")) {
                & powercfg.exe /setacvalueindex SCHEME_CURRENT $entry.Subgroup $entry.Setting $entry.Value
                if ($LASTEXITCODE -ne 0) { throw "powercfg exited with code $LASTEXITCODE" }
                & powercfg.exe /setactive SCHEME_CURRENT
                Write-W4SStatus changed "$target restored"
            }
        }
    } catch {
        $failures++
        Write-W4SStatus warning "$($entry.Key): $($_.Exception.Message)"
    }
}

Write-Host ''
if ($WhatIfPreference) {
    Write-Host 'Preview only: nothing was changed.' -ForegroundColor Cyan
} elseif ($failures -gt 0) {
    Write-Host "$failures setting(s) couldn't be restored (see warnings above). The backup file was kept." -ForegroundColor Yellow
} else {
    $restoredPath = $backupPath -replace '\.json$', ".restored-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    Rename-Item -LiteralPath $backupPath -NewName (Split-Path -Leaf $restoredPath)
    Write-Host 'All settings restored. Sign out and back in to see all of them.' -ForegroundColor Green
}
