// hele_shaw_ferrofluid.glsl
// Ferrofluid confined in a Hele-Shaw cell: a thin gap between parallel plates.
// When the gap is thin enough (~0.5 mm), the 3-D problem collapses to 2-D:
// spikes become FINGERS, and the instability is related to viscous fingering
// (Saffman-Taylor) but driven by magnetic instead of pressure gradients.
//
// Physical basis:
//   In a Hele-Shaw cell, the velocity field is Darcy-flow:
//       u = -(b²/12η) ∇p_total
//   where b = gap width, and p_total = fluid pressure + magnetic pressure.
//   Ferrofluid displacing non-magnetic fluid → labyrinthine fingering patterns.
//   The magnetic Bond number Bo_m = μ₀ M² / (γ/d) controls whether fingers
//   are wide (low Bo_m) or narrow/labyrinthine (high Bo_m).
//
//   Unlike the free-surface Rosensweig instability, Hele-Shaw patterns are:
//   - 2-D (top view, not side view)
//   - Show branching "dendritic" finger tips at high field
//   - Can be arrested: labyrinthine patterns freeze at equilibrium
//   - Show droplet splitting and reconnection dynamics
//
// Parameters:
//   magnetStrength   — applied field [0..10], default 4.0
//   susceptibility   — fluid response [0.1..5], default 2.0
//   surfaceTension   — finger width control [0.1..5], default 1.0
//   viscosity        — flow resistance / finger dynamics [0.1..5], default 2.0
//   fieldOscillation — magnet scan speed [0..5], default 0.4
//   gapWidth         — Hele-Shaw gap parameter [0.1..2], default 0.8
//   dropletMode      — 0=fingers, 1=droplet splitting, default 0.0

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 4.0
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 1.0
uniform float viscosity;        // default 2.0
uniform float fieldOscillation; // default 0.4
uniform float gapWidth;         // default 0.8
uniform float dropletMode;      // default 0.0

