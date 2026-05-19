# Ferrofluid Magnetism Physics

## What Is Ferrofluid?

Ferrofluid is a colloidal suspension of **nanoscale ferrimagnetic particles** (typically magnetite, Fe₃O₄, ~10 nm diameter) stabilized by a surfactant coating and suspended in a carrier fluid (water, oil, or kerosene). The particles are small enough that thermal agitation prevents bulk sedimentation (no settling), and the surfactant prevents particle aggregation.

The result is a macroscopically homogeneous liquid that behaves as a single magnetic fluid: it flows, wets surfaces, has a meniscus — and it moves visibly and dramatically in response to magnetic fields.

---

## Magnetic Properties

### Superparamagnetism

Because each particle is a single magnetic domain (~10 nm), it behaves **superparamagnetically**:
- In zero field: magnetizations are randomly oriented by thermal fluctuations → bulk magnetization M = 0
- In applied field B: particles partially align → bulk M rises
- No hysteresis: when B is removed, M instantly returns to zero
- No permanent magnetization, no remanence

This is what makes ferrofluid *respond to* but not *remember* a field.

### Magnetization Curve (Langevin)

The equilibrium magnetization of a ferrofluid follows the **Langevin function**:

```
M(H) = M_s · L(α)
L(α) = coth(α) - 1/α
α    = μ₀ m H / (k_B T)
```

Where:
- `M_s` = saturation magnetization (maximum alignment)
- `m` = magnetic moment of a single particle
- `H` = applied magnetic field intensity
- `k_B T` = thermal energy

At low fields (α ≪ 1): `M ≈ M_s α/3 = χ H`  (linear regime, susceptibility χ)  
At high fields (α ≫ 1): `M → M_s`  (saturation)

Typical values:
- Susceptibility χ ≈ 0.5 – 3 (dimensionless, SI)
- Saturation magnetization M_s ≈ 20 – 100 kA/m
- Saturation field H_s ≈ 10 – 100 kA/m

### Magnetic Dipole Field

A permanent magnet (or electromagnet) can be approximated as a magnetic dipole with moment **m** (A·m²). The field it produces at displacement **r** from the dipole is:

```
B(r) = (μ₀/4π) · [3(m̂·r̂)r̂ - m̂] · |m|/r³
```

- Falls off as r⁻³ (dipole field)
- Has a characteristic "figure-8" topology: strong near the poles, weak at the equator
- Field gradient ∇B points toward the magnet → pulls ferrofluid toward regions of higher field

### Kelvin Body Force

The force per unit volume on a magnetically polarized fluid in an inhomogeneous field:

```
f = μ₀ (M · ∇) H
```

For a linear material in the low-field approximation:

```
f = (μ₀ χ / 2) ∇(H²)
```

This is the **ponderomotive force** — it pulls the fluid toward regions of stronger field, regardless of field direction. This is why ferrofluid climbs toward a magnet even when gravity acts against it.

---

## Fluid Mechanics

### Governing Equations

Ferrofluid flow is governed by the **Navier-Stokes equations** with an additional magnetic body force:

```
ρ (∂u/∂t + u·∇u) = -∇p + η∇²u + μ₀(M·∇)H + ρg
∇·u = 0   (incompressibility)
```

The magnetic term `μ₀(M·∇)H` couples the flow field to the magnetic field.

### Magnetic Pressure

At a ferrofluid–air interface, the **Bernoulli-like** pressure jump includes a magnetic contribution:

```
[p] = μ₀/2 · (M_n² - M_t²)|_n  +  γ κ
```

Where:
- `M_n`, `M_t` = normal and tangential magnetization components at the interface
- `γ` = surface tension coefficient
- `κ` = interface curvature (principal curvatures sum)
- `[p]` = pressure jump across the interface

The `μ₀ M_n²/2` term acts as a **magnetic pressure** that inflates the surface where the normal field is strong — this is what drives spike formation.

### Viscosity

Ferrofluid viscosity is higher than the carrier fluid alone due to:
1. **Hydrodynamic contribution**: volume fraction of particles increases viscosity (Einstein relation: η_eff ≈ η₀(1 + 2.5φ))
2. **Magnetoviscous effect**: in a field, particles tend to align, resisting shear → effective viscosity increases by factor 2–3 in strong fields
3. **Relaxation time**: Brownian relaxation τ_B ≈ 3ηV/k_BT (Néel relaxation for locked particles)

For visualization purposes: **high viscosity** means slower spike response, more damping of waves, longer relaxation after field removal.

---

## Surface Tension

Surface tension γ is the energetic cost of creating new interface (units: N/m or J/m²). For ferrofluid–air:
- Water-based: γ ≈ 0.05 – 0.07 N/m
- Oil-based: γ ≈ 0.02 – 0.04 N/m

Surface tension is what limits spike height. A spike increases surface area, which costs energy; the magnetic energy gain from concentrating field lines at the spike tip must exceed this cost for the spike to form.

The **capillary length** sets the length scale for this competition:

```
l_c = √(γ / ρg)   (capillary-gravity length, ~2 mm for water)
l_γ = √(γ / μ₀ M²) (capillary-magnetic length)
```

---

## Key Physical Parameters

| Symbol | Name | Typical Value | Effect on Spikes |
|--------|------|---------------|-----------------|
| χ | Susceptibility | 0.5 – 3 | Higher → larger spikes |
| M_s | Saturation magnetization | 20 – 100 kA/m | Sets maximum spike height |
| γ | Surface tension | 0.02 – 0.07 N/m | Higher → shorter, blunter spikes |
| η | Dynamic viscosity | 1 – 50 mPa·s | Controls response speed |
| ρ | Density | 1000 – 1500 kg/m³ | Higher → gravity fights spikes harder |
| φ | Volume fraction of particles | 5 – 15% | Sets χ and M_s |

---

## References

- Rosensweig, R.E. (1985). *Ferrohydrodynamics*. Cambridge University Press.
- Shliomis, M.I. (1972). Effective viscosity of magnetic suspensions. *Soviet Physics JETP*, 34(6).
- Odenbach, S. (Ed.) (2002). *Ferrofluids: Magnetically Controllable Fluids and Their Applications*. Springer.
- Cowley, M.D. & Rosensweig, R.E. (1967). The interfacial stability of a ferromagnetic fluid. *Journal of Fluid Mechanics*, 30(4).
