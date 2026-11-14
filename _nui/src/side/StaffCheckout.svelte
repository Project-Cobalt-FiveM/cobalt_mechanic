<script lang="ts">
  import CaretLeft from 'phosphor-svelte/lib/CaretLeft';
  import WarningCircle from 'phosphor-svelte/lib/WarningCircle';
  import { app } from '../lib/store.svelte';
  import { fetchNui } from '../lib/nui';
  import { formatMoney, initials } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import { pop } from '../lib/motion';
  import type { BillStatus, Customer, Quote, Session } from '../lib/types';

  type Props = { session: Session };
  type Payer = 'customer' | 'shop';

  let { session }: Props = $props();

  let payer = $state<Payer>('customer');
  let customers = $state<Customer[]>([]);
  let target = $state<number | null>(null);
  let markup = $state(0);
  let quote = $state<Quote | null>(null);
  let error = $state<string | null>(null);
  let quoteTimer: ReturnType<typeof setTimeout> | undefined;

  const shop = $derived(session.shop);
  const subtotal = $derived(quote ? quote.lines.reduce((sum, line) => sum + line.price, 0) : app.total);
  const appliedMarkup = $derived(payer === 'customer' ? markup : 0);
  const total = $derived(quote?.total ?? Math.round(subtotal * (1 + appliedMarkup / 100)));
  const markupAmount = $derived(total - subtotal);
  const crew = $derived(quote?.crew.length ? quote.crew : [session.me.name]);
  const crewShare = $derived(Math.floor((markupAmount * shop.mechanicShare) / crew.length));
  const shopGets = $derived(total - crewShare * crew.length);
  const customer = $derived(customers.find((entry) => entry.id === target));
  const firstName = $derived(customer?.name.split(' ')[0] ?? t('ui.staff.customer'));
  const missing = $derived(quote?.materials.filter((material) => material.have < material.need) ?? []);
  const materialText = $derived(quote?.materials.map((material) => `${material.need} ${material.label.toLowerCase()}`).join(', ') ?? '');
  const otherCrew = $derived(crew.filter((name) => name !== session.me.name));

  const canSend = $derived(app.cart.length > 0 && missing.length === 0 && !quote?.error && (payer === 'shop' || target !== null));

  async function lookAround() {
    const reply = await fetchNui('nearby');
    customers = reply.customers;
    if (reply.customers.some((entry) => entry.id === target)) return;
    target = reply.customers.find((entry) => entry.isOwner)?.id ?? reply.customers[0]?.id ?? null;
  }

  $effect(() => {
    if (payer !== 'customer' || app.phase !== 'editing') return;

    void lookAround();
    const timer = setInterval(() => void lookAround(), 2000);
    return () => clearInterval(timer);
  });

  $effect(() => {
    const changes = app.cartChanges;
    const percent = appliedMarkup;
    clearTimeout(quoteTimer);
    quoteTimer = setTimeout(() => {
      void fetchNui('quote', { changes, markup: percent }).then((reply) => (quote = reply));
    }, 150);
    return () => clearTimeout(quoteTimer);
  });

  async function send() {
    app.phase = 'sending';
    error = null;
    const reply = await fetchNui('sendBill', {
      changes: app.cartChanges,
      payer,
      target: payer === 'customer' && target !== null ? target : undefined,
      markup: appliedMarkup,
    });

    if (!reply.ok) {
      app.phase = 'editing';
      error = reply.error ?? t('ui.staff.send_failed');
      return;
    }

    app.phase = payer === 'customer' ? 'pending' : 'sending';
  }

  function billShop() {
    payer = 'shop';
    app.status = null;
    app.phase = 'editing';
  }

  function undoWork() {
    app.status = null;
    app.phase = 'editing';
    app.clear();
  }

  function declinedTitle(status: BillStatus): string {
    if (status.status === 'expired') return t('ui.staff.expired', status.customer);
    if (status.status === 'failed') return t('ui.staff.failed');
    return t('ui.staff.declined', status.customer);
  }

  function rangeFill(node: HTMLInputElement, value: number) {
    const paint = (current: number) => node.style.setProperty('--fill', `${(current / Math.max(1, shop.maxMarkup)) * 100}%`);
    paint(value);
    return { update: paint };
  }
</script>

