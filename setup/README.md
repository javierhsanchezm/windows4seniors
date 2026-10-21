# Windows setup

Scripts that apply the Phase 0 settings from [docs/PLAN.md](../docs/PLAN.md) to Dad's
and Mum's PCs, plus a checklist of the steps a script can't do.

| Script | Run it as | What it changes |
|---|---|---|
| `Set-MachineSettings.ps1` | **Your admin account**, PowerShell opened with *Run as administrator* | Chrome protection, no Widgets, Windows Update active hours, power settings. Also reports the Windows version and Smart App Control |
| `Set-UserSettings.ps1` | **Signed in as Dad or Mum**, a normal PowerShell window | Text size, scrollbars, notification duration, accidental keyboard shortcuts, window snapping, taskbar and Start clutter, tips and ads |
| `Restore-Settings.ps1` | The same account as the script you're undoing | Puts every changed setting back to its value from before the first run |

The differences between Dad and Mum are in [`profiles/papa.psd1`](profiles/papa.psd1)
and [`profiles/mama.psd1`](profiles/mama.psd1). Change a number there, not in the
scripts.

## How to run

1. On the PC, download this repository: **Code → Download ZIP** on GitHub, and extract it
   to `C:\windows4seniors`.
2. Create the Windows accounts first (see *Before the scripts* below).
3. **Machine settings**, from your admin account: open the Start menu, type
   `PowerShell`, right-click it and choose *Run as administrator*. Then:

   ```powershell
   cd C:\windows4seniors\setup
   powershell -ExecutionPolicy Bypass -File .\Set-MachineSettings.ps1 -Person papa -WhatIf   # preview
   powershell -ExecutionPolicy Bypass -File .\Set-MachineSettings.ps1 -Person papa           # apply
   ```

4. **User settings**: sign in as Dad (or Mum) and open PowerShell normally (*not* as
   administrator). Then:

   ```powershell
   cd C:\windows4seniors\setup
   powershell -ExecutionPolicy Bypass -File .\Set-UserSettings.ps1 -Person papa -WhatIf      # preview
   powershell -ExecutionPolicy Bypass -File .\Set-UserSettings.ps1 -Person papa              # apply
   ```

5. Sign out and back in.

Use `-Person mama` on Mum's PC.

Notes:
- `-WhatIf` shows every change it would make, without making any.
- The scripts can be run again safely: anything already set is reported as `[ok]`.
- `-ExecutionPolicy Bypass` is needed because Windows blocks unsigned scripts by
  default. It applies only to that one command.
- After the machine script, Chrome shows *"Managed by your organization"* in its menu.
  That's expected: it's how Chrome shows that protection settings are active. Check them
  at `chrome://policy`.

### Undo

```powershell
powershell -ExecutionPolicy Bypass -File .\Restore-Settings.ps1 -Scope User      # as Dad or Mum
powershell -ExecutionPolicy Bypass -File .\Restore-Settings.ps1 -Scope Machine   # as admin
```

The original values are kept in `%LOCALAPPDATA%\windows4seniors\` (user) and
`%ProgramData%\windows4seniors\` (machine).

## Before the scripts

- [ ] Install all Windows updates (Settings → Windows Update), restarting until none are left.
- [ ] Your account: **administrator**, with a password only you know.
- [ ] Dad's or Mum's account: **standard user** (Settings → Accounts → Other users).
- [ ] Install **Google Chrome**, **Microsoft 365** (Word, Excel, Outlook) and **WhatsApp**
      (Microsoft Store), from your admin account.
- [ ] Install **Chrome Remote Desktop** with unattended access
      (remotedesktop.google.com/access), so you can help remotely.

## After the scripts (by hand)

Signed in as Dad or Mum:

**Sign-in and display**
- [ ] Settings → Accounts → Sign-in options: set up **face recognition** (if the camera
      supports it) or a **PIN**. Under *If you've been away…*, choose **Never**.
- [ ] Settings → System → Display: keep the recommended **Scale**. Increase it if text
      still looks small.
- [ ] Lock screen: a family photo. Turn off *Get fun facts, tips, tricks*.

**Sound and captions** (Dad especially)
- [ ] Settings → Accessibility → Audio: **Flash my screen during audio notifications**.
- [ ] Turn on **Live captions** once (Win + Ctrl + L), choose **Español**, and pin it to the
      top of the screen if he wants it during calls.
- [ ] Pair the hearing aids or plug in the TV streamer (docs/PLAN.md, section 7).

**Notifications**
- [ ] Settings → System → Notifications: turn **off** every app except WhatsApp, Outlook
      and (for Mum) Teams.

**Mouse**
- [ ] File Explorer → ⋯ → Options: **Single-click to open an item**.
- [ ] Optional: Control Panel → Mouse → Pointer options: *Show location of pointer when I
      press CTRL*.

**Apps**
- [ ] Chrome: set it as the **default browser**. Settings → Appearance: page zoom 125% if
      useful. Sign in to the newspapers.
- [ ] Chrome: check that **uBlock Origin Lite** is installed (puzzle icon). In its settings,
      turn on the *Annoyances* filters (cookie notices).
- [ ] YouTube (signed in): Settings → Playback and performance → **Always show captions**.
- [ ] Outlook: add his Gmail account. Turn off *Focused Inbox* and conversation grouping.
- [ ] WhatsApp Desktop: link it to the phone (QR code). On the phone: WhatsApp →
      Settings → Privacy → Calls → **Silence unknown callers**.
- [ ] Gmail (in the browser): a filter that moves mail from unknown senders out of the
      inbox into a *Revisar* label, for you to check on visits.
- [ ] Mum: create the permanent **family video room** link (Google Meet and/or Teams) and
      test joining it from Chrome.
