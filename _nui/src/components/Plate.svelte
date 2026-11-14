<script lang="ts">
  import { t } from '../lib/locale.svelte';

  type Props = { index: number; text: string };

  type Look = {
    plate: string;
    border: string;
    number: string;
    emboss: string;
    screws?: string;
  };

  let { index, text }: Props = $props();

  const id = $props.id();

  const looks: Record<number, Look> = {
    0: { plate: '#F4F4F2', border: '#C9CBCF', number: '#0F2352', emboss: '#B9BECB' },
    1: { plate: '#131416', border: '#3A3B3E', number: '#F2C230', emboss: '#6B5410' },
    2: { plate: '#1D3384', border: '#14245E', number: '#F6C93A', emboss: '#0F1C4A' },
    3: { plate: '#F4F4F2', border: '#C9CBCF', number: '#2246B0', emboss: '#B9BECB' },
    4: { plate: '#F4F4F2', border: '#C9CBCF', number: '#2246B0', emboss: '#B9BECB' },
    5: { plate: '#EEEEE8', border: '#BFC0BA', number: '#1B2230', emboss: '#B4B6AE' },
    6: { plate: '#B8161D', border: '#8A1015', number: '#FFFFFF', emboss: '#7A0D12' },
    7: { plate: '#F3EFE4', border: '#C9C2AE', number: '#1D3468', emboss: '#BDB6A2' },
    8: { plate: '#E9EEF4', border: '#B6C0CC', number: '#1A2C55', emboss: '#AEB8C6' },
    9: { plate: '#F4F4F2', border: '#C9CBCF', number: '#131313', emboss: '#B7B7B7' },
    10: { plate: '#4A2A8A', border: '#33196A', number: '#F6E7A6', emboss: '#2A1457', screws: '#2C1A55' },
    11: { plate: '#0D0D0F', border: '#2E2E30', number: '#D9A63A', emboss: '#4A3612' },
    12: { plate: '#2E8A3C', border: '#20682C', number: '#FFFFFF', emboss: '#1B5A25' },
  };

  const look = $derived(looks[index] ?? looks[0]!);
  const screwColour = $derived(look.screws ?? '#8E9096');
  const screws = [
    [101, 62],
    [367, 62],
    [101, 212],
    [367, 212],
  ] as const;
</script>

