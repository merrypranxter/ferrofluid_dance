// cosmic_ferrofluid.glsl
// Astronomical-scale ferrofluid: magnetar moons, solar prominences,
// galaxy filaments, accretion disk magnetohydrodynamics.
// The physics is identical — only the scale changes.
//
// Parameters:
//   magnetStrength   — field intensity [0.0 .. 10.0], default 6.0
//   susceptibility   — fluid magnetic response [0.1 .. 5.0], default 3.0
//   surfaceTension   — surface energy (stand-in for plasma pressure) [0.1 .. 5.0], default 0.5
//   fieldOscillation — rotation / oscillation speed [0.0 .. 5.0], default 0.4
//   gravity          — effective gravity [0.0 .. 2.0], default 0.3

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 6.0
uniform float susceptibility;   // default 3.0
uniform float surfaceTension;   // default 0.5
uniform float fieldOscillation; // default 0.4
uniform float gravity;          // default 0.3

// ─── NOISE ───────────────────────────────────────────────────────────────────
float hash(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f*f*(3.0-2.0*f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}
float fbm(vec2 v, int oct) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 6; i++) {
        if (i >= oct) break;
        s += noise(v) * a;
        v *= 2.1; a *= 0.5;
    }
    return s;
}

// ─── MAGNETIC FIELD HELPERS ──────────────────────────────────────────────────

// Toroidal field from rotating magnetar (poloidal slice)
float magnetarField(vec2 p, float t) {
    float angle = t * fieldOscillation * 6.2831853;
    vec2  pole1 = vec2(cos(angle), sin(angle)) * 0.08;
    vec2  pole2 = -pole1;
    float B1 = magnetStrength / (dot(p-pole1, p-pole1) + 0.004);
    float B2 = magnetStrength / (dot(p-pole2, p-pole2) + 0.004);
    return (B1 + B2) * 0.01;
}

// Galaxy filament field — elongated along x-axis, current-sheet-like
float filamentField(vec2 p) {
    float dist = abs(p.y + 0.05 * sin(p.x * 4.0 + time * fieldOscillation));
    return magnetStrength * 0.3 / (dist * 8.0 + 0.02);
}

// Solar prominence: fountain of fluid erupting from lower edge
float prominenceField(vec2 p, float t) {
    float angle = t * fieldOscillation * 2.5;
    vec2  footL = vec2(-0.25 + sin(angle) * 0.05, -0.28);
    vec2  footR = vec2(0.25 + cos(angle) * 0.05,  -0.28);
    float BL = magnetStrength * 0.5 / (dot(p-footL, p-footL)*30.0 + 0.01);
    float BR = magnetStrength * 0.5 / (dot(p-footR, p-footR)*30.0 + 0.01);
    return BL + BR;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    // Composite cosmic field
    float B = magnetarField(p, time) +
              filamentField(p)       +
              prominenceField(p, time);

    // Plasma/fluid surface approximation
    float h = B * susceptibility / surfaceTension;

    // Prominence fountain SDF: fluid rises in arcs from the solar equator
    float equator  = -0.28;
    float arcR     = 0.3;
    float sdfDisk  = p.y - equator;   // below equator = inside body
    float surfaceH = equator + h * 0.07 +
                     fbm(p * 5.0 + time * 0.1, 4) * 0.02 * B;
    float sdf = p.y - surfaceH;

    // --- Shading ---
    float mask  = smoothstep(0.008, -0.008, sdf);

    // Stellar body: deep orange-red glow beneath equator
    float body  = smoothstep(0.0, -0.15, sdf);
    vec3  star  = vec3(0.6, 0.15, 0.02) * body;

    // Prominence glow: orange-gold plasma arcs
    float edge  = smoothstep(0.025, 0.0, abs(sdf));
    float prom  = prominenceField(p, time);
    vec3  promC = vec3(0.9, 0.4, 0.05) * prom * 0.015 * edge;

    // Filament glow: cold blue-white cosmic threads
    float fil  = filamentField(p);
    float filG = smoothstep(0.3, 0.0, abs(p.y)) * fil * 0.02;
    vec3  filC = vec3(0.2, 0.35, 0.65) * filG;

    // Starfield background
    vec2  starSeed = floor(p * 120.0);
    float star2    = step(0.985, hash(starSeed)) * 0.6;
    vec3  bg       = vec3(0.0, 0.0, 0.008) + star2 * vec3(0.8, 0.9, 1.0) * 0.3;

    vec3 col = mix(bg, star + promC + filC + edge * vec3(0.8, 0.5, 0.1) * 0.3, mask);
    col += promC * (1.0 - mask) + filC * (1.0 - mask);

    gl_FragColor = vec4(col, 1.0);
}
