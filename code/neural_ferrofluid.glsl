// neural_ferrofluid.glsl
// The ferrofluid as nervous system. Spikes are neurons. Field lines are axons.
// Activation propagates from spike to spike along field-line corridors.
// Synchrony, desynchrony, spreading depolarization waves made black and liquid.
//
// Conceptual mapping:
//   - Ferrofluid spike     = neuron soma (cell body)
//   - Field line between spikes = axon / synaptic connection
//   - Spike height         = membrane potential
//   - Rosensweig threshold = action potential threshold
//   - Field collapse       = inhibitory post-synaptic potential
//   - Traveling wave       = spreading cortical depression (like a migraine aura)
//   - Hexagonal ordering   = columnar cortical microarchitecture
//
// The fluid doesn't just look like neural tissue — it obeys analogous
// differential equations. The Rosensweig instability and neural excitability
// are both bifurcations in a nonlinear dynamical system driven past a threshold.
//
// Parameters:
//   magnetStrength   — excitatory drive [0..10], default 4.0
//   susceptibility   — membrane excitability [0.1..5], default 2.5
//   surfaceTension   — inhibitory tone [0.1..5], default 0.8
//   fieldOscillation — oscillation frequency / neural rhythm [0..5], default 0.6
//   viscosity        — refractory period length [0.1..5], default 1.5
//   neuronCount      — number of neurons [4..48], default 24
//   synapticStrength — coupling between neurons [0..2], default 0.8
//   waveMode         — 0=focal, 1=global oscillation, 2=spreading wave

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;    // default 4.0
uniform float susceptibility;    // default 2.5
uniform float surfaceTension;    // default 0.8
uniform float fieldOscillation;  // default 0.6
uniform float viscosity;         // default 1.5
uniform float neuronCount;       // default 24.0
uniform float synapticStrength;  // default 0.8
uniform float waveMode;          // default 0.0

// ─── HASH / NOISE ─────────────────────────────────────────────────────────────
float hash1(float n) { return fract(sin(n) * 43758.5453); }
float hash(vec2 v)   { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}

// ─── NEURON POSITIONS (QUASI-HEXAGONAL) ──────────────────────────────────────
// Pack neurons in a perturbed hexagonal grid to mirror cortical column spacing.
vec2 neuronPos(int i, int total) {
    float fi = float(i);
    float ft = float(total);

    // Hexagonal packing: rows of offset circles
    float cols  = ceil(sqrt(ft * resolution.x / resolution.y));
    float col   = mod(fi, cols);
    float row   = floor(fi / cols);
    float rowOff = mod(row, 2.0) * 0.5;

    float spacing = 0.85 / cols;
    vec2  pos = (vec2(col + rowOff, row) * spacing -
                  vec2(cols * spacing * 0.5, ceil(ft / cols) * spacing * 0.5));

    // Jitter: biological tissue is never perfectly ordered
    float jitterAmt = 0.02;
    pos += vec2(hash1(fi * 2.1 + 7.3) - 0.5, hash1(fi * 3.7 + 2.1) - 0.5) * jitterAmt;

    return pos;
}

// ─── NEURON ACTIVATION STATE ─────────────────────────────────────────────────
// Each neuron has an intrinsic oscillation (theta/gamma rhythm analogy).
// Phase-coupled: nearby neurons synchronize via synaptic (field-line) coupling.
// This is a simplified Kuramoto oscillator model.

float neuronPhase(int i, vec2 pos) {
    float fi = float(i);
    // Natural frequency: slightly different for each neuron (heterogeneous network)
    float omega = fieldOscillation * (0.8 + 0.4 * hash1(fi + 99.0));
    // Intrinsic phase
    float phi0  = hash1(fi + 200.0) * 6.2831853;

    // Spreading wave mode: phase is set by distance from the wave origin
    float waveContrib = 0.0;
    if (waveMode > 1.5) {
        // Spreading cortical depression: plane wave from left edge
        vec2 waveOrigin = vec2(-0.45, 0.0);
        float waveDist  = length(pos - waveOrigin);
        float waveSpeed = 0.05;  // slow, like real spreading depression
        waveContrib = waveDist / waveSpeed - time * 0.3;
    }

    return time * omega + phi0 + waveContrib;
}

// Action potential: neuron fires when phase passes threshold.
// Returns [0,1] where 1 = peak of action potential.
float actionPotential(float phase, float refractoryPeriod) {
    float cycleFrac = fract(phase / 6.2831853);
    // Spike: fast rise, exponential decay (AHP = after-hyperpolarization)
    float spike = exp(-cycleFrac * refractoryPeriod * 10.0) * step(0.0, 0.5 - cycleFrac);
    return spike;
}

// ─── FIELD LINE BETWEEN NEURONS (AXON VISUALIZATION) ─────────────────────────
// The magnetic "axon" between two spikes is brightest along the field line
// connecting their tips. We approximate this as an exponential tube between
// each pair of significantly-coupled neurons.

