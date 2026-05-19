# Shader Parameter Guide

## How to Use This Repository's Shaders

Every GLSL file in `code/` accepts a set of uniform variables. This guide explains what each uniform does physically, how it interacts with other uniforms, and how to tune it for specific visual effects.

---

## Universal Uniforms

These appear in every shader:

### `time` (float)
- **Source**: Your rendering loop's elapsed time in seconds
- **Never set manually** — pass `performance.now() / 1000.0` or equivalent
- **Effect**: Drives all animation. If time is static, the fluid is frozen.

### `resolution` (vec2)
- **Source**: `vec2(canvas.width, canvas.height)`
- **Critical**: Without correct resolution, the aspect ratio correction fails → spikes appear skewed
- **Effect**: All `uv` calculations divide by this. Must match actual canvas size.

---

## Core Physical Uniforms

### `magnetStrength` — Field Intensity
- **Range**: 0.0 – 10.0  |  **Default**: 3.0
- **Units**: Dimensionless scale factor on the dipole field
- **Physical analog**: μ₀ M (magnetic moment magnitude)

| Value | Visual Effect |
|-------|--------------|
| 0.0 | No spikes. Flat pool |
| 1.0 – 2.0 | Sub-threshold: smooth surface with gentle swells |
| 2.5 – 4.0 | Active spike region: clear, discrete spikes |
| 5.0 – 7.0 | Strong field: tall, sharp spikes; potential saturation |
| 8.0 – 10.0 | Maximum: can cause numerical artifacts; clamp downstream values |

**Interaction**: Works multiplicatively with `susceptibility`. Doubling either doubles spike height. Doubling both quadruples it.

### `susceptibility` — Fluid Magnetic Response
- **Range**: 0.1 – 5.0  |  **Default**: 2.0
- **Physical meaning**: χ in M = χH (linear regime); how strongly the fluid magnetizes
- **Units**: Dimensionless (SI)

| Value | Fluid Type |
|-------|-----------|
| 0.1 – 0.5 | Very weakly magnetic (dilute ferrofluid) |
| 1.0 – 2.0 | Typical commercial ferrofluid (APG or EMG series) |
| 3.0 – 4.0 | High-concentration ferrofluid |
| 5.0 | Maximum physically plausible value |

**Interaction with `magnetStrength`**: The Rosensweig instability threshold scales as ~1/(χ·H²). High susceptibility → spikes form at lower field strength.

### `surfaceTension` — Resistance to Spike Formation
- **Range**: 0.1 – 5.0  |  **Default**: 1.0
- **Physical meaning**: γ (surface tension coefficient, N/m)
- **Effect on spikes**: Higher surfaceTension → shorter, blunter spikes. Think of it as the fluid's reluctance.

| Value | Spike Character |
|-------|----------------|
| 0.1 – 0.4 | Very low: fluid is eager to spike; thin, needle-like spikes |
| 0.5 – 1.5 | Normal: balanced spike formation |
| 2.0 – 3.5 | High: fluid resists spiking; rounded, low, widely-spaced bumps |
| 4.0 – 5.0 | Maximum: near-flat surface even at high field |

**Interaction**: The critical spike condition is approximately `magnetStrength * susceptibility > surfaceTension * threshold`. Below threshold: flat surface. Above: spikes.

### `spikeSharpness` — Tip Acuity
- **Range**: 0.1 – 3.0  |  **Default**: 1.5
- **Controls**: The width of the Gaussian spike profile. Does NOT affect height.

| Value | Visual |
|-------|--------|
| 0.1 | Very wide spikes: dome-shaped bumps |
| 0.8 – 1.0 | Moderate: classic Rosensweig cone shape |
| 1.5 – 2.0 | Sharp: narrow spike base, prominent tip |
| 2.5 – 3.0 | Needle: extreme narrowing, almost wire-like spikes |

**Tuning tip**: High `spikeSharpness` + low `surfaceTension` = thin, violent spikes (anger aesthetic). Low `spikeSharpness` + high `surfaceTension` = gentle, rounded swells (calm/grief aesthetic).

### `gravity` — Downward Restoring Force
- **Range**: 0.0 – 2.0  |  **Default**: 1.0

| Value | Interpretation |
|-------|---------------|
| 0.0 | Zero-gravity (space ferrofluid); spikes grow indefinitely |
| 1.0 | Earth gravity; spikes compete realistically against gravity |
| 2.0 | High-g planet; gravity dominates; very short spikes even at high field |

