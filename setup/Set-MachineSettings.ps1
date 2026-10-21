#Requires -Version 5.1
<#
.SYNOPSIS
    Applies the senior-friendly settings that affect the whole PC.

.DESCRIPTION
    Run this from your own administrator account, in PowerShell opened with
    "Run as administrator". It sets:
      - Chrome protection: no website notifications or pop-ups, enhanced Safe
        Browsing, uBlock Origin Lite installed and every other extension blocked,
        no guest or extra profiles, camera and microphone allowed for call sites;
      - no Widgets on the taskbar;
      - Windows Update active hours, so it never restarts during the day;
      - power: screen off, sleep, and no password when the screen wakes.
    It also reports the Windows version and Smart App Control, without changing them.

    The value of every setting before its first change is saved to
    %ProgramData%\windows4seniors\original-machine-settings.json, and
    Restore-Settings.ps1 -Scope Machine puts it back.

.PARAMETER Person
    The profile to use, from setup\profiles (papa or mama).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Set-MachineSettings.ps1 -Person mama -WhatIf
    Shows what would change, without changing anything.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Set-MachineSettings.ps1 -Person mama
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Person
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Common.ps1')

$settings = Get-W4SProfile -Person $Person

Write-Host ''
Write-Host "windows4seniors: PC settings for '$($settings.DisplayName)'" -ForegroundColor White
if (-not (Test-W4SAdmin)) {
    throw 'This script changes the whole PC. Open PowerShell with "Run as administrator" and run it again.'
}

Initialize-W4SBackup -Path (Get-W4SBackupPath -Scope Machine)

# --- Chrome ----------------------------------------------------------------------------

Write-W4SSection 'Chrome'

$chrome = 'HKLM:\SOFTWARE\Policies\Google\Chrome'
$uBlockOriginLite = 'ddkjiahejlhfcafbddmgiahcphecmpfh;https://clients2.google.com/service/update2/crx'

Set-W4SRegistryValue -Path $chrome -Name 'DefaultNotificationsSetting' -Value 2 `
    -Description 'Block notifications from all websites (the usual fake-virus scam route)'
Set-W4SRegistryValue -Path $chrome -Name 'DefaultPopupsSetting' -Value 2 `
    -Description 'Block pop-up windows'
Set-W4SRegistryValue -Path $chrome -Name 'SafeBrowsingProtectionLevel' -Value 2 `
    -Description 'Safe Browsing: enhanced protection'
Set-W4SRegistryValue -Path "$chrome\ExtensionInstallForcelist" -Name '1' -Type String -Value $uBlockOriginLite `
    -Description 'Install uBlock Origin Lite (blocks ads and scam pages)'
Set-W4SRegistryValue -Path "$chrome\ExtensionInstallBlocklist" -Name '1' -Type String -Value '*' `
    -Description 'Block all other extensions'
Set-W4SRegistryValue -Path $chrome -Name 'BrowserGuestModeEnabled' -Value 0 `
    -Description 'No guest mode'
Set-W4SRegistryValue -Path $chrome -Name 'BrowserAddPersonEnabled' -Value 0 `
    -Description 'No adding extra profiles'
Set-W4SRegistryValue -Path $chrome -Name 'IncognitoModeAvailability' -Value 1 `
    -Description 'No incognito windows'
Set-W4SRegistryValue -Path $chrome -Name 'DeveloperToolsAvailability' -Value 2 `
    -Description 'No developer tools'
Set-W4SRegistryValue -Path $chrome -Name 'PasswordManagerEnabled' -Value 1 `
    -Description 'Password manager on (you save the passwords for them)'

$sites = @($settings.ChromeCameraMicSites)
for ($i = 0; $i -lt $sites.Count; $i++) {
    $number = [string]($i + 1)
    Set-W4SRegistryValue -Path "$chrome\VideoCaptureAllowedUrls" -Name $number -Type String -Value $sites[$i] `
        -Description "Camera allowed without asking: $($sites[$i])"
    Set-W4SRegistryValue -Path "$chrome\AudioCaptureAllowedUrls" -Name $number -Type String -Value $sites[$i] `
        -Description "Microphone allowed without asking: $($sites[$i])"
}
if ($sites.Count -eq 0) {
    Write-W4SStatus skipped 'Camera and microphone sites (none in this profile)'
}

