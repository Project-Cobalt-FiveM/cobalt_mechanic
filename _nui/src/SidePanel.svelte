<script lang="ts">
  import Wrench from 'phosphor-svelte/lib/Wrench';
  import { app, type Tab } from './lib/store.svelte';
  import { crossfade } from './lib/motion';
  import { t } from './lib/locale.svelte';
  import type { Session } from './lib/types';
  import Categories from './customize/Categories.svelte';
  import PaintPicker from './customize/PaintPicker.svelte';
  import Rims from './customize/Rims.svelte';
  import TyreSmoke from './customize/TyreSmoke.svelte';
  import BodyParts from './customize/BodyParts.svelte';
  import Livery from './customize/Livery.svelte';
  import Extras from './customize/Extras.svelte';
  import Tint from './customize/Tint.svelte';
  import NeonHeadlights from './customize/NeonHeadlights.svelte';
  import Plates from './customize/Plates.svelte';
  import Upgrades from './upgrades/Upgrades.svelte';
  import Repair from './repair/Repair.svelte';
  import FittingPanel from './FittingPanel.svelte';

  type Props = { session: Session };

  let { session }: Props = $props();

  const tabs: { id: Tab; label: string }[] = [
    { id: 'customize', label: 'ui.tabs.customize' },
    { id: 'upgrades', label: 'ui.tabs.upgrades' },
    { id: 'repair', label: 'ui.tabs.repair' },
  ];

  const screen = $derived(app.tab === 'customize' ? (app.view ?? 'categories') : app.tab);
</script>

<aside class="flex h-full w-[28.75rem] flex-col rounded-lg border border-border bg-card">
  <header class="flex items-start gap-3 px-5 pt-5">
    <span class="grid size-10 shrink-0 place-items-center rounded-md border border-border bg-secondary">
      <Wrench size={18} />
    </span>
    <div class="min-w-0 flex-1">
      <h1 class="truncate text-xl font-semibold tracking-tight">{session.vehicle.label}</h1>
      <p class="truncate text-sm text-muted-foreground">
        {t('ui.panel.plate')} <span class="font-semibold text-foreground tabular-nums">{session.vehicle.plate}</span>{session.vehicle.owner ? t('ui.panel.owner', session.vehicle.owner) : ''}
      </p>
    </div>
    {#if !app.fitting}
      <button type="button" class="flex items-center gap-2 text-xs text-muted-foreground hover:text-foreground" onclick={() => app.escape()}>
        <span class="kbd">{t('ui.panel.esc')}</span>
        {app.view ? t('ui.panel.back') : t('ui.panel.close')}
      </button>
    {/if}
  </header>

  {#if app.fitting}
    <div class="flex min-h-0 flex-1 flex-col overflow-y-auto px-5 pt-6 pb-5" in:crossfade>
      <FittingPanel fitting={app.fitting} />
    </div>
  {:else}
    <div class="mx-5 mt-4 grid grid-cols-3 gap-1 rounded-md border border-border bg-background p-1" role="tablist">
      {#each tabs as tab (tab.id)}
        <button
          type="button"
          role="tab"
          aria-selected={app.tab === tab.id}
          class={['h-8 rounded-sm text-sm font-medium transition-colors', app.tab === tab.id ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground']}
          onclick={() => app.setTab(tab.id)}
        >
          {t(tab.label)}
        </button>
      {/each}
    </div>

    <div class="flex min-h-0 flex-1 flex-col overflow-y-auto px-5 pt-5 pb-5">
      {#key screen}
        <div class="flex min-h-0 flex-1 flex-col" in:crossfade>
          {#if screen === 'categories'}
            <Categories {session} />
          {:else if screen === 'paint:primary' || screen === 'paint:secondary' || screen === 'pearlescent'}
            <PaintPicker {session} target={screen} />
          {:else if screen === 'rimColour'}
            <PaintPicker {session} target="wheelColour" />
          {:else if screen === 'rims'}
            <Rims {session} />
          {:else if screen === 'tyreSmoke'}
            <TyreSmoke {session} />
          {:else if screen === 'body'}
            <BodyParts {session} />
          {:else if screen === 'livery'}
            <Livery {session} />
          {:else if screen === 'extras'}
            <Extras {session} />
          {:else if screen === 'tint'}
            <Tint {session} />
          {:else if screen === 'neon' || screen === 'headlights'}
            <NeonHeadlights {session} />
          {:else if screen === 'plate'}
            <Plates {session} />
          {:else if screen === 'upgrades'}
            <Upgrades {session} />
          {:else}
            <Repair {session} />
          {/if}
        </div>
      {/key}
    </div>
  {/if}
</aside>
