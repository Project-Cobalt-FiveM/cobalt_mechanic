<script lang="ts">
  import Mouse from 'phosphor-svelte/lib/Mouse';
  import { fetchNui } from './lib/nui';
  import { t } from './lib/locale.svelte';
  import type { CameraView } from './lib/types';

  const views: { id: CameraView; label: string }[] = [
    { id: 'front', label: 'ui.camera.front' },
    { id: 'side', label: 'ui.camera.side' },
    { id: 'rear', label: 'ui.camera.rear' },
    { id: 'wheel', label: 'ui.camera.wheel' },
    { id: 'engine', label: 'ui.camera.engine' },
    { id: 'interior', label: 'ui.camera.interior' },
  ];

  type Props = { view: CameraView | null; onpick: (view: CameraView) => void };

  let { view, onpick }: Props = $props();

  function pick(next: CameraView) {
    onpick(next);
    void fetchNui('camera', { view: next });
  }
</script>

<div class="flex items-center gap-1 rounded-lg border border-border bg-card p-1">
  {#each views as entry (entry.id)}
    <button
      type="button"
      class={['h-8 rounded-md px-3 text-sm font-medium transition-colors', view === entry.id ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:bg-muted hover:text-foreground']}
      onclick={() => pick(entry.id)}
    >
      {t(entry.label)}
    </button>
  {/each}
  <span class="mx-1 h-5 w-px bg-border"></span>
  <span class="flex items-center gap-1.5 px-2 text-xs text-muted-foreground">
    <Mouse size={14} />
    {t('ui.camera.hint')}
  </span>
</div>