**Physics**: Gravity sets the Rosensweig wavelength via λ_c = 2π√(γ/ρg). Higher gravity → shorter wavelength → more spikes per unit area, but shorter.

### `viscosity` — Fluid Response Speed
- **Range**: 0.1 – 5.0  |  **Default**: 1.0
- **Physical meaning**: Dynamic viscosity η (mPa·s, scaled)

| Value | Fluid Character |
|-------|----------------|
| 0.1 | Water-like: instant response, high wave activity |
| 0.5 – 1.0 | Standard ferrofluid (5–20 mPa·s) |
| 2.0 – 3.5 | Heavy: slow response, waves damp quickly |
| 5.0 | Very viscous: fluid barely responds; almost static geometry |

**In oscillating shaders**: Viscosity controls wave damping rate. High viscosity → waves decay within one or two wavelengths. Low viscosity → waves propagate across the whole pool.

**In vortex_field.glsl**: Viscosity determines the angular lag behind the rotating magnet. High viscosity → large lag angle → more dramatic spiral arm structure.

### `fieldOscillation` — Oscillation / Rotation Speed
- **Range**: 0.0 – 5.0  |  **Default**: 0.5

| Shader | Effect |
|--------|--------|
| `oscillating_spikes.glsl` | Frequency of vertical magnet oscillation |
| `vortex_field.glsl` | Angular velocity of rotating magnet (rad/s scaled) |
| `multi_magnet.glsl` | Drift/orbit speed of all magnets |
| `labyrinthine_ferrofluid.glsl` | Rotation speed of in-plane field |
| `audio_ferrofluid.glsl` | Base modulation rate |

**Resonance tip**: In `oscillating_spikes.glsl`, setting `fieldOscillation ≈ 1.0` creates the closest analog to Faraday wave resonance. The spikes respond most dramatically near this value.

---

## Shader-Specific Uniforms

### `basic_ferrofluid.glsl`

#### `magnetPos` (vec2)
- **Range**: (0.0, 0.0) – (1.0, 1.0) in UV space
- **Default**: (0.5, 0.3) — centered, slightly above middle
- **Effect**: Moves the entire spike cluster. The spike column follows the magnet.
- **Note**: The shader converts from UV to aspect-corrected coordinates internally.

---

### `multi_magnet.glsl`

#### `magnetCount` (int)
- **Range**: 1 – 20  |  **Default**: 3

| Count | Pattern |
|-------|---------|
| 1 | Single spike cluster (same as basic_ferrofluid) |
| 2 | Two clusters; midpoint depletion zone |
| 3 | Triangular arrangement; three-way competition |
| 4 – 6 | Ring of clusters; hexagonal order begins to emerge |
| 7 – 12 | Dense array; quasi-hexagonal global ordering |
| 15 – 20 | High density; field superposition creates complex interference |

---

### `emotional_ferrofluid.glsl`

#### `emotion` (float)
- **Range**: 0.0 – 1.0
- **Mapping**: 0.0=CALM, 0.25=ANGER, 0.5=FEAR, 0.75=JOY, 1.0=GRIEF
- **Behavior**: Linearly interpolates between the five emotional states. Values between the anchors blend properties smoothly.

| Emotion | Field Freq | Spike Amp | Noise | Edge Color |
|---------|-----------|-----------|-------|-----------|
| CALM | 0.1 | 0.4× | None | Cold blue-white |
| ANGER | 4.0 | 2.5× | 0.06 | Deep red |
| FEAR | 2.5 | 0.8× | 0.12 | Dark blue |
| JOY | 1.5 | 1.4× | 0.02 | Mid blue |
| GRIEF | 0.15 | 0.15× | 0.005 | Near-black |

#### `emotionIntensity` (float)
- **Range**: 0.0 – 1.0  |  **Default**: 0.8
- Scales the difference from calm. 0.0 = always calm regardless of `emotion`. 1.0 = full emotional expression.

---

### `biological_ferrofluid.glsl`

#### `biologicalMode` (float → bool)
- **0.0**: Classical Rosensweig physics only
- **1.0**: Full biological lifecycle (growth, reproduction, death)
- **Between 0 and 1**: Gradual transition. 0.5 is haunting — the fluid has half-remembered biology.

---