// ─── NOISE ───────────────────────────────────────────────────────────────────
float hash(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float hash1(float n){ return fract(sin(n) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}
float fbm(vec2 v, int oct) {
    float s = 0.0, a = 0.5, freq = 1.0;
    for (int i = 0; i < 6; i++) {
        if (i >= oct) break;
        s += noise(v * freq) * a;
        freq *= 2.1; a *= 0.48;
    }
    return s;
}

// ─── MAGNETIC FIELD (SCANNING MAGNET) ────────────────────────────────────────
// The magnet moves slowly over the cell, leaving behind a frozen labyrinthine
// wake. Each position the magnet visits imprints a pattern in the fluid.
vec2 magnetScan(float t) {
    float x = sin(t * fieldOscillation * 2.0) * 0.25;
    float y = cos(t * fieldOscillation * 1.3) * 0.2;
    return vec2(x, y);
}

float fieldMagnitude(vec2 p, vec2 magPos, float strength) {
    vec2  d = p - magPos;
    float r2 = dot(d, d) + 1e-3;
    return strength / (r2 * sqrt(r2));
}

// ─── HELE-SHAW LABYRINTHINE PATTERN ──────────────────────────────────────────
// We approximate the evolved Hele-Shaw pattern using a reaction-diffusion analog:
// the pattern at time t is the result of finger growth from a central injection
// point, broadening outward. The finger width ∝ (γ b²) / (μ₀ M² b)
//   → wider at high surface tension, narrower at high field.

float fingerWidth(float strength, float gamma, float gap) {
    // Magnetic Bond number Bo_m: high → thin fingers
    float Bom = strength * strength / (gamma * 100.0 + 0.1);
    // Finger width in normalized units: decreases with Bom
    return clamp(gap * 0.3 / (1.0 + Bom * 0.5), 0.008, 0.1);
}

// Labyrinthine pattern using a warped periodic function.
// The pattern is NOT time-symmetric — it has a frozen-in character
// because Hele-Shaw equilibrium patterns are metastable.
float labyrinthePattern(vec2 p, float t, float fwidth) {
    // Frozen time: the pattern established some time ago is mostly static
    // but slowly evolves at the boundary with fresh fluid.
    float frozenT = floor(t * fieldOscillation * 0.5) / (fieldOscillation * 0.5 + 1e-5);
    float evolveT = fract(t * fieldOscillation * 0.5);

    // Pattern 1: established domain
    float k = 1.0 / fwidth;
    float ang1 = fbm(p * k * 0.6 + frozenT * 0.1, 4) * 6.2831853;
    float pat1 = sin(p.x * k + ang1) * cos(p.y * k * 0.9 + ang1 * 0.7);

    // Pattern 2: currently growing (at boundary of magnet influence)
    vec2  magPos = magnetScan(t);
    float distMag = length(p - magPos);
    float k2 = k * (1.0 + 0.3 * sin(t * 0.7));
    float ang2 = fbm(p * k2 * 0.5 + t * 0.3, 4) * 6.2831853;
    float pat2 = sin(p.x * k2 * 1.1 + ang2) * cos(p.y * k2 + ang2 * 1.2);

    // Blend: near magnet = fresh pattern; far = frozen
    float freshness = exp(-distMag * 8.0 / max(magnetStrength, 0.1));
    return mix(pat1, pat2, freshness * evolveT);
}

// ─── DROPLET SPLITTING ────────────────────────────────────────────────────────
// When a ferrofluid droplet in non-magnetic carrier is exposed to a normal field,
// it elongates along the field and eventually splits into two (above a critical field).
// We simulate a sequence of droplets in various stages of splitting.

float dropletsField(vec2 p, float t, float strength) {
    float total = 0.0;
    for (int i = 0; i < 5; i++) {
        float fi   = float(i);
        float phase = hash1(fi) * 6.2831853;
        float r     = 0.05 + hash1(fi + 1.0) * 0.15;
        vec2  center = vec2(hash1(fi + 2.0) - 0.5, hash1(fi + 3.0) - 0.5) * 0.5;

        // Deformation parameter: elongation under field
        float deform = strength * susceptibility * 0.1 *
                       (0.5 + 0.5 * sin(t * fieldOscillation * 0.8 + phase));
        deform = clamp(deform, 0.0, 1.0);

        // Pre-split: single elongated droplet (ellipse)
        // Post-split: two circular droplets
        float splitProg = smoothstep(0.6, 0.85, deform);

        // Two-center SDF for splitting droplet
        float sepDist = r * 0.8 * splitProg;
        vec2  c1 = center + vec2(0.0, sepDist);
        vec2  c2 = center - vec2(0.0, sepDist);
        float dropR = r * (1.0 - splitProg * 0.25);

        // Smooth union of two circles using log-sum-exp
        float d1 = length(p - c1) - dropR;
        float d2 = length(p - c2) - dropR;
        float k  = 0.05;
        float d  = -k * log(exp(-d1/k) + exp(-d2/k));

        total += smoothstep(0.005, -0.005, d);
    }
    return clamp(total, 0.0, 1.0);
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    float fwidth  = fingerWidth(magnetStrength, surfaceTension, gapWidth);
    float pattern = labyrinthePattern(p, time, fwidth);

    // Threshold the pattern to get binary fluid/air domains
    float threshold = 0.5 - (susceptibility - 2.0) * 0.05;
    float fluid     = smoothstep(threshold + fwidth * 2.0,
                                 threshold - fwidth * 2.0, pattern);

    // Droplet mode blends in the droplet-splitting visual
    float droplets = dropletsField(p, time, magnetStrength);
    fluid = mix(fluid, droplets, dropletMode);

    // Magnetic field overlay (shows where the magnet currently is)
    vec2  magPos  = magnetScan(time);
    float Bfield  = fieldMagnitude(p, magPos, magnetStrength * 0.5);
    float fieldGlow = Bfield * 0.002;

    // ─── SHADING ─────────────────────────────────────────────────────────────
    // In Hele-Shaw, we look from ABOVE (top view).
    // Ferrofluid domain = dark. Non-magnetic carrier = bright.
    // Domain walls = bright edge.

    float edgeSDF   = fluid - 0.5;  // -0.5 inside fluid, +0.5 outside
    float edge      = smoothstep(0.08, 0.0, abs(edgeSDF));

    // Fluid domain: jet black
    vec3 fluidColor = vec3(0.0, 0.0, 0.0);

    // Carrier fluid: almost-white, slightly blue (light transmission through
    // the thin non-magnetic layer)
    vec3 carrierColor = vec3(0.85, 0.88, 0.95);

    // Edge: the black meniscus ring around each finger
    vec3 edgeColor = vec3(0.05, 0.08, 0.14) * edge;

    // Field glow: subtle blue at the magnet location
    vec3 fieldColor = vec3(0.1, 0.2, 0.5) * fieldGlow;

    vec3 col = mix(fluidColor, carrierColor, 1.0 - fluid) + edgeColor + fieldColor;
    col = clamp(col, 0.0, 1.0);

    gl_FragColor = vec4(col, 1.0);
}
