// biological_ferrofluid.glsl
// Spikes are alive: growth, predation, reproduction, death, evolution.
// Each spike is an agent competing for field-line territory.
//
// Parameters:
//   magnetStrength   — field intensity [0.0 .. 10.0], default 3.5
//   susceptibility   — fluid response [0.1 .. 5.0], default 2.0
//   surfaceTension   — spike resistance [0.1 .. 5.0], default 0.9
//   biologicalMode   — 0=off (classic spikes), 1=full biology
//   fieldOscillation — slow pulse rate [0.0 .. 5.0], default 0.3

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 3.5
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 0.9
uniform float biologicalMode;   // default 1.0
uniform float fieldOscillation; // default 0.3

// ─── NOISE / HASH ────────────────────────────────────────────────────────────
float hash(float n)  { return fract(sin(n) * 43758.5453); }
float hash2(vec2 v)  { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    float a = hash2(i), b = hash2(i + vec2(1,0));
    float c = hash2(i + vec2(0,1)), d = hash2(i + vec2(1,1));
    vec2 u = f * f * (3.0 - 2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

// ─── DIPOLE FIELD ────────────────────────────────────────────────────────────
float dipoleField(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float ct = delta.y / r;
    return strength * sqrt(1.0 + 3.0 * ct * ct) / (r2 * r);
}

// ─── BIOLOGICAL SPIKE AGENT ─────────────────────────────────────────────────
// Each spike is seeded by a hash position; its lifecycle is driven by time.
// Phase: [0,1) birth→growth→competition→death, modulated by fieldOscillation.

struct Spike {
    vec2  pos;      // 2-D base position
    float age;      // lifecycle 0→1
    float height;   // normalized height
    float radius;   // territory radius
};

Spike spikeAt(int i, vec2 magnetPos) {
    float fi   = float(i);
    float seed = hash(fi);
    // Position jittered around the magnet
    vec2 pos = magnetPos + vec2(hash(fi + 1.0) - 0.5, hash(fi + 2.0) - 0.5) * 0.35;

    float birthPhase = hash(fi + 5.0);
    float cycleLen   = 6.0 + hash(fi + 6.0) * 8.0;
    float age        = fract((time * fieldOscillation + birthPhase * cycleLen) / cycleLen);

    // Life curve: rise fast, plateau, slow death
    float height = smoothstep(0.0, 0.25, age) * (1.0 - smoothstep(0.6, 1.0, age));
    height *= 0.5 + 0.5 * seed;  // some spikes are taller

    // Reproduction bifurcation: at peak, spike gains a small satellite
    float bifurcate = smoothstep(0.45, 0.55, age) * biologicalMode;

    Spike s;
    s.pos    = pos;
    s.age    = age;
    s.height = height;
    s.radius = 0.02 + 0.015 * seed;
    return s;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    // Slow pulsing magnet
    float pulse = sin(time * fieldOscillation * 6.2831853) * 0.05;
    vec2  mp    = vec2(0.0, 0.22 + pulse);
    vec2  delta = p - mp;
    float B     = dipoleField(delta, magnetStrength);

    // --- Aggregate biological spike field ---
    float surfaceH = 0.0;
    float glowAcc  = 0.0;

    for (int i = 0; i < 24; i++) {
        Spike s     = spikeAt(i, mp);
        vec2  d     = p - s.pos;
        // Contribution to surface: Gaussian spike profile
        float spike = exp(-dot(d,d) / (s.radius * s.radius));
        surfaceH   += spike * s.height * 0.12 * biologicalMode;
        // Glowing tip: bright apex where age is in reproductive peak
        float tip   = spike * smoothstep(0.4, 0.6, s.age) * 0.08;
        glowAcc    += tip;
    }

    // Classic Rosensweig underlayer
    surfaceH += B * susceptibility / surfaceTension * 0.07 * (1.0 - biologicalMode * 0.5);

    // Mycelial branching texture
    float branch = noise(p * 22.0 + time * 0.2) * 0.015 * biologicalMode;
    surfaceH += branch;

    float baseLine = -0.08;
    float surface  = baseLine + surfaceH;
    float sdf      = p.y - surface;

    // --- Shading ---
    float mask = smoothstep(0.005, -0.005, sdf);
    float edge = smoothstep(0.018, 0.0, abs(sdf));

    // Bioluminescent spike tips
    vec3 bioGlow = vec3(0.0, 0.18, 0.12) * glowAcc * mask * biologicalMode;

    // Coral-like edge texture
    float edgeNoise = noise(p * 60.0 + time * 0.1) * 0.5 + 0.5;
    vec3  glint = edge * vec3(0.1, 0.2, 0.18) * (0.5 + 0.5 * edgeNoise);

    vec3 col = glint + bioGlow;
    vec3 bg  = vec3(0.0, 0.003, 0.006);
    col = mix(bg, col, mask + edge * 0.5);

    gl_FragColor = vec4(col, 1.0);
}
