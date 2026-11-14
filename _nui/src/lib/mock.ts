import type { MockHandlers } from './nui';
import catalogData from './mock-catalog.json';
import type { Catalog, Chameleon, Change, Colour, Fitting, Messages, ModOption, Session, Stats, UpgradeOption, VehicleProps } from './types';

const colours = catalogData.colours as Colour[];
const chameleons = catalogData.chameleons as Chameleon[];

const catalog: Catalog = {
  colours,
  chameleons,
  tints: [
    { level: 0, name: 'None', hex: '#E5E5E5' },
    { level: 3, name: 'Light Smoke', hex: '#7A7A7A' },
    { level: 2, name: 'Dark Smoke', hex: '#2E2E2E' },
    { level: 5, name: 'Limo', hex: '#1A1A1A' },
    { level: 1, name: 'Pure Black', hex: '#0A0A0A' },
    { level: 6, name: 'Green', hex: '#1F4A2A' },
  ],
  neons: [
    { name: 'White', rgb: [255, 255, 255] },
    { name: 'Blue', rgb: [2, 21, 255] },
    { name: 'Electric', rgb: [3, 144, 255] },
    { name: 'Mint', rgb: [0, 255, 140] },
    { name: 'Lime', rgb: [94, 255, 1] },
    { name: 'Yellow', rgb: [255, 255, 0] },
    { name: 'Orange', rgb: [255, 128, 0] },
    { name: 'Red', rgb: [255, 0, 0] },
    { name: 'Pink', rgb: [255, 20, 147] },
    { name: 'Hot Pink', rgb: [255, 5, 190] },
    { name: 'Purple', rgb: [138, 43, 226] },
    { name: 'Violet', rgb: [64, 0, 255] },
  ],
  xenons: [
    { index: 255, name: 'Xenon', hex: '#DCE6F0' },
    { index: 0, name: 'White', hex: '#FFFFFF' },
    { index: 1, name: 'Blue', hex: '#1F66E0' },
    { index: 2, name: 'Electric Blue', hex: '#0390FF' },
    { index: 3, name: 'Mint Green', hex: '#00FF8C' },
    { index: 4, name: 'Lime Green', hex: '#5EFF01' },
    { index: 5, name: 'Yellow', hex: '#FFFF00' },
    { index: 6, name: 'Golden Shower', hex: '#FFD24C' },
    { index: 7, name: 'Orange', hex: '#FF8000' },
    { index: 8, name: 'Red', hex: '#FF0000' },
    { index: 9, name: 'Pony Pink', hex: '#FF1493' },
    { index: 10, name: 'Hot Pink', hex: '#FF05BE' },
    { index: 11, name: 'Purple', hex: '#8A2BE2' },
    { index: 12, name: 'Blacklight', hex: '#4000FF' },
  ],
  plates: [
    { index: 0, name: 'Blue on White 1' },
    { index: 3, name: 'Blue on White 2' },
    { index: 4, name: 'SA Exempt' },
    { index: 1, name: 'Yellow on Black' },
    { index: 2, name: 'Yellow on Blue' },
    { index: 5, name: 'North Yankton' },
    { index: 6, name: 'eCola' },
    { index: 7, name: 'Las Venturas' },
    { index: 8, name: 'Liberty City' },
    { index: 9, name: 'LS Car Meet' },
    { index: 10, name: 'Panic' },
    { index: 11, name: 'Pounders' },
    { index: 12, name: 'Sprunk' },
  ],
  prices: {
    paint: 800,
    paintCustom: 1000,
    chameleon: 2500,
    pearlescent: 600,
    wheelColour: 400,
    wheels: 1800,
    tyreSmoke: 350,
    tint: 350,
    neon: 250,
    xenon: 300,
    plate: 200,
    livery: 500,
    extra: 150,
  },
  services: [
    { name: 'oil', label: 'Oil change', price: 200, system: 'oil' },
    { name: 'battery', label: 'New battery', price: 600, system: 'battery' },
    { name: 'tyres', label: 'Tyre set (4)', price: 800, system: 'tyres' },
    { name: 'brakes', label: 'Brake pads', price: 400, system: 'brakes' },
    { name: 'clutch', label: 'Clutch kit', price: 900, system: 'clutch' },
  ],
  repairs: { engine: { perPercent: 20, minimum: 150 }, body: { perPercent: 12, minimum: 100 } },
};

