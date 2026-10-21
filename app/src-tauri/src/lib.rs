//! "Inicio": a full-screen Home screen with large tiles, and a bar docked at the top of
//! the screen with Home, the time, volume and Help. See docs/PLAN.md, section 8.

mod config;
#[cfg(windows)]
mod win;

use std::collections::HashMap;
use std::sync::atomic::{AtomicIsize, Ordering};
use std::sync::{Arc, Mutex};

use config::{Config, OpenAction};
use tauri::{AppHandle, Manager, RunEvent, State, WindowEvent};

/// Height of the top bar, in screen points (scaled with the Windows display scale).
const BAR_HEIGHT: f64 = 96.0;
/// Volume steps per click: Windows changes the volume by 2% per step.
const VOLUME_STEPS: usize = 2;

#[cfg(windows)]
type OpenedWindows = Arc<Mutex<HashMap<usize, win::WindowId>>>;
#[cfg(not(windows))]
type OpenedWindows = Arc<Mutex<HashMap<usize, ()>>>;

struct AppState {
    config: Mutex<Result<Config, String>>,
    /// The window each tile opened, so a second click brings it back instead of
    /// opening another copy.
    opened: OpenedWindows,
    /// The docked bar's window handle, to undock it on exit.
    bar_hwnd: AtomicIsize,
}

impl AppState {
    fn config(&self) -> Result<Config, String> {
        self.config.lock().unwrap().clone()
    }
}

#[tauri::command]
fn load_config(state: State<AppState>) -> Result<Config, String> {
    state.config()
}

#[tauri::command]
fn open_tile(index: usize, state: State<AppState>) -> Result<(), String> {
    let config = state.config()?;
    let tile = config.tiles.get(index).ok_or("Esa casilla no existe")?;
    open(index, &tile.open, &state.opened)
}

#[tauri::command]
fn open_help(state: State<AppState>) -> Result<(), String> {
    let config = state.config()?;
    let uri = format!("whatsapp://send?phone={}", config.help.whatsapp_phone);
    open(usize::MAX, &OpenAction::Uri { uri }, &state.opened)
}

#[tauri::command]
fn change_volume(up: bool) {
    #[cfg(windows)]
    win::press_volume_key(up, VOLUME_STEPS);
    #[cfg(not(windows))]
    let _ = (up, VOLUME_STEPS);
}

#[tauri::command]
fn show_home(app: AppHandle) {
    bring_home_to_front(&app);
}

#[tauri::command]
fn check_pin(pin: String, state: State<AppState>) -> bool {
    state.config().map(|config| config.admin_pin == pin).unwrap_or(false)
}

#[tauri::command]
fn reload_app(app: AppHandle, state: State<AppState>) {
    *state.config.lock().unwrap() = config::load();
    state.opened.lock().unwrap().clear();
    for window in app.webview_windows().values() {
        let _ = window.eval("location.reload()");
    }
}

#[tauri::command]
fn quit_app(app: AppHandle) {
    app.exit(0);
}

fn bring_home_to_front(app: &AppHandle) {
    if let Some(home) = app.get_webview_window("home") {
        let _ = home.unminimize();
        let _ = home.show();
        let _ = home.maximize();
        let _ = home.set_focus();
    }
}

#[cfg(windows)]
fn open(index: usize, action: &OpenAction, opened: &OpenedWindows) -> Result<(), String> {
    use std::time::Duration;

    if let Some(&window) = opened.lock().unwrap().get(&index) {
        if win::bring_to_front(window) {
            return Ok(());
        }
    }

    let before = win::app_windows();
    match action {
        OpenAction::App { id } => win::shell_open(&format!("shell:AppsFolder\\{id}"), None)?,
        OpenAction::Program { name } => win::shell_open(name, None)?,
        OpenAction::Uri { uri } => win::shell_open(uri, None)?,
        OpenAction::Web { url } => win::shell_open("chrome.exe", Some(&format!("--app={url} --start-maximized")))?,
        OpenAction::Browser { url } => win::shell_open("chrome.exe", Some(&format!("--start-maximized {url}")))?,
        OpenAction::Soon => return Ok(()),
    }

    // Remember the window that appears, in the background so the screen stays responsive.
    let opened = Arc::clone(opened);
    std::thread::spawn(move || {
        if let Some(window) = win::wait_for_new_window(&before, Duration::from_secs(10)) {
            opened.lock().unwrap().insert(index, window);
        }
    });
    Ok(())
}

#[cfg(not(windows))]
fn open(_index: usize, _action: &OpenAction, _opened: &OpenedWindows) -> Result<(), String> {
    Err("Solo funciona en Windows".into())
}

/// Docks the bar at the top of the screen, and lets full-screen apps (a YouTube video)
/// cover it while they're in front.
#[cfg(windows)]
fn set_up_bar(app: &AppHandle, state: &AppState) {
    use std::time::Duration;

    let Some(bar) = app.get_webview_window("bar") else { return };
    let Ok(handle) = bar.hwnd() else { return };
    let raw = handle.0 as isize;
    let scale = bar.scale_factor().unwrap_or(1.0);
    win::dock_top(raw, (BAR_HEIGHT * scale).round() as i32);
    state.bar_hwnd.store(raw, Ordering::SeqCst);

    std::thread::spawn(move || {
        let mut on_top = true;
        loop {
            std::thread::sleep(Duration::from_secs(1));
            let should_be_on_top = !win::fullscreen_app_in_front(raw);
            if should_be_on_top != on_top {
                on_top = should_be_on_top;
                let _ = bar.set_always_on_top(on_top);
            }
        }
    });
}

pub fn run() {
    let config = config::load();
    let start_with_windows = config.is_ok() && !cfg!(debug_assertions);

    let app = tauri::Builder::default()
        // A second copy (for example, started by hand while one is running) just
        // brings the Home screen to the front.
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| bring_home_to_front(app)))
        .manage(AppState {
            config: Mutex::new(config),
            opened: Arc::new(Mutex::new(HashMap::new())),
            bar_hwnd: AtomicIsize::new(0),
        })
        .invoke_handler(tauri::generate_handler![
            load_config,
            open_tile,
            open_help,
            change_volume,
            show_home,
            check_pin,
            reload_app,
            quit_app
        ])
        .setup(move |app| {
            #[cfg(windows)]
            {
                set_up_bar(app.handle(), &app.state::<AppState>());
                if start_with_windows {
                    if let Err(error) = win::start_at_sign_in() {
                        eprintln!("Couldn't set up start at sign-in: {error}");
                    }
                }
            }
            #[cfg(not(windows))]
            let _ = start_with_windows;
            bring_home_to_front(app.handle());
            Ok(())
        })
        // Closing the Home screen or the bar (Alt+F4) would leave him stranded: only the
        // family menu can close the app.
        .on_window_event(|_window, event| {
            if let WindowEvent::CloseRequested { api, .. } = event {
                api.prevent_close();
            }
        })
        .build(tauri::generate_context!())
        .expect("error while building the app");

    app.run(|app, event| {
        if let RunEvent::Exit = event {
            #[cfg(windows)]
            {
                let raw = app.state::<AppState>().bar_hwnd.load(Ordering::SeqCst);
                if raw != 0 {
                    win::undock(raw);
                }
            }
            #[cfg(not(windows))]
            let _ = app;
        }
    });
}
