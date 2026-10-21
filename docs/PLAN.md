# Windows for Seniors — Plan

A simple, safe, large-print Windows 11 Home setup for Dad (95), and possibly Mum (80s),
with a small set of apps, hearing aids connected to the PC, and a home-made
memory and attention trainer.

Everything the parents see is in **Colombian Spanish**. The answers to the original open
questions, and what they change, are in **§12 Decisions**.

This document is the thinking: what to do, in which order, and why. Nothing here
needs code until Phase 1.

---

## 1. Guiding principles

Every decision below follows from these rules:

1. **Fewer choices.** About eight big buttons. If something isn't on the Home screen, it
   doesn't exist for him.
2. **There's always a way home.** One big "Home" button that is always visible and
   always works, whatever app is open.
3. **Nothing pops up unexpectedly.** No tips, no "Try Copilot", no restart nags, no
   website notifications, no cookie banners if we can avoid them.
4. **Big, high contrast and clearly labelled.** Words next to icons, never icons on
   their own.
5. **One left click does everything.** No double-click, right-click, drag-and-drop or
   hover menus.
6. **He can't break it, and you can fix it from home.** He uses a standard account,
   and you have remote access that doesn't need him to do anything.
7. **Protect him from scams.** For a 95-year-old online, scams are a bigger risk than
   viruses.
8. **Watch him use it, then adjust.** Sit beside him for an hour and write down every
   moment he hesitates. That list is the real backlog.

---

## 2. The big picture

```
 ┌──────────────── Dad's Windows account (standard user, no admin) ────────────────┐
 │                                                                                 │
 │  ┌─ Top bar (always visible) ─────────────────────────────────────────────────┐ │
 │  │ [🏠 Home]   Tuesday 21 October · 10:42 · morning    [🔉 − ] [🔊 + ] [❓ Help] │ │
 │  └────────────────────────────────────────────────────────────────────────────┘ │
 │  ┌─ Home screen (full screen, opens at sign-in) ──────────────────────────────┐ │
 │  │   [ Email ]      [ WhatsApp ]     [ YouTube ]     [ Newspaper A ]          │ │
 │  │   [ Word ]       [ Excel ]        [ Internet ]    [ Newspaper B ]          │ │
 │  │   [ Brain games ]                 [ Family photos ]                         │ │
 │  └────────────────────────────────────────────────────────────────────────────┘ │
 │                                                                                 │
 │  Windows 11 Home: decluttered, bigger text and pointer, no nags                 │
 │  Chrome: newspapers and YouTube open as their own windows, ads and scams blocked │
 │  Audio → hearing aids (LE Audio / classic Bluetooth / TV streamer)              │
 └─────────────────────────────────────────────────────────────────────────────────┘
        ▲ You: unattended remote access (Chrome Remote Desktop)
        ▲ You: Home screen configuration and updates published from this repo
```

There are three parts:

| Part | What it is | Code? |
|---|---|---|
| **A. Windows setup** | Accounts, accessibility, decluttering, Chrome, safety, remote help | No (a PowerShell script later, to make it repeatable) |
| **B. Home launcher** | A full-screen Home screen with big tiles, plus the always-visible top bar | Yes (Phase 1) |
| **C. Brain trainer** | Daily 10–15 minute sessions for memory, attention, language and reasoning | Yes (Phase 2) |

---

## 3. Windows 11 Home has no kiosk mode

Windows has a built-in way to restrict a user to a few apps, called **Assigned Access**
(single-app or multi-app kiosk), but it isn't available on Home. It needs
Pro, Enterprise or Education. Group Policy Editor and Shell Launcher are also missing
from Home.

Options:

| Option | Pros | Cons |
|---|---|---|
| **Upgrade to Pro** and use a multi-app kiosk | A real lockdown | Configured with XML, hard to change, awkward with Store apps (WhatsApp, new Outlook), and it costs money |
| **Light lockdown (recommended)**: standard account, decluttered Windows, and our own launcher | Works on Home, flexible, he can still do anything when he wants to | Not a security barrier: a determined user can get out. Your dad isn't trying to |

**Recommendation:** go with the light lockdown. We're not defending against your father.
We're removing confusion. Only consider Pro if, after a few weeks, he keeps ending up
somewhere he can't get back from.

