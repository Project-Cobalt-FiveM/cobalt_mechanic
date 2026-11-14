export type ShopMode = 'employee' | 'self';
export type PaintSlot = 'primary' | 'secondary';
export type Finish = 'normal' | 'metallic' | 'pearl' | 'matte' | 'metal' | 'chrome';
export type PaintTab = 'metallic' | 'matte' | 'util' | 'worn' | 'metals';
export type Rgb = [number, number, number];
export type CameraView = 'front' | 'side' | 'rear' | 'wheel' | 'engine' | 'interior';
export type ModGroup = 'exterior' | 'interior' | 'engine';
export type UpgradeName = 'engine' | 'brakes' | 'transmission' | 'suspension' | 'armour' | 'turbo';
export type RepairPart = 'engine' | 'body';
export type ServiceName = 'oil' | 'battery' | 'tyres' | 'brakes' | 'clutch';
export type WearSystem = 'brakes' | 'clutch' | 'oil' | 'battery' | 'tyres';
export type PayMethod = 'bank' | 'cash';

export type Change =
  | { kind: 'paint'; slot: PaintSlot; index: number }
  | { kind: 'paintCustom'; slot: PaintSlot; rgb: Rgb; finish: Finish }
  | { kind: 'pearlescent'; index: number }
  | { kind: 'wheelColour'; index: number }
  | { kind: 'wheels'; type: number; index: number; custom: boolean }
  | { kind: 'tyreSmoke'; rgb: Rgb }
  | { kind: 'tint'; index: number }
  | { kind: 'neon'; enabled: [boolean, boolean, boolean, boolean]; colour: number }
  | { kind: 'xenon'; enabled: boolean; colour: number }
  | { kind: 'plate'; index: number }
  | { kind: 'livery'; index: number; legacy: boolean }
  | { kind: 'extra'; id: number; enabled: boolean }
  | { kind: 'mod'; slot: number; index: number }
  | { kind: 'upgrade'; name: UpgradeName; level: number }
  | { kind: 'repair'; part: RepairPart }
  | { kind: 'service'; name: ServiceName };

export type Colour = { index: number; name: string; hex: string; tab: PaintTab; group?: string };
export type Chameleon = { index: number; name: string; series: string; from: string; to: string };
export type Tint = { level: number; name: string; hex: string };
export type NeonColour = { name: string; rgb: Rgb };
export type Xenon = { index: number; name: string; hex: string };
export type Plate = { index: number; name: string };

export type Prices = {
  paint: number;
  paintCustom: number;
  chameleon: number;
  pearlescent: number;
  wheelColour: number;
  wheels: number;
  tyreSmoke: number;
  tint: number;
  neon: number;
  xenon: number;
  plate: number;
  livery: number;
  extra: number;
};

export type Catalog = {
  colours: Colour[];
  chameleons: Chameleon[];
  tints: Tint[];
  neons: NeonColour[];
  xenons: Xenon[];
  plates: Plate[];
  prices: Prices;
  services: { name: ServiceName; label: string; price: number; system: WearSystem }[];
  repairs: Record<RepairPart, { perPercent: number; minimum: number }>;
};

/** The ox_lib vehicle properties the menu reads. Colours are a palette index or a custom RGB. */
export type VehicleProps = {
  color1: number | Rgb;
  color2: number | Rgb;
  pearlescentColor: number;
  wheelColor: number;
  wheels: number;
  modFrontWheels: number;
  modCustomTiresF: boolean;
  modSmokeEnabled: boolean;
  tyreSmokeColor: Rgb;
  windowTint: number;
  neonEnabled: [boolean, boolean, boolean, boolean];
  neonColor: Rgb;
  modXenon: boolean;
  xenonColor: number;
  plateIndex: number;
  livery: number;
  modLivery: number;
  extras: Record<string, 0 | 1>;
  /** Body mod index per slot, -1 for stock. */
  mods: Record<string, number>;
  /** Fitted level per upgrade, 0 for stock. */
  upgrades: Record<UpgradeName, number>;
};

