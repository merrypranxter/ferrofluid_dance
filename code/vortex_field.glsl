// vortex_field.glsl
// Rotating magnetic dipole creates spiral arm structures — galaxy-like ferrofluid.
// The magnet spins; the fluid chases it; the spikes form trailing arcs.
//
// Parameters:
//   magnetStrength   — field intensity [0.0 .. 10.0], default 4.0
//   susceptibility   — fluid response [0.1 .. 5.0], default 2.5
//   surfaceTension   — spike resistance [0.1 .. 5.0], default 0.8
//   fieldOscillation — rotation speed [0.0 .. 5.0], default 1.2
//   viscosity        — fluid lag behind field [0.1 .. 5.0], default 1.0

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 4.0
uniform float susceptibility;   // default 2.5
uniform float surfaceTension;   // default 0.8
uniform float fieldOscillation; // default 1.2
uniform float viscosity;        // default 1.0

// ─── UTILITIES ───────────────────────────────────────────────────────────────

mat2 rot2D(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

// Dipole field in 2-D with arbitrary moment direction
// m  — unit vector of dipole moment
// p  — displacement from dipole
// strength — scalar magnitude
float dipoleField(vec2 p, vec2 m, float strength) {
    float r2 = dot(p, p) + 1e-4;
    float r  = sqrt(r2);
    float mdotr = dot(m, p / r);
    return strength * sqrt(1.0 + 3.0 * mdotr * mdotr) / (r2 * r);
}

// Viscous lag: the fluid's field response is phase-shifted behind the magnet
float laggedField(vec2 p, float t, float strength) {
    float lag   = 1.0 / max(viscosity, 0.1);  // high viscosity → slow response
    float angle = t * fieldOscillation;

    // Primary (current) magnet position
    float r0 = 0.22;
    vec2  mp0 = vec2(cos(angle), sin(angle)) * r0;
    vec2  m0  = vec2(cos(angle + 1.5708), sin(angle + 1.5708)); // moment ⊥ orbit
    float B0  = dipoleField(p - mp0, m0, strength);

    // Ghost (lagged) position — represents fluid memory
    float lagAngle = angle - lag * 0.4;
    vec2  mp1 = vec2(cos(lagAngle), sin(lagAngle)) * r0;
    vec2  m1  = vec2(cos(lagAngle + 1.5708), sin(lagAngle + 1.5708));
    float B1  = dipoleField(p - mp1, m1, strength * 0.5);

    return B0 + B1;
}

// Spiral arm pattern: spikes form along the trailing arm
float spiralArm(vec2 p, float t) {
    float angle  = t * fieldOscillation;
    float r      = length(p);
    float theta  = atan(p.y, p.x);
    // Archimedean spiral: θ - t - r*k = 0 at arm centre
    float k      = 4.0;
    float armPhase = fract((theta - angle - r * k) / 6.2831853);
    return exp(-armPhase * armPhase * 80.0) + exp(-(armPhase - 1.0) * (armPhase - 1.0) * 80.0);
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    float B   = laggedField(p, time, magnetStrength);
    float arm = spiralArm(p, time);

    // --- Surface height ---
    float h       = B * susceptibility / surfaceTension;
    float surface = 0.0 + h * 0.06 + arm * 0.04 * susceptibility;
    float r       = length(p);
    float sdf     = r - 0.28 - surface;   // radial SDF for circular pool

    // --- Shading ---
    float mask = smoothstep(0.006, -0.006, sdf);

    // Spiral arm glow
    vec3 armColor = vec3(0.05, 0.12, 0.22) * arm * mask;

    // Surface meniscus
    float edge = smoothstep(0.02, 0.0, abs(sdf));
    vec3  glint = edge * vec3(0.18, 0.22, 0.3);

    // Vortex center: brighter due to converging field lines
    float center = exp(-r * 8.0) * 0.15;
    vec3  cCore  = vec3(0.1, 0.15, 0.25) * center * mask;

    vec3 col = (armColor + glint + cCore) * mask;

    vec3 bg = vec3(0.0, 0.002, 0.008);
    col = mix(bg, col, mask * 0.98 + edge * 0.02);

    gl_FragColor = vec4(col, 1.0);
}