---

## 4. Phase 0: set up Windows (no code, one afternoon)

### 4.1 Accounts

- **Your account: administrator**, with a password only you know.
- **Dad's account: standard user.** He can't install software or change system
  settings, and neither can a scammer talking him through it on the phone.
- **Sign-in:** Windows Hello **face recognition** is ideal: he sits down and he's in.
  This needs a Windows Hello (IR) webcam; a cheap one plugs in over USB. Otherwise
  use a 4-digit PIN.
- Settings → Accounts → Sign-in options → *If you've been away, when should Windows
  require you to sign in again?* → **Never**.

### 4.2 Make everything bigger

| Setting | Where | Suggested value |
|---|---|---|
| Display scale | Settings → System → Display → Scale | 150–175% (scales everything) |
| Text size | Settings → Accessibility → Text size | 125–150% extra on top of scaling |
| Mouse pointer size and colour | Accessibility → Mouse pointer and touch | Size 4–6, custom bright colour (lime or yellow) with a black outline |
| Text cursor | Accessibility → Text cursor | Turn on the text cursor indicator and make it thicker |
| Scrollbars | Accessibility → Visual effects | Always show scrollbars |
| Transparency and animations | Accessibility → Visual effects | Off (sharper and calmer) |
| Notification duration | Accessibility → Visual effects | 1–5 minutes |
| Contrast and colour | Accessibility → Contrast themes / Color filters | Try them with him. Some older eyes (cataracts, macular degeneration) do better with high contrast |
| Magnifier | Win + Plus | Teach this only if he needs it |

The Windows 11 taskbar itself can't be made bigger. Display scaling is the only
supported way, which is another reason the launcher gets its own large top bar.

### 4.3 Simplify the mouse

- **Hardware first:** a large two-button mouse, wired so the batteries never run out, or a
  **trackball** if he has a tremor. The ball moves, his hand doesn't.
- Settings → Bluetooth & devices → Mouse: **slower pointer speed**, scroll fewer lines
  at a time.
- *Additional mouse settings* (old Control Panel):
  - **Double-click speed: slowest**, for the few places that still need it.
  - **Show location of pointer when I press CTRL**: on.
  - *Enhance pointer precision*: try it on and off with him. With a tremor, one is
    usually clearly better.
- File Explorer → Options → **Single-click to open an item** (applies to the desktop too).
- **Remove right-click** (optional): if right-click menus confuse him, turn the right
  button off for his account only, using the mouse vendor's software (Logitech Options+,
  Microsoft Mouse and Keyboard Center) or a one-line AutoHotkey script.
- **PowerToys** (free, from Microsoft): turn on only *Find My Mouse* (shake the mouse to
  spotlight the pointer) and *Keyboard Manager* (to disable Caps Lock, Insert and
  similar keys).
- Settings → System → Multitasking: **Snap windows off** and *Title bar window shake* off,
  so windows don't jump around when dragged.

### 4.4 Keyboard

- A **large-print, high-contrast keyboard** (yellow keys with black letters) helps.
- Accessibility → Keyboard: **turn off the shortcuts** for Sticky Keys (Shift ×5) and
  Filter Keys (hold Right Shift). Accidental pop-ups from these confuse many seniors.
- If he has a tremor: Filter Keys → *Ignore brief or repeated keystrokes*.
- **Voice typing (Win + H)** works for writing emails, and WhatsApp messages if typing is
  hard. **Voice access** (control the PC by voice) supports English, Spanish, French,
  German, Italian and more.

### 4.5 Remove distractions and surprises

- **Taskbar:** hide Search, Task view, Widgets and Copilot. Pin only his apps, or nothing,
  if the launcher's top bar replaces it.
- **Start menu:** turn off recently added apps, recommended files, and "recommendations
  for tips, shortcuts, new apps".
- **Notifications:** turn off everything except WhatsApp and Outlook, if he wants those.
  Under *Additional settings*, turn off "Show the Windows welcome experience…",
  "Suggest ways to get the most out of Windows" and "Get tips and suggestions".