float axonField(vec2 p, vec2 a, vec2 b, float coupling, float activation) {
    vec2  ab  = b - a;
    float len = length(ab);
    if (len < 0.001) return 0.0;
    vec2  ab_n = ab / len;
    vec2  ap   = p - a;
    float t    = clamp(dot(ap, ab_n) / len, 0.0, 1.0);
    vec2  proj = a + t * ab;
    float dist = length(p - proj);
    // Axon radius scales with coupling strength
    float radius = 0.005 + coupling * 0.004;
    return exp(-dist * dist / (radius * radius)) * coupling * activation;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    int N = int(clamp(neuronCount, 4.0, 48.0));

    float totalSpikeH  = 0.0;  // aggregate spike field height
    float axonGlow     = 0.0;  // aggregate axon glow
    float maxActivation = 0.0; // track peak activation for coloring
    float syncPhase    = 0.0;  // population average phase (for global mode)

    // ── Pass 1: accumulate neuron activations ─────────────────────────────
    float activations[48];  // GLSL ES: must be compile-time size
    vec2  positions[48];
    for (int i = 0; i < 48; i++) {
        if (i >= N) break;
        vec2  pos   = neuronPos(i, N);
        float phase = neuronPhase(i, pos);
        float act   = actionPotential(phase, viscosity);

        activations[i] = act;
        positions[i]   = pos;

        // Spike height contribution at this pixel
        vec2  d       = p - pos;
        float r2      = dot(d, d);
        float spikeR  = 0.02 + susceptibility * 0.005;
        float spike   = exp(-r2 / (spikeR * spikeR)) * act;
        // Resting potential: spike exists even at act=0, just shorter
        float rest    = exp(-r2 / (spikeR * spikeR * 4.0)) * 0.3;
        totalSpikeH  += max(spike, rest) * magnetStrength / surfaceTension * 0.04;
        maxActivation = max(maxActivation, act);
        syncPhase    += phase;
    }
    syncPhase /= float(N);

    // ── Pass 2: axon field lines between connected neurons ────────────────
    for (int i = 0; i < 48; i++) {
        if (i >= N) break;
        for (int j = i + 1; j < 48; j++) {
            if (j >= N) break;
            // Connection strength decays with distance (local connectivity)
            float dist   = length(positions[i] - positions[j]);
            float maxDist = 0.15;  // connection range
            if (dist > maxDist) continue;
            float coupling = synapticStrength *
                             exp(-dist * dist / (maxDist * maxDist * 0.3));
            // Activation propagates along axon with a time delay
            float delay   = dist / (0.2 * max(viscosity, 0.1));
            float avgAct  = (activations[i] + activations[j]) * 0.5;
            axonGlow += axonField(p, positions[i], positions[j], coupling, avgAct);
        }
    }

    // ── Surface SDF ───────────────────────────────────────────────────────
    float baseLine = -0.1;
    float surface  = baseLine + totalSpikeH;
    float sdf      = p.y - surface;

    // ── Shading ──────────────────────────────────────────────────────────
    float mask = smoothstep(0.005, -0.005, sdf);
    float edge = smoothstep(0.018, 0.0, abs(sdf));

    // Axon glow: cool blue-white threads running between spikes
    vec3 axonColor = vec3(0.05, 0.15, 0.35) * clamp(axonGlow, 0.0, 1.0) * mask;

    // Activation coloring: firing neurons glow warm; resting neurons cold
    // Color maps:  resting → cold blue, firing → warm white/gold
    vec3 restColor = vec3(0.0, 0.04, 0.12);
    vec3 fireColor = vec3(0.7, 0.8, 1.0);
    float actField = clamp(totalSpikeH / (magnetStrength / surfaceTension * 0.04 * 0.5 + 1e-4),
                           0.0, 1.0);
    vec3 neuronColor = mix(restColor, fireColor, actField * maxActivation);
    neuronColor *= mask;

    // Meniscus
    vec3 glint = edge * (vec3(0.08, 0.14, 0.25) + neuronColor * 0.3);

    // Global synchrony: when all neurons fire together, the whole pool brightens
    float popSync = smoothstep(0.3, 0.8, maxActivation);
    vec3  syncGlow = vec3(0.03, 0.06, 0.12) * popSync * mask;

    // Spreading wave front: bright leading edge
    float waveFront = 0.0;
    if (waveMode > 1.5) {
        float wDist = length(p - vec2(-0.45, 0.0));
        float wTime = time * 0.3;
        waveFront = smoothstep(0.025, 0.0, abs(wDist - wTime * 0.05));
    }
    vec3 waveColor = vec3(0.15, 0.25, 0.4) * waveFront;

    vec3 col = glint + axonColor + syncGlow + waveColor + neuronColor * 0.2;
    vec3 bg  = vec3(0.0, 0.002, 0.006) + axonGlow * 0.01 * vec3(0.1, 0.2, 0.5);
    col = mix(bg, col, mask + edge * 0.5);

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
