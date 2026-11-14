<script lang="ts">
  import type { Component } from 'svelte';
  import CaretRight from 'phosphor-svelte/lib/CaretRight';
  import PaintBucket from 'phosphor-svelte/lib/PaintBucket';
  import PaintBrush from 'phosphor-svelte/lib/PaintBrush';
  import Sparkle from 'phosphor-svelte/lib/Sparkle';
  import Tire from 'phosphor-svelte/lib/Tire';
  import CircleHalf from 'phosphor-svelte/lib/CircleHalf';
  import Wind from 'phosphor-svelte/lib/Wind';
  import CarProfile from 'phosphor-svelte/lib/CarProfile';
  import Swatches from 'phosphor-svelte/lib/Swatches';
  import SquaresFour from 'phosphor-svelte/lib/SquaresFour';
  import Eye from 'phosphor-svelte/lib/Eye';
  import Lightbulb from 'phosphor-svelte/lib/Lightbulb';
  import Headlights from 'phosphor-svelte/lib/Headlights';
  import IdentificationCard from 'phosphor-svelte/lib/IdentificationCard';
  import { app, type CustomizeView } from '../lib/store.svelte';
  import { paintHex, paintName } from '../lib/catalog';
  import { rgbToHex } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  type Row = { view: CustomizeView; label: string; icon: Component; value: string; swatch?: string; keys: string[] };
  type Group = { title: string; rows: Row[] };

  const catalog = $derived(session.catalog);
  const fitted = $derived(session.props);
  const options = $derived(session.options);

  function count(keys: string[]): number {
    return app.cart.filter((item) => keys.some((key) => item.key === key || (key.endsWith(':') && item.key.startsWith(key)))).length;
  }

  function current(key: string, fallback: string): string {
    return app.itemFor(key)?.label ?? fallback;
  }

  function paintSwatch(key: string, fallback: string): string {
    const change = app.itemFor(key)?.change;
    if (!change) return fallback;
    if (change.kind === 'paint' || change.kind === 'pearlescent' || change.kind === 'wheelColour') return paintHex(catalog, change.index);
    if (change.kind === 'paintCustom' || change.kind === 'tyreSmoke') return rgbToHex(change.rgb);
    return fallback;
  }

  const wheelName = $derived.by(() => {
    if (fitted.modFrontWheels < 0) return t('ui.categories.stock');
    const type = options.wheels.find((wheel) => wheel.type === fitted.wheels);
    const name = type?.options[fitted.modFrontWheels] ?? t('ui.rims.style', fitted.modFrontWheels + 1);
    return type ? t('ui.categories.wheel_value', name, type.name.toLowerCase()) : name;
  });

  const fittedMods = $derived(options.mods.filter((mod) => (fitted.mods[mod.slot] ?? -1) >= 0).length);
  const liveryIndex = $derived(options.liveries.legacy ? fitted.livery : fitted.modLivery);
  const enabledExtras = $derived(options.extras.filter((id) => fitted.extras[id] === 0).length);
  const tintName = $derived(catalog.tints.find((tint) => tint.level === fitted.windowTint)?.name ?? t('ui.categories.none'));
  const tintHex = $derived(catalog.tints.find((tint) => tint.level === fitted.windowTint)?.hex ?? '#E5E5E5');
  const neonOn = $derived(fitted.neonEnabled.some(Boolean));
  const xenonName = $derived(fitted.modXenon ? (catalog.xenons.find((xenon) => xenon.index === fitted.xenonColor)?.name ?? t('ui.categories.xenon')) : t('ui.categories.halogen'));
  const plateName = $derived(catalog.plates.find((plate) => plate.index === fitted.plateIndex)?.name ?? catalog.plates[0]?.name ?? '');

  const groups: Group[] = $derived([
    {
      title: 'ui.categories.paint',
      rows: [
        { view: 'paint:primary', label: 'ui.categories.primary', icon: PaintBucket, keys: ['paint:primary'], value: current('paint:primary', paintName(catalog, fitted.color1)), swatch: paintSwatch('paint:primary', paintHex(catalog, fitted.color1)) },
        { view: 'paint:secondary', label: 'ui.categories.secondary', icon: PaintBrush, keys: ['paint:secondary'], value: current('paint:secondary', paintName(catalog, fitted.color2)), swatch: paintSwatch('paint:secondary', paintHex(catalog, fitted.color2)) },
        { view: 'pearlescent', label: 'ui.categories.pearlescent', icon: Sparkle, keys: ['pearlescent'], value: current('pearlescent', fitted.pearlescentColor > 0 ? paintName(catalog, fitted.pearlescentColor) : t('ui.categories.none')), swatch: fitted.pearlescentColor > 0 || app.itemFor('pearlescent') ? paintSwatch('pearlescent', paintHex(catalog, fitted.pearlescentColor)) : undefined },
      ],
    },
    {
      title: 'ui.categories.wheels',
      rows: [
        { view: 'rims', label: 'ui.categories.rims', icon: Tire, keys: ['wheels'], value: current('wheels', wheelName) },
        { view: 'rimColour', label: 'ui.categories.rim_colour', icon: CircleHalf, keys: ['wheelColour'], value: current('wheelColour', paintName(catalog, fitted.wheelColor)), swatch: paintSwatch('wheelColour', paintHex(catalog, fitted.wheelColor)) },
        { view: 'tyreSmoke', label: 'ui.categories.tyre_smoke', icon: Wind, keys: ['tyreSmoke'], value: current('tyreSmoke', fitted.modSmokeEnabled ? rgbToHex(fitted.tyreSmokeColor) : t('ui.categories.off')), swatch: fitted.modSmokeEnabled || app.itemFor('tyreSmoke') ? paintSwatch('tyreSmoke', rgbToHex(fitted.tyreSmokeColor)) : undefined },
      ],
    },
    {
      title: 'ui.categories.body',
      rows: [
        { view: 'body', label: 'ui.categories.body_parts', icon: CarProfile, keys: ['mod:'], value: options.mods.length === 0 ? t('ui.categories.none_on_model') : t('ui.categories.slots', options.mods.length, fittedMods) },
        { view: 'livery', label: 'ui.categories.livery', icon: Swatches, keys: ['livery'], value: current('livery', options.liveries.options.length === 0 ? t('ui.categories.none_on_model') : liveryIndex < 0 ? t('ui.categories.none_of', options.liveries.options.length) : (options.liveries.options[liveryIndex] ?? t('ui.livery.numbered', liveryIndex + 1))) },
        { view: 'extras', label: 'ui.categories.extras', icon: SquaresFour, keys: ['extra:'], value: options.extras.length === 0 ? t('ui.categories.none_on_model') : t('ui.categories.extras_on', enabledExtras, options.extras.length) },
      ],
    },
    {
      title: 'ui.categories.lights',
      rows: [
        { view: 'tint', label: 'ui.categories.tint', icon: Eye, keys: ['tint'], value: current('tint', tintName), swatch: tintHex },
        { view: 'neon', label: 'ui.categories.neon', icon: Lightbulb, keys: ['neon'], value: current('neon', neonOn ? t('ui.categories.on') : t('ui.categories.off')) },
        { view: 'headlights', label: 'ui.categories.headlights', icon: Headlights, keys: ['xenon'], value: current('xenon', xenonName) },
        { view: 'plate', label: 'ui.categories.plate', icon: IdentificationCard, keys: ['plate'], value: current('plate', plateName) },
      ],
    },
  ]);
