// Bridge to the Windows side (src-tauri). In a normal browser (`npm run dev`) there is
// no Windows side, so these fall back to a sample configuration and log the actions:
// that's enough to work on the screens.

import { invoke, isTauri } from '@tauri-apps/api/core';
import type { LauncherConfig } from './config';

export async function loadConfig(): Promise<LauncherConfig> {
  if (isTauri()) return invoke<LauncherConfig>('load_config');

  const person = new URLSearchParams(location.search).get('person') ?? 'papa';
  const sample = person === 'mama'
    ? await import('../../config/mama.json')
    : await import('../../config/papa.json');
  const { adminPin: _adminPin, ...config } = sample.default as LauncherConfig & { adminPin: string };
  return config;
}

export async function openTile(index: number): Promise<void> {
  if (isTauri()) return invoke('open_tile', { index });
  console.info('open_tile', index);
}

export async function changeVolume(up: boolean): Promise<void> {
  if (isTauri()) return invoke('change_volume', { up });
  console.info('change_volume', up);
}

export async function showHome(): Promise<void> {
  if (isTauri()) return invoke('show_home');
  console.info('show_home');
}

export async function openHelp(): Promise<void> {
  if (isTauri()) return invoke('open_help');
  console.info('open_help');
}

export async function checkPin(pin: string): Promise<boolean> {
  if (isTauri()) return invoke<boolean>('check_pin', { pin });
  return pin === '0000';
}

export async function reloadApp(): Promise<void> {
  if (isTauri()) return invoke('reload_app');
  location.reload();
}

export async function quitApp(): Promise<void> {
  if (isTauri()) return invoke('quit_app');
  console.info('quit_app');
}
