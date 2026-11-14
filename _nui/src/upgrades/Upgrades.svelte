<script lang="ts">
  import CheckCircle from 'phosphor-svelte/lib/CheckCircle';
  import Lock from 'phosphor-svelte/lib/Lock';
  import { app } from '../lib/store.svelte';
  import { formatMoney } from '../lib/format';
  import { t } from '../lib/locale.svelte';
  import type { Session, UpgradeLevel, UpgradeName, UpgradeOption } from '../lib/types';

  type Props = { session: Session };

  let { session }: Props = $props();

  const upgrades = $derived(session.options.upgrades);
  const employee = $derived(session.mode === 'employee');
  const grade = $derived(session.me.grade);

  let chosen = $state<UpgradeName | null>(null);

  const active = $derived(upgrades.find((upgrade) => upgrade.name === chosen) ?? upgrades.find((upgrade) => !upgrade.toggle));

  function installedLevel(name: UpgradeName): number {
    return session.props.upgrades[name] ?? 0;
  }

  function shownLevel(name: UpgradeName): number {
    const change = app.itemFor(`upgrade:${name}`)?.change;
    return change?.kind === 'upgrade' ? change.level : installedLevel(name);
  }

  function isLocked(level: UpgradeLevel): boolean {
    return employee && level.grade > grade;
  }

  function pick(upgrade: UpgradeOption, level: number) {
    if (level === installedLevel(upgrade.name)) {
      app.undo();
      app.remove(`upgrade:${upgrade.name}`);
      return;
    }

    const entry = upgrade.levels[level - 1];
    app.select({
      label: entry ? entry.name : t('ui.upgrades.stock', upgrade.label.toLowerCase()),
      detail: upgrade.label,
      price: entry?.price ?? 0,
      change: { kind: 'upgrade', name: upgrade.name, level },
    });
  }

  function levelSummary(upgrade: UpgradeOption): string {
    const level = installedLevel(upgrade.name);
    if (upgrade.toggle) return level > 0 ? t('ui.upgrades.fitted') : t('ui.upgrades.not_fitted');
    return level === 0 ? t('ui.upgrades.stock_level') : (upgrade.levels[level - 1]?.name ?? t('ui.upgrades.level', level));
  }

  const pendingEntry = $derived.by(() => {
    if (!active || app.pending?.key !== `upgrade:${active.name}`) return null;
    const change = app.pending.change;
    if (change.kind !== 'upgrade' || change.level === 0) return null;
    return active.levels[change.level - 1] ?? null;
  });

  const health = $derived(session.diagnosis.engine);
</script>

