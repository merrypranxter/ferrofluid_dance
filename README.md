# FERROFLUID DANCE
## Magnetic Fluid Spikes, Field Line Visualization, Black Liquid Geometry

> *"The fluid doesn't want to be beautiful. It wants to obey. It wants to follow the invisible lines of force that hold it in place. The spikes aren't decoration — they're compliance. The black liquid is an army of iron particles standing at attention, saluting a magnet it will never touch."*

---

## WHAT THIS IS

This repo is a visual knowledge pack for **ferrofluid simulation** — the strange, alien behavior of magnetic fluid under the influence of moving magnetic fields.

You have `slime_molds`, `fungi`, and `crystalline` — all organic growth patterns. But you have NOTHING that captures this specific intersection of **liquid + magnetism + spikes + black aesthetic**. It's the "weird science" repo your collection is crying out for.

Ferrofluid is jet-black, oily, and when exposed to a magnetic field it grows spikes that follow field lines. It's simultaneously biological (it looks like a sea urchin, a fungus, a nervous system) and completely mechanical (it's obeying Maxwell's equations, nothing more).

When RepoScripter ingests this alongside `kirlian_discharge`, ` Lichtenberg_burn`, or `plasma_cosmology_vis`, expect the AI to create electric-magnetic-organic hybrid systems. A ferrofluid that also discharges plasma. A lightning bolt captured in oil.

---

## CORE CONCEPTS

### 1. Magnetic Susceptibility
Ferrofluid contains nanoscale iron oxide particles (magnetite, Fe₃O₄) suspended in a carrier fluid (usually oil). When magnetized:
- Particles align with field lines
- Regions of high field gradient pull fluid toward them
- Surface tension resists, creating characteristic spike pattern
- The spikes ARE the field lines made visible

### 2. Rosensweig Instability
The mathematical description of why spikes form:
- Normal magnetic field + gravity → flat surface
- When field exceeds critical value: surface becomes unstable
- Wavelength of instability depends on surface tension, gravity, magnetization
- Result: hexagonal array of spikes (nature loves hexagons)

### 3. Dynamic Field Manipulation
Moving magnets create moving spikes:
- **Rotation**: Spiral patterns, vortex filaments
- **Oscillation**: Breathing spikes, wave propagation through fluid
- **Multiple magnets**: Spike competition, field line superposition, complex interference patterns
- **Field collapse**: When magnet is removed, spikes collapse in milliseconds — a fast, violent relaxation

### 4. The Black Aesthetic
Ferrofluid is literally black because:
- Iron oxide nanoparticles absorb all visible wavelengths
- The carrier oil is transparent but the colloid is opaque
- At thin edges, it can appear brownish (transmission)
- When illuminated from the side, edges glow with a thin meniscus of light

---

## MATHEMATICAL FOUNDATION

### Magnetic Field from a Dipole
```
B(r) = (μ₀/4π) * [3(m·r̂)r̂ - m] / r³
```
Where m is the magnetic moment, r is position vector, r̂ is unit vector.

### Rosensweig Instability Critical Field
```
B_c = √(2μ₀ρg/μ₀χ) * √(1 + l_c²/l_γ²)
```
Where ρ is density, g is gravity, χ is magnetic susceptibility, l_c and l_γ are capillary lengths.

### Spike Height Approximation
```
spikeHeight ≈ (magnetDistance)^(-2.5) * (susceptibility) * (1/surfaceTension)
```
Closer magnet = taller spikes. Stronger fluid = taller spikes.

### Surface Energy Minimization
The ferrofluid surface finds a shape that minimizes:
```
E = E_gravity + E_surfaceTension + E_magnetic
```
This is why spikes form — the magnetic energy gain outweighs the surface tension cost.

---

## INSIDE THE BOX (Fundamentals)

### Basic Ferrofluid Simulation
See `code/basic_ferrofluid.glsl` — dipole field visualization with spike approximation. Simple, elegant, immediately recognizable as ferrofluid.

