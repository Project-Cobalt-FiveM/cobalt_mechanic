<script lang="ts">
  import Check from 'phosphor-svelte/lib/Check';
  import MagnifyingGlass from 'phosphor-svelte/lib/MagnifyingGlass';
  import SubHeader from '../components/SubHeader.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import { app } from '../lib/store.svelte';
  import { findColour, paintHex, paintName, swatchOf, tabLabels, type PaintSwatch } from '../lib/catalog';
  import { formatMoney, hexToRgb, rgbToHex } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Change, Finish, PaintSlot, PaintTab, Rgb, Session } from '../lib/types';

  type Target = 'paint:primary' | 'paint:secondary' | 'pearlescent' | 'wheelColour';
  type Tab = PaintTab | 'chameleon' | 'custom';
  type Props = { session: Session; target: Target };

  let { session, target }: Props = $props();

  const catalog = $derived(session.catalog);
  const prices = $derived(catalog.prices);
  const slot = $derived<PaintSlot | null>(target === 'paint:primary' ? 'primary' : target === 'paint:secondary' ? 'secondary' : null);
  const isBody = $derived(slot !== null);

  const titles: Record<Target, string> = {
    'paint:primary': 'ui.categories.primary',
    'paint:secondary': 'ui.categories.secondary',
    pearlescent: 'ui.categories.pearlescent',
    wheelColour: 'ui.categories.rim_colour',
  };

  const finishLabels: Record<Finish, string> = {
    normal: 'ui.paint.finish_normal',
    metallic: 'ui.paint.finish_metallic',
    pearl: 'ui.paint.finish_pearl',
    matte: 'ui.paint.finish_matte',
    metal: 'ui.paint.finish_metal',
    chrome: 'ui.paint.finish_chrome',
  };

  const installed = $derived.by((): number | Rgb => {
    const props = session.props;
    if (target === 'paint:primary') return props.color1;
    if (target === 'paint:secondary') return props.color2;
    if (target === 'pearlescent') return props.pearlescentColor;
    return props.wheelColor;
  });

  const selectedChange = $derived(app.itemFor(target)?.change);
  const selectedIndex = $derived(selectedChange && 'index' in selectedChange ? selectedChange.index : null);

  let tab = $state<Tab>('metallic');
  let search = $state('');
  let series = $state<string | null>(null);
  let hovered = $state<{ swatch: PaintSwatch; x: number; y: number } | null>(null);
  let customHex = $state('#5078D7');
  let finish = $state<Finish>('metallic');

  const finishes: Finish[] = ['normal', 'metallic', 'pearl', 'matte', 'metal', 'chrome'];

  const tabs = $derived.by(() => {
    const list: { id: Tab; label: string; count?: number }[] = (Object.keys(tabLabels) as PaintTab[]).map((id) => ({
      id,
      label: t(tabLabels[id]),
      count: catalog.colours.filter((colour) => colour.tab === id).length,
    }));
    if (isBody) {
      list.push({ id: 'chameleon', label: t('ui.paint.tab_chameleon'), count: catalog.chameleons.length });
      list.push({ id: 'custom', label: t('ui.paint.tab_custom') });
    }
    return list;
  });

  const seriesList = $derived([...new Set(catalog.chameleons.map((colour) => colour.series))]);

  type Section = { title: string | null; swatches: PaintSwatch[] };

  const sections = $derived.by((): Section[] => {
    const query = search.trim().toLowerCase();

    if (query) {
      const pool = [...catalog.colours, ...(isBody ? catalog.chameleons : [])];
      return [{ title: null, swatches: pool.filter((colour) => colour.name.toLowerCase().includes(query)).map(swatchOf) }];
    }

    if (tab === 'chameleon') {
      return [{ title: null, swatches: catalog.chameleons.filter((colour) => !series || colour.series === series).map(swatchOf) }];
    }

    if (tab === 'custom') return [];

    const inTab = catalog.colours.filter((colour) => colour.tab === tab);
    const groups = [...new Set(inTab.map((colour) => colour.group ?? null))];
    return groups.map((group) => ({ title: group, swatches: inTab.filter((colour) => (colour.group ?? null) === group).map(swatchOf) }));
  });

  function priceFor(index: number): number {
    if (target === 'pearlescent') return prices.pearlescent;
    if (target === 'wheelColour') return prices.wheelColour;
    return index > 160 ? prices.chameleon : prices.paint;
  }

  function changeFor(index: number): Change {
    if (slot) return { kind: 'paint', slot, index };
    if (target === 'pearlescent') return { kind: 'pearlescent', index };
    return { kind: 'wheelColour', index };
  }

  function labelFor(name: string): string {
    if (slot) return t(slot === 'primary' ? 'ui.paint.label_primary' : 'ui.paint.label_secondary', name);
    if (target === 'pearlescent') return t('ui.paint.label_pearlescent', name);
    return t('ui.paint.label_rims', name);
  }

  function pick(swatch: PaintSwatch) {
    app.select({
      label: labelFor(swatch.name),
      detail: t('ui.paint.detail', swatch.index, paintName(catalog, installed)),
      price: priceFor(swatch.index),
      change: changeFor(swatch.index),
    });
  }

  function pickCustom() {
    if (!slot) return;
    const rgb = hexToRgb(customHex);
    app.select({
      label: t(slot === 'primary' ? 'ui.paint.custom_primary' : 'ui.paint.custom_secondary', rgbToHex(rgb)),
      detail: t('ui.paint.finish_detail', t(finishLabels[finish])),
      price: prices.paintCustom,
      change: { kind: 'paintCustom', slot, rgb, finish },
    });
  }

  function hover(event: MouseEvent, swatch: PaintSwatch) {
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    hovered = { swatch, x: rect.left + rect.width / 2, y: rect.bottom + 6 };
  }

  const pendingSwatch = $derived.by(() => {
    const change = app.pending?.key === target ? app.pending.change : null;
    if (!change) return undefined;
    if (change.kind === 'paintCustom') return rgbToHex(change.rgb);
    if (!('index' in change)) return undefined;
    const colour = findColour(catalog, change.index);
    return colour ? (swatchOf(colour).gradient ?? swatchOf(colour).hex) : paintHex(catalog, change.index);
  });

  const description = $derived(
    isBody
      ? t('ui.paint.body_prices', formatMoney(prices.paint), formatMoney(prices.paintCustom), formatMoney(prices.chameleon))
      : t('ui.paint.shared_list', catalog.colours.length),
  );

  const headerPrice = $derived.by(() => {
    if (target === 'pearlescent') return prices.pearlescent;
    if (target === 'wheelColour') return prices.wheelColour;
    if (tab === 'chameleon') return prices.chameleon;
    if (tab === 'custom') return prices.paintCustom;
    return prices.paint;
  });
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader title={t(titles[target])} {description} price={headerPrice} onback={() => app.open(null)} />

  <label class="relative block">
    <span class="sr-only">{t('ui.paint.search_label')}</span>
    <MagnifyingGlass size={14} class="pointer-events-none absolute top-1/2 left-3 -translate-y-1/2 text-muted-foreground" />
    <input class="field pl-8" placeholder={t('ui.paint.search', isBody ? catalog.colours.length + catalog.chameleons.length : catalog.colours.length)} bind:value={search} />
  </label>

  {#if !search.trim()}
    <div class="flex flex-wrap gap-1.5">
      {#each tabs as entry (entry.id)}
        <button
          type="button"
          class={[
            'h-7 rounded-md px-2.5 text-xs font-medium transition-colors',
            tab === entry.id ? 'bg-primary text-primary-foreground' : 'bg-secondary text-foreground hover:bg-secondary-hover',
          ]}
          onclick={() => (tab = entry.id)}
        >
          {entry.label}
          {#if entry.count !== undefined}
            <span class={['ml-1 tabular-nums', tab === entry.id ? 'text-primary-foreground' : 'text-muted-foreground']}>{entry.count}</span>
          {/if}
        </button>
      {/each}
    </div>
  {/if}

  {#if tab === 'chameleon' && !search.trim()}
    <div class="flex flex-wrap gap-1.5">
      {#each [null, ...seriesList] as entry (entry ?? 'all')}
        <button
          type="button"
          class={[
            'h-6 rounded-sm px-2 text-xs transition-colors',
            series === entry ? 'bg-foreground text-background' : 'border border-border text-muted-foreground hover:text-foreground',
          ]}
          onclick={() => (series = entry)}
        >
          {entry ?? t('ui.paint.all_series')}
        </button>
      {/each}
    </div>
  {/if}

  <div class="-mr-2 min-h-0 flex-1 overflow-y-auto pr-2" onscroll={() => (hovered = null)}>
    {#if tab === 'custom' && !search.trim() && slot}
      <div class="flex flex-col gap-4">
        <div class="flex items-center gap-3">
          <input type="color" class="h-12 w-16 cursor-pointer rounded-md border border-input bg-transparent" bind:value={customHex} onchange={pickCustom} />
          <input class="field font-medium uppercase tabular-nums" maxlength="7" bind:value={customHex} onchange={pickCustom} />
        </div>
        <div>
          <p class="mb-2 text-xs font-medium text-muted-foreground">{t('ui.paint.finish')}</p>
          <div class="grid grid-cols-3 gap-1.5">
            {#each finishes as option (option)}
              <button
                type="button"
                class={[
                  'h-8 rounded-md text-xs font-medium transition-colors',
                  finish === option ? 'bg-primary text-primary-foreground' : 'bg-secondary hover:bg-secondary-hover',
                ]}
                onclick={() => {
                  finish = option;
                  pickCustom();
                }}
              >
                {t(finishLabels[option])}
              </button>
            {/each}
          </div>
        </div>
        <button type="button" class="h-9 rounded-md border border-input bg-secondary text-sm font-medium hover:bg-secondary-hover" onclick={pickCustom}>
          {t('ui.paint.preview_custom')}
        </button>
      </div>
    {:else}
      {#each sections as section, i (section.title ?? i)}
        <section class="mb-3">
          {#if section.title}
            <h4 class="mb-1.5 text-xs text-muted-foreground">{section.title}</h4>
          {/if}
          {#if section.swatches.length === 0}
            <p class="py-6 text-center text-sm text-muted-foreground">{t('ui.paint.no_match', search)}</p>
          {/if}
          <div class="grid grid-cols-11 gap-1.5">
            {#each section.swatches as swatch (swatch.index)}
              {@const isSelected = selectedIndex === swatch.index}
              {@const isInstalled = installed === swatch.index}
              <button
                type="button"
                class={[
                  'relative grid aspect-square place-items-center rounded-md border transition-transform duration-150 hover:scale-105',
                  isSelected ? 'border-foreground outline-2 outline-offset-1 outline-primary' : 'border-input',
                ]}
                style:background={swatch.gradient ?? swatch.hex}
                aria-label={t('ui.paint.swatch_aria', swatch.name, swatch.index)}
                onmouseenter={(event) => hover(event, swatch)}
                onmouseleave={() => (hovered = null)}
                onclick={() => pick(swatch)}
              >
                {#if isInstalled}
                  <span class="grid size-4 place-items-center rounded-full bg-foreground text-background">
                    <Check size={10} />
                  </span>
                {/if}
              </button>
            {/each}
          </div>
        </section>
      {/each}
      {#if isBody && tab !== 'chameleon'}
        <p class="text-xs text-muted-foreground">{t('ui.paint.same_list', catalog.colours.length)}</p>
      {/if}
    {/if}
  </div>

  <PreviewActions keys={[target]} swatch={pendingSwatch} />
</div>

{#if hovered}
  <div
    class="pointer-events-none fixed z-50 -translate-x-1/2 rounded-md border border-border bg-popover px-2.5 py-1.5 shadow-lg"
    style:left="{hovered.x}px"
    style:top="{hovered.y}px"
  >
    <p class="text-xs font-semibold whitespace-nowrap">{hovered.swatch.name}</p>
    <p class="text-xs text-muted-foreground tabular-nums">{t('ui.paint.index', hovered.swatch.index)}</p>
  </div>
{/if}