<div class="flex min-h-0 flex-1 flex-col gap-5">
  <div class="flex flex-col gap-1.5">
    {#each upgrades as upgrade (upgrade.name)}
      {@const shown = shownLevel(upgrade.name)}
      {@const installed = installedLevel(upgrade.name)}
      {@const isActive = active?.name === upgrade.name}
      {#if upgrade.toggle}
        <div class="flex h-11 items-center gap-3 rounded-lg border border-border bg-card px-3">
          <span class="w-36 text-sm font-semibold">{upgrade.label}</span>
          <span class="flex-1 text-sm text-muted-foreground">{levelSummary(upgrade)}</span>
          <button
            type="button"
            role="switch"
            aria-checked={shown > 0}
            aria-label={upgrade.label}
            disabled={shown === 0 && upgrade.levels[0] !== undefined && isLocked(upgrade.levels[0])}
            class={['relative h-5 w-9 rounded-full transition-colors', shown > 0 ? 'bg-primary' : 'bg-secondary']}
            onclick={() => {
              chosen = upgrade.name;
              pick(upgrade, shown > 0 ? 0 : 1);
            }}
          >
            <span class={['absolute top-0.5 left-0.5 size-4 rounded-full bg-foreground transition-transform duration-150', shown > 0 && 'translate-x-4']}></span>
          </button>
        </div>
      {:else}
        <button
          type="button"
          class={[
            'flex h-11 items-center gap-3 rounded-lg border px-3 text-left transition-colors',
            isActive ? 'border-primary bg-primary text-primary-foreground' : 'border-border bg-card hover:bg-muted',
          ]}
          onclick={() => {
            if (app.pending?.key.startsWith('upgrade:')) app.undo();
            chosen = upgrade.name;
          }}
        >
          <span class="w-36 text-sm font-semibold">{upgrade.label}</span>
          <span class={['flex-1 truncate text-sm', isActive ? 'text-primary-foreground' : 'text-muted-foreground']}>{levelSummary(upgrade)}</span>
          <span class="flex gap-1" aria-label={t('ui.upgrades.levels_aria', shown, upgrade.levels.length)}>
            {#each upgrade.levels as _, i (i)}
              <span
                class={[
                  'h-1 w-5 rounded-full',
                  i < Math.min(shown, installed) ? 'bg-foreground' : i < shown ? (isActive ? 'bg-foreground' : 'bg-primary') : isActive ? 'bg-cobalt-hover' : 'bg-secondary',
                ]}
              ></span>
            {/each}
          </span>
        </button>
      {/if}
    {/each}
  </div>

  {#if active}
    {@const installed = installedLevel(active.name)}
    {@const shown = shownLevel(active.name)}
    <section class="flex min-h-0 flex-1 flex-col gap-2 border-t border-border pt-4">
      <div class="flex items-baseline justify-between">
        <h3 class="text-base font-semibold">{active.label}</h3>
        {#if active.name === 'engine'}
          <span class="text-xs text-muted-foreground tabular-nums">{t('ui.upgrades.engine_health', Math.round(health))}</span>
        {/if}
      </div>

      <div class="-mr-2 flex min-h-0 flex-col gap-1.5 overflow-y-auto pr-2">
        {#each [null, ...active.levels] as level, i (i)}
          {@const locked = level !== null && isLocked(level)}
          {@const selected = shown === i && shown !== installed}
          <button
            type="button"
            disabled={locked || (i === installed && shown === installed)}
            class={[
              'flex min-h-14 items-center gap-3 rounded-lg border px-3 py-2 text-left transition-colors',
              selected ? 'border-primary bg-card outline-1 outline-primary' : 'border-border bg-card enabled:hover:bg-muted',
              locked && 'text-muted-foreground',
            ]}
            onclick={() => pick(active, i)}
          >
            <span class="min-w-0 flex-1">
              <span class={['block text-sm', locked ? '' : 'font-semibold']}>{level ? level.name : t('ui.upgrades.stock', active.label.toLowerCase())}</span>
              <span class="block text-xs text-muted-foreground">
                {#if locked && level}
                  {t('ui.upgrades.locked', level.grade, grade)}
                {:else}
                  {t('ui.upgrades.level', i)}
                {/if}
              </span>
            </span>
            {#if i === installed}
              <span class="flex items-center gap-1.5 text-xs font-medium text-foreground">
                <CheckCircle size={14} class="text-success" />
                {t('ui.option.installed')}
              </span>
            {:else}
              {#if locked}
                <Lock size={13} />
              {/if}
              <span class="text-sm font-semibold tabular-nums">{formatMoney(level?.price ?? 0)}</span>
            {/if}
          </button>
        {/each}
      </div>

      {#if pendingEntry}
        {#if employee && pendingEntry.materials.length > 0}
          <div class="rounded-lg border border-border bg-card p-3">
            <p class="mb-2 text-sm font-medium">{t('ui.upgrades.to_fit', pendingEntry.name)}</p>
            <div class="flex flex-wrap gap-1.5">
              {#each pendingEntry.materials as material (material.item)}
                <span class="rounded-sm bg-secondary px-2 py-0.5 text-xs font-medium tabular-nums">{material.label} {material.count}</span>
              {/each}
            </div>
            <p class="mt-2 text-xs text-muted-foreground">{t('ui.upgrades.materials_note')}</p>
          </div>
        {/if}
        <button
          type="button"
          class="h-9 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground transition-colors hover:bg-cobalt-hover"
          onclick={() => app.addPending()}
        >
          {t('ui.preview.add_named', pendingEntry.name, formatMoney(pendingEntry.price))}
        </button>
      {:else if app.pending?.key === `upgrade:${active.name}`}
        <button
          type="button"
          class="h-9 rounded-md bg-primary px-4 text-sm font-medium text-primary-foreground transition-colors hover:bg-cobalt-hover"
          onclick={() => app.addPending()}
        >
          {t('ui.upgrades.add', app.pending.label)}
        </button>
      {/if}
    </section>
  {/if}
</div>
