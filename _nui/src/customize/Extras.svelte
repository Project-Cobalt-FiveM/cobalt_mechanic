<script lang="ts">
  import SubHeader from '../components/SubHeader.svelte';
  import { formatMoney } from '../lib/format';
  import { app } from '../lib/store.svelte';
  import { t } from '../lib/locale.svelte';
  import type { Session } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const extras = $derived(session.options.extras);
  const price = $derived(session.catalog.prices.extra);

  function isOn(id: number): boolean {
    const change = app.itemFor(`extra:${id}`)?.change;
    if (change?.kind === 'extra') return change.enabled;
    return session.props.extras[id] === 0;
  }

  function toggle(id: number) {
    const key = `extra:${id}`;
    const installedOn = session.props.extras[id] === 0;
    const next = !isOn(id);

    if (next === installedOn) {
      app.remove(key);
      return;
    }

    app.addNow({ label: t(next ? 'ui.extras.on' : 'ui.extras.off', id), detail: t('ui.extras.detail'), price, change: { kind: 'extra', id, enabled: next } });
  }
</script>

<div class="flex min-h-0 flex-1 flex-col gap-4">
  <SubHeader title={t('ui.extras.title')} description={t('ui.extras.description', formatMoney(price))} onback={() => app.open(null)} />

  {#if extras.length === 0}
    <p class="py-8 text-center text-sm text-muted-foreground">{t('ui.extras.none')}</p>
  {:else}
    <div class="flex flex-col gap-1.5">
      {#each extras as id (id)}
        {@const on = isOn(id)}
        <div class="flex h-12 items-center justify-between rounded-lg border border-border bg-card px-3">
          <span class="text-sm font-medium">{t('ui.extras.name', id)}</span>
          <button
            type="button"
            role="switch"
            aria-checked={on}
            aria-label={t('ui.extras.name', id)}
            class={['relative h-5 w-9 rounded-full transition-colors', on ? 'bg-primary' : 'bg-secondary']}
            onclick={() => toggle(id)}
          >
            <span class={['absolute top-0.5 left-0.5 size-4 rounded-full bg-foreground transition-transform duration-150', on && 'translate-x-4']}></span>
          </button>
        </div>
      {/each}
    </div>
  {/if}
</div>
