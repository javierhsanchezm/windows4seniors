//! The launcher configuration: %LOCALAPPDATA%\windows4seniors\launcher.json.
//!
//! The screens get a copy without the admin PIN; tiles are opened by index, so the
//! screens can only ever open what this file lists.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Config {
    pub name: String,
    pub locale: String,
    #[serde(skip_serializing)]
    pub admin_pin: String,
    pub help: Help,
    pub tiles: Vec<Tile>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Help {
    pub label: String,
    pub whatsapp_phone: String,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Tile {
    pub label: String,
    pub icon: String,
    pub color: String,
    pub open: OpenAction,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(tag = "type", rename_all = "lowercase")]
pub enum OpenAction {
    /// A Store or desktop app by its AppID (PowerShell: Get-StartApps).
    App { id: String },
    /// A program registered with Windows, such as "winword.exe".
    Program { name: String },
    /// A link handled by an app, such as "whatsapp:".
    Uri { uri: String },
    /// A website in its own Chrome window, without tabs or address bar.
    Web { url: String },
    /// A website in a normal Chrome window.
    Browser { url: String },
    /// Not ready yet; the screen shows a "coming soon" message.
    Soon,
}

pub fn path() -> PathBuf {
    let base = std::env::var_os("LOCALAPPDATA")
        .map(PathBuf::from)
        .unwrap_or_else(std::env::temp_dir);
    base.join("windows4seniors").join("launcher.json")
}

pub fn load() -> Result<Config, String> {
    let path = path();
    let text = std::fs::read_to_string(&path).map_err(|error| {
        format!("No se pudo leer {}: {error}", path.display())
    })?;
    let config: Config = serde_json::from_str(text.trim_start_matches('\u{feff}'))
        .map_err(|error| format!("Error en {}: {error}", path.display()))?;
    validate(&config).map_err(|error| format!("Error en {}: {error}", path.display()))?;
    Ok(config)
}

fn validate(config: &Config) -> Result<(), String> {
    if config.tiles.is_empty() {
        return Err("no hay ninguna casilla (\"tiles\")".into());
    }
    if !config.help.whatsapp_phone.chars().all(|c| c.is_ascii_digit()) {
        return Err("\"whatsappPhone\" debe tener solo números, con el código del país (57...)".into());
    }
    for tile in &config.tiles {
        match &tile.open {
            OpenAction::Web { url } | OpenAction::Browser { url } => {
                let is_http = url.starts_with("https://") || url.starts_with("http://");
                let is_plain = !url.chars().any(|c| c.is_whitespace() || c == '"');
                if !is_http || !is_plain {
                    return Err(format!("dirección no válida en «{}»: {url}", tile.label));
                }
            }
            OpenAction::App { id } if id.trim().is_empty() => {
                return Err(format!("falta el \"id\" de la aplicación en «{}»", tile.label));
            }
            _ => {}
        }
    }
    Ok(())
}
