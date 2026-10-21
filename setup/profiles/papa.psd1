# Settings profile for Dad's PC and Windows account.
# Dad's main difficulty is hearing; vision and mouse control are fine (docs/PLAN.md, 12.4).
@{
    DisplayName = 'Papa'

    # --- Per-user settings (Set-UserSettings.ps1) ---

    # Extra text size on top of display scaling, 100-225. A small increase only.
    TextScalePercent = 115

    # Double-click speed in milliseconds (Windows default 500, slowest 900).
    # $null leaves it alone: his mouse control is fine.
    DoubleClickMs = $null

    # How long notifications stay on screen, in seconds. Longer helps when he
    # doesn't hear the notification sound.
    NotificationSeconds = 60

    # Play the same sound in both ears. Turn on if one ear is much weaker.
    MonoAudio = $false

    # --- Machine settings (Set-MachineSettings.ps1) ---

    # Windows Update won't restart the PC between these hours (span of 18 hours or less).
    ActiveHoursStart = 7
    ActiveHoursEnd = 22

    # Plugged in: turn the screen off after N minutes; sleep after N minutes (0 = never).
    ScreenOffMinutes = 20
    SleepMinutes = 0

    # Sites that may use the camera and microphone without asking.
    # Dad makes video calls in the WhatsApp app, not in Chrome.
    ChromeCameraMicSites = @()
}
