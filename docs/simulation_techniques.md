# Ferrofluid Simulation Techniques

## Overview

Simulating ferrofluid computationally requires solving three coupled problems:
1. **Magnetic field** — Maxwell's equations in the magnetostatic limit
2. **Fluid dynamics** — Navier-Stokes with magnetic body force
3. **Interface tracking** — the free surface between ferrofluid and air

This document covers the methods used in this repository's GLSL shaders and places them in the context of more rigorous simulation approaches.

---

## Field Solver Methods

### 1. Point Dipole (Used in Most Shaders Here)

**Formula**:
```
B(r) = (μ₀/4π) · [3(m̂·r̂)r̂ - m̂] · |m| / r³
```

**Strengths**:
- Computationally trivial: one `dot` product, one `sqrt`
- Exact for a magnetic dipole at distances r >> magnet size
- Produces the correct qualitative field topology (figure-8 pattern)

**Weaknesses**:
- Singular at r=0 (regularized with `+1e-4` in the denominator)
- Diverges near the magnet — no field saturation
- Does not model the internal field structure of real magnets (pole faces, fringing)

**When to use**: Any visualization where the magnet is far enough from the fluid surface that the point approximation holds. In practice: magnet-to-surface distance > 2× magnet diameter.

**GLSL Implementation** (from `basic_ferrofluid.glsl`):
```glsl
float dipoleField(vec2 p, float strength) {
    float r2 = dot(p, p) + 1e-4;  // regularize singularity
    float r  = sqrt(r2);
    float cosTheta = p.y / r;      // elevation angle from axis
    // |B|² ∝ (1 + 3cos²θ) / r^6  → |B| ∝ sqrt(1+3cos²θ) / r³
    return strength * sqrt(1.0 + 3.0 * cosTheta * cosTheta) / (r2 * r);
}
```

### 2. Exact Circular Loop (Biot-Savart with Elliptic Integrals)

**Formula** (see `biot_savart_coil.glsl` for full derivation):
```
Bz(r,z) = (μ₀I/2π) · [(R²-r²-z²)/((R-r)²+z²) · E(k²) + K(k²)] / √((R+r)²+z²)
Br(r,z) = (μ₀Iz/2πr) · [(R²+r²+z²)/((R-r)²+z²) · E(k²) - K(k²)] / √((R+r)²+z²)
```

**Strengths**:
- Exact field at all distances (including inside the loop)
- Models the field reversal outside the loop radius correctly
- Captures the saddle point at the loop center

**Weaknesses**:
- More expensive: requires elliptic integral evaluation (~20 operations)
- Polynomial approximations to K(k²) and E(k²) introduce small errors near k²→1

**When to use**: Whenever the coil geometry matters — particularly when visualizing the field inside vs. outside a current loop, or building Helmholtz/anti-Helmholtz configurations.

### 3. Halbach Array (Analytic Fourier)

For a Halbach array with spatial period λ (see `halbach_array.glsl`):
```
Bx(x,y) = B₀ cos(2πx/λ) exp(-2πy/λ)   [strong side, y > 0]
By(x,y) = B₀ sin(2πx/λ) exp(-2πy/λ)
|B|      = B₀ exp(-2πy/λ)               [magnitude constant along x]
```

**Strengths**:
- Closed-form analytic solution
- Captures the exponential decay with distance characteristic of periodic arrays
- |B| is spatially uniform along the surface → equal spike heights everywhere

**Weaknesses**:
- Applies only to an infinite, ideal Halbach array
- Fringe fields at array ends require separate treatment

### 4. Superposition (Multi-Magnet)

`multi_magnet.glsl` uses linear superposition of N dipole fields:
```
B_total = Σᵢ B_dipole(p - pᵢ, strengthᵢ)
```

This is valid because Maxwell's equations are linear in the field (for non-ferromagnetic materials). The ferrofluid's magnetization introduces a nonlinear coupling, but for visualization purposes the superposition in air is exact.

**Saturation handling**: Real ferrofluid saturates at M_s; the shader clamps `totalB` to avoid unphysical values:
```glsl
totalB = min(totalB, 20.0);
```

### 5. Scalar Magnetic Potential (for Complex Geometry)

For geometries too complex for analytic formulas, the magnetostatic field satisfies:
```
H = -∇Ψ   (in current-free regions)
∇²Ψ = 0   (Laplace equation)
```

This can be solved numerically on a grid (finite differences or finite elements), then stored in a texture and sampled in the shader. The texture-lookup approach enables real-time rendering of pre-computed complex fields.

**GPU implementation sketch**:
1. Off-line: solve Laplace equation on 512×512 grid, store ∂Ψ/∂x and ∂Ψ/∂y in a texture
2. In shader: `vec2 H = texture2D(fieldTex, uv).xy;`
3. Compute |H| → spike height

This approach is used in production ferrofluid simulations and enables arbitrary magnet geometries.

---

## Surface Representation Methods

### 1. Height Field (Used Here)

The simplest approach: represent the fluid surface as a single-valued function h(x,y) — the height above the baseline at each horizontal position.