<section class="flex h-full flex-col rounded-lg border border-border bg-card">
  <header class="flex items-center gap-3 border-b border-border p-4">
    <button
      type="button"
      class="grid size-8 shrink-0 place-items-center rounded-md border border-border bg-secondary hover:bg-secondary-hover disabled:text-muted-foreground"
      aria-label={t('ui.staff.back')}
      disabled={app.phase === 'pending' || app.phase === 'sending'}
      onclick={() => (app.checkout = false)}
    >
      <CaretLeft size={14} />
    </button>
    <div>
      <h2 class="text-lg font-semibold tracking-tight">{t('ui.staff.title')}</h2>
      <p class="text-xs text-muted-foreground">{t('ui.staff.subtitle', shop.label)}</p>
    </div>
  </header>

  {#if app.phase === 'declined' && app.status}
    <div class="flex flex-1 flex-col gap-4 p-4" in:pop>
      <div class="flex items-start gap-3 rounded-lg border border-border bg-muted p-4">
        <WarningCircle size={20} class="mt-0.5 shrink-0 text-destructive" />
        <div>
          <p class="text-sm font-semibold">{declinedTitle(app.status)}</p>
          <p class="text-sm text-muted-foreground">{app.status.message ?? t('ui.staff.declined_note')}</p>
        </div>
      </div>
      <div class="mt-auto flex flex-col gap-2">
        {#if session.me.canBillShop}
          <button type="button" class="h-10 rounded-md bg-primary text-sm font-medium text-primary-foreground hover:bg-cobalt-hover" onclick={billShop}>
            {t('ui.staff.bill_shop')}
          </button>
        {/if}
        <button type="button" class="h-10 rounded-md border border-input bg-secondary text-sm font-medium hover:bg-secondary-hover" onclick={() => (app.phase = 'editing')}>
          {t('ui.staff.retry')}
        </button>
        <button type="button" class="h-10 rounded-md bg-destructive-solid text-sm font-medium text-white hover:bg-destructive-hover" onclick={undoWork}>
          {t('ui.staff.take_off')}
        </button>
      </div>
    </div>
  {:else}
    <div class="flex min-h-0 flex-1 flex-col gap-5 overflow-y-auto p-4">
      <div class="flex flex-col gap-2.5">
        {#each app.cart as item (item.key)}
          <div class="flex justify-between gap-3 text-sm">
            <span class="truncate font-medium">{item.label}</span>
            <span class="font-semibold tabular-nums">{formatMoney(item.price)}</span>
          </div>
        {/each}
        <div class="flex justify-between border-t border-border pt-2.5 text-sm">
          <span class="text-muted-foreground">{t('ui.cart.subtotal')}</span>
          <span class="font-semibold tabular-nums">{formatMoney(subtotal)}</span>
        </div>
      </div>

      <div class="flex flex-col gap-2">
        <p class="text-sm font-semibold">{t('ui.staff.bill_to')}</p>
        <div class="grid grid-cols-2 gap-1 rounded-md border border-border bg-background p-1">
          <button
            type="button"
            class={['h-8 rounded-sm text-sm font-medium transition-colors', payer === 'customer' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground']}
            onclick={() => (payer = 'customer')}
          >
            {t('ui.staff.customer')}
          </button>
          <button
            type="button"
            disabled={!session.me.canBillShop}
            title={session.me.canBillShop ? undefined : t('ui.staff.rank_blocked')}
            class={['h-8 rounded-sm text-sm font-medium transition-colors', payer === 'shop' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground enabled:hover:text-foreground']}
            onclick={() => (payer = 'shop')}
          >
            {t('ui.staff.shop_account')}
          </button>
        </div>

        {#if payer === 'customer'}
          {#if customers.length === 0}
            <p class="rounded-md border border-border px-3 py-3 text-sm text-muted-foreground">{t('ui.staff.nobody')}</p>
          {/if}
          {#each customers as entry (entry.id)}
            <button
              type="button"
              class={['flex items-center gap-3 rounded-md border px-3 py-2 text-left transition-colors', target === entry.id ? 'border-primary bg-muted' : 'border-border hover:bg-muted']}
              onclick={() => (target = entry.id)}
            >
              <span class="grid size-8 place-items-center rounded-full bg-secondary text-xs font-semibold">{initials(entry.name)}</span>
              <span>
                <span class="block text-sm font-semibold">{entry.name}</span>
                <span class="block text-xs text-muted-foreground tabular-nums">
                  {t(entry.isOwner ? 'ui.staff.owner_distance' : 'ui.staff.distance', Math.round(entry.distance))}
                </span>
              </span>
            </button>
          {/each}
        {:else}
          <p class="text-xs text-muted-foreground">{t('ui.staff.shop_pays', formatMoney(subtotal))}</p>
        {/if}
      </div>

      {#if payer === 'customer' && shop.maxMarkup > 0}
        <div class="flex flex-col gap-2">
          <div class="flex justify-between text-sm">
            <span class="font-semibold">{t('ui.staff.markup')}</span>
            <span class="font-semibold tabular-nums">{t('ui.performance.percent', markup)}</span>
          </div>
          <input type="range" class="markup" min="0" max={shop.maxMarkup} step="1" bind:value={markup} use:rangeFill={markup} aria-label={t('ui.staff.markup')} />
          <div class="flex justify-between text-xs text-muted-foreground tabular-nums">
            <span>{t('ui.performance.percent', 0)}</span>
            <span>{t('ui.staff.markup_limit', shop.maxMarkup)}</span>
          </div>
          <p class="text-xs text-muted-foreground">
            {t('ui.staff.markup_note', formatMoney(markupAmount), Math.round(shop.mechanicShare * 100))}
          </p>
        </div>
      {/if}

      {#if error || quote?.error}
        <p class="flex items-center gap-2 text-sm text-destructive"><WarningCircle size={14} />{error ?? quote?.error}</p>
      {/if}
    </div>

    <footer class="flex flex-col gap-2 border-t border-border p-4">
      <div class="flex items-baseline justify-between">
        <span class="text-sm text-muted-foreground">{payer === 'customer' ? t('ui.staff.pays', firstName) : t('ui.staff.shop_account_pays')}</span>
        <span class="text-2xl font-semibold tracking-tight tabular-nums">{formatMoney(total)}</span>
      </div>
      {#if payer === 'customer'}
        <div class="flex justify-between text-sm">
          <span class="text-muted-foreground">{t('ui.staff.shop_gets')}</span>
          <span class="font-medium tabular-nums">{formatMoney(shopGets)}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-muted-foreground">{otherCrew.length > 0 ? t('ui.staff.crew_gets', otherCrew.join(', ')) : t('ui.staff.you_get')}</span>
          <span class="font-medium tabular-nums">{formatMoney(crewShare)}</span>
        </div>
      {/if}
      {#if materialText}
        <div class="flex justify-between gap-4 text-sm">
          <span class="shrink-0 text-muted-foreground">{t('ui.staff.materials')}</span>
          <span class={['truncate text-right font-medium', missing.length > 0 && 'text-destructive']}>{materialText}</span>
        </div>
      {/if}
      {#if missing.length > 0}
        <p class="text-xs text-destructive">
          {t('ui.staff.short', missing.map((material) => t('ui.staff.short_item', material.label.toLowerCase(), material.have, material.need)).join(', '))}
        </p>
      {/if}
      <div class="mt-2 flex gap-2">
        <button
          type="button"
          class="h-10 rounded-md border border-input bg-secondary px-4 text-sm font-medium hover:bg-secondary-hover disabled:text-muted-foreground"
          disabled={app.phase !== 'editing'}
          onclick={() => (app.checkout = false)}
        >
          {t('ui.staff.back')}
        </button>
        {#if app.phase === 'pending'}
          <div class="flex h-10 flex-1 items-center justify-center rounded-md bg-muted text-sm text-muted-foreground">{t('ui.staff.waiting', firstName)}</div>
        {:else}
          <button
            type="button"
            class="h-10 flex-1 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground transition-colors hover:bg-cobalt-hover disabled:bg-secondary disabled:text-muted-foreground"
            disabled={!canSend || app.phase !== 'editing'}
            onclick={() => (app.phase = 'confirm')}
          >
            {payer === 'customer' ? t('ui.staff.send_to', firstName, formatMoney(total)) : t('ui.staff.charge_shop_total', formatMoney(total))}
          </button>
        {/if}
      </div>
    </footer>
  {/if}
</section>

{#if app.phase === 'confirm'}
  <div class="fixed inset-0 z-40 grid place-items-center">
    <div class="w-full max-w-md rounded-lg border border-border bg-popover p-6 shadow-lg" role="dialog" aria-modal="true" aria-labelledby="confirm-title" in:pop>
      <h2 id="confirm-title" class="text-lg font-semibold">
        {payer === 'customer' ? t('ui.staff.confirm_customer_title', customer?.name ?? t('ui.staff.the_customer')) : t('ui.staff.confirm_shop_title')}
      </h2>
      <p class="mt-1 text-sm text-muted-foreground">
        {payer === 'customer'
          ? app.cart.length === 1
            ? t('ui.staff.confirm_customer_one', formatMoney(total))
            : t('ui.staff.confirm_customer_many', formatMoney(total), app.cart.length)
          : t('ui.staff.confirm_shop', formatMoney(total), shop.label)}
      </p>
      <div class="mt-6 flex justify-end gap-2">
        <button type="button" class="h-9 rounded-md border border-input bg-secondary px-4 text-sm font-medium hover:bg-secondary-hover" onclick={() => (app.phase = 'editing')}>
          {t('ui.staff.cancel')}
        </button>
        <button type="button" class="h-9 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-cobalt-hover" onclick={send}>
          {payer === 'customer' ? t('ui.staff.send') : t('ui.staff.charge_shop')}
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .markup {
    appearance: none;
    height: 0.375rem;
    border-radius: 999px;
    background: linear-gradient(to right, var(--color-primary) var(--fill), var(--color-secondary) var(--fill));
  }

  .markup::-webkit-slider-thumb {
    appearance: none;
    width: 1rem;
    height: 1rem;
    border-radius: 999px;
    background: var(--color-foreground);
    border: 2px solid var(--color-primary);
  }
</style>
