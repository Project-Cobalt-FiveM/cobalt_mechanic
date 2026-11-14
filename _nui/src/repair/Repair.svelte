<script lang="ts">
  import { app } from '../lib/store.svelte';
  import { fetchNui } from '../lib/nui';
  import { ago, formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { RepairPart, Session, WearSystem } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  type Bar = { id: string; label: string; value: number; repair?: RepairPart; system?: WearSystem };

  let scanning = $state(false);
  let now = $state(Date.now());

  $effect(() => {
    const timer = setInterval(() => (now = Date.now()), 30000);
    return () => clearInterval(timer);
  });

  const diagnosis = $derived(session.diagnosis);
  const services = $derived(session.catalog.services);

  const bars = $derived.by((): Bar[] => {
    const list: Bar[] = [
      { id: 'engine', label: 'ui.repair.engine', value: diagnosis.engine, repair: 'engine' },
      { id: 'body', label: 'ui.repair.body', value: diagnosis.body, repair: 'body' },
    ];
    if (diagnosis.wear) {
      list.push(
        { id: 'brakes', label: 'ui.repair.brakes', value: diagnosis.wear.brakes, system: 'brakes' },
        { id: 'clutch', label: 'ui.repair.clutch', value: diagnosis.wear.clutch, system: 'clutch' },
        { id: 'oil', label: 'ui.repair.oil', value: diagnosis.wear.oil, system: 'oil' },
        { id: 'battery', label: 'ui.repair.battery', value: diagnosis.wear.battery, system: 'battery' },
        { id: 'tyres', label: 'ui.repair.tyres', value: diagnosis.wear.tyres, system: 'tyres' },
      );
    }
    return list;
  });

  function tone(value: number): { bar: string; text: string } {
    if (value < 30) return { bar: 'bg-destructive', text: 'text-destructive' };
    if (value < 50) return { bar: 'bg-warning', text: 'text-warning' };
    return { bar: 'bg-foreground', text: 'text-foreground' };
  }

  function repairPrice(part: RepairPart, value: number): number {
    const { perPercent, minimum } = session.catalog.repairs[part];
    return Math.max(minimum, Math.ceil((100 - value) * perPercent));
  }

  function addRepair(part: RepairPart, value: number) {
    const label = t(part === 'engine' ? 'ui.repair.engine_repair' : 'ui.repair.body_repair');
    app.addNow({ label, detail: t('ui.repair.detail', Math.floor(value)), price: repairPrice(part, value), change: { kind: 'repair', part } });
  }

  async function scan() {
    scanning = true;
    const reply = await fetchNui('scan');
    scanning = false;
    if (!app.session || !reply.diagnosis) return;
    app.session = { ...app.session, diagnosis: reply.diagnosis };
  }
</script>

<div class="flex min-h-0 flex-1 flex-col gap-5">
  <div class="flex items-start justify-between gap-3">
    <div>
      <h3 class="text-base font-semibold">{t('ui.repair.title')}</h3>
      <p class="text-xs text-muted-foreground tabular-nums">
        {diagnosis.wear
          ? t('ui.repair.scanned_at', ago(diagnosis.scannedAt, now), diagnosis.mileageKm.toLocaleString('en-US'))
          : t('ui.repair.scanned', ago(diagnosis.scannedAt, now))}
      </p>
    </div>
    <button
      type="button"
      class="h-8 rounded-md border border-input bg-secondary px-3 text-xs font-medium transition-colors hover:bg-secondary-hover disabled:text-muted-foreground"
      disabled={scanning}
      onclick={scan}
    >
      {scanning ? t('ui.repair.scanning') : t('ui.repair.scan')}
    </button>
  </div>

  <div class="flex flex-col">
    {#each bars as bar (bar.id)}
      {@const colours = tone(bar.value)}
      {@const service = bar.system ? services.find((entry) => entry.system === bar.system) : undefined}
      {@const repairKey = bar.repair ? `repair:${bar.repair}` : service ? `service:${service.name}` : ''}
      {@const inCart = repairKey !== '' && app.inCart(repairKey) !== undefined}
      <div class="flex h-12 items-center gap-3">
        <span class="w-16 text-sm font-medium">{t(bar.label)}</span>
        <span class="h-1.5 flex-1 rounded-full bg-secondary">
          <span class={['block h-full rounded-full transition-[width] duration-300', colours.bar]} style:width="{Math.max(2, bar.value)}%"></span>
        </span>
        <span class={['w-11 text-right text-sm font-semibold tabular-nums', colours.text]}>{Math.round(bar.value)}%</span>
        <span class="flex w-28 justify-end">
          {#if inCart}
            <button type="button" class="h-7 rounded-md bg-primary px-2.5 text-xs font-medium text-primary-foreground" onclick={() => app.remove(repairKey)}>{t('ui.option.in_cart')}</button>
          {:else if bar.repair && bar.value < 99.5}
            {@const part = bar.repair}
            <button
              type="button"
              class="h-7 rounded-md border border-input bg-secondary px-2.5 text-xs font-medium tabular-nums hover:bg-secondary-hover"
              onclick={() => addRepair(part, bar.value)}
            >
              {t('ui.repair.repair', formatMoney(repairPrice(part, bar.value)))}
            </button>
          {:else if bar.value < 30}
            <span class="text-xs text-muted-foreground">{t('ui.repair.low')}</span>
          {:else}
            <span class="text-xs text-muted-foreground">{t('ui.repair.healthy')}</span>
          {/if}
        </span>
      </div>
    {/each}
  </div>

  {#if diagnosis.wear}
    <section class="flex flex-col gap-1.5 border-t border-border pt-4">
      <h3 class="mb-1 text-sm font-semibold">{t('ui.repair.services')}</h3>
      {#each services as service (service.name)}
        {@const key = `service:${service.name}`}
        {@const added = app.inCart(key) !== undefined}
        <button
          type="button"
          class={[
            'flex h-11 items-center gap-3 rounded-lg border px-3 text-left transition-colors',
            added ? 'border-primary bg-primary text-primary-foreground' : 'border-border bg-card hover:bg-muted',
          ]}
          onclick={() =>
            added ? app.remove(key) : app.addNow({ label: service.label, detail: t('ui.repair.service_detail'), price: service.price, change: { kind: 'service', name: service.name } })}
        >
          <span class="flex-1 text-sm font-semibold">{service.label}</span>
          {#if added}
            <span class="text-xs">{t('ui.option.in_cart')}</span>
          {/if}
          <span class="text-sm font-semibold tabular-nums">{formatMoney(service.price)}</span>
        </button>
      {/each}
    </section>
  {:else}
    <p class="text-xs text-muted-foreground">{t('ui.repair.no_wear')}</p>
  {/if}
</div>
