# Magnetic Field Visualization Reference

## How to See the Invisible

Magnetic fields are, strictly speaking, invisible. You cannot look at a magnetic field. What you can do is look at things that reveal the field's topology: iron filings, compass needles, ferrofluid spikes, and — in this repository — GLSL shaders.

This document is a reference for the visual vocabulary of magnetic field topology. What field line patterns mean. Where the saddle points are. What makes a Halbach array look different from a dipole. The language of Maxwell's equations, translated into what you actually see on screen.

---

## Field Line Fundamentals

### What a Field Line Means

A magnetic field line at any point is tangent to the magnetic field vector **B** at that point. Field lines are a continuous, smooth family of curves that fill all of space.

**Conventions**:
- Field lines emerge from **north** poles and enter **south** poles (outside the magnet)
- Inside a magnet, field lines run from south to north (completing the circuit)
- Field lines **never cross** — because at any single point, **B** has only one direction
- Field lines **never begin or end** in free space — they form closed loops (∇·**B** = 0)

**Density encodes strength**: Where field lines are closely spaced, the field is strong. Where they are widely spaced, the field is weak. This is not a convention — it is the mathematical content of ∇·**B** = 0.

### Field Line Topology vs. Field Strength

These are two different things:

| Concept | What it Shows | Visualization Method |
|---------|--------------|---------------------|
| Field topology | Direction of **B** at every point | Streamlines / field lines |
| Field strength | Magnitude |**B**| at every point | Color map / heat map |
| Field gradient | ∇|**B**| — where the field changes fastest | Arrow field / gradient color |
| Flux | ∫ **B** · d**A** | Density of field lines per area |

A visualization that shows ONLY field lines (e.g., iron filings) tells you direction and density but not the absolute strength. A heat map of |**B**| tells you strength but not direction. The best visualizations show both simultaneously.

---

## Dipole Field Topology

### The Point Dipole Pattern

The most common magnetic source in ferrofluid work is a small permanent magnet, treated as a magnetic dipole with moment **m**. Its field pattern is:

```
B_r(r, θ)     = (μ₀/4π) · 2m cosθ / r³
B_θ(r, θ)     = (μ₀/4π) · m sinθ / r³
|B|(r, θ)      = (μ₀/4π) · m √(1 + 3cos²θ) / r³
```

where θ is the polar angle from the dipole axis.

**Key features**:
- **Poles** (θ = 0, π): |**B**| = μ₀m/2π r³ — strongest field, field lines purely radial
- **Equator** (θ = π/2): |**B**| = μ₀m/4π r³ — weakest field (half pole strength), field lines tangential
- **Null plane**: There is no null point in a dipole field — the field is nonzero everywhere except at infinity
- **Fall-off**: |**B**| ∝ r⁻³ — the field falls much faster than, say, a current-sheet field (r⁻¹)

### The Figure-8 Topology

In a cross-section containing the dipole axis, the field lines form a characteristic "figure-8" or "butterfly" pattern:
- Above and below the magnet (along the axis): tight, focused field lines pointing up through both N and S
- At the sides (equatorial plane): field lines bow out far from the magnet and curl back

The "waist" of the figure-8 is at the magnet position. This topology is exactly what ferrofluid spikes reveal: the spike directly above the magnet points along the axis; spikes further away in the equatorial plane point more horizontal.

### In GLSL

Field line visualization using the stream function approach (from `biot_savart_coil.glsl`):
```glsl
// The Stokes stream function Ψ for a dipole is:
// Ψ = (μ₀m/4π) · sin²θ / r
// Field lines are iso-Ψ curves.
float streamFn = (p.x * p.x + p.y * p.y) / length(p - magnetPos);  // approximate
float fieldLine = smoothstep(0.01, 0.0, abs(fract(streamFn * 8.0) - 0.5) - 0.01);
```

---

## Field Topology Features

### Null Points (Zeros of B)