**SDF construction** (from `basic_ferrofluid.glsl`):
```glsl
// SDF: positive above surface, negative below
float sdf = p.y - surface;
```

**Strengths**:
- Trivial to implement in a fragment shader
- Smooth: the height function can be differentiated analytically

**Weaknesses**:
- Cannot represent overhangs, bubbles, or closed surfaces
- Spike tips become multivalued if a spike curves back over itself
- Not suitable for fragmentation or droplet pinch-off

**When it works**: For attached surfaces (fluid pool connected to a container), height fields capture all the essential physics of Rosensweig spikes.

### 2. Signed Distance Field (SDF)

A more general representation: `d(p)` = signed distance from point p to the nearest fluid interface (positive outside, negative inside).

Used in `inverse_ferrofluid.glsl` for droplets:
```glsl
// Droplet as ellipse SDF
float dSDF = (along² / a² + perp² / b²) - 1.0;
// Smooth union for chaining
float smin(float a, float b, float k) { ... }
```

**Strengths**:
- Handles overhangs, droplets, bubbles, and topology changes
- Smooth interpolation at interfaces via `smoothstep`
- CSG operations (union, difference, intersection) via min/max/negation

**Weaknesses**:
- More expensive to evaluate for complex geometries
- Global topology changes (droplet splitting) require careful handling

### 3. Level Set Method

The dynamical extension of SDF: evolve a field φ(x,y,t) where the interface is at {φ = 0}. The evolution equation is:

```
∂φ/∂t + u·∇φ = 0
```

where u is the fluid velocity (from Navier-Stokes). The field φ is periodically "reinitialized" to maintain the signed-distance property.

This method handles all topology changes automatically (the level set naturally handles pinch-off and reconnection). It is the standard method for high-fidelity ferrofluid simulation but is too expensive for real-time GPU use (requires an Eulerian velocity field update each frame).

### 4. Particle Methods (SPH)

Smoothed Particle Hydrodynamics represents the fluid as particles, each with position, velocity, density, and magnetic moment. The surface is reconstructed from particle positions.

Particularly useful for:
- Ferrofluid droplet dynamics in a carrier fluid
- Hele-Shaw cell simulations
- The `inverse_ferrofluid.glsl` scenario (droplet chains)

**GPU implementation**: SPH is parallelizable. With 50,000–100,000 particles on a modern GPU, real-time ferrofluid simulation at ~30 fps is feasible.

### 5. Phase Field Method

The ferrofluid–air interface is represented as a diffuse zone where an order parameter φ transitions continuously from 0 (air) to 1 (ferrofluid). The Cahn-Hilliard equation governs the interface:

```
∂φ/∂t + u·∇φ = M ∇²(μ)
μ = -aφ + bφ³ - ε²∇²φ  (chemical potential)
```

The phase field method naturally handles:
- Droplet coalescence and splitting
- Film formation and dewetting
- Contact angle dynamics

The surface tension arises as a consequence of the diffuse interface energy, not as a boundary condition — this makes the method physically consistent.

---

## Real-Time GPU Approaches

### Fragment Shader (This Repository)

**Architecture**: Each pixel evaluates the field equations independently. The "surface" is computed implicitly from the field value at the pixel's spatial position.

**Performance**: O(N) per pixel for N magnets. For N=20 magnets and 1920×1080 pixels: ~40 million field evaluations per frame. Modern GPUs execute this in <1 ms.

**Limitations**: Cannot model fluid dynamics (viscous flow, inertia). Each frame is computed independently — there is no state carried between frames unless you use a render-to-texture feedback loop.

### Render-to-Texture Feedback

To add temporal dynamics (viscosity, inertia, wave propagation):
1. Render the current state to **Texture A**
2. Use Texture A as input to compute the next state → **Texture B**
3. Swap: A ↔ B each frame

This is a discretized PDE solver on the GPU. For ferrofluid surface waves:

```glsl
// In the update pass:
// Read previous surface height
float h_prev = texture2D(prevState, uv).r;
// Apply damped wave equation: ∂²h/∂t² = c²∇²h - 2β∂h/∂t
float laplacian = (texture2D(prevState, uv + eps.xo) + texture2D(prevState, uv - eps.xo)
                 + texture2D(prevState, uv + eps.oy) + texture2D(prevState, uv - eps.oy)
                 - 4.0 * h_prev) / (eps.x * eps.x);
float h_next = 2.0 * h_prev - h_pprev + dt * dt * (cSqr * laplacian - damping);
```

This enables physically accurate wave propagation with viscous damping, at the cost of two render passes per frame.

### Vertex Displacement (3-D Spike Geometry)

For three.js or WebGL 3-D scenes, spikes are best rendered as displaced geometry:

```glsl
// In the vertex shader:
float B = dipoleField(position.xz - magnetPos.xz, magnetStrength);
float h = B * susceptibility / surfaceTension;
position.y += h;
normal = normalize(vec3(-dh/dx, 1.0, -dh/dz));  // analytical normal
```

This approach (used in Three.js ferrofluid demos) gives proper 3-D rendering with correct normals for lighting.

### Compute Shaders (WebGPU / WebGL 2)