### Multi-Magnet Field Superposition
See `code/multi_magnet.glsl` — two or more magnets creating interference patterns. Spike competition zones. Field line crossovers.

### Rotating Field Vortex
See `code/vortex_field.glsl` — rotating magnet creates spiral arm structures in the fluid. Galaxy-like patterns from simple rotation.

### Oscillating Spike Wave
See `code/oscillating_spikes.glsl` — magnet moved up and down creates traveling wave through spike array. Liquid that dances.

---

## OUTSIDE THE BOX (Creative Destinations)

### Emotional Ferrofluid
The fluid responds to emotional input:
- **Calm**: Flat, smooth, mirror-like surface
- **Anger**: Violent spikes, rapid oscillation, fluid splashing
- **Fear**: Erratic, twitching micro-spikes, nervous trembling
- **Joy**: Rhythmic, flowing waves, organic spiral growth
- **Grief**: Slow collapse, spikes falling like tears, pool of flat black

### Biological Ferrofluid
The spikes are not mechanical — they're alive:
- **Growth**: Spikes lengthen and branch like coral
- **Predation**: Large spikes consume small spikes
- **Reproduction**: When a spike reaches critical height, it splits into two
- **Death**: Old spikes lose magnetization and dissolve back into flat fluid
- **Evolution**: The fluid develops more efficient spike arrangements over time

### Cosmic Ferrofluid
Scale it up to astronomical:
- A planet-sized ferrofluid moon orbiting a magnetar
- Solar prominences as ferrofluid spikes on the sun's surface
- Galaxy filaments as magnetic field lines in a cosmic ferrofluid
- Black hole accretion disks with ferrofluid magnetohydrodynamics

### Ferrofluid Architecture
Build structures with it:
- **Ferrofluid walls**: Panels of fluid held in place by embedded magnets
- **Ferrofluid furniture**: Chairs that reshape when you sit
- **Ferrofluid sculpture**: Art that changes every time you move a magnet nearby
- **Ferrofluid architecture**: Buildings with walls that breathe and reshape

### Ferrofluid as Data
The spike pattern IS information:
- **Binary**: Spikes up = 1, flat = 0
- **Frequency encoding**: Spike height = amplitude, spike density = frequency
- **Image display**: An array of magnets under a ferrofluid pool creates a grayscale image in the spike heights
- **Neural network**: Ferrofluid + magnet array = physical neural network, spikes = activation states

### Ferrofluid Glitch
Corrupted magnetism:
- Magnets with non-uniform fields create "sick" spikes — bent, twisted, malformed
- Rapid field reversal causes spike "strobe" — fluid can't keep up, creates ghost images
- Partial magnetization — some particles align, others don't, creating patchy, diseased-looking growth
- "Dead zones" in the magnet create flat circles surrounded by spikes — wounds in the field

---

## BLENDING WITH OTHER REPOS

**+ `kirlian_discharge`** → Ferrofluid that also corona-discharges. Electric spikes + magnetic spikes. The fluid becomes a plasma conductor.

**+ `plasma_cosmology_vis`** → Birkeland currents THROUGH ferrofluid. The fluid traces magnetic field lines that are also carrying plasma currents. Electric universe made visible.

**+ `crystalline`** → Ferrofluid that forms crystal lattices. Magnetic fields as crystal growth directors. Iron oxide nanoparticles arrange into mineral structures.

**+ `fungi`** → Mycelial ferrofluid. Branching hyphal networks that follow field lines. Spore release triggered by magnetic pulses. The fluid is a fungal colony.

**+ `Lichtenberg_burn`** → Dielectric breakdown patterns captured in ferrofluid. Lightning burned into oil. The fluid records electrical trauma like a photograph.

**+ `neural_architecture`** → Ferrofluid as brain tissue. Neurons as magnetic field lines. Synapses as spike junctions. Thought as magnetic topology.

---

## ARTISTIC REFERENCES