- **Lock screen:** a family photo. Turn off "fun facts, tips, tricks".
- **Privacy & security → General:** turn off suggested content and ad ID.
- **Startup apps:** disable everything that isn't needed (Teams, Edge boost, game launchers).
- **Edge:** you can't remove it, but take it out of sight and make Chrome the default
  browser. Choose the default mail and PDF apps on purpose.
- **OneDrive:** set it up once, intentionally. Backing up Documents is good, but
  "Back up your folders?" pop-ups are not. Decide, then silence the prompts.

### 4.6 Sleep, power and updates

- Screen off after about 20 minutes. Sleep after 1 hour, or never on a desktop PC.
  Moving the mouse wakes it.
- **Windows Update → Active hours** set to his real day, for example 8:00–23:00.
  Restarts happen at night.
- Install updates yourself, remotely, every month or so, so he never sees an "Update
  and restart" decision.

### 4.7 Hardware matters more than software

| Item | Why |
|---|---|
| 24–27" matte monitor at eye level, or a desktop/all-in-one rather than a laptop | No touchpad or lid; big, steady picture |
| Speakers with a **physical volume knob**, or a USB volume knob | A knob is easier than on-screen sliders |
| Webcam with a good microphone, optionally Windows Hello | WhatsApp video calls with family, and face sign-in |
| Trackball or large mouse; large-print keyboard | See above |
| Optional: a **big USB button** set to "Home" or "Help" | A physical button he can always find |
| Good lighting, no glare on the screen | Often forgotten, makes a big difference |

### 4.8 Remote help for you (essential)

- **Chrome Remote Desktop** with *unattended access* (free; works on Windows Home): you
  connect whenever you need to, with a PIN, without him reading out codes. Windows'
  own Remote Desktop host is not available on Home.
- Quick Assist (built in) is a backup, but it needs him to type a code.
- The launcher's **Help** button can message you ("Dad pressed Help"), so you can connect
  straight away (see §8).

---

## 5. The apps

| App | Install | Senior-friendly settings |
|---|---|---|
| **Outlook** (the new Outlook for Windows, or classic if he relies on it) | Microsoft 365. *Microsoft 365 Family* covers up to 6 people, so it can include both parents | Larger text (Settings → Layout → Text size), **Focused Inbox off**, **conversation grouping off** (one email per line), larger reading pane. Contacts with photos. **Junk filter: trust only Safe Senders** (only family and known senders reach the Inbox) |
| **WhatsApp Desktop** | Microsoft Store | Linked to his phone. WhatsApp Desktop is a "linked device", so **he needs WhatsApp on a smartphone**, and the link drops if the phone isn't used for about 14 days. Zoom in (Ctrl +). Video calls to family work well from a PC with a webcam. Privacy: *Silence unknown callers*; only contacts can add him to groups |
| **YouTube** | A Chrome app window (see below) | **YouTube Premium (Family)** removes ads, which confuse seniors ("Skip ad", fake buttons). Turn on **Always show captions** (helps with hearing). Make playlists for him: music from his youth, chair exercises, documentaries |
| **Word / Excel** | Microsoft 365 | Larger default font: in Word, Home → Font → *Set As Default* (for example 16 pt); in Excel, File → Options → General → *Font size* for new workbooks. Use the simplified ribbon where available. Save to a single, obvious "Documents" folder |
| **Chrome** | google.com/chrome | See 5.2 |
| **Newspapers** | Chrome app windows | See 5.1 |

### 5.1 Newspapers (and YouTube) as their own apps

Each newspaper becomes its own window with its own icon and **no address bar or
tabs**, so he can't wander off:

- Chrome menu → *Cast, save and share* → **Install page as app** (in older Chrome:
  *More tools → Create shortcut → Open as window*), **or**
- The launcher starts `chrome.exe --app=https://<newspaper> --start-maximized`, which gives
  the same clean window.

Then:

- Sign in to his subscriptions once, and the session stays logged in.
- Chrome → Settings → Appearance: **larger page zoom** (125–150%) and a larger font size.
- Chrome **Reading mode** (right-click → *Open in reading mode*) shows articles as plain
  large text without ads, and can **read aloud**. Edge's *Immersive Reader* is even better
  for listening, so it's worth trying if listening suits him.
