<script lang="ts">
  import { app } from '../lib/store.svelte';
  import { formatSigned } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Stats } from '../lib/types';

  type Props = { stats: Stats };

  let { stats }: Props = $props();

  type Row = { key: keyof Stats; label: string; max: number; format: (value: number) => string; digits: number; lowerIsBetter?: boolean };

  const rows: Row[] = [
    { key: 'topSpeed', label: 'ui.performance.top_speed', max: 260, format: (value) => t('ui.performance.speed', Math.round(value)), digits: 0 },
    { key: 'acceleration', label: 'ui.performance.acceleration', max: 10, format: (value) => t('ui.performance.score', value.toFixed(1)), digits: 1 },
    { key: 'braking', label: 'ui.performance.braking', max: 10, format: (value) => t('ui.performance.score', value.toFixed(1)), digits: 1 },
    { key: 'handling', label: 'ui.performance.handling', max: 10, format: (value) => t('ui.performance.score', value.toFixed(1)), digits: 1 },
    { key: 'traction', label: 'ui.performance.traction', max: 10, format: (value) => t('ui.performance.score', value.toFixed(1)), digits: 1 },
    { key: 'armour', label: 'ui.performance.armour', max: 100, format: (value) => t('ui.performance.percent', Math.round(value)), digits: 0 },
  ];

  const next = $derived(app.previewStats ?? stats);
  const showing = $derived(app.pending?.label ?? (app.cart.length > 0 ? t('ui.performance.whole_cart') : null));

  function percent(value: number, max: number): number {
    return Math.min(100, Math.max(0, (value / max) * 100));
  }
</script>

<section class="rounded-lg border border-border bg-card p-4">
  <h2 class="text-base font-semibold">{t('ui.performance.title')}</h2>
  <p class="mb-3 text-xs text-muted-foreground">{showing ? t('ui.performance.showing', showing) : t('ui.performance.hint')}</p>

  <div class="flex flex-col gap-3">
    {#each rows as row (row.key)}
      {@const before = stats[row.key]}
      {@const after = next[row.key]}
      {@const delta = Number((after - before).toFixed(row.digits))}
      {@const gain = delta > 0}
      <div>
        <div class="mb-1.5 flex items-baseline gap-2 text-sm">
          <span class="flex-1 font-medium">{t(row.label)}</span>
          <span class="font-semibold tabular-nums">{row.format(after)}</span>
          <span class={['w-10 text-right text-xs tabular-nums', delta === 0 ? 'text-muted-foreground' : gain ? 'text-cobalt-foreground' : 'text-destructive']}>
            {formatSigned(delta, row.digits)}
          </span>
        </div>
        <div class="relative h-1.5 overflow-hidden rounded-full bg-secondary">
          <span class="absolute inset-y-0 left-0 bg-foreground transition-[width] duration-300" style:width="{percent(Math.min(before, after), row.max)}%"></span>
          {#if delta !== 0}
            <span
              class={['absolute inset-y-0 transition-all duration-300', gain ? 'bg-primary' : 'bg-destructive']}
              style:left="{percent(Math.min(before, after), row.max)}%"
              style:width="{percent(Math.abs(after - before), row.max)}%"
            ></span>
          {/if}
        </div>
      </div>
    {/each}
  </div>

  <div class="mt-4 flex gap-4 text-xs text-muted-foreground">
    <span class="flex items-center gap-1.5"><span class="h-1 w-3 rounded-full bg-foreground"></span>{t('ui.performance.now')}</span>
    <span class="flex items-center gap-1.5"><span class="h-1 w-3 rounded-full bg-primary"></span>{t('ui.performance.gain')}</span>
    <span class="flex items-center gap-1.5"><span class="h-1 w-3 rounded-full bg-destructive"></span>{t('ui.performance.loss')}</span>
  </div>
</section>
