# Rosensweig Instability — The Math of Spike Formation

## Overview

The **Rosensweig instability** (also called the **normal-field instability**) is a spontaneous pattern-forming phenomenon at the free surface of a ferrofluid exposed to a sufficiently strong normal (perpendicular) magnetic field.

Below a critical field, the flat surface is stable. Above it, the surface spontaneously develops a hexagonal array of cone-shaped spikes. This is a **bifurcation** — a sudden jump from one stable configuration to another.

It was first described by R.E. Rosensweig in 1966 and analyzed theoretically by Cowley and Rosensweig in 1967.

---

## The Physical Mechanism

### Why the Flat Surface Becomes Unstable

Consider a flat ferrofluid surface with a uniform normal magnetic field H₀ (pointing upward, perpendicular to the surface).

Imagine a small perturbation: a bump of height ε appears at some point on the surface. What happens next?

**Stabilizing forces** (want to flatten the bump):
- **Gravity**: the bump has higher gravitational potential energy → gravity pulls it back down
- **Surface tension**: the bump increases surface area → surface tension resists

**Destabilizing force** (wants to grow the bump):
- **Magnetic field concentration**: the bump is a better conductor of magnetic flux than air → field lines concentrate at the tip → the magnetic field is stronger at the tip → the magnetic pressure `μ₀ M_n²/2` is larger → the bump is pulled further upward

When the destabilizing magnetic pressure exceeds the combined stabilizing effect of gravity and surface tension, the bump grows — the flat surface is unstable.

### Why Spikes, Not a Corrugated Sheet?

The instability has a preferred **wavelength** λ_c. This is because:
- Very short-wavelength perturbations (high curvature) are killed by surface tension
- Very long-wavelength perturbations are killed by gravity
- The most unstable mode has wavelength `λ_c = 2π l_c` where `l_c = √(γ/ρg)` (capillary length)

For a typical ferrofluid (oil-based):
- l_c ≈ 1.5 – 2.5 mm
- λ_c ≈ 10 – 15 mm
- Spike spacing ≈ 8 – 14 mm

The geometry that minimizes energy at supercritical fields is a **hexagonal array** of spikes (same reason bees use hexagons — it tiles the plane with minimum perimeter).

---

## Linear Stability Analysis

### Setup

Flat ferrofluid layer, depth h → ∞ (deep layer limit).  
Uniform normal field H₀ applied.  
Surface perturbation: ζ(x,y,t) = ε · exp(σt + ik·x)

Where:
- σ = growth rate (σ > 0 → instability)
- k = wavevector, |k| = wavenumber

### Dispersion Relation

After solving the coupled magnetic + hydrodynamic equations (Laplace for the field, Stokes for the fluid), the growth rate is:

```
σ²(k) = k/ρ · [μ₀ M² k / (1 + μᵣ) - γk² - ρg]
```

Wait — let me give the correct form. Neglecting viscosity (inviscid linear theory):

```
σ²(k) = (1/ρ) · [μ₀ (μᵣ-1)² H₀² k / (2μᵣ) - γk³ - ρgk]
```

Where:
- ρ = fluid density
- μᵣ = relative permeability = 1 + χ
- H₀ = applied field at the surface
- γ = surface tension
- g = gravitational acceleration
- k = wavenumber = 2π/λ

### Critical Wavenumber

The most unstable wavenumber k_c minimizes the stabilizing terms relative to the destabilizing term. Setting ∂σ²/∂k = 0:

```
k_c = √(ρg/γ) = 1/l_c
```

The critical wavenumber is set **only** by gravity and surface tension — independent of the field strength. The field strength determines whether this mode is unstable, not which mode.

### Critical Field

The field at which σ²(k_c) first becomes positive (onset of instability):

```
H_c = √(2/μ₀ · √(ρgγ) · μᵣ/(μᵣ-1)²)
```

Or equivalently, in terms of the critical magnetization M_c:

```
M_c = √(2√(ρgγ) / μ₀)  ·  (μᵣ / (μᵣ - 1))
```

For a ferrofluid with χ = 2 (μᵣ = 3), ρ = 1200 kg/m³, γ = 0.03 N/m:

```
H_c ≈ 10 – 15 kA/m
B_c = μ₀ H_c ≈ 12 – 18 mT
```

This matches experimental observations.

---

## Nonlinear Regime: Spike Amplitude

Beyond the linear threshold, spikes grow to finite amplitude. The leading-order nonlinear theory (Gailitis 1977) gives the spike height h as:

```
h ≈ A · √(ε)   near onset  (ε = (H - H_c)/H_c)
```

This is a **supercritical pitchfork bifurcation**: the spike amplitude grows continuously from zero at the critical field (no discontinuity, no hysteresis in the ideal case).

However, experiments show **hysteresis**: the field must be raised to H_up > H_c to first form spikes, but once formed, they persist until the field drops to H_down < H_up. This is due to nonlinear stabilization and the finite energy barrier between the flat and spiked states.