For particle-based approaches, compute shaders enable:
- SPH neighbor search and force computation
- Efficient field evaluation at particle positions
- GPU-side particle integration

Example WebGPU compute shader for ferrofluid particle update:
```wgsl
@compute @workgroup_size(64)
fn updateParticles(@builtin(global_invocation_id) id : vec3<u32>) {
    let i = id.x;
    var p = particles[i];
    let B = dipoleField(p.pos - magnetPos, magnetStrength);
    let F_magnetic = susceptibility * gradient(B, p.pos);
    let F_gravity  = vec2(0.0, -gravity * density);
    let F_viscous  = -viscosity * p.vel;
    p.vel += (F_magnetic + F_gravity + F_viscous) * dt;
    p.pos += p.vel * dt;
    particles[i] = p;
}
```

---

## Numerical Methods for the Spike Shape

### Quasi-Static Spike Profile

For a single spike in equilibrium under gravity + surface tension + magnetic pressure:

The spike profile satisfies the **Young-Laplace equation** with magnetic pressure:

```
γ κ = ρg h + μ₀ M_n²/2
```

where κ is the mean curvature, h is spike height above baseline, and M_n is the normal magnetization at the surface.

For a spike of revolution (circular cross-section):

```
γ (h'' / (1+h'²)^(3/2) + h' / (r(1+h'²)^(1/2))) = ρg(h - h₀) - μ₀ M_n²/2
```

This ODE can be solved numerically (Runge-Kutta) given boundary conditions:
- At r = 0 (spike tip): h'(0) = 0 (by symmetry)
- At r → ∞: h → 0 (spike merges with flat surface)
- Tip height h(0) is determined by the magnetic pressure balance

**Spike height vs. magnet distance** (from numerical solutions):
```
h_tip ≈ C · (μ₀ M²) / (2 ρg) · (1 - (B_c / B)^2)^(1/2)
```
where B_c is the critical field. Near the threshold, the spike grows slowly; at 2B_c, height ≈ 0.4× the capillary length.

### Approximate Gaussian Profile (Shader Approximation)

In the shaders, the spike profile is approximated as:
```glsl
float spikeProfile = exp(-abs(delta.x) * spikeSharpness * 8.0) * h * 0.15;
```

This Gaussian envelope correctly captures:
- Zero height at large horizontal distance
- Maximum at the spike axis
- Width controlled by `spikeSharpness`

**Where it fails**: The Gaussian spike is not the true minimal-energy shape (which is more cusp-like at the tip). For artistic purposes this is acceptable; for physical accuracy, use the numerically-solved profile.

---

## Stability and Numerical Artifacts

### Time Step Constraints

For any time-marching solver (render-to-texture feedback):

**CFL condition** (wave propagation):
```
dt < dx / c_wave   where c_wave = √(γ k / ρ)
```
For k = 2π/λ_c, c_wave ≈ 0.05–0.15 m/s → at a spatial resolution of 1 mm, dt < 10 ms (100 Hz minimum update rate).

**Viscous stability**:
```
dt < ρ dx² / (2η)
```

At typical resolutions and viscosities: dt < 1 ms (1000 Hz).

**Practical consequence**: Real-time ferrofluid simulation at 60 fps allows Δt = 16.7 ms, which may violate the viscous stability condition. Solutions:
1. Multiple sub-steps per frame
2. Implicit time integration (unconditionally stable but requires matrix solve)
3. Artificial viscosity (increase η in the numerics beyond the physical value)

### Singularity Regularization

The point dipole field diverges as r → 0. All shaders in this repository use:
```glsl
float r2 = dot(delta, delta) + 1e-4;
```

The regularization radius is sqrt(1e-4) = 0.01 in normalized UV units. This is comparable to 10 pixels at 1000-pixel width — large enough that spikes close to the magnet are notably blunted. For a more physical rendering, reduce to `1e-6` (still prevents NaN) or use the actual magnet cross-section as a cutoff.

---

## References

- Batchelor, G.K. (1967). *An Introduction to Fluid Dynamics*. Cambridge University Press. (Foundational fluid dynamics)
- Rosensweig, R.E. (1985). *Ferrohydrodynamics*. Cambridge University Press. (Chapters 5–7 on stability and dynamics)
- Kim, S. & Karrila, S.J. (1991). *Microhydrodynamics*. Butterworth-Heinemann. (Particle-level ferrofluid dynamics)
- Osher, S. & Fedkiw, R. (2003). *Level Set Methods and Dynamic Implicit Surfaces*. Springer. (Level set method)
- Müller, M., Charypar, D., & Gross, M. (2003). Particle-based fluid simulation for interactive applications. *SCA 2003*. (SPH for graphics)
- Brackbill, J.U., Kothe, D.B., & Zemach, C. (1992). A continuum method for modeling surface tension. *Journal of Computational Physics*, 100, 335–354. (Surface tension in VOF/phase-field)
- Cowley, M.D. & Rosensweig, R.E. (1967). The interfacial stability of a ferromagnetic fluid. *Journal of Fluid Mechanics*, 30(4). (Original stability analysis)
