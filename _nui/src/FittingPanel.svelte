<script lang="ts">
  import CheckCircle from 'phosphor-svelte/lib/CheckCircle';
  import XCircle from 'phosphor-svelte/lib/XCircle';
  import Wrench from 'phosphor-svelte/lib/Wrench';
  import HourglassMedium from 'phosphor-svelte/lib/HourglassMedium';
  import { formatMoney, initials } from './lib/format';
  import { rise } from './lib/motion';
  import { t } from './lib/locale.svelte';
  import type { Fitting } from './lib/types';

  type Props = { fitting: Fitting };

  let { fitting }: Props = $props();

  let startedAt = $state(Date.now());
  let now = $state(Date.now());

  $effect(() => {
    void fitting.id;
    void fitting.index;
    startedAt = Date.now();
    now = startedAt;

    const timer = setInterval(() => (now = Date.now()), 1000);
    return () => clearInterval(timer);
  });

  const active = $derived(fitting.items[fitting.index - 1]);
  const elapsed = $derived(Math.max(0, (now - startedAt) / 1000));
  const remaining = $derived(active ? Math.max(0, Math.ceil(active.seconds - elapsed)) : 0);
  const onTheJob = $derived.by(() => {
    const names = fitting.crew.map((member) => member.name);
    if (names.length === 0) return '';
    if (names.length === 1) return t('ui.fitting.crew_one', names[0] ?? '');
    return t('ui.fitting.crew_many', names.slice(0, -1).join(', '), names.at(-1) ?? '');
  });
</script>

<div class="flex min-h-0 flex-1 flex-col">
  <h2 class="text-base font-semibold">{t('ui.fitting.title')}</h2>
  <p class="text-xs text-muted-foreground tabular-nums">{t('ui.fitting.paid_by', fitting.paidBy, formatMoney(fitting.total))}</p>

  <ol class="mt-4 flex flex-col gap-2">
    {#each fitting.items as item, i (item.key)}
      {#if item.status === 'active'}
        <li class="rounded-md border border-primary bg-card px-3.5 py-3" in:rise>
          <div class="flex items-center gap-3">
            <Wrench size={16} class="shrink-0 text-cobalt-foreground" />
            <span class="min-w-0 flex-1 truncate text-sm font-semibold">{item.label}</span>
            <span class="text-xs font-medium tabular-nums">{t('ui.fitting.seconds_left', remaining)}</span>
          </div>
          <div class="mt-2.5 h-1 overflow-hidden rounded-full bg-secondary">
            <div class="fill h-full origin-left rounded-full bg-primary" style:animation-duration="{item.seconds}s"></div>
          </div>
          {#if onTheJob}
            <p class="mt-2 text-xs text-muted-foreground">{onTheJob}</p>
          {/if}
        </li>
      {:else}
        <li class="flex items-center gap-3 rounded-md border border-border px-3.5 py-3">
          {#if item.status === 'done'}
            <CheckCircle size={16} class="shrink-0 text-success" />
          {:else if item.status === 'skipped'}
            <XCircle size={16} class="shrink-0 text-muted-foreground" />
          {:else}
            <HourglassMedium size={16} class="shrink-0 text-muted-foreground" />
          {/if}
          <div class="min-w-0 flex-1">
            <p class={['truncate text-sm font-semibold', item.status === 'skipped' && 'text-muted-foreground line-through']}>{item.label}</p>
            {#if item.status === 'next' && i === fitting.index && active}
              <p class="truncate text-xs text-muted-foreground">{t('ui.fitting.starts_after', active.label)}</p>
            {/if}
          </div>
          <span class="shrink-0 text-xs text-muted-foreground">
            {#if item.status === 'done'}{t('ui.fitting.done')}{:else if item.status === 'skipped'}{t('ui.fitting.refunded')}{:else if i === fitting.index}{t('ui.fitting.next')}{:else}{t('ui.fitting.queued')}{/if}
          </span>
        </li>
      {/if}
    {/each}
  </ol>

  {#if fitting.crew.length > 0}
    <div class="mt-5 border-t border-border pt-4">
      <div class="flex items-baseline justify-between gap-3">
        <h3 class="text-sm font-semibold">{t('ui.fitting.crew_title', fitting.crewRadius)}</h3>
        {#if fitting.sharesMarkup}
          <span class="text-xs text-muted-foreground">{t('ui.fitting.equal_share')}</span>
        {/if}
      </div>
      <ul class="mt-2.5 flex flex-col gap-2">
        {#each fitting.crew as member (member.name)}
          <li class="flex items-center gap-3 rounded-md border border-border px-3.5 py-2.5">
            <span class="grid size-8 shrink-0 place-items-center rounded-full bg-secondary text-xs font-semibold">{initials(member.name)}</span>
            <div class="min-w-0">
              <p class="truncate text-sm font-semibold">{member.isYou ? t('ui.fitting.you', member.name) : member.name}</p>
              <p class="truncate text-xs text-muted-foreground tabular-nums">
                {member.isYou ? t('ui.fitting.role_grade', member.role, member.grade) : t('ui.fitting.role_distance', member.role, member.distance)}
              </p>
            </div>
          </li>
        {/each}
      </ul>
    </div>
  {/if}
</div>

<style>
  .fill {
    animation-name: fill;
    animation-timing-function: linear;
    animation-fill-mode: forwards;
  }

  @keyframes fill {
    from {
      transform: scaleX(0);
    }

    to {
      transform: scaleX(1);
    }
  }
</style>