### `cosmic_ferrofluid.glsl`

#### `gravity` (float)
- At cosmic scale, gravity = 0.3 means effective surface gravity of ~3 m/s² — matching a large asteroid or moon's surface gravity.
- Setting gravity = 0.0 removes the gravitational baseline entirely; prominence eruptions grow unlimited.

---

### `glitch_ferrofluid.glsl`

#### `glitchAmount` (float)
- **Range**: 0.0 – 1.0  |  **Default**: 0.6

| Value | Effect |
|-------|--------|
| 0.0 | Clean, normal ferrofluid |
| 0.1 – 0.2 | Subtle: slight field non-uniformity, occasional dead zones |
| 0.3 – 0.5 | Moderate: visible UV banding, bent spikes |
| 0.6 – 0.8 | Heavy: RGB aberration, frequent field reversals |
| 0.9 – 1.0 | Severe: the fluid is barely recognizable as ferrofluid |

**Tuning**: At glitchAmount = 1.0, the strobe effect is continuous — reduce `fieldOscillation` to slow the strobe period.

---

### `audio_ferrofluid.glsl`

#### `audioBass`, `audioMid`, `audioHigh`, `audioTreble` (float)
- **Range**: 0.0 – 1.0 (normalized from your FFT)
- **Band centers**: Bass ≈ 80 Hz, Mid ≈ 700 Hz, High ≈ 5 kHz, Treble ≈ 12 kHz

**Mapping FFT to these uniforms** (example in JavaScript):
```javascript
analyser.getFloatFrequencyData(dataArray); // dB values, typically -100 to 0
// Normalize to [0,1]:
function bandEnergy(lo, hi) {
    const binLo = Math.floor(lo * analyser.fftSize / analyser.context.sampleRate);
    const binHi = Math.floor(hi * analyser.fftSize / analyser.context.sampleRate);
    let sum = 0;
    for (let i = binLo; i <= binHi; i++) sum += Math.pow(10, dataArray[i] / 20);
    return Math.sqrt(sum / (binHi - binLo + 1));
}
gl.uniform1f(loc.audioBass,   Math.min(1.0, bandEnergy(20, 200) * 5.0));
gl.uniform1f(loc.audioMid,    Math.min(1.0, bandEnergy(200, 2000) * 4.0));
gl.uniform1f(loc.audioHigh,   Math.min(1.0, bandEnergy(2000, 8000) * 3.0));
gl.uniform1f(loc.audioTreble, Math.min(1.0, bandEnergy(8000, 20000) * 3.0));
```

#### `audioPeak` (float)
- **Effect**: Triggers brief white flash on transient beats
- **Best driven by**: Onset detection, kick drum signal, or max(bassNow - bassPrev, 0)

---

### `halbach_array.glsl`

#### `arrayPitch` (float)
- **Range**: 0.05 – 0.5  |  **Default**: 0.15
- **Controls**: Spacing between spikes. Physical pitch = magnet width × 2.
- **Note**: Smaller pitch → more tightly-packed, finer spikes. But pitch cannot be smaller than the capillary length (~0.02 in normalized units) or spikes merge.

#### `halbachSide` (float)
- **1.0**: Strong side — dense, regular spikes
- **-1.0**: Weak side — near-flat surface with tiny fringe-field ripples
- **Transition**: Flipping from 1.0 to -1.0 simulates rotating the ferrofluid above the array to its other side.

---

### `hele_shaw_ferrofluid.glsl`

#### `gapWidth` (float)
- **Range**: 0.1 – 2.0  |  **Default**: 0.8
- **Physical meaning**: Scales the Hele-Shaw gap parameter b in b²/12η
- Narrower gap → more viscous Darcy flow → wider, smoother fingers
- Wider gap → less viscous → narrower, more labyrinthine fingers

#### `dropletMode` (float)
- **0.0**: Labyrinthine finger pattern (injection scenario)
- **1.0**: Isolated droplets elongating and splitting in a carrier fluid
- **Blending**: Intermediate values create hybrid scenarios

---

### `neural_ferrofluid.glsl`

#### `neuronCount` (float → int)
- **Range**: 4 – 48  |  **Default**: 24
- **Layout**: Automatically arranges in a perturbed hexagonal grid
- High count → dense cortical-column-like packing