</script>

<div class="flex flex-col gap-5">
  {#each groups as group (group.title)}
    <section class="flex flex-col">
      <h3 class="mb-1 text-xs font-medium text-muted-foreground">{t(group.title)}</h3>
      {#each group.rows as row (row.view)}
        {@const added = count(row.keys)}
        <button
          type="button"
          class="group -mx-2 flex h-11 items-center gap-3 rounded-md px-2 text-left transition-colors hover:bg-muted"
          onclick={() => app.open(row.view)}
        >
          <row.icon size={18} class="shrink-0 text-muted-foreground group-hover:text-foreground" />
          <span class="w-36 shrink-0 text-sm font-semibold">{t(row.label)}</span>
          <span class="flex size-3.5 shrink-0 items-center">
            {#if row.swatch}
              <span class="size-3.5 rounded-sm border border-input" style:background={row.swatch}></span>
            {/if}
          </span>
          <span class="min-w-0 flex-1 truncate text-sm text-muted-foreground">{row.value}</span>
          <span class="flex w-5 shrink-0 justify-center">
            {#if added > 0}
              <span class="rounded-sm bg-secondary px-1.5 text-xs font-semibold tabular-nums">{added}</span>
            {/if}
          </span>
          <CaretRight size={12} class="shrink-0 text-muted-foreground" />
        </button>
      {/each}
    </section>
  {/each}
</div>
