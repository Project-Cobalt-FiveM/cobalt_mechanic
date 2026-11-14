import { rgbToHex } from './format';
import { t } from './locale.svelte';
import type { Catalog, Chameleon, Colour, PaintTab, Rgb } from './types';

export type PaintSwatch = { index: number; name: string; hex: string; gradient?: string };

export function findColour(catalog: Catalog, index: number): Colour | Chameleon | undefined {
  return catalog.colours.find((colour) => colour.index === index) ?? catalog.chameleons.find((colour) => colour.index === index);
}

export function swatchOf(colour: Colour | Chameleon): PaintSwatch {
  if ('series' in colour) {
    return { index: colour.index, name: colour.name, hex: colour.from, gradient: `linear-gradient(135deg, ${colour.from}, ${colour.to})` };
  }
  return { index: colour.index, name: colour.name, hex: colour.hex };
}

export function paintName(catalog: Catalog, value: number | Rgb): string {
  if (Array.isArray(value)) return t('ui.paint.custom_name', rgbToHex(value));
  return findColour(catalog, value)?.name ?? t('ui.paint.colour_name', value);
}

export function paintHex(catalog: Catalog, value: number | Rgb): string {
  if (Array.isArray(value)) return rgbToHex(value);
  const colour = findColour(catalog, value);
  if (!colour) return '#262626';
  return 'series' in colour ? colour.from : colour.hex;
}

export const tabLabels: Record<PaintTab, string> = {
  metallic: 'ui.paint.tab_metallic',
  matte: 'ui.paint.tab_matte',
  util: 'ui.paint.tab_util',
  worn: 'ui.paint.tab_worn',
  metals: 'ui.paint.tab_metals',
};
