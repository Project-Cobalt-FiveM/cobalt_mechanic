<script lang="ts">
  import CaretLeft from 'phosphor-svelte/lib/CaretLeft';
  import Bank from 'phosphor-svelte/lib/Bank';
  import Money from 'phosphor-svelte/lib/Money';
  import Info from 'phosphor-svelte/lib/Info';
  import WarningCircle from 'phosphor-svelte/lib/WarningCircle';
  import type { Component } from 'svelte';
  import { app } from '../lib/store.svelte';
  import { fetchNui } from '../lib/nui';
  import { formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { PayMethod, Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  let error = $state<string | null>(null);

  const total = $derived(app.total);
  const balances = $derived(session.balances ?? { bank: 0, cash: 0 });
  const methods = $derived<{ id: PayMethod; label: string; icon: Component; balance: number }[]>([
    { id: 'bank', label: 'ui.self.bank', icon: Bank, balance: balances.bank },
    { id: 'cash', label: 'ui.self.cash', icon: Money, balance: balances.cash },
  ]);

  let chosen = $state<PayMethod | null>(null);

  const method = $derived(chosen ?? methods.find((entry) => entry.balance >= total)?.id ?? 'bank');
  const affordable = $derived((methods.find((entry) => entry.id === method)?.balance ?? 0) >= total);

  async function pay() {
    app.phase = 'sending';
    error = null;
    const reply = await fetchNui('checkout', { changes: app.cartChanges, method });
    if (!reply.ok) {
      app.phase = 'editing';
      error = reply.error ?? t('ui.self.failed');
    }
  }
</script>

<section class="flex h-full flex-col rounded-lg border border-border bg-card">
  <header class="flex items-center gap-3 border-b border-border p-4">
    <button
      type="button"
      class="grid size-8 shrink-0 place-items-center rounded-md border border-border bg-secondary hover:bg-secondary-hover"
      aria-label={t('ui.self.keep_editing')}
      onclick={() => (app.checkout = false)}
    >
      <CaretLeft size={14} />
    </button>
    <div>
      <h2 class="text-lg font-semibold tracking-tight">{t('ui.self.title')}</h2>
      <p class="text-xs text-muted-foreground">{t('ui.self.subtitle', session.shop.label)}</p>
    </div>
  </header>

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
        <span class="font-semibold tabular-nums">{formatMoney(total)}</span>
      </div>
    </div>

    <div class="flex flex-col gap-2">
      <p class="text-sm font-semibold">{t('ui.self.pay_with')}</p>
      {#each methods as entry (entry.id)}
        {@const enough = entry.balance >= total}
        <button
          type="button"
          class={['flex items-center gap-3 rounded-md border px-3 py-2.5 text-left transition-colors', method === entry.id ? 'border-primary bg-muted' : 'border-border hover:bg-muted']}
          onclick={() => (chosen = entry.id)}
        >
          <entry.icon size={18} class={method === entry.id ? 'text-cobalt-foreground' : 'text-muted-foreground'} />
          <span>
            <span class="block text-sm font-semibold">{t(entry.label)}</span>
            <span class={['block text-xs tabular-nums', enough ? 'text-muted-foreground' : 'text-destructive']}>
              {t(entry.id === 'bank' ? 'ui.self.available' : 'ui.self.on_you', formatMoney(entry.balance))}{enough ? '' : t('ui.self.not_enough')}
            </span>
          </span>
        </button>
      {/each}
    </div>

    <p class="flex gap-2.5 rounded-md border border-border p-3 text-xs text-muted-foreground">
      <Info size={14} class="mt-px shrink-0 text-cobalt-foreground" />
      {t('ui.self.note', session.shop.label)}
    </p>

    {#if error}
      <p class="flex items-center gap-2 text-sm text-destructive"><WarningCircle size={14} />{error}</p>
    {/if}
  </div>

  <footer class="flex flex-col gap-2 border-t border-border p-4">
    <div class="flex items-baseline justify-between">
      <span class="text-sm text-muted-foreground">{t('ui.self.you_pay')}</span>
      <span class="text-2xl font-semibold tracking-tight tabular-nums">{formatMoney(total)}</span>
    </div>
    <div class="flex justify-between text-sm">
      <span class="text-muted-foreground">{t('ui.self.to_shop')}</span>
      <span class="font-medium tabular-nums">{formatMoney(total)}</span>
    </div>
    <div class="mt-2 flex gap-2">
      <button type="button" class="h-10 rounded-md border border-input bg-secondary px-4 text-sm font-medium hover:bg-secondary-hover" onclick={() => (app.checkout = false)}>
        {t('ui.self.keep_editing')}
      </button>
      <button
        type="button"
        class="h-10 flex-1 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground transition-colors hover:bg-cobalt-hover disabled:bg-secondary disabled:text-muted-foreground"
        disabled={!affordable || app.phase !== 'editing' || app.cart.length === 0}
        onclick={pay}
      >
        {app.phase === 'sending' ? t('ui.self.paying') : t('ui.bill.pay', formatMoney(total))}
      </button>
    </div>
  </footer>
</section>
