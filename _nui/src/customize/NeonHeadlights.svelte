<script lang="ts">
  import Info from 'phosphor-svelte/lib/Info';
  import SubHeader from '../components/SubHeader.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import { app } from '../lib/store.svelte';
  import { formatMoney, rgbToHex } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Session } from '../lib/types';

  type Props = { session: Session };
  type Strips = [boolean, boolean, boolean, boolean];

  let { session }: Props = $props();

  const neons = $derived(session.catalog.neons);
  const xenons = $derived(session.catalog.xenons);
  const prices = $derived(session.catalog.prices);
  const fitted = $derived(session.props);
  const strips = ['ui.neon.left', 'ui.neon.right', 'ui.neon.front', 'ui.neon.back'] as const;

  const neonChange = $derived.by(() => {
    const change = app.itemFor('neon')?.change;
    return change?.kind === 'neon' ? change : null;
  });

  const xenonChange = $derived.by(() => {
    const change = app.itemFor('xenon')?.change;
    return change?.kind === 'xenon' ? change : null;
  });

  const installedColour = $derived.by(() => {
    const [r, g, b] = fitted.neonColor;
    const index = neons.findIndex(({ rgb }) => rgb[0] === r && rgb[1] === g && rgb[2] === b);
    return index === -1 ? 1 : index + 1;
  });

  const enabled = $derived<Strips>(neonChange?.enabled ?? fitted.neonEnabled);
  const colour = $derived(neonChange?.colour ?? installedColour);
  const xenonOn = $derived(xenonChange ? xenonChange.enabled : fitted.modXenon);
  const xenonColour = $derived(xenonChange?.enabled ? xenonChange.colour : fitted.xenonColor);

  function applyNeon(next: Strips, nextColour: number) {
    const on = next.filter(Boolean).length;
    const name = neons[nextColour - 1]?.name ?? t('ui.neon.fallback');

    app.select({
      label: on === 0 ? t('ui.neon.off') : t('ui.neon.label', name),
      detail: on === 0 ? t('ui.neon.all_off') : t('ui.neon.strips_on', on),
      price: prices.neon,
      change: { kind: 'neon', enabled: next, colour: nextColour },
    });
  }

  function toggleStrip(index: number) {
    const next: Strips = [...enabled];
    next[index] = !next[index];
    applyNeon(next, colour);
  }

  function pickNeon(index: number) {
    const next: Strips = enabled.some(Boolean) ? [...enabled] : [true, true, true, true];
    applyNeon(next, index);
  }

  function pickXenon(index: number) {
    const name = xenons.find((xenon) => xenon.index === index)?.name ?? t('ui.xenon.fallback');
    app.select({
      label: t('ui.xenon.label', name),
      detail: t('ui.xenon.detail'),
      price: prices.xenon,
      change: { kind: 'xenon', enabled: true, colour: index },
    });
  }

  function toggleXenons() {
    if (!xenonOn) return pickXenon(xenonColour >= 0 && xenonColour <= 12 ? xenonColour : 255);

    app.select({
      label: t('ui.xenon.halogen'),
      detail: t('ui.xenon.stock'),
      price: prices.xenon,
      change: { kind: 'xenon', enabled: false, colour: 255 },
    });
  }
</script>

<div class="flex min-h-0 flex-1 flex-col gap-5">
  <SubHeader
    title={t('ui.neon.title')}
    description={t('ui.neon.description', formatMoney(prices.neon), formatMoney(prices.xenon))}
    onback={() => app.open(null)}
  />

  <section class="flex flex-col gap-3">
    <h3 class="text-sm font-semibold">{t('ui.neon.strips')}</h3>
    <div class="grid grid-cols-4 gap-1.5">
      {#each strips as strip, index (strip)}
        <button
          type="button"
          aria-pressed={enabled[index]}
          class={['h-9 rounded-md text-sm font-medium transition-colors', enabled[index] ? 'bg-primary text-primary-foreground' : 'bg-secondary text-muted-foreground hover:bg-secondary-hover']}
          onclick={() => toggleStrip(index)}
        >
          {t(strip)}
        </button>
      {/each}
    </div>

    <div class="grid grid-cols-6 gap-x-2 gap-y-3">
      {#each neons as neon, i (neon.name)}
        {@const selected = colour === i + 1}
        <button type="button" class="flex flex-col items-center gap-1.5" aria-pressed={selected} onclick={() => pickNeon(i + 1)}>
          <span
            class={['h-9 w-full rounded-md border-2 transition-colors', selected ? 'border-primary' : 'border-transparent']}
            style:background={rgbToHex(neon.rgb)}
          ></span>
          <span class={['truncate text-xs', selected ? 'font-semibold text-foreground' : 'text-muted-foreground']}>{neon.name}</span>
        </button>
      {/each}
    </div>
  </section>

  <section class="flex flex-col gap-3 border-t border-border pt-4">
    <div class="flex items-center justify-between gap-3">
      <h3 class="text-sm font-semibold">{t('ui.xenon.title')}</h3>
      <label class="flex items-center gap-2 text-xs text-muted-foreground">
        {t('ui.xenon.fit')}
        <button
          type="button"
          role="switch"
          aria-checked={xenonOn}
          aria-label={t('ui.xenon.fit')}
          class={['relative h-5 w-9 rounded-full transition-colors', xenonOn ? 'bg-primary' : 'bg-secondary']}
          onclick={toggleXenons}
        >
          <span class={['absolute top-0.5 left-0.5 size-4 rounded-full bg-foreground transition-transform duration-150', xenonOn && 'translate-x-4']}></span>
        </button>
      </label>
    </div>

    {#if !xenonOn}
      <p class="flex items-start gap-2.5 rounded-md border border-border px-3 py-2.5 text-xs text-muted-foreground">
        <Info size={14} class="mt-px shrink-0 text-cobalt-foreground" />
        {t('ui.xenon.halogen_note', xenons.length)}
      </p>
    {/if}

    <div class="flex flex-wrap gap-1.5">
      {#each xenons as xenon (xenon.index)}
        {@const selected = xenonOn && xenonColour === xenon.index}
        <button
          type="button"
          aria-label={t('ui.xenon.label', xenon.name)}
          title={xenon.name}
          aria-pressed={selected}
          class={['size-6 rounded-sm border-2 transition-colors', selected ? 'border-primary' : 'border-transparent']}
          style:background={xenon.hex}
          onclick={() => pickXenon(xenon.index)}
        ></button>
      {/each}
    </div>
  </section>

  <PreviewActions keys={['neon', 'xenon']} compact />
</div>
