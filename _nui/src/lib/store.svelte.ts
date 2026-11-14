import { fetchNui } from './nui';
import { keyOf } from './keys';
import type { Bill, BillStatus, CameraView, Change, Fitting, Messages, Session, Stats } from './types';

export type Tab = 'customize' | 'upgrades' | 'repair';

export type CustomizeView =
  | 'paint:primary'
  | 'paint:secondary'
  | 'pearlescent'
  | 'rims'
  | 'rimColour'
  | 'tyreSmoke'
  | 'body'
  | 'livery'
  | 'extras'
  | 'tint'
  | 'neon'
  | 'headlights'
  | 'plate';

export type CartItem = { key: string; label: string; detail: string; price: number; change: Change };

export type Selection = Omit<CartItem, 'key'>;

export type CheckoutPhase = 'editing' | 'confirm' | 'sending' | 'pending' | 'declined';

class AppState {
  visible = $state(false);
  fitting = $state<Fitting | null>(null);
  session = $state<Session | null>(null);
  bill = $state<Bill | null>(null);
  billBusy = $state(false);
  tab = $state<Tab>('customize');
  view = $state<CustomizeView | null>(null);
  cart = $state<CartItem[]>([]);
  pending = $state<CartItem | null>(null);
  previewStats = $state<Stats | null>(null);
  checkout = $state(false);
  phase = $state<CheckoutPhase>('editing');
  status = $state<BillStatus | null>(null);
  camera = $state<CameraView | null>('front');

  #previewTimer: ReturnType<typeof setTimeout> | undefined;

  get total(): number {
    return this.cart.reduce((sum, item) => sum + item.price, 0);
  }

  get changes(): Change[] {
    const pending = this.pending;
    const kept = this.cart.filter((item) => item.key !== pending?.key).map((item) => item.change);
    return pending ? [...kept, pending.change] : kept;
  }

  get cartChanges(): Change[] {
    return this.cart.map((item) => item.change);
  }

  handle(message: Messages): void {
    switch (message.action) {
      case 'open':
        this.reset();
        this.session = message.data;
        this.visible = true;
        break;
      case 'refresh':
        if (!this.session) return;
        this.session = { ...this.session, ...message.data };
        this.cart = [];
        this.pending = null;
        this.previewStats = null;
        this.checkout = false;
        this.phase = 'editing';
        this.status = null;
        break;
      case 'close':
        this.visible = false;
        this.session = null;
        this.reset();
        break;
      case 'fitting':
        this.fitting = message.data;
        if (!message.data) break;
        this.cart = [];
        this.pending = null;
        this.checkout = false;
        this.phase = 'editing';
        this.status = null;
        this.view = null;
        break;
      case 'bill':
        this.bill = message.data;
        break;
      case 'billCancelled':
        if (this.bill?.id === message.data) this.bill = null;
        break;
      case 'billStatus':
        this.status = message.data;
        this.phase = message.data.status === 'paid' ? 'editing' : 'declined';
        break;
      default: {
        const exhaustive: never = message;
        return exhaustive;
      }
    }
  }

  reset(): void {
    this.tab = 'customize';
    this.view = null;
    this.cart = [];
    this.pending = null;
    this.previewStats = null;
    this.checkout = false;
    this.phase = 'editing';
    this.status = null;
    this.camera = 'front';
    this.fitting = null;
  }

  itemFor(key: string): CartItem | undefined {
    if (this.pending?.key === key) return this.pending;
    return this.cart.find((item) => item.key === key);
  }

  inCart(key: string): CartItem | undefined {
    return this.cart.find((item) => item.key === key);
  }

  select(selection: Selection): void {
    const key = keyOf(selection.change);
    this.pending = { ...selection, key };
    this.preview();
  }

  addPending(): void {
    const pending = this.pending;
    if (!pending) return;

    this.put(pending);
    this.pending = null;
  }

  put(item: CartItem): void {
    const index = this.cart.findIndex((entry) => entry.key === item.key);
    this.cart = index === -1 ? [...this.cart, item] : this.cart.map((entry, i) => (i === index ? item : entry));
    this.preview();
  }

  addNow(selection: Selection): void {
    this.put({ ...selection, key: keyOf(selection.change) });
  }

  undo(): void {
    this.pending = null;
    this.preview();
  }

  remove(key: string): void {
    this.cart = this.cart.filter((item) => item.key !== key);
    if (this.cart.length === 0) this.checkout = false;
    this.preview();
  }

  clear(): void {
    this.cart = [];
    this.pending = null;
    this.checkout = false;
    this.preview();
  }

  open(view: CustomizeView | null): void {
    if (this.pending) this.undo();
    this.view = view;
  }

  setTab(tab: Tab): void {
    if (this.pending) this.undo();
    this.tab = tab;
    this.view = null;
  }

  preview(): void {
    clearTimeout(this.#previewTimer);
    this.#previewTimer = setTimeout(() => {
      void fetchNui('preview', { changes: this.changes }).then((reply) => {
        this.previewStats = reply.stats;
      });
    }, 80);
  }

  async answerBill(accept: boolean): Promise<void> {
    const bill = this.bill;
    if (!bill || this.billBusy) return;

    this.billBusy = true;
    await fetchNui('answerBill', { id: bill.id, accept });
    this.billBusy = false;
    if (this.bill?.id === bill.id) this.bill = null;
  }

  async close(): Promise<void> {
    await fetchNui('close');
    this.visible = false;
    this.session = null;
    this.reset();
  }

  escape(): void {
    if (this.bill || this.fitting) return;
    if (this.phase === 'confirm') {
      this.phase = 'editing';
      return;
    }
    if (this.checkout && this.phase === 'editing') {
      this.checkout = false;
      return;
    }
    if (this.view) {
      this.open(null);
      return;
    }
    if (this.phase === 'pending') return;
    void this.close();
  }
}

export const app = new AppState();
