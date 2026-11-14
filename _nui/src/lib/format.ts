import { t } from './locale.svelte';

const money = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 });

export function formatMoney(value: number): string {
  return money.format(value);
}

export function formatSigned(value: number, digits = 0): string {
  const rounded = Number(value.toFixed(digits));
  if (rounded === 0) return t('ui.performance.same');
  return `${rounded > 0 ? '+' : ''}${rounded.toFixed(digits)}`;
}

export function rgbToHex([r, g, b]: [number, number, number]): string {
  return `#${[r, g, b].map((part) => part.toString(16).padStart(2, '0')).join('').toUpperCase()}`;
}

export function hexToRgb(hex: string): [number, number, number] {
  const value = Number.parseInt(hex.replace('#', ''), 16);
  return [(value >> 16) & 255, (value >> 8) & 255, value & 255];
}

export function initials(name: string): string {
  return name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part.charAt(0).toUpperCase())
    .join('');
}

export function ago(timestamp: number, now = Date.now()): string {
  const minutes = Math.max(0, Math.round((now - timestamp) / 60000));
  if (minutes < 1) return t('ui.time.just_now');
  if (minutes < 60) return t('ui.time.minutes_ago', minutes);
  return t('ui.time.hours_ago', Math.round(minutes / 60));
}
