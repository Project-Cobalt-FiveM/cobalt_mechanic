<script lang="ts">
  import CheckCircle from 'phosphor-svelte/lib/CheckCircle';
  import SubHeader from '../components/SubHeader.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import Plate from '../components/Plate.svelte';
  import { app } from '../lib/store.svelte';
  import { t } from '../lib/locale.svelte';
  import type { Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const plates = $derived(session.catalog.plates);
  const price = $derived(session.catalog.prices.plate);
  const selected = $derived.by(() => {
    const change = app.itemFor('plate')?.change;
    return change?.kind === 'plate' ? change.index : null;
  });
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader title={t('ui.categories.plate')} description={t('ui.plates.description', plates.length)} {price} onback={() => app.open(null)} />

  <div class="-mr-2 grid min-h-0 flex-1 grid-cols-2 content-start gap-3 overflow-y-auto pr-2">
    {#each plates as plate (plate.index)}
      {@const active = selected === plate.index}
      <button
        type="button"
        class={['flex flex-col gap-1.5 rounded-lg border p-2 text-left transition-colors', active ? 'border-primary bg-muted' : 'border-border hover:bg-muted']}
        onclick={() => app.select({ label: t('ui.plates.label', plate.name), detail: t('ui.categories.plate'), price, change: { kind: 'plate', index: plate.index } })}
      >
        <Plate index={plate.index} text={session.vehicle.plate} />
        <span class="flex items-center gap-1.5 text-xs text-muted-foreground">
          {#if session.props.plateIndex === plate.index}
            <CheckCircle size={12} class="text-success" />
          {/if}
          <span class={active ? 'text-foreground' : ''}>{plate.name}</span>
        </span>
      </button>
    {/each}
  </div>

  <PreviewActions keys={['plate']} />
</div>
