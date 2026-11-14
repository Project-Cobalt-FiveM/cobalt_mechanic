<script lang="ts">
  import { formatMoney } from '../lib/format';
  import { app } from '../lib/store.svelte';
  import { t } from '../lib/locale.svelte';

  type Props = { keys: string[]; swatch?: string; compact?: boolean };

  let { keys, swatch, compact = false }: Props = $props();

  const pending = $derived(app.pending && keys.includes(app.pending.key) ? app.pending : null);
  const replaces = $derived(pending ? app.inCart(pending.key) : undefined);
</script>

{#if pending && compact}
  <div class="flex gap-2">
    <button
      type="button"
      class="h-9 min-w-0 flex-1 truncate rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground transition-colors hover:bg-cobalt-hover"
      onclick={() => app.addPending()}
    >
      {t('ui.preview.add_named', pending.label, formatMoney(pending.price))}
    </button>
    <button
      type="button"
      class="h-9 rounded-md border border-input bg-secondary px-4 text-sm font-medium transition-colors hover:bg-secondary-hover"
      onclick={() => app.undo()}
    >
      {t('ui.preview.undo')}
    </button>
  </div>
{:else if pending}
  <div class="mt-auto flex flex-col gap-3 rounded-lg border border-border bg-card p-4">
    <div class="flex items-center gap-3">
      {#if swatch}
        <span class="size-12 shrink-0 rounded-md border border-border" style:background={swatch}></span>
      {/if}
      <div class="min-w-0 flex-1">
        <p class="truncate text-sm font-semibold">{pending.label}</p>
        <p class="truncate text-xs text-muted-foreground">{replaces ? t('ui.preview.replaces', replaces.label) : pending.detail}</p>
      </div>
      <span class="text-sm font-semibold tabular-nums">{formatMoney(pending.price)}</span>
    </div>
    <div class="flex gap-2">
      <button
        type="button"
        class="h-9 flex-1 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground transition-colors hover:bg-cobalt-hover"
        onclick={() => app.addPending()}
      >
        {t('ui.preview.add')}
      </button>
      <button
        type="button"
        class="h-9 rounded-md border border-input bg-secondary px-4 text-sm font-medium transition-colors hover:bg-secondary-hover"
        onclick={() => app.undo()}
      >
        {t('ui.preview.undo')}
      </button>
    </div>
  </div>
{/if}
