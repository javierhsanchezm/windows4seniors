# Settings profile for Mum's PC and Windows account.
# Mum hears well; her difficulty is answering video calls on WhatsApp, Google Meet and
# Teams (docs/PLAN.md, section 10).
@{
    DisplayName = 'Mama'

    # --- Per-user settings (Set-UserSettings.ps1) ---

    # Extra text size on top of display scaling, 100-225.
    TextScalePercent = 115

    # Double-click speed in milliseconds (Windows default 500, slowest 900).
    # $null leaves it alone.
    DoubleClickMs = $null

    # How long notifications stay on screen, in seconds. A call notification that
    # disappears quickly is a missed call.
    NotificationSeconds = 60

    # Play the same sound in both ears.
    MonoAudio = $false

    # --- Machine settings (Set-MachineSettings.ps1) ---

    # Windows Update won't restart the PC between these hours (span of 18 hours or less).
    ActiveHoursStart = 7
    ActiveHoursEnd = 22

    # Plugged in: turn the screen off after N minutes; sleep after N minutes (0 = never).
    ScreenOffMinutes = 20
    SleepMinutes = 0

    # Sites that may use the camera and microphone without asking, so joining a
    # Meet or Teams call never shows a permission prompt.
    ChromeCameraMicSites = @(
        'https://meet.google.com'
        'https://teams.microsoft.com'
        'https://teams.live.com'
    )
}
