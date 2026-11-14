<script lang="ts">
  import SubHeader from '../components/SubHeader.svelte';
  import OptionRow from '../components/OptionRow.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import { app } from '../lib/store.svelte';
  import { t } from '../lib/locale.svelte';
  import type { Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const tints = $derived(session.catalog.tints);
  const price = $derived(session.catalog.prices.tint);
  const selected = $derived.by(() => {
    const change = app.itemFor('tint')?.change;
    return change?.kind === 'tint' ? change.index : null;
  });
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader title={t('ui.categories.tint')} description={t('ui.tint.description', tints.length)} {price} onback={() => app.open(null)} />

  <div class="flex flex-col gap-1.5">
    {#each tints as tint (tint.level)}
      <div class="flex items-center gap-3">
        <span class="size-10 shrink-0 rounded-md border border-input" style:background={tint.hex}></span>
        <div class="flex-1">
          <OptionRow
            title={tint.name}
            {price}
            installed={session.props.windowTint === tint.level}
            selected={selected === tint.level}
            onclick={() => app.select({ label: t('ui.tint.label', tint.name), detail: t('ui.categories.tint'), price, change: { kind: 'tint', index: tint.level } })}
          />
        </div>
      </div>
    {/each}
  </div>

  <PreviewActions keys={['tint']} />
</div>
