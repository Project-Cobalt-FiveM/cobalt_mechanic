import type { Change } from './types';

export function keyOf(change: Change): string {
  switch (change.kind) {
    case 'paint':
    case 'paintCustom':
      return `paint:${change.slot}`;
    case 'pearlescent':
    case 'wheelColour':
    case 'wheels':
    case 'tyreSmoke':
    case 'tint':
    case 'neon':
    case 'xenon':
    case 'plate':
    case 'livery':
      return change.kind;
    case 'extra':
      return `extra:${change.id}`;
    case 'mod':
      return `mod:${change.slot}`;
    case 'upgrade':
      return `upgrade:${change.name}`;
    case 'repair':
      return `repair:${change.part}`;
    case 'service':
      return `service:${change.name}`;
    default: {
      const exhaustive: never = change;
      return exhaustive;
    }
  }
}
