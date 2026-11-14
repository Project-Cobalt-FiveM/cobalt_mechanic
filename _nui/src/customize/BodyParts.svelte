<script lang="ts">
  import Check from 'phosphor-svelte/lib/Check';
  import SubHeader from '../components/SubHeader.svelte';
  import OptionRow from '../components/OptionRow.svelte';
  import PreviewActions from '../components/PreviewActions.svelte';
  import { app } from '../lib/store.svelte';
  import { t } from '../lib/locale.svelte';
  import type { ModGroup, ModOption, Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const mods = $derived(session.options.mods);
  const groupNames: Record<ModGroup, string> = { exterior: 'ui.body.exterior', interior: 'ui.body.interior', engine: 'ui.body.engine' };
  const groups = $derived((Object.keys(groupNames) as ModGroup[]).filter((group) => mods.some((mod) => mod.group === group)));

  let slot = $state<number | null>(null);

  const active = $derived(mods.find((mod) => mod.slot === slot) ?? mods[0]);
  const installed = $derived(active ? (session.props.mods[active.slot] ?? -1) : -1);
  const selected = $derived.by(() => {
    if (!active) return null;
    const change = app.itemFor(`mod:${active.slot}`)?.change;
    return change?.kind === 'mod' ? change.index : null;
  });

  function priceOf(mod: ModOption, index: number): number {
    return mod.price.base + mod.price.step * Math.max(index, 0);
  }

  function pick(mod: ModOption, index: number) {
    const name = index < 0 ? t('ui.body.stock', mod.name.toLowerCase()) : (mod.options[index] ?? t('ui.body.option', index + 1));
    app.select({
      label: index < 0 ? name : t('ui.body.part', name, mod.name.toLowerCase()),
      detail: t('ui.body.previewing'),
      price: priceOf(mod, index),
      change: { kind: 'mod', slot: mod.slot, index },
    });
  }
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader
    title={t('ui.body.title')}
    description={active ? t('ui.body.description', active.name, active.options.length, session.vehicle.label.split(' ').at(-1) ?? '') : t('ui.body.none')}
    onback={() => app.open(null)}
  />

  {#each groups as group (group)}
    <div class="flex flex-col gap-1.5">
      {#if groups.length > 1}
        <p class="text-xs text-muted-foreground">{t(groupNames[group])}</p>
      {/if}
      <div class="flex flex-wrap gap-1.5">
        {#each mods.filter((mod) => mod.group === group) as mod (mod.slot)}
          {@const added = app.inCart(`mod:${mod.slot}`)}
          <button
            type="button"
            class={[
              'h-7 rounded-md px-2.5 text-xs font-medium transition-colors',
              active?.slot === mod.slot ? 'bg-primary text-primary-foreground' : 'bg-secondary hover:bg-secondary-hover',
            ]}
            onclick={() => {
              if (app.pending?.key.startsWith('mod:')) app.undo();
              slot = mod.slot;
            }}
          >
            {mod.name}
            {#if added}
              <Check size={10} class="ml-0.5 inline" />
            {/if}
          </button>
        {/each}
      </div>
    </div>
  {/each}

  {#if active}
    <div class="-mr-2 flex min-h-0 flex-1 flex-col gap-1.5 overflow-y-auto pr-2">
      <OptionRow
        title={t('ui.body.stock', active.name.toLowerCase())}
        subtitle={t('ui.body.factory')}
        price={priceOf(active, -1)}
        installed={installed < 0}
        selected={selected === -1}
        onclick={() => pick(active, -1)}
      />
      {#each active.options as name, index (index)}
        <OptionRow
          title={name}
          subtitle={selected === index && app.pending ? t('ui.body.previewing') : undefined}
          price={priceOf(active, index)}
          installed={installed === index}
          selected={selected === index}
          inCart={selected === index && app.pending?.key !== `mod:${active.slot}`}
          onclick={() => pick(active, index)}
        />
      {/each}
    </div>
    <PreviewActions keys={[`mod:${active.slot}`]} compact />
  {/if}
</div>