#### `waveMode` (float)
- **0.0**: Focal activation — one neuron fires, others respond locally
- **1.0**: Global oscillation — all neurons synchronize
- **2.0**: Spreading depression wave — slow wave propagates from left edge (migraine aura analog)

#### `synapticStrength` (float)
- **Range**: 0.0 – 2.0  |  **Default**: 0.8
- Controls coupling distance and strength between neurons
- High values → long-range connections → rapid global synchrony
- Low values → isolated local clusters → fragmented activation patterns

---

### `biot_savart_coil.glsl`

#### `coilRadius` (float)
- **Range**: 0.05 – 0.5  |  **Default**: 0.25
- Sets the physical size of the current loop as a fraction of the normalized coordinate space
- The coil appears as two wire dots at (±coilRadius, ±sep) in the cross-section view

#### `helmholtzMode` (float)
- **0.0**: Single loop — non-uniform field, strong at center, reversal outside
- **1.0**: Helmholtz pair (same direction) — nearly uniform field in the central region
- **2.0**: Anti-Helmholtz (opposite directions) — gradient field, zero at center; used in atom traps

---

### `inverse_ferrofluid.glsl`

#### `chainMode` (float)
- **0.0**: Independent droplets — each droplet behaves separately
- **0.5**: Weak chaining — droplets begin to elongate toward each other
- **1.0**: Full chaining — droplets merge into wormlike columns along field lines

#### `dropletCount` (float → int)
- **Range**: 1 – 20  |  **Default**: 8
- More droplets → denser carrier fluid appearance, more coalescence events

---

### `crystal_ferrofluid.glsl`

#### `crystalAge` (float)
- **Range**: 0.0 – 1.0  |  **Default**: 0.6
- **0.0**: Fresh ferrofluid — fully liquid, classic spike appearance
- **0.5**: Mid-crystallization — partially frozen, mixed fluid/mineral regions
- **1.0**: Fully crystallized — mineral facets, no fluid motion

#### `latticeSymmetry` (float → int)
- **Meaningful values**: 3, 4, 6
- **3**: Trigonal/hexagonal symmetry (natural magnetite) — spokes at 120°
- **4**: Cubic symmetry — 90° growth directions (iron/magnetite cubic phase)
- **6**: High-symmetry hexagonal — six preferred directions; densely faceted appearance

#### `dendriticMode` (float)
- **0.0**: Faceted euhedral crystal — flat cleavage planes, angular geometry
- **0.5**: Mixed — dendritic branches terminating in faceted tips
- **1.0**: Pure dendritic — fractal branching, no flat faces

---

## Parameter Interaction Map

```
magnetStrength ──────┐
                     ├──► spike HEIGHT ──► spikeSharpness ──► spike WIDTH
susceptibility ──────┘

surfaceTension ─────────► spike threshold and HEIGHT (inverse)

gravity ────────────────► Rosensweig wavelength (spike SPACING)

viscosity ──────────────► wave DAMPING, rotation LAG, response SPEED

fieldOscillation ───────► animation SPEED of all field changes
```

## Recommended Presets

### Classic Ferrofluid (Sachiko Kodama aesthetic)
```
magnetStrength = 4.0, susceptibility = 2.5, surfaceTension = 1.0,
spikeSharpness = 1.8, gravity = 1.0, viscosity = 1.2
```

### Violent Eruption
```
magnetStrength = 8.0, susceptibility = 4.0, surfaceTension = 0.3,
spikeSharpness = 2.5, gravity = 0.5, fieldOscillation = 3.0
```

### Slow, Heavy, Molten
```
magnetStrength = 3.0, susceptibility = 2.0, surfaceTension = 2.5,
spikeSharpness = 0.8, gravity = 1.5, viscosity = 4.5
```

### Zero-Gravity Dream
```
magnetStrength = 5.0, susceptibility = 3.0, surfaceTension = 0.5,
gravity = 0.0, spikeSharpness = 2.0, fieldOscillation = 0.4
```

### Neural Storm
```
// neural_ferrofluid.glsl
magnetStrength = 7.0, susceptibility = 3.5, surfaceTension = 0.4,
neuronCount = 40, synapticStrength = 1.5, waveMode = 1.0
```

### Crystallizing at the Threshold
```
// crystal_ferrofluid.glsl
magnetStrength = 4.5, crystalAge = 0.55, dendriticMode = 0.6,
latticeSymmetry = 4.0, fieldOscillation = 0.08
```