### Spike Height Approximation (for Real-Time Simulation)

For the shaders in this repository, a simplified scaling law is used:

```
h_spike ≈ C · B² · χ / (2 · γ · ρg)
```

Where C is a geometric constant (~0.1 – 0.3). This captures the correct scaling:
- Stronger field → taller spikes (B² dependence)
- Higher susceptibility → taller spikes
- Higher surface tension → shorter spikes
- Higher gravity → shorter spikes

For the dipole geometry (a point magnet above the surface), the field falls as r⁻³, so:

```
h_spike ∝ (d_magnet)^(-6) · m² · χ / (γ · ρg)
```

Where d_magnet is the distance from the magnet. This is why bringing a magnet close to ferrofluid creates dramatically taller spikes — the field is both stronger AND the gradient is steeper.

---

## Pattern Selection: Why Hexagons?

Near onset, the free energy of a periodic surface pattern can be expanded in mode amplitudes. For a 2-D pattern:

```
F = a₂A² + a₃A³ cos(3θ) + a₄A⁴ + ...
```

The cubic term `a₃` (from three-wave interaction) **favors hexagonal symmetry**: three modes at angles 0°, 60°, 120° with the same wavenumber k_c can mutually amplify each other (resonant triad). Square or stripe patterns lack this resonance.

For ferrofluid, the coefficient a₃ is negative near onset, which means the **hexagonal pattern is preferred**. (If a₃ > 0, stripes would be preferred.)

Observed pattern types as a function of field amplitude and direction:
- **Normal field, weak**: flat surface
- **Normal field, critical**: hexagonal spike array
- **Normal field, strong**: long-range hexagonal order, spike-to-spike competition
- **Tilted field**: stripes (field breaks the in-plane symmetry)
- **Rotating horizontal field**: traveling wave patterns, labyrinthine domains
- **Pulsed field**: transient spike-and-collapse dynamics

---

## Temporal Dynamics

### Growth Time

From viscous linear theory, the growth time scale near onset:

```
τ_growth ≈ ηk_c / (ρ · |σ²(k_c)|)
```

For typical ferrofluid (η ≈ 5 mPa·s): τ_growth ≈ 10 – 100 ms. This is why you can see spikes form in real-time when you move a magnet.

### Relaxation Time

When the field is removed, spikes collapse. The relaxation time is governed by:
1. **Viscosity**: high-viscosity fluids collapse slowly (100 ms – 1 s)
2. **Gravity**: restoring force proportional to ρg
3. **Surface tension**: helps restore flat surface

```
τ_relax ≈ η / (ρg l_c)
```

For typical ferrofluid: τ_relax ≈ 50 – 500 ms. The collapse is faster than formation because there is no longer a destabilizing force to overcome.

### Resonance

If the field oscillates at a frequency ω near the natural frequency of the spike:

```
ω_0 ≈ √(ρg k_c / ρ) = √(g/l_c)
```

For l_c = 2 mm: ω_0 ≈ 70 rad/s, f_0 ≈ 11 Hz

Driving at f_0 creates resonant amplification — parametric resonance in the Mathieu equation sense. This is the mechanism behind **Faraday-wave-like** patterns in oscillating ferrofluid.

---

## Simulation Implications

For the shaders in `code/`:

| Physical effect | Shader parameter | Mechanism |
|----------------|-----------------|-----------|
| Critical field exceeded | `magnetStrength > threshold` | Spikes appear above threshold |
| Hexagonal order | Multiple spike agents | Hexagonal seeding pattern |
| Spike sharpness | `spikeSharpness` | Controls curvature of tip |
| Resonant oscillation | `fieldOscillation ≈ 1.0` | Peak response at unit frequency |
| Viscous damping | `viscosity` | Damping coefficient in wave equation |
| Spike competition | `multi_magnet.glsl` | Gradient competition between adjacent spikes |

---

## References

- Cowley, M.D. & Rosensweig, R.E. (1967). The interfacial stability of a ferromagnetic fluid. *Journal of Fluid Mechanics*, 30(4), 671–688.
- Gailitis, A. (1977). Formation of the hexagonal pattern on the surface of a ferromagnetic fluid in an applied magnetic field. *Journal of Fluid Mechanics*, 82(3), 401–413.
- Boudouvis, A.G., Puchalla, J.L., Scriven, L.E., & Rosensweig, R.E. (1987). Normal field instability and patterns in pools of ferrofluid. *Journal of Magnetism and Magnetic Materials*, 65, 307–310.
- Richter, R. & Barashenkov, I.V. (2005). Two-dimensional solitons on the surface of magnetic fluids. *Physical Review Letters*, 94, 184503.
- Rosensweig, R.E. (1985). *Ferrohydrodynamics*. Cambridge University Press. (Chapter 7: Field-induced surface instabilities)
