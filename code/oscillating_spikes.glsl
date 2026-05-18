// oscillating_spikes.glsl
// Vertically oscillating magnet drives a traveling wave through the spike array.
// Liquid that dances: wave propagation, phase lag, resonance effects.
//
// Parameters:
//   magnetStrength   — field intensity [0.0 .. 10.0], default 5.0
//   susceptibility   — fluid response [0.1 .. 5.0], default 2.0
//   surfaceTension   — spike resistance [0.1 .. 5.0], default 1.0
//   spikeSharpness   — tip acuity [0.1 .. 3.0], default 1.5
//   fieldOscillation — oscillation frequency [0.0 .. 5.0], default 1.0
//   viscosity        — wave damping [0.1 .. 5.0], default 1.0
//   gravity          — downward restoring force [0.0 .. 2.0], default 1.0

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 5.0
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 1.0
uniform float spikeSharpness;   // default 1.5
uniform float fieldOscillation; // default 1.0
uniform float viscosity;        // default 1.0
uniform float gravity;          // default 1.0

// ─── UTILITIES ───────────────────────────────────────────────────────────────

// Magnet oscillates vertically above the pool centre
vec2 magnetPos() {
    float y = 0.25 + 0.12 * sin(time * fieldOscillation * 6.2831853);
    return vec2(0.0, y);
}

// Dipole field strength
float dipoleField(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float cosTheta = delta.y / r;
    return strength * sqrt(1.0 + 3.0 * cosTheta * cosTheta) / (r2 * r);
}

// Traveling wave surface height
// The oscillation drives capillary waves outward from the magnet contact point.
// Wave velocity c ≈ sqrt(γ/ρ) (surface-tension waves), damped by viscosity.
float waveHeight(vec2 p, float B) {
    float dist  = length(p);
    float freq  = fieldOscillation * 6.2831853;
    float cWave = 0.6 / max(viscosity, 0.1);   // wave speed
    float damp  = exp(-dist * viscosity * 3.0);
    float wave  = sin(dist * 12.0 - time * freq) * damp;
    float spike = B * susceptibility / surfaceTension;
    return spike * 0.1 + wave * 0.04 * susceptibility;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    vec2  mp    = magnetPos();
    vec2  delta = p - mp;
    float B     = dipoleField(delta, magnetStrength);

    float surface = -0.1 * gravity + waveHeight(p, B);
    float sdf     = p.y - surface;

    // Spike narrowing profile using horizontal distance from magnet column
    float spikeProfile = exp(-abs(delta.x) * spikeSharpness * 8.0) *
                         B * susceptibility / surfaceTension * 0.1;
    sdf -= spikeProfile;

    // --- Shading ---
    float mask = smoothstep(0.005, -0.005, sdf);
    float edge = smoothstep(0.016, 0.0, abs(sdf));

    // Wave crests light up the meniscus
    float waveCrest = smoothstep(0.0, 0.01, fract(length(p) * 12.0 - time * fieldOscillation) - 0.88);
    float waveGlow  = waveCrest * mask * 0.12;

    vec3 body  = vec3(0.0, 0.0, 0.0);
    vec3 glint = edge * vec3(0.14, 0.18, 0.25);
    vec3 wGlow = vec3(0.1, 0.2, 0.35) * waveGlow;

    vec3 col = (body + glint + wGlow);
    col = mix(col, vec3(0.0), 1.0 - mask);

    vec3 bg = vec3(0.0, 0.002, 0.01) * (1.0 - uv.y * 0.5);
    col = mix(bg, col, mask + edge * 0.5);

    gl_FragColor = vec4(col, 1.0);
}