const mods: ModOption[] = [
  { slot: 0, name: 'Spoiler', group: 'exterior', price: { base: 1250, step: 600 }, options: ['Carbon lip', 'Low wing', 'Race wing', 'GT wing', 'Ducktail'] },
  { slot: 1, name: 'Front bumper', group: 'exterior', price: { base: 1000, step: 400 }, options: ['Carbon splitter', 'Race splitter'] },
  { slot: 2, name: 'Rear bumper', group: 'exterior', price: { base: 1000, step: 400 }, options: ['Carbon diffuser', 'Race diffuser'] },
  { slot: 3, name: 'Skirts', group: 'exterior', price: { base: 900, step: 300 }, options: ['Carbon skirts'] },
  { slot: 4, name: 'Exhaust', group: 'exterior', price: { base: 800, step: 250 }, options: ['Titanium tips', 'Big bore', 'Quad exit'] },
  { slot: 6, name: 'Grille', group: 'exterior', price: { base: 600, step: 150 }, options: ['Mesh grille'] },
  { slot: 7, name: 'Hood', group: 'exterior', price: { base: 1200, step: 400 }, options: ['Vented hood', 'Carbon hood'] },
  { slot: 10, name: 'Roof', group: 'exterior', price: { base: 1100, step: 350 }, options: ['Carbon roof'] },
  { slot: 14, name: 'Horn', group: 'interior', price: { base: 300, step: 50 }, options: ['Truck horn', 'Cop horn', 'Clown horn', 'Musical horn 1'] },
  { slot: 32, name: 'Seats', group: 'interior', price: { base: 600, step: 150 }, options: ['Race seats', 'Bucket seats'] },
  { slot: 33, name: 'Steering wheel', group: 'interior', price: { base: 600, step: 150 }, options: ['Race wheel', 'Rally wheel'] },
  { slot: 39, name: 'Engine block', group: 'engine', price: { base: 600, step: 150 }, options: ['Chrome block', 'Carbon covers'] },
];

const steel = { item: 'steel', label: 'Steel' };
const copper = { item: 'copper', label: 'Copper' };
const aluminum = { item: 'aluminum', label: 'Aluminium' };
const oil = { item: 'oil', label: 'Engine oil' };
const rubber = { item: 'rubber', label: 'Rubber' };
const kit = { item: 'electronickit', label: 'Electronic kit' };

const upgrades: UpgradeOption[] = [
  {
    name: 'engine',
    label: 'Engine',
    toggle: false,
    levels: [
      { name: 'Street tune', price: 4500, grade: 0, materials: [{ ...steel, count: 2 }, { ...oil, count: 1 }] },
      { name: 'Sport tune', price: 9000, grade: 1, materials: [{ ...steel, count: 4 }, { ...copper, count: 2 }, { ...oil, count: 1 }] },
      { name: 'Race tune', price: 15000, grade: 2, materials: [{ ...steel, count: 6 }, { ...copper, count: 4 }, { ...kit, count: 1 }, { ...oil, count: 2 }] },
      { name: 'Competition tune', price: 25000, grade: 3, materials: [{ ...steel, count: 8 }, { ...aluminum, count: 4 }, { ...kit, count: 2 }] },
    ],
  },
  {
    name: 'transmission',
    label: 'Transmission',
    toggle: false,
    levels: [
      { name: 'Street transmission', price: 3500, grade: 0, materials: [{ ...steel, count: 3 }] },
      { name: 'Sport transmission', price: 7000, grade: 1, materials: [{ ...steel, count: 5 }, { ...aluminum, count: 2 }] },
      { name: 'Race transmission', price: 12000, grade: 2, materials: [{ ...steel, count: 6 }, { ...kit, count: 1 }] },
    ],
  },
  {
    name: 'brakes',
    label: 'Brakes',
    toggle: false,
    levels: [
      { name: 'Street brakes', price: 2500, grade: 0, materials: [{ ...steel, count: 2 }, { ...rubber, count: 2 }] },
      { name: 'Sport brakes', price: 5000, grade: 1, materials: [{ ...steel, count: 3 }, { ...rubber, count: 2 }] },
      { name: 'Race brakes', price: 9000, grade: 2, materials: [{ ...steel, count: 4 }, { ...rubber, count: 3 }] },
    ],
  },
  {
    name: 'suspension',
    label: 'Suspension',
    toggle: false,
    levels: [
      { name: 'Lowered', price: 1500, grade: 0, materials: [{ ...steel, count: 2 }] },
      { name: 'Street', price: 3000, grade: 0, materials: [{ ...steel, count: 3 }] },
      { name: 'Sport', price: 5000, grade: 1, materials: [{ ...steel, count: 4 }] },
      { name: 'Competition', price: 8000, grade: 2, materials: [{ ...steel, count: 5 }] },
    ],
  },
  {
    name: 'armour',
    label: 'Armour',
    toggle: false,
    levels: [
      { name: 'Armour 20%', price: 3000, grade: 0, materials: [{ ...steel, count: 4 }] },
      { name: 'Armour 40%', price: 6000, grade: 0, materials: [{ ...steel, count: 6 }] },
      { name: 'Armour 60%', price: 10000, grade: 1, materials: [{ ...steel, count: 8 }] },
      { name: 'Armour 80%', price: 15000, grade: 2, materials: [{ ...steel, count: 10 }] },
      { name: 'Armour 100%', price: 22000, grade: 3, materials: [{ ...steel, count: 12 }] },
    ],
  },
  {
    name: 'turbo',
    label: 'Turbo',
    toggle: true,
    levels: [{ name: 'Turbo tuning', price: 15000, grade: 2, materials: [{ ...steel, count: 3 }, { ...kit, count: 1 }] }],
  },
];

