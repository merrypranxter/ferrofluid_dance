// basic_ferrofluid.glsl
// Dipole magnetic field visualization with Rosensweig spike approximation.
// Single magnet, classic black ferrofluid aesthetic.
//
// Parameters (pass as uniforms):
//   magnetStrength   — field intensity [0.0 .. 10.0], default 3.0
//   susceptibility   — fluid magnetic response [0.1 .. 5.0], default 2.0
//   surfaceTension   — resistance to spike formation [0.1 .. 5.0], default 1.0
//   spikeSharpness   — tip acuity [0.1 .. 3.0], default 1.5
//   gravity          — downward pull [0.0 .. 2.0], default 1.0
//   magnetPos        — 2-D position of magnet in UV space

// ─── GLSL 3.00 ES ────────────────────────────────────────────────────────────
#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 3.0
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 1.0
uniform float spikeSharpness;   // default 1.5
uniform float gravity;          // default 1.0
uniform vec2  magnetPos;        // default (0.5, 0.3)

// ─── UTILITIES ───────────────────────────────────────────────────────────────

// Magnetic dipole field magnitude at point p from dipole at origin
// pointing upward (+Y). Returns scalar field strength.
float dipoleField(vec2 p, float strength) {
    float r2 = dot(p, p) + 1e-4;
    float r  = sqrt(r2);
    // Dipole moment aligned with +Y; field magnitude ~ (1/r^3) with
    // angular modulation: |B| ∝ sqrt(1 + 3cos²θ) / r³
    float cosTheta = p.y / r;
    float B = strength * sqrt(1.0 + 3.0 * cosTheta * cosTheta) / (r2 * r);
    return B;
}

// Spike height at surface point from Rosensweig approximation:
//   h ≈ B^2 * χ / (2 * γ * ρg)
// simplified to: h ≈ fieldStrength * susceptibility / surfaceTension
float spikeHeight(float fieldStrength) {
    return fieldStrength * susceptibility / surfaceTension;
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p = (uv - 0.5) * aspect;

    // Magnet position in screen space
    vec2 mPos = (magnetPos - 0.5) * aspect;
    vec2 delta = p - mPos;

    // --- Field at this pixel ---
    float B = dipoleField(delta, magnetStrength);

    // --- Surface height field ---
    // The ferrofluid "pool" occupies the lower half; the surface profile is
    // computed by treating each column as a 1-D height field.
    float h   = spikeHeight(B);
    float surface = mPos.y - gravity * 0.2 + h * 0.15;

    // Signed distance to fluid surface (positive = above, negative = inside fluid)
    float sdf = p.y - surface;

    // Spike sharpening: narrow the spike profile using field gradient
    float spikeProfile = exp(-abs(delta.x) * spikeSharpness * 8.0) * h * 0.15;
    sdf -= spikeProfile;

    // --- Shading ---
    // Body: jet black ferrofluid
    vec3 col = vec3(0.0);

    // Edge glow: thin bright meniscus at the surface
    float edge = smoothstep(0.012, 0.0, abs(sdf));
    col += edge * vec3(0.15, 0.18, 0.22);  // cold blue-white glint

    // Sub-surface depth: very slight warm highlight deeper in
    float depth = smoothstep(0.0, -0.3, sdf);
    col += depth * 0.04 * vec3(0.4, 0.3, 0.2);

    // Mask: only draw fluid below (or near) the surface
    float mask = smoothstep(0.004, -0.004, sdf);
    col *= mask;

    // Background: near-black with subtle blue gradient
    vec3 bg = vec3(0.0, 0.004, 0.012) * (1.0 - uv.y * 0.5);
    col = mix(bg, col, mask);

    gl_FragColor = vec4(col, 1.0);
}
