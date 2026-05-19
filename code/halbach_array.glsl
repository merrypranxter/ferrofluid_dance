// halbach_array.glsl
// Halbach array magnetic field — the engineered magnet configuration where
// flux is concentrated entirely on ONE side and cancels on the other.
// Named for Klaus Halbach (1924–2000), physicist at Lawrence Berkeley.
//
// Physical basis:
//   A Halbach array is a sequence of magnets with rotating dipole orientation:
//   → ↑ ← ↓ → ↑ ← ↓  (rotating by 90° each step)
//   By interference, all flux emerges from ONE face (the strong side) and
//   the opposite face has near-zero field. This is why maglev trains float:
//   the rails have Halbach arrays — maximum lift force, zero stray field above.
//
//   For ferrofluid: a Halbach array creates a SPATIALLY PERIODIC strong-side
//   field with wavelength equal to the array pitch. The ferrofluid forms
//   a regular forest of equally-spaced, equally-tall spikes — no competition,
//   perfect periodicity. The spacing is set by the magnet geometry, not by
//   surface tension (unlike the Rosensweig case).
//
// Parameters:
//   magnetStrength   — array field intensity [0..10], default 5.0
//   susceptibility   — fluid response [0.1..5], default 2.5
//   surfaceTension   — spike resistance [0.1..5], default 1.0
//   arrayPitch       — spatial period of the Halbach array [0.05..0.5], default 0.15
//   arrayCount       — number of magnet pairs in the array [2..12], default 6
//   fieldOscillation — slow field modulation speed [0..5], default 0.3
//   halbachSide      — 1.0 = strong side (spikes), -1.0 = weak side (flat)

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 5.0
uniform float susceptibility;   // default 2.5
uniform float surfaceTension;   // default 1.0
uniform float arrayPitch;       // default 0.15
uniform float arrayCount;       // default 6.0
uniform float fieldOscillation; // default 0.3
uniform float halbachSide;      // default 1.0  (+1 strong, -1 weak)