<svg viewBox="0 0 480 240" class="block h-auto w-full" role="img" aria-label={t('ui.plate.aria', text)}>
  <defs>
    <clipPath id="{id}-clip">
      <rect x="2" y="2" width="476" height="236" rx="14" />
    </clipPath>
    <linearGradient id="{id}-sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#3D7FC4" />
      <stop offset="0.55" stop-color="#E9A35A" />
      <stop offset="1" stop-color="#F6D38A" />
    </linearGradient>
    <linearGradient id="{id}-dusk" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stop-color="#16294F" />
      <stop offset="1" stop-color="#3A64A0" />
    </linearGradient>
  </defs>

  <rect x="2" y="2" width="476" height="236" rx="14" fill={look.plate} stroke={look.border} stroke-width="4" />

  <g clip-path="url(#{id}-clip)">
    {#if index === 0}
      <rect x="19" y="19" width="66" height="36" fill="#ECEDDB" />
      <text x="52" y="46" text-anchor="middle" class="sticker" fill="#1866EA">MAY</text>
      <rect x="395" y="19" width="66" height="36" fill="#EE4A0A" />
      <text x="400" y="30" class="tiny" fill="#111111">SA</text>
      <text x="400" y="51" class="tiny" fill="#111111">L 6324478</text>
      <text x="240" y="54" text-anchor="middle" class="script" fill="#D20F0F">San Andreas</text>
    {:else if index === 1 || index === 2}
      <text x="240" y="54" text-anchor="middle" class="script" fill={look.number}>San Andreas</text>
    {:else if index === 3}
      <text x="240" y="54" text-anchor="middle" class="script" fill="#2246B0">San Andreas</text>
    {:else if index === 4}
      <text x="240" y="54" text-anchor="middle" class="script" fill="#D20F0F">San Andreas</text>
      <text x="240" y="226" text-anchor="middle" class="foot" fill="#D20F0F">EXEMPT</text>
    {:else if index === 5}
      <rect x="0" y="0" width="480" height="56" fill="#C8262B" />
      <rect x="20" y="13" width="54" height="30" rx="3" fill="#F2F2EE" />
      <text x="47" y="35" text-anchor="middle" class="tiny" fill="#C8262B">NY</text>
      <text x="240" y="44" text-anchor="middle" class="band" fill="#FFFFFF">YANKTON</text>
      <rect x="0" y="56" width="480" height="4" fill="#1B2230" />
    {:else if index === 6}
      <path d="M0 196 C 120 172, 240 222, 480 190 L 480 240 L 0 240 Z" fill="#D9363C" />
      <text x="240" y="58" text-anchor="middle" class="script" fill="#FFFFFF">eCola</text>
    {:else if index === 7}
      <rect x="0" y="0" width="480" height="72" fill="url(#{id}-sky)" />
      <circle cx="372" cy="54" r="20" fill="#FBE7A6" />
      <path d="M0 72 L 52 40 L 96 58 L 150 26 L 214 62 L 262 44 L 318 68 L 360 50 L 420 64 L 480 38 L 480 72 Z" fill="#C67A3E" />
      <path d="M0 72 L 70 56 L 140 70 L 230 52 L 300 72 Z M 300 72 L 390 58 L 480 70 L 480 72 Z" fill="#8F4F2A" />
      <text x="240" y="30" text-anchor="middle" class="script small" fill="#FFFFFF">Las Venturas</text>
      <text x="240" y="226" text-anchor="middle" class="foot" fill="#1D3468">LAS VENTURAS</text>
    {:else if index === 8}
      <rect x="0" y="0" width="480" height="64" fill="url(#{id}-dusk)" />
      <path
        d="M0 64 L0 46 L22 46 L22 34 L40 34 L40 50 L58 50 L58 22 L66 14 L74 22 L74 50 L96 50 L96 38 L118 38 L118 52 L150 52 L150 28 L170 28 L170 52 L196 52 L196 40 L226 40 L226 52 L262 52 L262 18 L272 8 L282 18 L282 52 L310 52 L310 36 L334 36 L334 52 L362 52 L362 30 L384 30 L384 52 L414 52 L414 42 L440 42 L440 50 L480 50 L480 64 Z"
        fill="#0C1A36"
      />
      <text x="240" y="40" text-anchor="middle" class="band" fill="#FFFFFF">LIBERTY CITY</text>
      <text x="240" y="226" text-anchor="middle" class="foot" fill="#1A2C55">STATE OF LIBERTY</text>
    {:else if index === 9}
      <rect x="0" y="0" width="480" height="58" fill="#C8102E" />
      <path d="M0 58 L 0 48 C 30 66, 60 44, 96 60 C 130 72, 170 46, 210 62 C 250 74, 300 48, 340 64 C 380 76, 430 50, 480 60 L 480 58 Z" fill="#C8102E" />
      <circle cx="70" cy="22" r="7" fill="#F4F4F2" />
      <circle cx="94" cy="38" r="4" fill="#F4F4F2" />
      <circle cx="410" cy="20" r="6" fill="#F4F4F2" />
      <circle cx="386" cy="40" r="3" fill="#F4F4F2" />
      <text x="240" y="42" text-anchor="middle" class="band" fill="#FFFFFF">LS CAR MEET</text>
      <rect x="0" y="222" width="480" height="18" fill="#C8102E" />
    {:else if index === 10}
      <rect x="18" y="16" width="62" height="32" rx="3" fill="#1C1430" />
      <text x="49" y="40" text-anchor="middle" class="sticker" fill="#F2F2EE">NOV</text>
      <text x="240" y="50" text-anchor="middle" class="band" fill="#F6CF3A">PANIC</text>
      <text x="240" y="226" text-anchor="middle" class="foot" fill="#F6CF3A">LOS SANTOS</text>
    {:else if index === 11}
      <text x="240" y="56" text-anchor="middle" class="script" fill="#D9A63A">Pounders</text>
      <text x="240" y="226" text-anchor="middle" class="foot" fill="#D9A63A">SAN ANDREAS</text>
    {:else if index === 12}
      <path d="M0 192 C 140 222, 300 168, 480 198 L 480 240 L 0 240 Z" fill="#43A852" />
      <text x="240" y="58" text-anchor="middle" class="script" fill="#FFFFFF">Sprunk</text>
    {/if}

    {#each screws as [x, y] (`${x}-${y}`)}
      <rect x={x} y={y} width="12" height="8" rx="4" fill={screwColour} />
    {/each}

    <text x="240" y="187" text-anchor="middle" class="number" fill={look.emboss}>{text}</text>
    <text x="240" y="184" text-anchor="middle" class="number" fill={look.number}>{text}</text>
  </g>
</svg>

<style>
  .number {
    font-family: 'Onest Variable', sans-serif;
    font-size: 84px;
    font-weight: 700;
    letter-spacing: 0.02em;
  }

  .script {
    font-family: 'Onest Variable', sans-serif;
    font-size: 44px;
    font-weight: 600;
  }

  .script.small {
    font-size: 30px;
  }

  .band {
    font-family: 'Onest Variable', sans-serif;
    font-size: 32px;
    font-weight: 700;
    letter-spacing: 0.18em;
  }

  .foot {
    font-family: 'Onest Variable', sans-serif;
    font-size: 18px;
    font-weight: 700;
    letter-spacing: 0.22em;
  }

  .sticker {
    font-family: 'Onest Variable', sans-serif;
    font-size: 24px;
    font-weight: 700;
  }

  .tiny {
    font-family: 'Onest Variable', sans-serif;
    font-size: 10px;
    font-weight: 700;
  }
</style>