A null point is a location where |**B**| = 0 — where the field vector vanishes. These are topologically significant: field lines cannot be defined here (no direction), and the topology of the field fundamentally changes character at these points.

**Types of null points** (in 3-D, Parnell & Galsgaard classification):
- **A-type (proper null)**: Radial null with fan plane
- **B-type (improper null)**: Three eigenvalues, not all real

**In 2-D (cross-section view)**:
- **O-point**: Field lines encircle it in closed loops — like the center of a magnetic island
- **X-point (saddle point)**: Four separatrices cross here; field lines approach along two directions and leave along two others

**For ferrofluid**: Null points are "dead zones" — the fluid is not attracted there. In `glitch_ferrofluid.glsl`, the simulated dead zone is a field null:
```glsl
// Dead zone creates a null at a random location
float dead = 1.0 - smoothstep(deadRadius * 0.5, deadRadius, length(p - deadCenter));
B *= (1.0 - dead * amount);
```

The flat circle of undisturbed fluid surrounded by spikes is the visual signature of a local field null.

### Separatrices

Separatrices are the special field lines that divide space into regions of different field topology. In a two-magnet system, the separatrix divides the field into regions "belonging" to each magnet.

**Visual signature**: The separatrix is where field-line competition becomes visible. In `multi_magnet.glsl`, the region between two magnets where their fields cancel shows depleted spike height — that's the separatrix.

**Finding separatrices programmatically**: They pass through null points and X-points. In 2-D, the separatrix from an X-point is the curve along which |**B**| is locally minimum.

### Flux Tubes

A flux tube is a bundle of field lines enclosed by a surface that field lines do not cross. It carries a fixed total flux Φ = ∫ **B** · d**A**.

As a flux tube narrows (e.g., near a spike tip), the field lines converge → **B** increases. This is why the spike tip has the strongest field: it is a natural flux concentrator. The narrow tip of the spike acts as a converging lens for magnetic flux.

**Ferrofluid intuition**: The spike grows because it IS a flux tube. The fluid reaches up toward the magnet because in so doing, it increases the field at its tip (fewer competing field lines → higher local **B**). The spike is a self-organizing flux concentrator.

---

## Visualization Techniques in the Shaders

### Technique 1: Iso-Contour Lines (Field Lines)

Map the stream function (or magnetic potential) to discrete levels:
```glsl
float fieldStrength = dipoleField(p - magnetPos, strength);
// Draw field lines as level sets of cumulative field
float isolevel = fract(fieldStrength * density);
float line = smoothstep(lineWidth, 0.0, abs(isolevel - 0.5) - 0.5 + lineWidth);
```

**Used in**: `multi_magnet.glsl` for the field-line texture.

**Note**: This shows iso-surfaces of field STRENGTH, not true field lines (which are iso-surfaces of the vector potential). For dipole fields, the distinction matters near the equatorial plane.

### Technique 2: Heat Map (Strength Color)

Map |**B**| to a color gradient:
```glsl
float B = dipoleField(p - magnetPos, strength);
// HSV colormap: blue (weak) → red (strong)
vec3 heatColor = hsv2rgb(vec3(0.67 - 0.67 * clamp(B / maxB, 0.0, 1.0), 1.0, 1.0));
```

**Used in**: `biot_savart_coil.glsl` background, `cosmic_ferrofluid.glsl` prominence coloring.

**Best for**: Showing where the field is strongest — useful for debugging field calculations and for showing the gradient structure.

### Technique 3: LIC (Line Integral Convolution) Approximation

True LIC requires a texture convolution along field lines. In fragment shaders, an approximation:
```glsl
// Sample noise along field direction
vec2 H = normalize(dipoleFieldVec(p - mp, 1.0));
vec2 perp = vec2(-H.y, H.x);
// Average noise along the perpendicular → smear parallel to H
float lic = mix(noise(p * 20.0), noise(p * 20.0 + perp * 0.02), 0.5) * 0.5
           + mix(noise(p * 20.0 - perp * 0.02), noise(p * 20.0), 0.5) * 0.5;
```

