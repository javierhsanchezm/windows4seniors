#Requires -Version 5.1
<#
.SYNOPSIS
    Applies the senior-friendly settings to the Windows account that is signed in.

.DESCRIPTION
    Run this while signed in as Dad or Mum, in a normal (not "Run as administrator")
    PowerShell window. It changes only the current account: text size, tips and
    suggestions, taskbar clutter, accidental keyboard shortcuts, window snapping.

    The value of every setting before its first change is saved to
    %LOCALAPPDATA%\windows4seniors\original-user-settings.json, and
    Restore-Settings.ps1 -Scope User puts it back.

    Sign out and back in afterwards: text size and some taskbar changes only apply then.

.PARAMETER Person
    The profile to use, from setup\profiles (papa or mama).

.PARAMETER Force
    Don't ask for confirmation before changing the account.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Set-UserSettings.ps1 -Person papa -WhatIf
    Shows what would change, without changing anything.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\Set-UserSettings.ps1 -Person papa
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Person,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'lib\Common.ps1')

$settings = Get-W4SProfile -Person $Person

Write-Host ''
Write-Host "windows4seniors: user settings for '$($settings.DisplayName)'" -ForegroundColor White
Write-Host "Windows account being changed: $env:USERDOMAIN\$env:USERNAME"
if (Test-W4SAdmin) {
    Write-W4SStatus warning 'PowerShell is running as administrator. If you typed an admin password to start it, these settings will go to that account, not to the senior''s. Close it and run it normally.'
}
if (-not $WhatIfPreference -and -not $Force) {
    if (-not $PSCmdlet.ShouldContinue("Change the settings of the account '$env:USERNAME'?", 'windows4seniors')) {
        return
    }
}

Initialize-W4SBackup -Path (Get-W4SBackupPath -Scope User)

$accessibility = 'HKCU:\Software\Microsoft\Accessibility'
$controlPanelAccessibility = 'HKCU:\Control Panel\Accessibility'
$explorerAdvanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$contentDelivery = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'

# --- Reading ---------------------------------------------------------------------------

Write-W4SSection 'Reading'

if ($settings.TextScalePercent -lt 100 -or $settings.TextScalePercent -gt 225) {
    throw "TextScalePercent must be between 100 and 225 (profile '$Person')."
}
Set-W4SRegistryValue -Path $accessibility -Name 'TextScaleFactor' -Value $settings.TextScalePercent `
    -Description "Text size $($settings.TextScalePercent)%"
Set-W4SRegistryValue -Path $controlPanelAccessibility -Name 'DynamicScrollbars' -Value 0 `
    -Description 'Always show scrollbars'
Set-W4SRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 `
    -Description 'Transparency effects off (sharper text)'
Set-W4SRegistryValue -Path $controlPanelAccessibility -Name 'MessageDuration' -Value $settings.NotificationSeconds `
    -Description "Notifications stay on screen for $($settings.NotificationSeconds) seconds"

# --- Sound -----------------------------------------------------------------------------

Write-W4SSection 'Sound'

Set-W4SRegistryValue -Path 'HKCU:\Software\Microsoft\Multimedia\Audio' -Name 'AccessibilityMonoMixState' `
    -Value ([int][bool]$settings.MonoAudio) -Description "Mono audio $(if ($settings.MonoAudio) { 'on' } else { 'off' })"

# --- Mouse and keyboard ----------------------------------------------------------------

Write-W4SSection 'Mouse and keyboard'

if ($null -ne $settings.DoubleClickMs) {
    Set-W4SRegistryValue -Path 'HKCU:\Control Panel\Mouse' -Name 'DoubleClickSpeed' -Type String `
        -Value ([string]$settings.DoubleClickMs) -Description "Double-click speed $($settings.DoubleClickMs) ms"
} else {
    Write-W4SStatus skipped 'Double-click speed (left as it is in this profile)'
}