const props: VehicleProps = {
  color1: 0,
  color2: 1,
  pearlescentColor: 0,
  wheelColor: 120,
  wheels: 0,
  modFrontWheels: -1,
  modCustomTiresF: false,
  modSmokeEnabled: true,
  tyreSmokeColor: [255, 255, 255],
  windowTint: 0,
  neonEnabled: [false, false, false, false],
  neonColor: [255, 255, 255],
  modXenon: false,
  xenonColor: 255,
  plateIndex: 0,
  livery: -1,
  modLivery: -1,
  extras: {},
  mods: { 0: -1, 1: -1, 2: -1, 3: -1, 4: 0, 6: -1, 7: -1, 10: -1, 14: -1, 32: -1, 33: -1, 39: -1 },
  upgrades: { engine: 1, brakes: 0, transmission: 2, suspension: 0, armour: 2, turbo: 0 },
};

const baseStats: Stats = { topSpeed: 189, acceleration: 7.8, braking: 6.2, handling: 7.1, traction: 6.6, armour: 40 };

function statsFor(changes: Change[]): Stats {
  const stats = { ...baseStats };

  for (const change of changes) {
    if (change.kind !== 'upgrade') continue;
    const delta = change.level - props.upgrades[change.name];
    if (change.name === 'engine') {
      stats.topSpeed += delta * 4.5;
      stats.acceleration += delta * 0.3;
    }
    if (change.name === 'transmission') stats.acceleration += delta * 0.25;
    if (change.name === 'brakes') stats.braking += delta * 0.6;
    if (change.name === 'suspension') {
      stats.handling += delta * 0.3;
      stats.traction -= delta * 0.1;
    }
    if (change.name === 'armour') stats.armour = change.level * 20;
    if (change.name === 'turbo') stats.acceleration += change.level * 0.5;
  }

  return stats;
}

const session: Session = {
  mode: 'employee',
  shop: { label: "Benny's Original Motorworks", maxMarkup: 50, mechanicShare: 0.5 },
  vehicle: { label: 'Pegassi Zentorno', plate: '48KDJ203', owner: 'Mia Torres' },
  me: { name: 'Alex Kane', grade: 2, canBillShop: true },
  balances: null,
  props,
  options: {
    mods,
    wheels: [
      { type: 0, name: 'Sport', options: ['Inferno', 'Deep Five', 'Lozspeed Mk.V', 'Diamond Cut', 'Chrono', 'Feroci RR', 'FiftyNine', 'Mercie'] },
      { type: 5, name: 'Tuner', options: ['Cosmo', 'Super Mesh', 'Outsider', 'Rollas', 'Driftmeister'] },
      { type: 7, name: 'High end', options: ['Shadow', 'Hypher', 'Blade', 'Diamond', 'Supa Gee', 'Chromatic Z'] },
      { type: 1, name: 'Muscle', options: ['Classic Five', 'Dukes', 'Muscle Freak', 'Kracka'] },
    ],
    liveries: { legacy: false, options: ['Pegassi stripe', 'Race number', 'Checkered', 'Flames'] },
    extras: [],
    upgrades,
  },
  diagnosis: {
    mileageKm: 18420,
    scannedAt: Date.now() - 120000,
    engine: 66,
    body: 42,
    wear: { brakes: 19, clutch: 88, oil: 22, battery: 64, tyres: 71 },
  },
  stats: baseStats,
  catalog,
};

