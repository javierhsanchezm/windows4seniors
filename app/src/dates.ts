// Day, date and time in words, for orientation: "martes, 21 de octubre de 2026".

function capitalize(text: string): string {
  return text.charAt(0).toLocaleUpperCase() + text.slice(1);
}

export function longDate(now: Date, locale: string): string {
  return capitalize(new Intl.DateTimeFormat(locale, {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
  }).format(now));
}

export function shortDate(now: Date, locale: string): string {
  return capitalize(new Intl.DateTimeFormat(locale, {
    weekday: 'long', day: 'numeric', month: 'long',
  }).format(now));
}

export function time(now: Date, locale: string): string {
  return new Intl.DateTimeFormat(locale, { hour: 'numeric', minute: '2-digit' }).format(now);
}

export function greeting(now: Date): string {
  const hour = now.getHours();
  if (hour >= 5 && hour < 12) return 'Buenos días';
  if (hour >= 12 && hour < 19) return 'Buenas tardes';
  return 'Buenas noches';
}

export function partOfDay(now: Date): string {
  const hour = now.getHours();
  if (hour >= 5 && hour < 12) return 'de la mañana';
  if (hour >= 12 && hour < 19) return 'de la tarde';
  return 'de la noche';
}

// Calls `update` now and then at the start of every minute.
export function everyMinute(update: () => void): void {
  update();
  const untilNextMinute = 60_000 - (Date.now() % 60_000);
  setTimeout(() => {
    update();
    setInterval(update, 60_000);
  }, untilNextMinute);
}