- **Cookie banners and ads:** install **uBlock Origin Lite** and enable its "annoyances"
  filters, which also hide most cookie notices.

### 5.2 Chrome hardening (scam protection)

Set these as Chrome policies (registry, applied to his account or machine-wide):

- **Block all website notifications** (`DefaultNotificationsSetting = 2`). Fake "Your PC
  is infected!" notifications are the main tech-support scam route.
- Pop-ups blocked; **Safe Browsing: Enhanced protection**.
- **Force-install uBlock Origin Lite** from the Chrome Web Store; block every other
  extension.
- No guest mode or adding profiles; developer tools off.
- Password manager **on**: you save his passwords so he never types them.

> Note: on a home (unmanaged) Windows PC, Chrome ignores a few policies such as home
> page and startup pages. That's fine here, because the launcher opens the right page
> directly.

---

## 6. Safety: scams are the main risk

- Standard (non-admin) account (§4.1).
- **Safer DNS**: Cloudflare 1.1.1.2 (blocks malware) or Quad9, set on the PC (Settings →
  Network → DNS) or on the home router.
- **Smart App Control**: if the PC is new and it shows *On* or *Evaluation*, leave it on.
  It blocks unknown apps. Once turned off, it can't be turned back on without
  reinstalling Windows.
- Outlook trusts **Safe Senders only** (§5).
- WhatsApp: silence unknown callers. **Agree a family rule**: "We will never ask you for
  money or codes by WhatsApp or email, especially from a new number." The "Hi Dad,
  this is my new number" scam targets exactly his generation.
- Keep a printed card next to the PC: *"If anything asks you to call a number, pay, or
  install something: stop and press Help."*

---

## 7. Hearing aids over Bluetooth

What works depends entirely on **which Bluetooth technology his hearing aids use**,
so start by finding the brand and model (ask his audiologist).

### 7.1 Dad's hearing aids: Amplifon, Bluetooth, model unknown

Amplifon is mainly a **retail chain**. It sells its own models, which are built by
other manufacturers, as well as other brands. So "Amplifon + Bluetooth" doesn't tell
us which branch of the tree below applies. At the Amplifon store, ask:

1. The **exact model** and the **real manufacturer**.
2. Can they **stream from any Bluetooth device** (classic Bluetooth), only from **iPhone**
   (MFi) or **Android** (ASHA), or do they support **LE Audio / Auracast**?
3. Is there a **TV streamer** accessory for this model, and what does it cost?

On the new PC, check Settings → Bluetooth & devices. If it offers an **LE Audio**
option, the PC side is ready for path A.

```
Do the hearing aids support Bluetooth LE Audio (sometimes marketed as "Auracast")?
 ├─ Yes, and the PC supports LE Audio ──▶ A. Pair them directly in Windows 11 (24H2 or later)
 └─ No ─▶ Do they support classic Bluetooth (streaming to "any phone" or headset-style)?
           ├─ Yes (e.g. Phonak Marvel and newer) ──▶ B. Pair them like a Bluetooth headset
           └─ No (iPhone-only "MFi" or Android-only "ASHA") ──▶ C. Use the maker's TV streamer
```

**A. LE Audio (best when available).** Windows 11 24H2 and later supports LE Audio hearing
aids directly. Settings → Bluetooth & devices shows them as hearing devices, where he can
switch **presets** (the programs his audiologist set) and adjust **ambient sound**,
depending on the model. Both the hearing aids and the PC's Bluetooth need LE Audio.
Note that iPhone-only (MFi) and Android-only (ASHA) hearing aids are *not* LE Audio,
even if they say "Bluetooth LE".

**B. Classic Bluetooth.** Some brands (Phonak is the best-known) stream over standard
Bluetooth profiles (A2DP/HFP) and pair with a PC like a headset. Things to watch for:
- They can stream from only one device at a time. If his phone is connected, the PC may
  not get audio.
- If they show up as "LE" rather than as an audio device, remove that entry and pair
  again.

**C. TV streamer (most reliable for any brand).** Every major maker sells a small
**TV streamer/adapter** that plugs into an audio output (3.5 mm jack or optical) and
streams to the hearing aids. Plug it into the PC (with a USB sound adapter if
needed). No Bluetooth pairing on the PC, so nothing to reconnect after sleep. For a
95-year-old, this simplicity is often worth the cost.