# --- Windows ---------------------------------------------------------------------------

Write-W4SSection 'Windows'

Set-W4SRegistryValue -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Dsh' -Name 'AllowNewsAndInterests' -Value 0 `
    -Description 'Taskbar: no Widgets (news and weather pop-ups)'

$start = [int]$settings.ActiveHoursStart
$end = [int]$settings.ActiveHoursEnd
$span = ($end - $start + 24) % 24
if ($start -lt 0 -or $start -gt 23 -or $end -lt 0 -or $end -gt 23 -or $span -eq 0 -or $span -gt 18) {
    throw "Active hours must be whole hours 0-23, spanning 1 to 18 hours (profile '$Person')."
}
$windowsUpdate = 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings'
Set-W4SRegistryValue -Path $windowsUpdate -Name 'SmartActiveHoursState' -Value 0 `
    -Description 'Windows Update: use fixed active hours'
Set-W4SRegistryValue -Path $windowsUpdate -Name 'ActiveHoursStart' -Value $start `
    -Description "Windows Update: active hours start at $($start):00"
Set-W4SRegistryValue -Path $windowsUpdate -Name 'ActiveHoursEnd' -Value $end `
    -Description "Windows Update: active hours end at $($end):00 (restarts only outside these hours)"

# --- Power (when plugged in) ------------------------------------------------------------

Write-W4SSection 'Power (when plugged in)'

Set-W4SPowerIndex -Subgroup SUB_VIDEO -Setting VIDEOIDLE -Value ($settings.ScreenOffMinutes * 60) `
    -Description "Turn the screen off after $($settings.ScreenOffMinutes) minutes"
$sleepText = if ($settings.SleepMinutes -eq 0) { 'Never sleep' } else { "Sleep after $($settings.SleepMinutes) minutes" }
Set-W4SPowerIndex -Subgroup SUB_SLEEP -Setting STANDBYIDLE -Value ($settings.SleepMinutes * 60) `
    -Description $sleepText
Set-W4SPowerIndex -Subgroup SUB_NONE -Setting CONSOLELOCK -Value 0 `
    -Description 'No password when the screen wakes up'

# --- Checks (nothing is changed) --------------------------------------------------------

Write-W4SSection 'Checks'

$windows = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$version = $windows.DisplayVersion
if ($version -and $version -ge '24H2') {
    Write-W4SStatus info "Windows version $version (supports LE Audio hearing aids if the Bluetooth hardware does)"
} else {
    Write-W4SStatus warning "Windows version $version. Install the latest Windows 11 update before pairing hearing aids (LE Audio needs 24H2 or later)."
}

$smartAppControl = Get-W4SRegistryValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name 'VerifiedAndReputablePolicyState'
$smartAppControlState = @{ 0 = 'Off'; 1 = 'On'; 2 = 'Evaluation' }
if ($smartAppControl.Exists -and $smartAppControlState.ContainsKey([int]$smartAppControl.Value)) {
    $state = $smartAppControlState[[int]$smartAppControl.Value]
    if ($state -eq 'Off') {
        Write-W4SStatus info 'Smart App Control is Off (it can only be turned on again by reinstalling Windows).'
    } else {
        Write-W4SStatus info "Smart App Control is $state. Leave it that way: it blocks unknown apps."
    }
} else {
    Write-W4SStatus info 'Smart App Control state unknown (check Windows Security > App & browser control).'
}

# --- Summary ---------------------------------------------------------------------------

Write-Host ''
if ($WhatIfPreference) {
    Write-Host 'Preview only: nothing was changed.' -ForegroundColor Cyan
} elseif ($script:W4SChangeCount -gt 0) {
    Write-Host "$script:W4SChangeCount setting(s) changed. Restart Chrome to apply its settings (chrome://policy shows them)." -ForegroundColor Green
    Write-Host "Original values saved in $(Get-W4SBackupPath -Scope Machine)"
} else {
    Write-Host 'Everything was already set. Nothing changed.' -ForegroundColor Green
}
Write-Host 'Next: sign in as the senior and run Set-UserSettings.ps1, then the manual steps in setup\README.md.'
