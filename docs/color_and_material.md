# Ferrofluid Color and Material

## Why Is Ferrofluid Black?

Ferrofluid appears **jet black** because of the physics of light interaction with its iron oxide nanoparticles.

### Absorption Mechanism

The particles in ferrofluid are **magnetite** (Fe₃O₄) nanoparticles, typically 8–12 nm in diameter. At this size:

1. **Broadband absorption**: Magnetite has high imaginary refractive index across the visible spectrum (400–700 nm). Unlike many pigments which absorb selectively, magnetite absorbs nearly all wavelengths equally. There is no selective reflection.

2. **Scattering is suppressed**: Particles of ~10 nm diameter are far smaller than visible light wavelengths (400–700 nm). In this Rayleigh scattering regime, scattering intensity ∝ d⁶/λ⁴ — the tiny particle size means almost no light is scattered back. The light that enters is absorbed, not scattered.

3. **Optical thickness**: Even a thin layer of ferrofluid (0.1 mm) contains enough particles to absorb essentially all incident light. The fluid is optically opaque well before it is geometrically thick.

**Result**: Ferrofluid appears the darkest, most absolute black of almost any naturally occurring liquid. It absorbs >99% of incident visible light.

### Thin Edges: The Brown Transmission Effect

At the very edge of a ferrofluid pool, where the film is only a few microns thick:
- The particle density is so low that some light passes through
- Magnetite has a reddish-brown absorption edge in the near-infrared
- The transmitted color is a dark reddish-brown — the "true" color of dilute magnetite suspension

This edge effect is subtle and only visible in certain lighting conditions, but it reveals the true color of the material beneath the optical thickness.

---

## How to Light Ferrofluid

The black surface of ferrofluid creates extreme lighting challenges. Traditional "illuminate evenly from all sides" doesn't work — you just get a uniformly dark blob. The effective lighting strategies are:

### 1. Grazing Light (Side Lighting)

Place the light source at a very low angle, nearly parallel to the ferrofluid surface. This creates:
- **Specular highlights** on spike tips and curved surface features (the metal-like glint)
- **Meniscus backlight** at the edges of spikes where the thin film transitions to air
- **Shadow definition** in valleys between spikes, emphasizing the 3D topology

This is the dominant lighting technique in professional ferrofluid photography. The spikes appear as a forest of dark trees with glowing edges.

### 2. Backlight (Transmitted Light)

Place the light source **beneath** a thin ferrofluid pool (requires glass bottom container):
- The body of the fluid blocks all light → appears black
- Thin meniscus edges transmit the reddish-brown edge color
- Moving spikes appear as dark shapes against a bright or colored background

This technique is used in macro video work (Roman De Giuli) and in some of Kodama's installations.

### 3. Projected Color Mapping

Because the ferrofluid surface is a perfect matte black absorber, it is also a perfect projection screen for structured light:
- Project colored light from above → colors appear exactly where projected
- The fluid is not reflective enough to wash out the projection
- As spikes move, they carry the projected color/texture with them
- This enables real-time projection-mapped ferrofluid (spike tips can appear to glow different colors based on position)

### 4. UV / Fluorescent Carrier

Some ferrofluid formulations use a UV-fluorescent carrier fluid (or the fluid can be mixed with a small amount of fluorescent dye):
- Under UV illumination, the base fluid glows
- The iron particles are black even under UV → they appear as dark inclusions in a glowing field
- Spikes appear as glowing forms with dark magnetic veins

This is rarely used commercially but creates a striking inverted aesthetic.

---

## Surface Properties

### Specular Reflection

Ferrofluid has a very high **surface reflectance** in the mirror-like (specular) sense. When the surface is flat and calm:
- The surface acts like a perfect black mirror
- Clear reflections of overhead objects are visible
- This is aesthetically identical to a black-lacquer surface or calm oil

The mirror quality is often emphasized in ferrofluid photography by using high-contrast compositions (white object reflected in black pool).

When spikes form, the smooth mirror surface is replaced by the complex topography of hundreds of curved spike surfaces. The reflections become fragmented, multiple, and distorted — a mirror that has broken into a forest.

### Contact Angle and Wettability

Ferrofluid has a low contact angle with most surfaces (it wets easily). This means:
- It spreads across surfaces it contacts
- It is notoriously difficult to contain — it climbs glass walls, seeps through microscopic gaps
- The **meniscus** at the fluid-container interface is thick and rounded

The wettability creates the characteristic **"pooling" behavior**: ferrofluid doesn't sit in a crisp pool with vertical walls; it creeps up the sides of its container, leaving a thin ring of magnetic contamination.

### Surface Tension Value