This gives the characteristic "fiber" texture of LIC images where texture runs along field lines.

### Technique 4: Arrow Field

Sample the field at grid points and draw small arrows:
```glsl
// Discretize space to a grid
vec2 cell = floor(p / gridSpacing) * gridSpacing + gridSpacing * 0.5;
vec2 H = normalize(dipoleFieldVec(cell - mp, 1.0));
// Draw arrow: SDF of an arrow glyph at cell center pointing along H
float arrow = arrowSDF(p - cell, H, arrowLength, arrowHeadSize);
```

Used for: Showing field direction at a glance. Less informative about strength than heat maps; more legible than LIC for presentation purposes.

### Technique 5: Field Gradient (∇|B|) Visualization

The Kelvin force on ferrofluid is proportional to ∇|**B**|². Visualizing this force field directly shows where the fluid will move:
```glsl
// Numerical gradient via finite difference
float eps = 0.001;
float Bp = dipoleField(p + vec2(eps, 0) - mp, strength);
float Bm = dipoleField(p - vec2(eps, 0) - mp, strength);
float dBdx = (Bp - Bm) / (2.0 * eps);
// Repeat for y...
vec2 gradB = vec2(dBdx, dBdy);
// Arrow pointing along gradB shows where the fluid will go
```

The gradient visualization is particularly useful for understanding why ferrofluid climbs a magnet: the gradient always points toward the magnet, pulling the fluid with it.

---

## Multi-Magnet Topology

### Two-Magnet Systems

When two magnets are placed near each other, their fields superpose and create topologically interesting structures.

**Same pole facing**: The fields reinforce on the outside (strong regions near each magnet) but cancel between them. A null point forms between the magnets. The separatrix runs through this null point, dividing space into two regions. Ferrofluid shows: two spike clusters with a flat "dead zone" between them.

**Opposite poles facing**: The fields add between the magnets — strong central field. Field lines run directly from N to S pole, creating a concentrated flux tube between them. Ferrofluid shows: a "bridge" of spikes between the two magnets, with a spike-free zone on the outside.

**Side-by-side (parallel poles)**: More complex topology with a saddle point above and below the midpoint. Field lines run up and away from both magnets, curving back to meet. Ferrofluid shows: a hexagonal array pattern between them with spike competition zones.

### Hexagonal Symmetry from Three-Magnet Rosensweig

The classic Rosensweig experiment uses a single magnet below a large ferrofluid pool. The resulting spike pattern is hexagonal. But why hexagonal? Three-wave resonance:

Three modes with wavenumbers k₁, k₂, k₃ where |k₁| = |k₂| = |k₃| = k_c and k₁ + k₂ + k₃ = 0 can satisfy resonant triad coupling. This is exactly the structure of the hexagonal lattice (three basis vectors at 60° to each other summing to zero).

**Visualization**: In `multi_magnet.glsl` with magnetCount = 3 and magnets arranged in an equilateral triangle, the hexagonal global ordering becomes visible as a natural emergent property.

---

## Color Mapping Reference

### Physical Color Modes

| Mode | Physical Justification | Use Case |
|------|----------------------|---------|
| `black` | Jet black ferrofluid, grazing-light edge glow | Realistic; default |
| `blue_edge` | LED ring-light photography aesthetic | Commercial ferrofluid photography look |
| `gold_highlight` | Warm incandescent side-lighting | Organic, biological feel (Kodama aesthetic) |
| `rainbow` | Scientific false-color field mapping | Debugging, educational |

### Perceptual Considerations

**Field line visibility**: For field lines to be clearly visible, they should have high contrast with the background. Cool blue on near-black works well; blue on deep-blue does not.

