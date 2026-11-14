<script lang="ts">
  import SubHeader from '../components/SubHeader.svelte';
  import OptionRow from '../components/OptionRow.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import { app } from '../lib/store.svelte';
  import { t } from '../lib/locale.svelte';
  import type { Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const liveries = $derived(session.options.liveries);
  const price = $derived(session.catalog.prices.livery);
  const installed = $derived(liveries.legacy ? session.props.livery : session.props.modLivery);
  const selected = $derived.by(() => {
    const change = app.itemFor('livery')?.change;
    return change?.kind === 'livery' ? change.index : null;
  });

  function pick(index: number) {
    const name = index < 0 ? t('ui.livery.none') : (liveries.options[index] ?? t('ui.livery.numbered', index + 1));
    app.select({ label: name, detail: t('ui.livery.title'), price, change: { kind: 'livery', index, legacy: liveries.legacy } });
  }
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader title={t('ui.livery.title')} description={t('ui.livery.description', liveries.options.length)} {price} onback={() => app.open(null)} />

  {#if liveries.options.length === 0}
    <p class="py-8 text-center text-sm text-muted-foreground">{t('ui.livery.empty')}</p>
  {:else}
    <div class="-mr-2 flex min-h-0 flex-1 flex-col gap-1.5 overflow-y-auto pr-2">
      {#if !liveries.legacy}
        <OptionRow title={t('ui.livery.none')} {price} installed={installed < 0} selected={selected === -1} onclick={() => pick(-1)} />
      {/if}
      {#each liveries.options as name, index (index)}
        <OptionRow title={name} {price} installed={installed === index} selected={selected === index} onclick={() => pick(index)} />
      {/each}
    </div>
  {/if}

  <PreviewActions keys={['livery']} />
</div>
