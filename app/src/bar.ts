import './styles.css';
import { everyMinute, partOfDay, shortDate, time } from './dates';
import { changeVolume, loadConfig, openHelp, showHome } from './native';

// The bar docked at the top of the screen. Windows keeps maximized apps below it, so
// "Inicio" and "Ayuda" are always visible.

const app = document.querySelector<HTMLDivElement>('#app')!;

async function start(): Promise<void> {
  const config = await loadConfig().catch(() => null);
  const locale = config?.locale ?? 'es-CO';
  const helpLabel = config?.help.label ?? 'Ayuda';

  app.innerHTML = `
    <nav class="bar">
      <button class="bar-button bar-home"><span aria-hidden="true">🏠</span> Inicio</button>
      <div class="bar-now"><span class="bar-time"></span><span class="bar-date"></span></div>
      <div class="bar-group">
        <button class="bar-button" data-volume="down"><span aria-hidden="true">🔉</span> Más bajo</button>
        <button class="bar-button" data-volume="up"><span aria-hidden="true">🔊</span> Más alto</button>
        <button class="bar-button bar-help"><span aria-hidden="true">🙋</span> <span class="help-label"></span></button>
      </div>
    </nav>
  `;
  app.querySelector('.help-label')!.textContent = helpLabel;

  const timeEl = app.querySelector<HTMLElement>('.bar-time')!;
  const dateEl = app.querySelector<HTMLElement>('.bar-date')!;
  everyMinute(() => {
    const now = new Date();
    timeEl.textContent = time(now, locale);
    dateEl.textContent = `${shortDate(now, locale)} · ${partOfDay(now)}`;
  });

  app.querySelector('.bar-home')!.addEventListener('click', () => showHome());
  app.querySelector('.bar-help')!.addEventListener('click', () => openHelp());
  app.querySelectorAll<HTMLButtonElement>('[data-volume]').forEach((button) => {
    button.addEventListener('click', () => changeVolume(button.dataset.volume === 'up'));
  });
}

start();