Ferrofluid surface tension γ ≈ 0.02 – 0.05 N/m (oil-based), lower than water (0.072 N/m). This means:
- Smaller capillary length: l_c = √(γ/ρg) ≈ 1.3 – 2 mm (vs ~2.7 mm for water)
- Spikes have smaller spacing (hexagonal lattice spacing ~ 8–12 mm)
- More "spiky" appearance at small scales

---

## Color Modes in the Shaders

The GLSL shaders support several `colorMode` options. Here is the physical/artistic justification for each:

### `black` (default)

The physically accurate mode. The fluid body is `vec3(0.0)` — absolute black. The only visible color comes from:
- **Edge meniscus**: thin bright line at the fluid surface (grazing light simulation)
- **Specular glint**: point highlight at spike tips

Color: `vec3(0.12, 0.16, 0.22)` — a slightly blue-biased white. This matches the color temperature of studio lighting reflected off a nearly-black surface with slight subsurface scattering.

### `blue_edge`

An enhanced version of the edge glow, pushing the meniscus color toward a deep cobalt blue. This evokes:
- Ferrofluid lit by a blue LED ring light (common in commercial photography)
- The suggestion of electrical charge at the surface
- An "underwater" quality — fluid from the deep

Color progression: `vec3(0.05, 0.12, 0.4)` at the meniscus, `vec3(0.0)` in the body.

### `gold_highlight`

Simulates warm incandescent side-lighting, which gives the spike tips a gold/amber glint. This is associated with:
- The Sachiko Kodama aesthetic — warm light, organic feel
- Ferrofluid as precious metal (liquid gold)
- Biomechanical reference: the gold sheen of insect carapaces, beetle shells

Color: `vec3(0.6, 0.4, 0.08)` at spike tips, fading to black.

### `rainbow`

A non-physical mode that maps the magnetic field strength to hue using HSV color space. High-field regions (spike tips) → warm colors (red/orange); low-field regions (base) → cool colors (blue/violet). This mode is:
- Useful for debugging field calculations (makes field topology visible)
- A reference to scientific false-color field visualization
- Aesthetically related to oil-film iridescence

---

## Material Design Notes

### Spike Tip Highlights

The bright spot at a spike tip is physically caused by the concentration of curvature — the spike tip is the point of highest Gaussian curvature on the surface, so it catches grazing light at the widest range of angles. In the shader, this is approximated by:

```glsl
float tipBrightness = pow(spikeHeight, 1.5) * edgeFactor;
```

The `pow(1.5)` ensures tips are disproportionately bright relative to the base, matching the real visual hierarchy.

### The Meniscus at the Container Wall

In real ferrofluid, the contact line where the fluid meets the container wall creates a thick curved meniscus. This meniscus is often the brightest part of the image under grazing light. In the shaders, this is not explicitly modeled (the containers have no walls), but the edge glow approximates it.

### Viscosity and Visual Quality

Higher viscosity ferrofluid:
- Has a more "heavy" feel — spikes form slowly, collapse slowly
- Maintains sharper spike geometry (less surface wave noise)
- Has a richer, more molten appearance

Lower viscosity:
- Surface is more responsive, more "alive"
- More wave activity at the surface
- Spike geometry is softer, more rounded

This maps to the `viscosity` uniform: high values → sharp-edged, slowly evolving shapes; low values → dynamic, wavy, softer forms.

---

## Photography and Rendering Reference

For matching real ferrofluid photography in renders or shaders:

| Property | Value |
|----------|-------|
| Base albedo | 0.01 – 0.02 (extremely dark) |
| Specular reflectance | 0.04 – 0.08 (dielectric-like, despite metal content) |
| Roughness at flat surface | 0.01 – 0.05 (near-mirror) |
| Roughness at spike surfaces | 0.05 – 0.15 |
| IOR (approximate, visible) | 1.7 – 2.0 |
| Edge transmission color | rgb(0.25, 0.12, 0.05) normalized — dark reddish-brown |
| Surface normal variation | High at spike array, zero at flat pool |

The counter-intuitive property: ferrofluid, despite containing metal nanoparticles, does not behave as a metallic reflector. The iron particles are too small and too dispersed. The macroscopic optical behavior is closer to a very dark, slightly glossy ceramic or graphite.

---

## References

- Odenbach, S. (2002). *Ferrofluids: Magnetically Controllable Fluids and Their Applications*. Springer Lecture Notes in Physics. (Chapter 6: Optical properties)
- Elborai, S., Kim, D.-K., Liu, X., & Allen, M.G. (2005). Self-assembled, aligned ferrofluid composites and their use in optical applications. *Journal of Applied Physics*.
- Philip, J. & Laskar, J.M. (2012). Optical properties and applications of ferrofluids. *Journal of Nanofluids*, 1(1).
