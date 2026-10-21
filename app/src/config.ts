// The launcher configuration, as the Windows side sends it to the screens.
// The admin PIN is never sent: the Windows side checks it.

export type OpenAction =
  | { type: 'app'; id: string }
  | { type: 'program'; name: string }
  | { type: 'uri'; uri: string }
  | { type: 'web'; url: string }
  | { type: 'browser'; url: string }
  | { type: 'soon' };

export interface Tile {
  label: string;
  icon: string;
  color: string;
  open: OpenAction;
}

export interface LauncherConfig {
  name: string;
  locale: string;
  help: { label: string; whatsappPhone: string };
  tiles: Tile[];
}
