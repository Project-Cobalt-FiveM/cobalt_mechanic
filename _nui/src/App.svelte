<script lang="ts">
  import { onMount } from 'svelte';
  import IconContext from 'phosphor-svelte/lib/IconContext';
  import { fetchNui, inGame, mockOpen, onMessage } from './lib/nui';
  import { setLocales } from './lib/locale.svelte';
  import { app } from './lib/store.svelte';
  import { rise } from './lib/motion';
  import type { Messages } from './lib/types';
  import SidePanel from './SidePanel.svelte';
  import Cart from './side/Cart.svelte';
  import Performance from './side/Performance.svelte';
  import StaffCheckout from './side/StaffCheckout.svelte';
  import SelfCheckout from './side/SelfCheckout.svelte';
  import CameraBar from './CameraBar.svelte';
  import BillCard from './BillCard.svelte';

  let dragging = $state(false);
  let lastX = 0;
  let lastY = 0;
  let queuedX = 0;
  let queuedY = 0;
  let lastSent = 0;

  function receive(message: Messages) {
    if (message.action === 'open' || message.action === 'bill') setLocales(message.locales);
    app.handle(message);
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key !== 'Escape') return;

    if (app.bill) {
      event.preventDefault();
      void app.answerBill(false);
      return;
    }

    if (!app.visible) return;
    event.preventDefault();
    app.escape();
  }

  function onpointerdown(event: PointerEvent) {
    if (event.target !== event.currentTarget) return;
    dragging = true;
    lastX = event.clientX;
    lastY = event.clientY;
    queuedX = 0;
    queuedY = 0;
    (event.currentTarget as HTMLElement).setPointerCapture(event.pointerId);
  }

  function onpointermove(event: PointerEvent) {
    if (!dragging) return;
    if ((event.buttons & 1) === 0) {
      dragging = false;
      return;
    }

    queuedX += event.clientX - lastX;
    queuedY += event.clientY - lastY;
    lastX = event.clientX;
    lastY = event.clientY;

    const now = performance.now();
    if (now - lastSent < 33) return;

    lastSent = now;
    app.camera = null;
    void fetchNui('orbit', { dx: queuedX, dy: queuedY });
    queuedX = 0;
    queuedY = 0;
  }

  function stopDragging() {
    dragging = false;
  }

  function onwheel(event: WheelEvent) {
    if (event.target !== event.currentTarget) return;
    void fetchNui('zoom', { delta: event.deltaY });
  }

  onMount(() => {
    const stop = onMessage(receive);

    void mockOpen().then((messages) => {
      for (const message of messages) receive(message);
    });

    if (!inGame) {
      document.body.style.background = '#3A3D42';
      window.addEventListener('hashchange', () => location.reload());
    }

    return stop;
  });
</script>

<svelte:window {onkeydown} />

<IconContext values={{ weight: 'fill' }}>
  {#if app.visible && app.session}
    {@const session = app.session}
    <main
      class={['fixed inset-0', dragging ? 'cursor-grabbing' : 'cursor-grab']}
      {onpointerdown}
      {onpointermove}
      onpointerup={stopDragging}
      onpointercancel={stopDragging}
      onlostpointercapture={stopDragging}
      {onwheel}
      transition:rise={{ duration: 300 }}
    >
      <div class="absolute top-6 bottom-6 left-6 cursor-default">
        <SidePanel {session} />
      </div>

      {#if app.checkout && !app.fitting}
        <div class="absolute top-6 right-6 bottom-6 w-[27.5rem] cursor-default" in:rise>
          {#if session.mode === 'employee'}
            <StaffCheckout {session} />
          {:else}
            <SelfCheckout {session} />
          {/if}
        </div>
      {:else if !app.fitting}
        <div class="absolute top-6 right-6 flex w-[21.25rem] cursor-default flex-col gap-4">
          <Cart {session} />
          {#if app.tab === 'upgrades'}
            <Performance stats={session.stats} />
          {/if}
        </div>
      {/if}

      {#if !app.fitting}
        <div class={['absolute bottom-6 -translate-x-1/2 cursor-default', app.checkout ? 'left-[calc((100%-27.5rem)/2+0.75rem)]' : 'left-1/2']}>
          <CameraBar view={app.camera} onpick={(view) => (app.camera = view)} />
        </div>
      {/if}
    </main>
  {/if}

  {#if app.bill}
    <BillCard bill={app.bill} />
  {/if}
</IconContext>
