//! The parts that talk to Windows directly.

use std::collections::HashSet;
use std::time::{Duration, Instant};

use windows::core::{w, BOOL, HSTRING, PCWSTR};
use windows::Win32::Foundation::{HWND, LPARAM, RECT};
use windows::Win32::Graphics::Gdi::{GetMonitorInfoW, MonitorFromWindow, MONITORINFO, MONITOR_DEFAULTTOPRIMARY};
use windows::Win32::System::Registry::{RegSetKeyValueW, HKEY_CURRENT_USER, REG_SZ};
use windows::Win32::System::Threading::GetCurrentProcessId;
use windows::Win32::UI::Input::KeyboardAndMouse::{
    SendInput, INPUT, INPUT_0, INPUT_KEYBOARD, KEYBDINPUT, KEYBD_EVENT_FLAGS, KEYEVENTF_KEYUP, VK_VOLUME_DOWN,
    VK_VOLUME_UP,
};
use windows::Win32::UI::Shell::{
    SHAppBarMessage, ShellExecuteW, ABE_TOP, ABM_NEW, ABM_QUERYPOS, ABM_REMOVE, ABM_SETPOS, APPBARDATA,
};
use windows::Win32::UI::WindowsAndMessaging::{
    EnumWindows, GetClassNameW, GetForegroundWindow, GetWindow, GetWindowRect, GetWindowTextLengthW,
    GetWindowThreadProcessId, IsIconic, IsWindow, IsWindowVisible, MoveWindow, SetForegroundWindow, ShowWindow,
    GW_OWNER, SW_RESTORE, SW_SHOWMAXIMIZED, WM_USER,
};

/// A top-level window, remembered as its handle plus its process id (a handle can be
/// reused by another window after the first one closes).
#[derive(Debug, Clone, Copy)]
pub struct WindowId {
    hwnd: isize,
    pid: u32,
}

fn hwnd(raw: isize) -> HWND {
    HWND(raw as *mut _)
}

// --- Opening things ---------------------------------------------------------------------

/// Opens a file, program, app or link the way double-clicking it would, maximized.
pub fn shell_open(file: &str, parameters: Option<&str>) -> Result<(), String> {
    let file_w = HSTRING::from(file);
    let parameters_w = parameters.map(HSTRING::from);
    let parameters_ptr = parameters_w.as_ref().map_or(PCWSTR::null(), |p| PCWSTR(p.as_ptr()));
    let result = unsafe {
        ShellExecuteW(None, w!("open"), &file_w, parameters_ptr, PCWSTR::null(), SW_SHOWMAXIMIZED)
    };
    // ShellExecute returns a value above 32 on success.
    if result.0 as isize > 32 {
        Ok(())
    } else {
        Err(format!("Windows no pudo abrir {file} (código {})", result.0 as isize))
    }
}

// --- Finding windows --------------------------------------------------------------------

fn process_id(window: HWND) -> u32 {
    let mut pid = 0;
    unsafe { GetWindowThreadProcessId(window, Some(&mut pid)) };
    pid
}

/// A visible, titled, unowned window of another process: what people think of as "an app".
fn is_app_window(window: HWND) -> bool {
    unsafe {
        IsWindowVisible(window).as_bool()
            && GetWindow(window, GW_OWNER).map_or(true, |owner| owner.0.is_null())
            && GetWindowTextLengthW(window) > 0
            && process_id(window) != GetCurrentProcessId()
    }
}

pub fn app_windows() -> HashSet<isize> {
    unsafe extern "system" fn collect(window: HWND, lparam: LPARAM) -> BOOL {
        let windows = unsafe { &mut *(lparam.0 as *mut HashSet<isize>) };
        if is_app_window(window) {
            windows.insert(window.0 as isize);
        }
        BOOL(1)
    }
    let mut windows = HashSet::new();
    unsafe {
        let _ = EnumWindows(Some(collect), LPARAM(&mut windows as *mut _ as isize));
    }
    windows
}

/// Waits for a window that wasn't open before, preferring the one in front.
pub fn wait_for_new_window(before: &HashSet<isize>, timeout: Duration) -> Option<WindowId> {
    let start = Instant::now();
    while start.elapsed() < timeout {
        std::thread::sleep(Duration::from_millis(250));
        let new: Vec<isize> = app_windows().difference(before).copied().collect();
        if new.is_empty() {
            continue;
        }
        let foreground = unsafe { GetForegroundWindow() }.0 as isize;
        let chosen = if new.contains(&foreground) { foreground } else { new[0] };
        return Some(WindowId { hwnd: chosen, pid: process_id(hwnd(chosen)) });
    }
    None
}

