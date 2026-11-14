<script lang="ts">
  import SubHeader from '../components/SubHeader.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import { app } from '../lib/store.svelte';
  import { hexToRgb, rgbToHex } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Rgb, Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const price = $derived(session.catalog.prices.tyreSmoke);
  const presets: { name: string; rgb: Rgb }[] = [
    { name: 'ui.smoke.white', rgb: [255, 255, 255] },
    { name: 'ui.smoke.black', rgb: [20, 20, 20] },
    { name: 'ui.smoke.blue', rgb: [0, 174, 239] },
    { name: 'ui.smoke.yellow', rgb: [252, 238, 0] },
    { name: 'ui.smoke.purple', rgb: [132, 102, 226] },
    { name: 'ui.smoke.orange', rgb: [255, 127, 0] },
    { name: 'ui.smoke.green', rgb: [114, 204, 114] },
    { name: 'ui.smoke.red', rgb: [226, 6, 6] },
    { name: 'ui.smoke.pink', rgb: [203, 54, 148] },
    { name: 'ui.smoke.brown', rgb: [180, 130, 97] },
  ];

  let hex = $state('#FFFFFF');

  $effect.pre(() => {
    hex = rgbToHex(session.props.tyreSmokeColor);
  });

  function pick(rgb: Rgb, name?: string) {
    hex = rgbToHex(rgb);
    app.select({ label: t('ui.smoke.label', name ?? hex), detail: t('ui.smoke.detail'), price, change: { kind: 'tyreSmoke', rgb } });
  }
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader title={t('ui.categories.tyre_smoke')} description={t('ui.smoke.description')} {price} onback={() => app.open(null)} />

  <div class="grid grid-cols-5 gap-2">
    {#each presets as preset (preset.name)}
      <button type="button" class="flex flex-col items-center gap-1.5 rounded-md p-2 hover:bg-muted" onclick={() => pick(preset.rgb, t(preset.name))}>
        <span class="size-9 rounded-md border border-input" style:background={rgbToHex(preset.rgb)}></span>
        <span class="text-xs text-muted-foreground">{t(preset.name)}</span>
      </button>
    {/each}
  </div>

  <div class="flex items-center gap-3">
    <input type="color" class="h-10 w-14 cursor-pointer rounded-md border border-input bg-transparent" bind:value={hex} onchange={() => pick(hexToRgb(hex))} />
    <input class="field font-medium uppercase tabular-nums" maxlength="7" bind:value={hex} onchange={() => pick(hexToRgb(hex))} />
  </div>

  <PreviewActions keys={['tyreSmoke']} swatch={hex} />
</div>