export type ModOption = { slot: number; name: string; group: ModGroup; price: { base: number; step: number }; options: string[] };
export type WheelOption = { type: number; name: string; options: string[] };
export type Material = { item: string; label: string; count: number };
export type UpgradeLevel = { name: string; price: number; grade: number; materials: Material[] };
export type UpgradeOption = { name: UpgradeName; label: string; toggle: boolean; levels: UpgradeLevel[] };

export type VehicleOptions = {
  mods: ModOption[];
  wheels: WheelOption[];
  liveries: { legacy: boolean; options: string[] };
  extras: number[];
  upgrades: UpgradeOption[];
};

export type Diagnosis = {
  mileageKm: number;
  scannedAt: number;
  engine: number;
  body: number;
  /** Null when the car has no wear record, i.e. it isn't player owned. */
  wear: Record<WearSystem, number> | null;
};

export type Stats = {
  topSpeed: number;
  acceleration: number;
  braking: number;
  handling: number;
  traction: number;
  armour: number;
};

export type Session = {
  mode: ShopMode;
  shop: { label: string; maxMarkup: number; mechanicShare: number };
  vehicle: { label: string; plate: string; owner: string | null };
  me: { name: string; grade: number; canBillShop: boolean };
  balances: { bank: number; cash: number } | null;
  props: VehicleProps;
  options: VehicleOptions;
  diagnosis: Diagnosis;
  stats: Stats;
  catalog: Catalog;
};

export type Line = { key: string; label: string; price: number };
export type MaterialNeed = { item: string; label: string; need: number; have: number };
export type Quote = { lines: Line[]; total: number; materials: MaterialNeed[]; crew: string[]; error?: string };

export type Customer = { id: number; name: string; distance: number; isOwner: boolean };

export type Bill = {
  id: number;
  shop: string;
  mechanic: string;
  vehicle: string;
  plate: string;
  lines: Line[];
  total: number;
  bankAfter: number;
  expiresInSeconds: number;
};

export type BillStatus = { status: 'paid' | 'declined' | 'expired' | 'failed'; customer: string; message?: string };

export type Result = { ok: boolean; error?: string };

export type FitStatus = 'next' | 'active' | 'done' | 'skipped';
export type FitItem = { key: string; label: string; seconds: number; status: FitStatus };
export type CrewMember = { name: string; role: string; grade: number; distance: number; isYou: boolean };

export type Fitting = {
  id: number;
  paidBy: string;
  total: number;
  index: number;
  sharesMarkup: boolean;
  crewRadius: number;
  items: FitItem[];
  crew: CrewMember[];
};

export type Locales = Record<string, string>;

export type Messages =
  | { action: 'open'; data: Session; locales?: Locales }
  | { action: 'refresh'; data: { props: VehicleProps; diagnosis: Diagnosis; stats: Stats; balances: Session['balances'] } }
  | { action: 'close' }
  | { action: 'fitting'; data: Fitting | null }
  | { action: 'bill'; data: Bill; locales?: Locales }
  | { action: 'billCancelled'; data: number }
  | { action: 'billStatus'; data: BillStatus };

/** Each NUI request: [payload, reply]. */
export type Requests = {
  close: [void, Result];
  preview: [{ changes: Change[] }, { stats: Stats }];
  quote: [{ changes: Change[]; markup: number }, Quote];
  camera: [{ view: CameraView }, Result];
  orbit: [{ dx: number; dy: number }, Result];
  zoom: [{ delta: number }, Result];
  scan: [void, { diagnosis?: Diagnosis }];
  nearby: [void, { customers: Customer[] }];
  sendBill: [{ changes: Change[]; payer: 'customer' | 'shop'; target?: number; markup: number }, Result];
  checkout: [{ changes: Change[]; method: PayMethod }, Result];
  answerBill: [{ id: number; accept: boolean }, Result];
};
