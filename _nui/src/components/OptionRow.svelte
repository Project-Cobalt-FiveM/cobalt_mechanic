<script lang="ts">
  import CheckCircle from 'phosphor-svelte/lib/CheckCircle';
  import Lock from 'phosphor-svelte/lib/Lock';
  import WarningCircle from 'phosphor-svelte/lib/WarningCircle';
  import { formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';

  type Props = {
    title: string;
    subtitle?: string;
    price?: number;
    selected?: boolean;
    installed?: boolean;
    inCart?: boolean;
    locked?: boolean;
    warning?: boolean;
    onclick: () => void;
  };

  let { title, subtitle, price, selected = false, installed = false, inCart = false, locked = false, warning = false, onclick }: Props = $props();
</script>

<button
  type="button"
  class={[
    'flex min-h-14 w-full items-center gap-3 rounded-lg border px-3 py-2.5 text-left transition-colors',
    selected ? 'border-primary bg-primary text-primary-foreground' : 'border-border bg-card hover:bg-muted',
    locked && !selected && 'text-muted-foreground',
  ]}
  disabled={locked}
  {onclick}
>
  <span class="min-w-0 flex-1">
    <span class={['block truncate text-sm', locked ? 'font-normal' : 'font-medium']}>{title}</span>
    {#if subtitle}
      <span class={['block truncate text-xs', selected ? 'text-primary-foreground' : 'text-muted-foreground']}>{subtitle}</span>
    {/if}
  </span>
  {#if installed && !selected}
    <span class="flex items-center gap-1.5 text-xs font-medium">
      <CheckCircle size={14} class="text-success" />
      {t('ui.option.installed')}
    </span>
  {:else}
    {#if inCart && !selected}
      <span class="rounded-sm bg-secondary px-2 py-0.5 text-xs font-medium">{t('ui.option.in_cart')}</span>
    {/if}
    {#if locked}
      <Lock size={13} class="text-muted-foreground" />
    {:else if warning}
      <WarningCircle size={13} class="text-warning" />
    {/if}
    {#if price !== undefined}
      <span class="text-sm font-semibold tabular-nums">{formatMoney(price)}</span>
    {/if}
  {/if}
</button>