# The keyboard shortcuts that switch these features on by accident (Shift five times,
# holding Right Shift, holding Num Lock) are bit 0x4 of each Flags value. Clear only
# that bit and keep whatever else is set. The defaults are the Windows defaults.
$accidentalShortcuts = @(
    @{ Key = 'StickyKeys'; Default = 510; Description = 'Sticky Keys shortcut (Shift x5) off' }
    @{ Key = 'Keyboard Response'; Default = 126; Description = 'Filter Keys shortcut (hold Right Shift) off' }
    @{ Key = 'ToggleKeys'; Default = 62; Description = 'Toggle Keys shortcut (hold Num Lock) off' }
)
foreach ($shortcut in $accidentalShortcuts) {
    $path = "$controlPanelAccessibility\$($shortcut.Key)"
    $current = Get-W4SRegistryValue -Path $path -Name 'Flags'
    $flags = $shortcut.Default
    if ($current.Exists) { $flags = [int]$current.Value }
    Set-W4SRegistryValue -Path $path -Name 'Flags' -Type String -Value ([string]($flags -band (-bnot 4))) `
        -Description $shortcut.Description
}

Set-W4SRegistryValue -Path 'HKCU:\Control Panel\Desktop' -Name 'WindowArrangementActive' -Type String -Value '0' `
    -Description 'Snap windows off (windows don''t jump when dragged to an edge)'
Set-W4SRegistryValue -Path $explorerAdvanced -Name 'DisallowShaking' -Value 1 `
    -Description 'Shaking a window doesn''t minimise the others'

# --- Taskbar and Start -----------------------------------------------------------------

Write-W4SSection 'Taskbar and Start menu'

Set-W4SRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -Value 0 `
    -Description 'Taskbar: hide Search'
Set-W4SRegistryValue -Path $explorerAdvanced -Name 'ShowTaskViewButton' -Value 0 `
    -Description 'Taskbar: hide Task view'
Set-W4SRegistryValue -Path $explorerAdvanced -Name 'ShowCopilotButton' -Value 0 `
    -Description 'Taskbar: hide Copilot button (older Windows versions)'
Set-W4SRegistryValue -Path $explorerAdvanced -Name 'Start_TrackDocs' -Value 0 `
    -Description 'Start: no recent files'
Set-W4SRegistryValue -Path $explorerAdvanced -Name 'Start_IrisRecommendations' -Value 0 `
    -Description 'Start: no tips, shortcuts or app recommendations'
Set-W4SRegistryValue -Path $explorerAdvanced -Name 'Start_AccountNotifications' -Value 0 `
    -Description 'Start: no account notifications'

# --- Tips, suggestions and ads ---------------------------------------------------------

Write-W4SSection 'Tips, suggestions and ads'

$contentDeliveryOff = [ordered]@{
    'SubscribedContent-310093Enabled' = 'No "welcome experience" after updates'
    'SubscribedContent-338388Enabled' = 'No app suggestions in Start'
    'SubscribedContent-338389Enabled' = 'No tips and suggestions notifications'
    'SubscribedContent-338393Enabled' = 'No suggested content in Settings (1 of 3)'
    'SubscribedContent-353694Enabled' = 'No suggested content in Settings (2 of 3)'
    'SubscribedContent-353696Enabled' = 'No suggested content in Settings (3 of 3)'
    'SystemPaneSuggestionsEnabled'    = 'No suggestions in Start'
    'SoftLandingEnabled'              = 'No "tips about Windows"'
    'RotatingLockScreenOverlayEnabled' = 'No fun facts and tips on the lock screen'
    'SilentInstalledAppsEnabled'      = 'No automatically installed suggested apps'
}
foreach ($name in $contentDeliveryOff.Keys) {
    Set-W4SRegistryValue -Path $contentDelivery -Name $name -Value 0 -Description $contentDeliveryOff[$name]
}
Set-W4SRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement' -Name 'ScoobeSystemSettingEnabled' -Value 0 `
    -Description 'No "Let''s finish setting up your device" screens'
Set-W4SRegistryValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 `
    -Description 'Advertising ID off'

# --- Summary ---------------------------------------------------------------------------

Write-Host ''
if ($WhatIfPreference) {
    Write-Host 'Preview only: nothing was changed.' -ForegroundColor Cyan
} elseif ($script:W4SChangeCount -gt 0) {
    Write-Host "$script:W4SChangeCount setting(s) changed. Sign out and back in to see all of them." -ForegroundColor Green
    Write-Host "Original values saved in $(Get-W4SBackupPath -Scope User)"
} else {
    Write-Host 'Everything was already set. Nothing changed.' -ForegroundColor Green
}
Write-Host 'Next: the manual steps in setup\README.md (notifications, Live captions, sign-in, Chrome).'