**Edge glow color temperature**: The physical meniscus color depends on the light source color temperature. Studio strobe lights (5500K) produce a very slightly blue-white glint; tungsten sources (3200K) produce warm gold. The shaders encode this distinction in the edge color vectors:
- Cool: `vec3(0.12, 0.16, 0.24)` — blue-biased white (daylight)
- Warm: `vec3(0.22, 0.18, 0.10)` — amber (tungsten)

**Rainbow maps**: The default rainbow gradient (blue → cyan → green → yellow → red) has poor perceptual uniformity — different colors at the same luminance level appear to have different magnitudes. For scientific visualization, prefer:
- **Viridis** (perceptually uniform, colorblind-safe): `vec3(0.267-1.26*t, 0.005+1.295*t, 0.329-1.029*t)` (approximation)
- **Plasma**: `vec3(0.050+2.72*t-3.27*t², 0.017+0.84*t-0.85*t², 0.527+0.43*t-2.5*t²)` (approximation)

---

## Topology of Specific Configurations in This Repository

### `basic_ferrofluid.glsl`
**Topology**: Single upward-pointing dipole. One spike cluster directly above the magnet. Field lines fan out in the equatorial plane. No nulls in the viewing region. Monotonically decreasing |**B**| away from the magnet.

### `multi_magnet.glsl`
**Topology**: Superposition of N dipole fields. Nulls appear where opposing fields cancel — visible as flat "dead zones." Near a null, the fluid surface is flat; away from it, the competing magnets produce hexagonal arrays. The orbit of magnets creates a continuously evolving topology.

### `vortex_field.glsl`
**Topology**: A rotating dipole. The field at any instant is a dipole, but the time-averaged field has cylindrical symmetry (the magnet visits all angular positions). The lagged fluid response creates a "wake" — a trailing region of elevated field behind the current magnet position. The spiral arm topology mirrors galactic spiral arms, which are also trailing wakes in a rotating system.

### `labyrinthine_ferrofluid.glsl`
**Topology**: In-plane (tangential) rotating field. The topology here is 2-D magnetization domain topology, not 3-D field topology. The domain walls are the separatrices between regions magnetized in opposite directions. As the field rotates, the domain walls rotate — but with lag — creating labyrinthine structures.

### `halbach_array.glsl`
**Topology**: Periodic field with exact 2π/λ periodicity in x and exponential decay in y. On the strong side: alternating up/down flux tubes spaced at λ/2. On the weak side: near-exact cancellation (exponentially small residual). The field has an infinite set of null planes at y = y₀ + nλ/2 (half-period spacing above the weak side).

### `biot_savart_coil.glsl`
**Topology**: Full circular current loop topology. Key feature: a **ring null** at r = R√(something), z = 0 where the axial field changes sign. Outside r = R, the field at the equatorial plane points DOWNWARD (opposite to inside). This creates a ring of suppressed spike height in the fluid — a donut-shaped low-field region surrounding the central spike cluster.

---

## Further Reading

- Griffiths, D.J. (2017). *Introduction to Electrodynamics* (4th ed.). Cambridge University Press. Chapters 5–6 cover magnetostatics and field topology.
- Stern, D.P. (1996). A brief history of magnetospheric physics before the spaceflight era. *Reviews of Geophysics*, 34(1). (Extended discussion of field line topology in planetary fields)
- Parnell, C.E. & Galsgaard, K. (2004). Elementary heating events — magnetic interactions between two flux sources. *Astronomy & Astrophysics*, 428. (Null point topology classification)
- Rosensweig, R.E. (1985). *Ferrohydrodynamics*. Chapter 6: Static shape of a ferrofluid surface. (Full treatment of spike topology and pattern selection)
- Twombly, C.M. & Thomas, J.W. (1983). Bifurcating instability of the free surface of a ferrofluid. *SIAM Journal on Mathematical Analysis*, 14(4). (Mathematical topology of the bifurcation)