// ─── NOISE ───────────────────────────────────────────────────────────────────
float hash(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float hash1(float n) { return fract(sin(n) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}

// ─── HALBACH ARRAY FIELD ─────────────────────────────────────────────────────
// A 1-D Halbach array of infinite extent along x produces a field that, on the
// strong side (y > 0), decays exponentially with distance from the array:
//
//   By(x, y) = B₀ · sin(2πx/λ) · exp(-2πy/λ)   (strong side, y > 0)
//   Bx(x, y) = B₀ · cos(2πx/λ) · exp(-2πy/λ)
//   |B|       = B₀ · exp(-2πy/λ)   (magnitude independent of x)
//
// On the weak side (y < 0): |B| ≈ 0 (perfect cancellation in ideal case).
// This gives PERIODIC spikes with spacing λ = arrayPitch.

vec2 halbachField(vec2 p, float strength, float pitch, float side) {
    // Array lies along y = -0.3 (below the pool surface at y = 0).
    float arrayY    = -0.3;
    float dist      = (p.y - arrayY) * side;   // positive on the desired side
    float k         = 6.2831853 / pitch;        // wavenumber = 2π/λ

    // Field only exists on the strong side
    float presence  = max(0.0, dist);
    float decay     = exp(-k * presence);

    float Bx = strength * cos(k * p.x) * decay;
    float By = strength * sin(k * p.x) * decay;

    return vec2(Bx, By);
}

float halbachMagnitude(vec2 p, float strength, float pitch, float side) {
    // Magnitude = B₀ · exp(-k · dist) [side-dependent]
    float arrayY = -0.3;
    float dist   = (p.y - arrayY) * side;
    float k      = 6.2831853 / pitch;
    float presence = max(0.0, dist);
    return strength * exp(-k * presence);
}

// ─── PERIODIC SPIKE PROFILE ──────────────────────────────────────────────────
// Unlike Rosensweig (random competition → quasi-hexagonal), Halbach forces
// spikes to appear at EXACTLY the field maxima: x = 0, ±λ, ±2λ, ...
// Each spike is identical in height and spacing.

float periodicSpikeHeight(vec2 p, float B, float pitch) {
    // Local x-position within one pitch period
    float kx    = 6.2831853 * p.x / pitch;
    // Spike at every integer of p.x/pitch — peak when sin(kx) == 1
    float spikeX = sin(kx);  // ranges -1..1
    // Only upward-pointing field (sin > 0) causes spikes
    float spikeProfile = max(0.0, spikeX);
    // Sharpness: raise to a power to narrow the spike base
    spikeProfile = pow(spikeProfile, 3.0);
    // Height proportional to local field × susceptibility / surface tension
    return B * susceptibility / surfaceTension * spikeProfile * 0.08;
}

// ─── ARRAY EDGE FRINGE EFFECTS ────────────────────────────────────────────────
// A finite array has fringe fields at its ends. These create asymmetric
// "banner" spikes at the array terminations — taller on the inside edge.
float fringeField(vec2 p, float count, float pitch, float strength) {
    float halfSpan = count * pitch * 0.5;
    float distEdge = halfSpan - abs(p.x);  // positive inside the array span
    float fringe   = strength * 0.4 / (abs(p.x - halfSpan) * 10.0 + 0.05) +
                     strength * 0.4 / (abs(p.x + halfSpan) * 10.0 + 0.05);
    return fringe * smoothstep(0.0, 0.1, distEdge);
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    // Slow field modulation (simulating DC offset variation)
    float modStrength = magnetStrength * (1.0 + 0.15 * sin(time * fieldOscillation * 6.2831853));

    // Only display the portion of the pool above the array
    float effectivePitch = max(arrayPitch, 0.04);
    float halfSpan = arrayCount * effectivePitch * 0.5;

    // Halbach magnitude at this point
    float B = halbachMagnitude(p, modStrength, effectivePitch, halbachSide);

    // Fringe contribution at array ends
    float Bfringe = fringeField(p, arrayCount, effectivePitch, modStrength * 0.1);
    B += Bfringe;

    // Clamp array span: no spikes outside the magnet array footprint
    float spanMask = smoothstep(halfSpan + 0.02, halfSpan - 0.02, abs(p.x));

    // Spike surface
    float spikeH = periodicSpikeHeight(p, B, effectivePitch) * spanMask;

    // Pool baseline (gravity-set)
    float baseLine = -0.08;
    float surface  = baseLine + spikeH;
    float sdf      = p.y - surface;

    // ─── SHADING ─────────────────────────────────────────────────────────────
    float mask = smoothstep(0.005, -0.005, sdf);
    float edge = smoothstep(0.016, 0.0, abs(sdf));

    // Field-strength gradient coloring: brighter above field maxima (x = nλ)
    vec2  Bvec      = halbachField(p, 1.0, effectivePitch, halbachSide);
    float fieldPhase = dot(normalize(Bvec + 1e-5), vec2(1,0));
    float fieldBright = fieldPhase * 0.5 + 0.5;

    // Meniscus: uniform-height spikes produce a perfect crenellated edge
    vec3 glint = edge * (vec3(0.1, 0.14, 0.22) + vec3(0.08, 0.1, 0.15) * fieldBright);

    // Depth shading: deeper fluid is slightly warmer (oil tint)
    float depth  = smoothstep(0.0, -0.2, sdf);
    vec3  depthC = vec3(0.04, 0.03, 0.02) * depth;

    // Spike tip highlight: a comb of bright points
    float tipLine = smoothstep(0.003, 0.0, abs(sdf + spikeH * 0.3)) * spanMask;
    vec3  tipGlow = vec3(0.2, 0.22, 0.3) * tipLine;

    // Array span boundary: thin edge line where array ends
    float spanEdge = smoothstep(0.01, 0.0, abs(abs(p.x) - halfSpan));
    vec3  spanGlow = vec3(0.04, 0.06, 0.12) * spanEdge * (1.0 - mask);

    // Weak-side indicator: if halbachSide < 0, show near-flat surface with
    // slight waviness from residual fringe field
    float weakSide  = max(0.0, -halbachSide);
    float weakWave  = noise(p * 20.0 + time * 0.2) * 0.003 * weakSide;
    float weakSDF   = p.y - (baseLine + weakWave);
    float weakMask  = smoothstep(0.004, -0.004, weakSDF) * weakSide;
    float weakEdge  = smoothstep(0.008, 0.0, abs(weakSDF)) * weakSide;
    vec3  weakGlint = weakEdge * vec3(0.04, 0.05, 0.08);

    vec3 col = glint + tipGlow + depthC * mask + spanGlow + weakGlint;
    vec3 bg  = vec3(0.0, 0.001, 0.006);
    col = mix(bg, col, max(mask, weakMask) + edge * 0.5 + weakEdge * 0.5);

    gl_FragColor = vec4(col, 1.0);
}
