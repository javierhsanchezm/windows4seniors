import './styles.css';
import type { LauncherConfig } from './config';
import { everyMinute, greeting, longDate, time } from './dates';
import { checkPin, loadConfig, openTile, quitApp, reloadApp } from './native';

// After a click, the tile ignores further clicks for this long: an app can take a few
// seconds to appear, and a second click would open it twice.
const OPENING_MS = 4000;
// Holding the clock this long opens the family (admin) menu.
const ADMIN_HOLD_MS = 4000;

const app = document.querySelector<HTMLDivElement>('#app')!;

async function start(): Promise<void> {
  let config: LauncherConfig;
  try {
    config = await loadConfig();
  } catch (error) {
    showSetupError(String(error));
    return;
  }
  document.documentElement.lang = config.locale.split('-')[0];
  render(config);
}

function render(config: LauncherConfig): void {
  app.innerHTML = `
    <header class="home-header">
      <div>
        <h1 class="greeting"></h1>
        <p class="today"></p>
      </div>
      <div class="clock" title=""></div>
    </header>
    <main class="tiles"></main>
    <div class="message" hidden><p></p></div>
  `;

  const greetingEl = app.querySelector<HTMLElement>('.greeting')!;
  const todayEl = app.querySelector<HTMLElement>('.today')!;
  const clockEl = app.querySelector<HTMLElement>('.clock')!;
  everyMinute(() => {
    const now = new Date();
    greetingEl.textContent = `${greeting(now)}, ${config.name}`;
    todayEl.textContent = longDate(now, config.locale);
    clockEl.textContent = time(now, config.locale);
  });

  const tilesEl = app.querySelector<HTMLElement>('.tiles')!;
  tilesEl.dataset.count = String(config.tiles.length);
  config.tiles.forEach((tile, index) => {
    const button = document.createElement('button');
    button.className = 'tile';
    button.style.setProperty('--tile-color', tile.color);
    button.innerHTML = `<span class="tile-icon" aria-hidden="true"></span><span class="tile-label"></span>`;
    button.querySelector('.tile-icon')!.textContent = tile.icon;
    button.querySelector('.tile-label')!.textContent = tile.label;
    button.addEventListener('click', () => onTileClick(button, index, config));
    tilesEl.append(button);
  });

  setUpAdminHold(clockEl);
}

async function onTileClick(button: HTMLButtonElement, index: number, config: LauncherConfig): Promise<void> {
  if (button.classList.contains('opening')) return;
  const tile = config.tiles[index];

  if (tile.open.type === 'soon') {
    showMessage(`«${tile.label}» estará listo muy pronto.`, 3000);
    return;
  }

  button.classList.add('opening');
  showMessage(`Abriendo ${tile.label}…`, OPENING_MS);
  try {
    await openTile(index);
  } catch (error) {
    console.error(error);
    showMessage(`No se pudo abrir ${tile.label}. Presione «Ayuda» arriba a la derecha.`, 8000);
  }
  setTimeout(() => button.classList.remove('opening'), OPENING_MS);
}

let messageTimer: number | undefined;

function showMessage(text: string, durationMs: number): void {
  const message = app.querySelector<HTMLElement>('.message')!;
  message.querySelector('p')!.textContent = text;
  message.hidden = false;
  window.clearTimeout(messageTimer);
  messageTimer = window.setTimeout(() => { message.hidden = true; }, durationMs);
}

function showSetupError(detail: string): void {
  app.innerHTML = `
    <div class="setup-error">
      <h1>Falta la configuración</h1>
      <p>Pídale ayuda a su familia.</p>
      <pre></pre>
    </div>
  `;
  app.querySelector('pre')!.textContent = detail;
}

// --- Family (admin) menu ----------------------------------------------------------------

function setUpAdminHold(target: HTMLElement): void {
  let timer: number | undefined;
  const cancel = () => window.clearTimeout(timer);
  target.addEventListener('pointerdown', () => {
    cancel();
    timer = window.setTimeout(openPinPad, ADMIN_HOLD_MS);
  });
  target.addEventListener('pointerup', cancel);
  target.addEventListener('pointerleave', cancel);
}

function openPinPad(): void {
  const dialog = document.createElement('dialog');
  dialog.className = 'admin';
  dialog.innerHTML = `
    <h2>Menú de la familia</h2>
    <p class="pin-display" aria-live="polite">&nbsp;</p>
    <div class="pin-pad"></div>
    <div class="admin-actions" hidden>
      <button data-action="reload">Recargar la configuración</button>
      <button data-action="quit">Cerrar el Inicio</button>
    </div>
    <button class="admin-cancel">Cancelar</button>
  `;
  document.body.append(dialog);

  let pin = '';
  const display = dialog.querySelector<HTMLElement>('.pin-display')!;
  const pad = dialog.querySelector<HTMLElement>('.pin-pad')!;
  const actions = dialog.querySelector<HTMLElement>('.admin-actions')!;
  const close = () => dialog.remove();

  for (const key of ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', '✓']) {
    const button = document.createElement('button');
    button.textContent = key;
    button.addEventListener('click', async () => {
      if (key === '⌫') pin = pin.slice(0, -1);
      else if (key === '✓') {
        if (await checkPin(pin)) {
          pad.hidden = true;
          actions.hidden = false;
          display.textContent = '';
          return;
        }
        pin = '';
        display.textContent = 'PIN incorrecto';
        return;
      } else if (pin.length < 8) pin += key;
      display.textContent = '•'.repeat(pin.length) || ' ';
    });
    pad.append(button);
  }

  actions.querySelector('[data-action="reload"]')!.addEventListener('click', () => reloadApp());
  actions.querySelector('[data-action="quit"]')!.addEventListener('click', () => quitApp());
  dialog.querySelector('.admin-cancel')!.addEventListener('click', close);
  dialog.addEventListener('cancel', close);
  dialog.showModal();
}

start();
