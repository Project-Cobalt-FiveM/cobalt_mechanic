<script lang="ts">
  import CaretRight from 'phosphor-svelte/lib/CaretRight';
  import SubHeader from '../components/SubHeader.svelte';
  import OptionRow from '../components/OptionRow.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import { app } from '../lib/store.svelte';
  import { paintHex, paintName } from '../lib/catalog';
  import { t } from '../lib/locale.svelte';
  import type { Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const fitted = $derived(session.props);
  const wheels = $derived(session.options.wheels);
  const price = $derived(session.catalog.prices.wheels);
  const selected = $derived.by(() => {
    const change = app.itemFor('wheels')?.change;
    return change?.kind === 'wheels' ? change : null;
  });

  let type = $state<number | null>(null);
  let custom = $state<boolean | null>(null);

  const activeType = $derived(type ?? selected?.type ?? (wheels.some((wheel) => wheel.type === fitted.wheels) ? fitted.wheels : (wheels[0]?.type ?? 0)));
  const activeCustom = $derived(custom ?? selected?.custom ?? fitted.modCustomTiresF);
  const current = $derived(wheels.find((wheel) => wheel.type === activeType));

  function choose(wheelType: number, index: number, customTyres: boolean) {
    const wheel = wheels.find((entry) => entry.type === wheelType);
    if (!wheel) return;
    const label = index < 0 ? t('ui.rims.stock') : t('ui.rims.label', wheel.options[index] ?? t('ui.rims.style', index + 1));
    const detail = index < 0 ? t('ui.rims.factory_wheels') : customTyres ? t('ui.rims.custom_detail', wheel.name) : wheel.name;
    app.select({ label, detail, price, change: { kind: 'wheels', type: wheelType, index, custom: customTyres } });
  }

  function pick(index: number) {
    choose(activeType, index, activeCustom);
  }

  function toggleCustom() {
    const next = !activeCustom;
    custom = next;

    if (selected) {
      choose(selected.type, selected.index, next);
      return;
    }

    if (next === fitted.modCustomTiresF) {
      app.undo();
      return;
    }

    choose(fitted.wheels, fitted.modFrontWheels, next);
  }

  const rimColour = $derived(app.itemFor('wheelColour')?.label ?? paintName(session.catalog, fitted.wheelColor));
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader title={t('ui.categories.rims')} description={t('ui.rims.description', wheels.length)} {price} onback={() => app.open(null)} />

  <div class="flex flex-wrap gap-1.5">
    {#each wheels as wheel (wheel.type)}
      <button
        type="button"
        class={[
          'h-7 rounded-md px-2.5 text-xs font-medium transition-colors',
          activeType === wheel.type ? 'bg-primary text-primary-foreground' : 'bg-secondary hover:bg-secondary-hover',
        ]}
        onclick={() => (type = wheel.type)}
      >
        {wheel.name}
      </button>
    {/each}
  </div>

  <div class="-mr-2 flex min-h-0 flex-1 flex-col gap-1.5 overflow-y-auto pr-2">
    <OptionRow
      title={t('ui.rims.stock')}
      subtitle={t('ui.body.factory')}
      price={price}
      installed={fitted.modFrontWheels < 0}
      selected={selected?.index === -1}
      inCart={selected?.index === -1 && app.pending?.key !== 'wheels'}
      onclick={() => pick(-1)}
    />
    {#each current?.options ?? [] as name, index (index)}
      {@const isSelected = selected?.type === activeType && selected?.index === index}
      <OptionRow
        title={name}
        subtitle={current?.name}
        {price}
        installed={fitted.wheels === activeType && fitted.modFrontWheels === index}
        selected={isSelected}
        inCart={isSelected && app.pending?.key !== 'wheels'}
        onclick={() => pick(index)}
      />
    {/each}
  </div>

  <div class="flex flex-col gap-1 border-t border-border pt-3">
    <label class="flex h-10 items-center justify-between gap-3">
      <span class="text-sm font-medium">{t('ui.rims.custom_tyres')}</span>
      <button
        type="button"
        role="switch"
        aria-checked={activeCustom}
        aria-label={t('ui.rims.custom_tyres')}
        class={['relative h-5 w-9 rounded-full transition-colors', activeCustom ? 'bg-primary' : 'bg-secondary']}
        onclick={toggleCustom}
      >
        <span class={['absolute top-0.5 left-0.5 size-4 rounded-full bg-foreground transition-transform duration-150', activeCustom && 'translate-x-4']}></span>
      </button>
    </label>
    <button type="button" class="-mx-2 flex h-10 items-center gap-3 rounded-md px-2 hover:bg-muted" onclick={() => app.open('rimColour')}>
      <span class="flex-1 text-left text-sm font-medium">{t('ui.categories.rim_colour')}</span>
      <span class="size-3.5 rounded-sm border border-input" style:background={paintHex(session.catalog, fitted.wheelColor)}></span>
      <span class="text-sm text-muted-foreground">{rimColour}</span>
      <CaretRight size={12} class="text-muted-foreground" />
    </button>
  </div>

  <PreviewActions keys={['wheels']} />
</div>