/// Brings a window we opened earlier back to the front. Returns false if it's gone.
pub fn bring_to_front(id: WindowId) -> bool {
    let window = hwnd(id.hwnd);
    unsafe {
        if !IsWindow(Some(window)).as_bool() || process_id(window) != id.pid || !IsWindowVisible(window).as_bool() {
            return false;
        }
        if IsIconic(window).as_bool() {
            let _ = ShowWindow(window, SW_RESTORE);
        }
        SetForegroundWindow(window).as_bool()
    }
}

// --- The bar docked at the top ------------------------------------------------------------

const APPBAR_CALLBACK: u32 = WM_USER + 0x100;

fn appbar_data(window: HWND) -> APPBARDATA {
    APPBARDATA {
        cbSize: std::mem::size_of::<APPBARDATA>() as u32,
        hWnd: window,
        uCallbackMessage: APPBAR_CALLBACK,
        uEdge: ABE_TOP,
        ..Default::default()
    }
}

fn monitor_rect(window: HWND) -> RECT {
    let mut info = MONITORINFO { cbSize: std::mem::size_of::<MONITORINFO>() as u32, ..Default::default() };
    unsafe {
        let monitor = MonitorFromWindow(window, MONITOR_DEFAULTTOPRIMARY);
        let _ = GetMonitorInfoW(monitor, &mut info);
    }
    info.rcMonitor
}

/// Registers the window as an "app bar" along the top of its screen, `height` pixels
/// tall. Windows then keeps maximized windows below it, like it does for the taskbar.
pub fn dock_top(raw: isize, height: i32) {
    let window = hwnd(raw);
    let screen = monitor_rect(window);
    let mut data = appbar_data(window);
    unsafe {
        SHAppBarMessage(ABM_NEW, &mut data);
        data.rc = RECT { left: screen.left, top: screen.top, right: screen.right, bottom: screen.top + height };
        SHAppBarMessage(ABM_QUERYPOS, &mut data);
        data.rc.bottom = data.rc.top + height;
        SHAppBarMessage(ABM_SETPOS, &mut data);
        let _ = MoveWindow(window, data.rc.left, data.rc.top, data.rc.right - data.rc.left, height, true);
    }
}

pub fn undock(raw: isize) {
    let mut data = appbar_data(hwnd(raw));
    unsafe {
        SHAppBarMessage(ABM_REMOVE, &mut data);
    }
}

/// True while the window in front covers the whole screen (a full-screen video, say).
/// The desktop itself also covers the screen, so it doesn't count.
pub fn fullscreen_app_in_front(bar: isize) -> bool {
    unsafe {
        let front = GetForegroundWindow();
        if front.0.is_null() || process_id(front) == GetCurrentProcessId() {
            return false;
        }
        let mut class = [0u16; 64];
        let length = GetClassNameW(front, &mut class) as usize;
        let class = String::from_utf16_lossy(&class[..length]);
        if class == "Progman" || class == "WorkerW" {
            return false;
        }
        let mut rect = RECT::default();
        if GetWindowRect(front, &mut rect).is_err() {
            return false;
        }
        let screen = monitor_rect(hwnd(bar));
        rect.left <= screen.left && rect.top <= screen.top && rect.right >= screen.right && rect.bottom >= screen.bottom
    }
}

// --- Volume -----------------------------------------------------------------------------

/// Presses the keyboard's volume key `steps` times (2% each), which also shows Windows'
/// own volume indicator.
pub fn press_volume_key(up: bool, steps: usize) {
    let key = if up { VK_VOLUME_UP } else { VK_VOLUME_DOWN };
    let mut inputs = Vec::with_capacity(steps * 2);
    for _ in 0..steps {
        for flags in [KEYBD_EVENT_FLAGS(0), KEYEVENTF_KEYUP] {
            inputs.push(INPUT {
                r#type: INPUT_KEYBOARD,
                Anonymous: INPUT_0 {
                    ki: KEYBDINPUT { wVk: key, wScan: 0, dwFlags: flags, time: 0, dwExtraInfo: 0 },
                },
            });
        }
    }
    unsafe {
        SendInput(&inputs, std::mem::size_of::<INPUT>() as i32);
    }
}

// --- Start with Windows -----------------------------------------------------------------

/// Starts this program when the current user signs in.
pub fn start_at_sign_in() -> Result<(), String> {
    let exe = std::env::current_exe().map_err(|error| error.to_string())?;
    let command: Vec<u16> = format!("\"{}\"", exe.display()).encode_utf16().chain([0]).collect();
    let result = unsafe {
        RegSetKeyValueW(
            HKEY_CURRENT_USER,
            w!("Software\\Microsoft\\Windows\\CurrentVersion\\Run"),
            w!("windows4seniors"),
            REG_SZ.0,
            Some(command.as_ptr().cast()),
            (command.len() * 2) as u32,
        )
    };
    if result.is_ok() {
        Ok(())
    } else {
        Err(format!("RegSetKeyValueW failed: {result:?}"))
    }
}
