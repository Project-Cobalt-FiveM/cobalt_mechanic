<script lang="ts">
  import Trash from 'phosphor-svelte/lib/Trash';
  import { app } from '../lib/store.svelte';
  import { formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import { rise } from '../lib/motion';
  import type { Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const employee = $derived(session.mode === 'employee');
</script>

<section class="rounded-lg border border-border bg-card">
  <header class="flex items-center justify-between px-4 pt-4 pb-2">
    <h2 class="text-base font-semibold">{t('ui.cart.title')}</h2>
    {#if app.cart.length > 0}
      <button type="button" class="text-xs text-muted-foreground transition-colors hover:text-foreground" onclick={() => app.clear()}>{t('ui.cart.clear')}</button>
    {/if}
  </header>

  {#if app.cart.length === 0}
    <p class="px-4 pb-4 text-sm text-muted-foreground">{t('ui.cart.empty')}</p>
  {:else}
    <ul class="flex max-h-[40vh] flex-col gap-3 overflow-y-auto px-4 pt-1 pb-4">
      {#each app.cart as item (item.key)}
        <li class="flex items-center gap-3" transition:rise>
          <span class="min-w-0 flex-1">
            <span class="block truncate text-sm font-semibold">{item.label}</span>
            <span class="block truncate text-xs text-muted-foreground">{item.detail}</span>
          </span>
          <span class="text-sm font-semibold tabular-nums">{formatMoney(item.price)}</span>
          <button
            type="button"
            class="grid size-6 place-items-center rounded-md text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
            aria-label={t('ui.cart.remove', item.label)}
            onclick={() => app.remove(item.key)}
          >
            <Trash size={13} />
          </button>
        </li>
      {/each}
    </ul>

    <div class="flex flex-col gap-3 border-t border-border p-4">
      <div class="flex items-baseline justify-between">
        <span class="text-sm text-muted-foreground">{t('ui.cart.subtotal')}</span>
        <span class="text-2xl font-semibold tracking-tight tabular-nums">{formatMoney(app.total)}</span>
      </div>
      <button
        type="button"
        class="h-10 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground transition-colors hover:bg-cobalt-hover"
        onclick={() => {
          if (app.pending) app.undo();
          app.checkout = true;
          app.phase = 'editing';
        }}
      >
        {employee ? t('ui.staff.title') : t('ui.self.title')}
      </button>
      <p class="text-xs text-muted-foreground">
        {employee ? t('ui.cart.staff_note') : t('ui.cart.self_note')}
      </p>
    </div>
  {/if}
</section>
