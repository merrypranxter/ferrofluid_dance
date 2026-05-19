// multi_magnet.glsl
// Field superposition from multiple magnetic dipoles.
// Spike competition zones, field line interference, hexagonal symmetry emergence.
//
// Parameters:
//   magnetCount      — number of magnets [1 .. 20], default 3
//   magnetStrength   — field intensity per magnet [0.0 .. 10.0], default 3.0
//   susceptibility   — fluid response [0.1 .. 5.0], default 2.0
//   surfaceTension   — spike resistance [0.1 .. 5.0], default 1.0
//   spikeSharpness   — tip acuity [0.1 .. 3.0], default 1.5
//   fieldOscillation — magnet drift speed [0.0 .. 5.0], default 0.5

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform int   magnetCount;      // default 3
uniform float magnetStrength;   // default 3.0
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 1.0
uniform float spikeSharpness;   // default 1.5
uniform float fieldOscillation; // default 0.5

// ─── MAX MAGNETS (GLSL ES: no dynamic array allocation) ─────────────────────
#define MAX_MAGNETS 20

// ─── UTILITIES ───────────────────────────────────────────────────────────────

float hash(float n) { return fract(sin(n) * 43758.5453); }
float hash2(vec2 v) { return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453); }

// Arrange magnets on a slow orbit; each has its own phase offset
vec2 magnetPosition(int i, float t) {
    float fi    = float(i);
    float angle = 6.2831853 * hash(fi) + t * fieldOscillation * (0.3 + 0.2 * hash(fi + 7.0));
    float radius = 0.18 + 0.14 * hash(fi + 3.0);
    return vec2(cos(angle), sin(angle) * 0.6) * radius;
}

// Dipole field magnitude (same derivation as basic_ferrofluid.glsl)
float dipoleField(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float cosTheta = delta.y / r;
    return strength * sqrt(1.0 + 3.0 * cosTheta * cosTheta) / (r2 * r);
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    // --- Accumulate field from all magnets ---
    float totalB  = 0.0;
    float totalBx = 0.0;   // for gradient-based spike sharpening

    int n = min(magnetCount, MAX_MAGNETS);
    for (int i = 0; i < MAX_MAGNETS; i++) {
        if (i >= n) break;
        vec2  mp    = magnetPosition(i, time);
        vec2  delta = p - mp;
        float B     = dipoleField(delta, magnetStrength);
        totalB  += B;
        totalBx += B * exp(-abs(delta.x) * spikeSharpness * 6.0);
    }

    // Clamp to avoid extreme saturation when magnets stack
    totalB  = min(totalB,  20.0);
    totalBx = min(totalBx, 20.0);

    // --- Surface height from Rosensweig approximation ---
    float h       = totalB * susceptibility / surfaceTension;
    float surface = -0.05 + h * 0.08;

    // Spike profile shaped by horizontal field gradient
    float sdf = p.y - surface - totalBx * 0.08;

    // --- Shading ---
    vec3 col = vec3(0.0);

    // Fluid body
    float mask = smoothstep(0.005, -0.005, sdf);

    // Surface edge meniscus glow
    float edge = smoothstep(0.015, 0.0, abs(sdf));
    col += edge * vec3(0.12, 0.16, 0.22) * (1.0 + 0.5 * h);

    // Field-line highlight: bright threads where field is strongest
    float fieldLine = smoothstep(0.4, 0.0, fract(totalB * 0.6) - 0.02) *
                      smoothstep(0.4, 0.0, 0.02 - fract(totalB * 0.6));
    col += fieldLine * 0.08 * vec3(0.3, 0.5, 0.8) * mask;

    // Background
    vec3 bg = vec3(0.0, 0.003, 0.01) * (1.0 - uv.y * 0.6);
    col = mix(bg, col, mask);

    gl_FragColor = vec4(col, 1.0);
}
