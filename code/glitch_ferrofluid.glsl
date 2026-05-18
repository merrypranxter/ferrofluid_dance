// glitch_ferrofluid.glsl
// Corrupted magnetism: sick spikes, strobe artifacts, dead zones, field reversals.
// The fluid is broken, diseased, traumatized.
//
// Parameters:
//   magnetStrength   — field intensity [0.0 .. 10.0], default 4.0
//   susceptibility   — fluid response [0.1 .. 5.0], default 2.0
//   surfaceTension   — spike resistance [0.1 .. 5.0], default 1.0
//   glitchAmount     — corruption intensity [0.0 .. 1.0], default 0.6
//   fieldOscillation — base oscillation speed [0.0 .. 5.0], default 1.0

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 4.0
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 1.0
uniform float glitchAmount;     // default 0.6
uniform float fieldOscillation; // default 1.0

// ─── NOISE / HASH ────────────────────────────────────────────────────────────
float hash(float n)  { return fract(sin(n)   * 43758.5453); }
float hash2(vec2 v)  { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(hash2(i),          hash2(i+vec2(1,0)), u.x),
               mix(hash2(i+vec2(0,1)),hash2(i+vec2(1,1)), u.x), u.y);
}

// ─── GLITCH HELPERS ──────────────────────────────────────────────────────────

// UV displacement glitch — horizontal bands that jump
vec2 glitchUV(vec2 p, float t, float amount) {
    float band  = floor(p.y * 14.0);
    float shift = (hash(band + floor(t * 12.0)) - 0.5) * amount * 0.06;
    float active = step(0.7, hash(band + floor(t * 7.0)));  // only some bands glitch
    return p + vec2(shift * active, 0.0);
}

// Corrupted field: non-uniform magnetization, patchy dead zones
float corruptField(vec2 p, float strength, float amount, float t) {
    // Base dipole
    float r2 = dot(p, p) + 1e-4;
    float r  = sqrt(r2);
    float ct = p.y / r;
    float B  = strength * sqrt(1.0 + 3.0 * ct * ct) / (r2 * r);

    // Partial demagnetization: multiply by patchy noise
    float corruption = mix(1.0, noise(p * 8.0 + t * 0.3) * 2.0, amount);
    B *= corruption;

    // Dead zone: field reversal pocket near random point
    vec2  deadCenter = vec2(hash(floor(t * 0.2)) - 0.5, hash(floor(t * 0.2) + 1.0) - 0.5) * 0.25;
    float deadRadius = 0.04 + 0.03 * amount;
    float dead = 1.0 - smoothstep(deadRadius * 0.5, deadRadius, length(p - deadCenter));
    B *= (1.0 - dead * amount);

    // Rapid field reversal strobe: fluid can't keep up
    float strobe = sign(sin(t * fieldOscillation * 20.0 * amount));
    B *= mix(1.0, strobe, amount * 0.4);

    return B;
}

// Twisted, bent spike profile (non-uniform field → deformed spikes)
float sickeningSpike(vec2 delta, float B, float amount, float t) {
    float twist = noise(vec2(delta.x * 6.0, t * 2.0)) * amount * 0.04;
    float sharpX = abs(delta.x + twist);
    return exp(-sharpX * 7.0) * B * susceptibility / surfaceTension * 0.1;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 raw    = (uv - 0.5) * aspect;

    // Glitch the UV coordinates
    vec2 p = glitchUV(raw, time, glitchAmount);

    vec2  mp    = vec2(sin(time * fieldOscillation * 0.7) * 0.15, 0.24);
    vec2  delta = p - mp;

    float B = corruptField(delta, magnetStrength, glitchAmount, time);

    // Surface height with sick spike profile
    float spike   = sickeningSpike(delta, B, glitchAmount, time);
    float surface = -0.06 + B * susceptibility / surfaceTension * 0.06 + spike;
    float sdf     = p.y - surface;

    // --- Shading ---
    float mask = smoothstep(0.005, -0.005, sdf);
    float edge = smoothstep(0.014, 0.0, abs(sdf));

    // Normal edge: cold blue-white
    vec3 glint = edge * vec3(0.12, 0.15, 0.22);

    // Glitch color aberration: RGB split along x
    float aberration = glitchAmount * 0.004;
    float edgeR = smoothstep(0.014, 0.0, abs(p.y - surface - aberration));
    float edgeG = edge;
    float edgeB = smoothstep(0.014, 0.0, abs(p.y - surface + aberration));
    vec3  aberrant = vec3(edgeR, edgeG, edgeB) * 0.25 * glitchAmount;

    // Dead zone: dark "wound" in the field — flat black circle
    vec2  deadCenter = vec2(hash(floor(time * 0.2)) - 0.5,
                            hash(floor(time * 0.2) + 1.0) - 0.5) * 0.25;
    float wound = smoothstep(0.06, 0.03, length(p - deadCenter)) * glitchAmount;
    vec3  woundC = vec3(0.0, 0.0, 0.0) * wound;

    // Strobe flash: periodic full-white flash at reversal moment
    float strobeFlash = smoothstep(0.04, 0.0, abs(fract(time * fieldOscillation * glitchAmount + 0.5) - 0.5));
    vec3  flash = vec3(0.05, 0.05, 0.08) * strobeFlash;

    vec3 col = glint + aberrant - woundC;
    vec3 bg  = vec3(0.0, 0.001, 0.006) + flash;
    col = mix(bg, col, mask + edge * 0.5);

    gl_FragColor = vec4(col, 1.0);
}