- **Sachiko Kodama** — ferrofluid sculpture pioneer. "Protrude, Flow" series.
- **Zelf Koelman** — "Ferrolic" clock. Ferrofluid + electromagnet array = living numbers.
- **Nils Völker** — ferrofluid + robot arms. Choreographed magnetic dance.
- **Roman De Giuli** — macro fluid art. Close-up fluid dynamics as abstract cinema.
- **Karl Sims** — evolutionary art, genetic algorithms for form generation.
- **Nam June Paik** — magnetism + CRT distortion. Early "glitch" aesthetic.
- **HR Giger** — biomechanical, black, organic-mechanical fusion. Ferrofluid is Giger in liquid form.
- **Zaha Hadid** — fluid architecture. Buildings that look like frozen ferrofluid.

---

## PARAMETER SPACE

| Parameter | Range | Effect |
|-----------|-------|--------|
| `magnetStrength` | 0.0-10.0 | How strong the magnetic field is |
| `magnetCount` | 1-20 | Number of magnetic sources |
| `susceptibility` | 0.1-5.0 | How responsive the fluid is |
| `surfaceTension` | 0.1-5.0 | Resistance to spike formation (high = smoother) |
| `viscosity` | 0.1-5.0 | How fast the fluid responds to field changes |
| `spikeSharpness` | 0.1-3.0 | How pointed vs. rounded the spikes are |
| `fieldOscillation` | 0.0-5.0 | Speed of field movement |
| `gravity` | 0.0-2.0 | 0 = weightless spikes, 1 = Earth gravity, 2 = heavy |
| `colorMode` | black/blue_edge/gold_highlight/rainbow | Edge lighting variations |
| `biologicalMode` | 0/1 | Enables growth, branching, death |
| `glitchAmount` | 0.0-1.0 | Field corruption and instability |

---

## REPOSCRIPTER INTEGRATION

When this repo is loaded into RepoScripter as context:
- **Magnetic field visualization** is the primary technique
- **Spike formation** is the signature visual — any prompt involving spikes, needles, black liquid, or magnetic phenomena should evoke this
- **Field line superposition** offers complex pattern generation from simple rules
- **The black aesthetic** is crucial — this is dark, oily, metallic, NOT bright or airy
- The AI should feel free to make ferrofluid represent: hair, coral, city skylines, sound waves, neural tissue, writing systems, trauma, compliance, obedience

---

## FILES

```
README.md                    <— You are here
context.manifest.json        <— RepoScripter ingestion manifest
code/
  basic_ferrofluid.glsl     <— Dipole field + spike approximation
  multi_magnet.glsl         <— Field superposition
  vortex_field.glsl         <— Rotating magnet spiral arms
  oscillating_spikes.glsl   <— Wave propagation through fluid
  emotional_ferrofluid.glsl <— Feeling drives magnetism
  biological_ferrofluid.glsl <— Growth, predation, evolution
  cosmic_ferrofluid.glsl    <— Astronomical scale
  glitch_ferrofluid.glsl    <— Corrupted field, sick spikes
docs/
  magnetism_physics.md      <— Real ferrofluid science
  rosenweig_instability.md  <— The math of spike formation
  ferrofluid_art_history.md <— Sachiko Kodama, Zelf Koelman, etc.
  color_and_material.md     <— Why it's black, how to light it
images/
  [placeholders for reference imagery]
```

---

## MANIFESTO

> *"Ferrofluid is the most honest substance in the world. It doesn't pretend. It doesn't have opinions. It just obeys. Put a magnet near it and it grows spikes — not because it wants to, but because the math demands it. The field lines are invisible, absolute, tyrannical. The fluid makes them visible. It is the only substance that shows you the shape of obedience. And the spikes are beautiful — not despite their compliance, but because of it. Nature is full of things that obey: crystals, snowflakes, galaxies. But ferrofluid obeys in real-time, right in front of you, reshaping itself to please a force it cannot see. There is something heartbreaking about that. Something deeply human."*

---

*FERROFLUID DANCE v1.0*
*For RepoScripter v7.7.7+*
*Created by Merry Pranxter's chaos consortium*
*"Black liquid geometry. Obedience made visible."*
