<script lang="ts">
  import Receipt from 'phosphor-svelte/lib/Receipt';
  import { app } from './lib/store.svelte';
  import { formatMoney } from './lib/format';
  import { t } from './lib/locale.svelte';
  import { pop } from './lib/motion';
  import type { Bill } from './lib/types';

  type Props = { bill: Bill };

  let { bill }: Props = $props();

  let now = $state(Date.now());

  const deadline = $derived.by(() => Date.now() + bill.expiresInSeconds * 1000);
  const left = $derived(Math.max(0, Math.ceil((deadline - now) / 1000)));

  $effect(() => {
    const timer = setInterval(() => {
      now = Date.now();
    }, 1000);
    return () => clearInterval(timer);
  });
</script>

<div class="fixed inset-0 z-50 grid place-items-center">
  <div class="w-[28rem] rounded-lg border border-border bg-popover p-6 shadow-lg" role="dialog" aria-modal="true" aria-labelledby="bill-title" in:pop>
    <div class="flex items-center gap-3">
      <span class="grid size-9 place-items-center rounded-md border border-border bg-secondary">
        <Receipt size={16} />
      </span>
      <div>
        <h2 id="bill-title" class="text-base font-semibold">{t('ui.bill.title', bill.shop)}</h2>
        <p class="text-xs text-muted-foreground">{t('ui.bill.subtitle', bill.mechanic, bill.vehicle, bill.plate)}</p>
      </div>
    </div>

    <div class="mt-5 flex flex-col gap-2.5">
      {#each bill.lines as line (line.key)}
        <div class="flex justify-between gap-3 text-sm">
          <span class="truncate">{line.label}</span>
          <span class="font-medium tabular-nums">{formatMoney(line.price)}</span>
        </div>
      {/each}
    </div>

    <div class="mt-3 flex items-baseline justify-between border-t border-border pt-3">
      <span class="text-sm text-muted-foreground">{t('ui.bill.total')}</span>
      <span class="text-2xl font-semibold tracking-tight tabular-nums">{formatMoney(bill.total)}</span>
    </div>

    <div class="mt-4 flex justify-between rounded-md border border-border px-3 py-2.5 text-sm">
      <span class="text-muted-foreground">{t('ui.bill.bank_after')}</span>
      <span class={['font-semibold tabular-nums', bill.bankAfter < 0 && 'text-destructive']}>{formatMoney(bill.bankAfter)}</span>
    </div>

    <div class="mt-5 flex items-center gap-2">
      <span class="flex-1 text-xs text-muted-foreground tabular-nums">{t('ui.bill.expires', left)}</span>
      <button
        type="button"
        class="h-9 rounded-md border border-input bg-secondary px-4 text-sm font-medium hover:bg-secondary-hover disabled:text-muted-foreground"
        disabled={app.billBusy}
        onclick={() => app.answerBill(false)}
      >
        {t('ui.bill.decline')}
      </button>
      <button
        type="button"
        class="h-9 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-cobalt-hover disabled:bg-secondary disabled:text-muted-foreground"
        disabled={app.billBusy || bill.bankAfter < 0}
        onclick={() => app.answerBill(true)}
      >
        {t('ui.bill.pay', formatMoney(bill.total))}
      </button>
    </div>
  </div>
</div>
