<script lang="ts">
  import CaretLeft from 'phosphor-svelte/lib/CaretLeft';
  import { formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';

  type Props = { title: string; description: string; price?: number; onback: () => void };

  let { title, description, price, onback }: Props = $props();
</script>

<div class="flex items-center gap-3">
  <button
    type="button"
    class="grid size-8 shrink-0 place-items-center rounded-md border border-border bg-secondary text-foreground transition-colors hover:bg-secondary-hover"
    aria-label={t('ui.panel.back')}
    onclick={onback}
  >
    <CaretLeft size={14} />
  </button>
  <div class="min-w-0 flex-1">
    <p class="truncate text-sm font-semibold">{title}</p>
    <p class="truncate text-xs text-muted-foreground">{description}</p>
  </div>
  {#if price !== undefined}
    <span class="text-sm font-semibold tabular-nums">{formatMoney(price)}</span>
  {/if}
</div>