const selfSession: Session = {
  ...session,
  mode: 'self',
  shop: { label: 'Los Santos Customs, LSIA', maxMarkup: 0, mechanicShare: 0 },
  me: { name: 'Mia Torres', grade: 0, canBillShop: false },
  balances: { bank: 14980, cash: 820 },
};

const fitting: Fitting = {
  id: 3,
  paidBy: 'Mia Torres',
  total: 6420,
  index: 4,
  sharesMarkup: true,
  crewRadius: 8,
  items: [
    { key: 'paint:primary', label: 'Saxony Blue primary paint', seconds: 8, status: 'done' },
    { key: 'tint', label: 'Dark Smoke tint', seconds: 5, status: 'done' },
    { key: 'wheels', label: 'Deep Five rims', seconds: 6, status: 'done' },
    { key: 'upgrade:engine', label: 'V8 Stage 1', seconds: 15, status: 'active' },
    { key: 'mod:0', label: 'Low wing spoiler', seconds: 6, status: 'next' },
  ],
  crew: [
    { name: 'Alex Kane', role: 'Mechanic', grade: 2, distance: 0, isYou: true },
    { name: 'Dani Reyes', role: 'Lead mechanic', grade: 3, distance: 3, isYou: false },
  ],
};

export function sceneFor(scene: string): Messages[] {
  if (scene === 'self') return [{ action: 'open', data: selfSession }];
  if (scene === 'fitting') return [{ action: 'open', data: session }, { action: 'fitting', data: fitting }];
  if (scene === 'bill') {
    return [{
      action: 'bill',
      data: {
        id: 7,
        shop: "Benny's",
        mechanic: 'Alex Kane',
        vehicle: 'Pegassi Zentorno',
        plate: '48KDJ203',
        lines: [
          { key: 'wheels', label: 'Deep Five rims', price: 2160 },
          { key: 'mod:0', label: 'Low wing spoiler', price: 2880 },
          { key: 'paint:primary', label: 'Saxony Blue primary paint', price: 960 },
          { key: 'tint', label: 'Dark Smoke tint', price: 420 },
        ],
        total: 6420,
        bankAfter: 8560,
        expiresInSeconds: 48,
      },
    }];
  }
  return [{ action: 'open', data: session }];
}

function mockPrice(change: Change): number {
  if (change.kind === 'upgrade') return upgrades.find((upgrade) => upgrade.name === change.name)?.levels[change.level - 1]?.price ?? 0;
  if (change.kind === 'paint') return change.index > 160 ? catalog.prices.chameleon : catalog.prices.paint;
  if (change.kind === 'mod') return (mods.find((mod) => mod.slot === change.slot)?.price.base ?? 600) + 300 * Math.max(change.index, 0);
  if (change.kind === 'wheels') return catalog.prices.wheels;
  if (change.kind === 'tint') return catalog.prices.tint;
  return 500;
}

export const handlers: MockHandlers = {
  close: () => ({ ok: true }),
  preview: ({ changes }) => ({ stats: statsFor(changes) }),
  quote: ({ changes, markup }) => {
    const lines = changes.map((change, i) => ({ key: `${change.kind}:${i}`, label: change.kind, price: mockPrice(change) }));
    const total = Math.round(lines.reduce((sum, line) => sum + line.price, 0) * (1 + markup / 100));
    return {
      lines,
      total,
      materials: [
        { item: 'steel', label: 'Steel', need: 4, have: 6 },
        { item: 'rubber', label: 'Rubber', need: 2, have: 2 },
      ],
      crew: ['Alex Kane', 'Dani Reyes'],
    };
  },
  camera: () => ({ ok: true }),
  orbit: () => ({ ok: true }),
  zoom: () => ({ ok: true }),
  scan: () => ({ diagnosis: { ...session.diagnosis, scannedAt: Date.now() } }),
  nearby: () => ({
    customers: [
      { id: 12, name: 'Mia Torres', distance: 2, isOwner: true },
      { id: 31, name: 'Jordan Pike', distance: 6, isOwner: false },
    ],
  }),
  sendBill: () => ({ ok: true }),
  checkout: ({ method }) => (method === 'cash' ? { ok: false, error: 'Not enough cash' } : { ok: true }),
  answerBill: () => ({ ok: true }),
};