**In any case:**
- Windows → Accessibility → Audio: **Mono audio** if one ear is much weaker. *Flash the
  screen* for alert sounds.
- **Live captions** (Win + Ctrl + L) subtitle *any* sound on the PC, including WhatsApp
  calls and YouTube. Spanish and many other languages are supported. This may help him
  more than anything else.
- The launcher's top bar can show **where the sound is going** ("🔊 Hearing aids" or
  "🔊 Speakers") with one button to switch, because "I can't hear anything" will be the
  most common problem.

---

## 8. Phase 1: the Home launcher (code)

### 8.1 What it does

- **Opens full screen at sign-in** for his account.
- **8–10 large tiles** (at least 200×200 px, icon and word, high contrast). One click
  opens the app **maximized**. If the app is already open, it **switches to it** instead
  of opening another copy, so we don't end up with 30 Chrome windows.
- **Always-visible top bar**, docked using the Windows *AppBar* API so maximized apps
  never cover it:
  - **🏠 Home**: brings the Home screen to the front from anywhere.
  - Large **day, date, time and part of day** ("Tuesday, 21 October — morning"), which
    helps orientation.
  - **Volume − / +** and the current audio output (hearing aids or speakers).
  - **❓ Help**: sends you a notification (for example via ntfy.sh or Telegram) and/or
    opens your WhatsApp chat, so you can connect remotely.
- **Family photos** slideshow tile, from a shared OneDrive folder the whole family can add to.
- **Returns to Home** after the PC wakes up, and optionally after long inactivity
  (except while a video is playing).
- **Hidden family/admin mode** (for example, hold the clock for 5 seconds and enter a
  PIN) to exit or reconfigure it.
- **Configuration in a JSON file**, kept in this repo or a synced folder, so you can add
  a newspaper or change a tile **remotely** without touching his PC:

```json
{
  "person": "Papá",
  "language": "es-CO",
  "helpContact": { "name": "Javier", "whatsapp": "+57XXXXXXXXXX" },
  "tiles": [
    { "label": "Correo",             "icon": "mail",      "open": { "app": "<AppID from Get-StartApps>" } },
    { "label": "WhatsApp",           "icon": "whatsapp",  "open": { "app": "<AppID from Get-StartApps>" } },
    { "label": "YouTube",            "icon": "youtube",   "open": { "web": "https://www.youtube.com" } },
    { "label": "Periódico",          "icon": "newspaper", "open": { "web": "https://<newspaper>" } },
    { "label": "Word",               "icon": "word",      "open": { "app": "<AppID from Get-StartApps>" } },
    { "label": "Excel",              "icon": "excel",     "open": { "app": "<AppID from Get-StartApps>" } },
    { "label": "Internet",           "icon": "globe",     "open": { "browser": "https://www.google.com" } },
    { "label": "Juegos de memoria",  "icon": "brain",     "open": { "internal": "/brain" } }
  ]
}
```

(`Get-StartApps` in PowerShell lists the AppID of every installed app, Store apps like
WhatsApp included. The launcher starts them with `explorer.exe shell:AppsFolder\<AppID>`.)

### 8.2 Technology

**Recommendation: one TypeScript web codebase for the user interface, wrapped in
[Tauri](https://tauri.app) for Windows.**

- The launcher and the brain trainer share the same large-button components, fonts and
  colours.
- Tauri uses WebView2, which is already part of Windows 11, so it's a small installer.
  A thin native layer handles the things a web page can't do: launch and focus apps,
  the docked AppBar, system volume and audio output, and auto-start at sign-in.
- The same brain-trainer code can also run as an installable web app (PWA) on **Mum's
  tablet**.
- Electron would also work if you'd rather stay in JavaScript only; it's just a bigger
  installer.

---

## 9. Phase 2: the brain trainer (code)

### 9.1 Set expectations honestly

- Brain-training games reliably make people **better at the games**. Gains in everyday
  memory are smaller and less certain. One notable exception is *speed-of-processing*
  training in the long-running **ACTIVE** study, which was linked to a lower dementia
  risk ten years later.
- What has the strongest evidence for older adults is a **mix**: physical activity,
  social contact, hearing correction (so the hearing aids matter!), sleep, and
  mental activity he **enjoys**.
- So the design goal is **daily, enjoyable, social and successful**, not
  scientifically optimal. A game he looks forward to beats a perfect exercise he avoids.

### 9.2 Design rules for a 95-year-old

- **Success most of the time (~80%).** Adaptive difficulty that eases off quickly.
  Never end a session on a failure.
- **No timers by default.** Speed exercises are gentle and never penalised.
- **One click only.** No drag-and-drop. To "move" something, click it and then click
  where it goes.
- **Huge targets** (≥ 120 px), large text (≥ 28 pt), high contrast, one task per screen.
- **Spoken instructions** (Windows' natural text-to-speech voices, which play through his
  hearing aids) **and** written ones. Always a "Repeat" button.
- **Always visible:** "Hint", "Skip" and "Finish". Nothing is ever "wrong" in red. Use
  "Let's try another one" instead.
- **Progress means showing up**, not scores: "You practised 5 days this week ⭐".
  Detailed trends are only for the family, if wanted (see 9.6).

### 9.3 Activities

| Area | Activity | How it works | Personal touch |
|---|---|---|---|
| Memory | **Family pairs** | Turn cards to find pairs (4 → 16 cards) | Family photos; says the name when a pair is found |
| Memory | **What's new?** | Objects on screen; next screen has one more; click the new one | Familiar objects from his life |
| Memory (delayed) | **Morning story** | Listen to and read a short story at the start; 3 questions at the end | Taken from today's newspaper |
| Memory | **Who is this?** | Photo with 3 large name options | Grandchildren and great-grandchildren. Gentle, always shows the answer |
| Attention | **Odd one out** | Find the one that's different | — |
| Attention | **Spot the difference** | Two pictures, click the differences | Old photos of his town |
| Attention / speed | **Catch it** | Click when the target appears, no penalty for misses | — |
| Language | **Finish the saying** | Proverbs and sayings, multiple choice | Sayings from his generation and region. He'll get these right, which builds confidence |
| Language | **Word search / anagrams** | Large grid, click letters | Themes he likes |
| Language | **Name as many…** | "Name fruits", answered by voice (later) | — |
| Reasoning | **Mini sudoku 4×4 / 6×6**, **Sort it** (put items into groups) | Click-and-place | — |
| Numbers | **Shopping change** | "You pay with 20 for 13.50; what's your change?" | His currency, real prices |
| Orientation | **Today** | Day, date, season, weather, one headline | Daily warm-up |
| Reminiscence | **Tell me about…** | A photo or question ("your first job?"); **records his answer** | Builds a family archive of his stories |
| Music | **Name that tune** | Short clips with 3 options | Songs from the 1940s–60s |

### 9.4 A daily session (10–15 minutes)

1. **Today** (orientation warm-up).
2. **Morning story** (listen and read).
3. Three games from different areas, chosen by the app and rotated each day.
4. **Morning story questions** (delayed recall).
5. Finish with something enjoyable: **reminiscence** or **music**.
6. Celebrate and show the week's ⭐ calendar.

He can also just open any game he likes from a "Free play" screen.

### 9.5 Adaptive difficulty

Each game has levels (for example the number of cards, the number of options, the
similarity between items). A simple rule: **two successes, go up a level; one
failure, go down a level and give a hint.** This keeps him around the 80% target. Store
the level per game, so the next session starts where he's comfortable.

### 9.6 Family content and family view

- Family members put photos into a shared folder with the name in the file name
  (`Lucia 2024.jpg`). The trainer and the photo slideshow read from it.
- A small "life profile" (where he was born, his job, his football team, favourite music)
  personalises the questions.
- **Privacy:** family photos and recordings stay on the PC or in private storage, **never**
  on a public website.
- Optional **family view**: days practised, favourite games, levels over time. This is
  *not* a medical test. If the family notices a sudden change, talk to his doctor.

### 9.7 Optional, later: AI

- Generate the daily *Morning story* and its questions from a real news article.
- Create personalised quizzes from his life profile.
- A gentle voice conversation ("Tell me about your day").

Start without AI, using a hand-picked content bank that the family can review. Add AI
only where it clearly helps, and think about cost, privacy and wrong answers.

### 9.8 Try existing apps first

Before building, spend a week with existing products to learn what he enjoys. For
example: **NeuronUP** and **CogniFit** (both have Spanish versions; NeuronUP is
used by therapists), and **Lumosity** or **Elevate** (game-like, but often too fast
for a 95-year-old). What he enjoys, and what frustrates him, is the spec for ours.

---

## 10. Mum

Mum has **her own PC** and an **Android phone with WhatsApp**. She has no hearing
problems. Her difficulty is **answering video calls** on WhatsApp, Google Meet and
Microsoft Teams.

- **Same launcher, her own configuration** (`config/mama.json`), with fewer tiles and the
  calls at the top.
- **WhatsApp calls:** link WhatsApp Desktop on her PC to her Android phone, so calls ring
  on the PC. Practise answering together a few times, and stick a printed card next to
  the screen ("When it rings: click the green button").
- **A permanent family video room:** create one Google Meet link (and/or Teams meeting)
  that never changes. Her Home screen gets a big **"Videollamada familiar"** tile that
  always opens it. The family says "join the family call" instead of sending new links.
- **Meet and Teams in Chrome**, so she needs no extra apps or accounts. Allow camera and
  microphone once for those sites, so she never sees a permission prompt.
- **Links from others** (a doctor, say) arrive by email or WhatsApp. A *"Unirme a una
  llamada"* tile can open the latest call link it finds, or you can add it to her
  configuration remotely.
- The brain trainer can be offered to her too, at a lighter level.

---

## 11. Roadmap

| Phase | What | Result |
|---|---|---|
| **0. Setup** (1–2 afternoons) | §4–§7: accounts, accessibility, declutter, apps, Chrome, safety, remote access, hearing-aid test | A calmer, safer, larger PC he can use today |
| **0.5 Observe** (1–2 weeks) | Watch him use it; note every confusion | The real requirements |
| **1. Launcher** | §8: Home screen, top bar, Help button, remote JSON config | One place for everything, and he can always get home |
| **1.5 Automate** | PowerShell script that applies all of Phase 0 (repeatable, reversible) | Easy rebuilds, and Mum's account in minutes |
| **2. Brain trainer MVP** | §9: 4 games (Family pairs, Finish the saying, Odd one out, Morning story), daily session, adaptive levels, spoken instructions | A daily habit |
| **3. Grow** | More games, reminiscence recordings, family view, Mum's profile, optional AI content | A family project |

### Proposed repository layout

```
windows4seniors/
├── docs/            Plan, setup checklist, hearing-aid notes
├── setup/           PowerShell scripts: accessibility, declutter, Chrome policies
├── app/             TypeScript web UI: launcher screens and brain games
├── src-tauri/       Native Windows layer: launch/focus apps, AppBar, audio, auto-start
└── config/          Per-person launcher configuration (papa.json, mama.json)
```

---

## 12. Decisions (answered 2026-10-21)

| Question | Answer | What it changes |
|---|---|---|
| Language and country | **Spanish, Colombia** | Interface, voices, sayings (*refranes*), music and newspapers are Colombian (§12.1) |
| Dad's hearing aids | **Amplifon, Bluetooth, model unknown** | Find the exact model (§7.1) |
| Dad's PC | **New desktop / all-in-one** | Should already run Windows 11 24H2 or later; check LE Audio support (§7.1) |
| Dad's accounts | **Microsoft 365; Gmail. No smartphone with WhatsApp** | WhatsApp needs a phone for him (§12.2); Outlook reads Gmail; scam filtering is done in Gmail (§12.3) |
| Dad's main difficulty | **Hearing only** (vision and mouse are fine) | Keep Windows close to normal size; put the effort into sound and captions (§12.4) |
| Mum | **Her own PC and Android phone with WhatsApp; no hearing issues; struggles to answer video calls (WhatsApp, Google Meet, Teams)** | A separate, smaller Home screen for her, built around calls (§10) |
| How to build | **Claude builds it in this repo; Javier tests on the PCs** | Code goes into this repo step by step |
| Distance | **Same city, visits often** | Set things up in person; remote access is still useful but not critical (§12.5) |

### 12.1 Colombian Spanish everywhere

- Launcher and games in Spanish (`es-CO`): *Correo*, *WhatsApp*, *YouTube*, *Periódico*,
  *Juegos de memoria*, *Ayuda*, *Inicio*.
- **Voice:** Windows has no built-in Colombian voice. The natural Spanish (Mexico) voices
  are the closest Latin American accent, and work offline. Two warmer options: record
  instructions in a family member's voice, or use a cloud voice with a Colombian accent.
- **Voice access and voice typing** support Spanish (Mexico), which works fine for
  Colombian speakers.
- **Live captions** support Spanish.
- **Newspapers:** the Colombian papers he reads (to confirm, for example *El Tiempo* or
  *El Espectador*), plus any regional paper from his home town.
- **Brain games content:** Colombian *refranes* and sayings, music from his youth
  (boleros, bambucos, cumbias, pasillos of the 1940s–60s), photos of his home town,
  prices in pesos for the "shopping change" game.

### 12.2 WhatsApp for Dad

WhatsApp on a PC is a "linked device" and can't exist without a phone. Options:

1. **A basic Android phone with a Colombian SIM (recommended)**, kept charging at home.
   Register WhatsApp with his number, link the PC, and open WhatsApp on the phone at
   least every couple of weeks (the PC is disconnected after about 14 days of phone
   inactivity). A family member can do this during visits.
2. Use an existing family number. This isn't recommended, because family chats would mix
   with his.

### 12.3 Gmail in Outlook

The new Outlook adds Gmail accounts directly. Junk and scam filtering then happens in
**Gmail's own settings**: create filters so only family and known senders reach the
inbox, and everything else is labelled for you to review on your visits.

### 12.4 Dad: focus on hearing, not on size

- Display scale: the PC's recommended value, plus a small text-size increase. No need
  for huge pointers or other vision aids.
- **Sound first:** the hearing-aid connection (§7), YouTube *Always show captions*,
  **Live captions** on during WhatsApp video calls, *Flash the screen* for alerts, and a
  clearly visible "where is the sound going?" indicator in the launcher's top bar.
- The launcher's tiles stay large anyway, because that helps everyone.

### 12.5 Same city

- Do Phase 0 **in person**, using a printed checklist.
- Still install **Chrome Remote Desktop** on both PCs: a five-minute remote fix saves
  a trip.
- The **Help** button can simply open a WhatsApp chat with you. A push notification is
  optional.

### 12.6 Next steps

1. **Before the next visit:** ask the Amplifon store for Dad's exact hearing-aid model
   and whether it streams via classic Bluetooth, LE Audio, or only iPhone/Android. Get
   a basic Android phone and SIM for his WhatsApp. Make a list of the newspapers both
   parents read.
2. **Claude:** write the Windows setup script (`setup/`), with a dry-run mode, for both PCs.
3. **Claude:** build the launcher MVP (Spanish, configurable for Dad and Mum).
4. **Claude:** build the brain trainer MVP with Colombian content.

---

## Sources

- Microsoft: [Using hearing devices with your Windows 11 PC](https://support.microsoft.com/accessibility/windows/using-hearing-devices-with-your-windows-11-pc)
- HearingTracker: [Windows 11 to directly pair with hearing aids with Bluetooth LE Audio](https://www.hearingtracker.com/news/windows-11-to-directly-pair-with-hearing-aids-with-bluetooth-le-audio)
- Phonak: [Can I connect Phonak hearing aids to my computer?](https://www.phonak.com/en-ca/support/knowledge-base/articles/laptop-and-phonak-hearing-aids)
- Microsoft: [Set up voice access](https://support.microsoft.com/en-gb/accessibility/windows/voice-access/set-up-voice-access)
- Assigned Access (kiosk) editions: [Redmond Mag, Windows 11 kiosk mode](https://redmondmag.com/articles/2023/06/13/windows-11-kiosk-mode.aspx), [Help Desk Geek, kiosk mode guide](https://helpdeskgeek.com/how-to-set-up-kiosk-mode-windows-11-10/)
