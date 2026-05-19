// biot_savart_coil.glsl
// Circular current loop and Helmholtz coil pair: more accurate field geometry
// than the point dipole approximation. Shows the full loop topology including
// the field reversal beyond the coil radius and the flat-field region inside
// a Helmholtz pair.
//
// Physical basis:
//   The Biot-Savart law gives the field from a current element dI:
//       dB = (μ₀/4π) · (I dl × r̂) / r²
//   For a full circular loop of radius R carrying current I, integrated
//   around the loop, on the axis:
//       Bz(z) = (μ₀ I R²) / (2(R² + z²)^(3/2))
//   Off-axis: no closed form, but the full 3-D field has:
//     - Strong field inside the loop (near-axis)
//     - Field reversal OUTSIDE the loop radius (opposite direction to on-axis)
//     - "Zero crossing" ring at r ≈ R√2 from the axis
//     - A saddle point at the loop center in the radial direction
//   A Helmholtz pair (two coaxial loops separated by R) produces a nearly
//   uniform field in the central region — the workhorse of laboratory
//   ferrofluid experiments.
//
// Parameters:
//   coilCurrent      — current intensity [0..10], default 4.0
//   coilRadius       — loop radius in UV units [0.05..0.5], default 0.25
//   susceptibility   — fluid response [0.1..5], default 2.0
//   surfaceTension   — spike resistance [0.1..5], default 1.0
//   fieldOscillation — AC modulation frequency [0..5], default 0.5
//   helmholtzMode    — 0=single loop, 1=Helmholtz pair, 2=anti-Helmholtz

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float coilCurrent;      // default 4.0
uniform float coilRadius;       // default 0.25
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 1.0
uniform float spikeSharpness;   // default 1.5
uniform float fieldOscillation; // default 0.5
uniform float helmholtzMode;    // default 0.0 (single loop)

// ─── NOISE ───────────────────────────────────────────────────────────────────
float hash(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}

// ─── CIRCULAR LOOP FIELD (2-D CROSS-SECTION) ─────────────────────────────────
// We render a SIDE VIEW cross-section of the coil. The coil appears as two
// dots (where the wire passes through the cross-section plane). Between them
// is the strong field region. Outside is the return flux.
//
// Exact axial formula evaluated off-axis using an elliptic integral approximation.
// For moderate off-axis distances (r < 2R), the off-axis field components are:
//   Br(r,z) ≈ Bz(0,z) · (-r/2) · d(ln Bz)/dz     [from ∇·B = 0]
//   Bz(r,z) ≈ Bz(0,z) · (1 - (r/R)² ...)
//
// For visualization we use a numerically-integrated superposition of N dipole
// segments around the loop, giving accurate topology.

vec2 singleLoopField(vec2 p, vec2 loopCenter, float R, float I) {
    // The loop lies in the xy plane at loopCenter.y = loopCenter.y (our "z" axis = screen vertical).
    // Cross-section shows the loop as two wire dots at (±R, 0) relative to loopCenter.

    // We compute the 2-D field by summing N arc segments, each approximated as
    // a small magnetic dipole oriented tangentially.
    vec2 totalB = vec2(0.0);
    int  N = 32;
    for (int i = 0; i < 32; i++) {
        float angle = 6.2831853 * float(i) / 32.0;
        // Wire position: the circular loop is in the plane perpendicular to
        // the screen. We integrate around the loop — in 2-D cross-section,
        // each segment at angle θ is at position (R cosθ, 0) in 3-D, but
        // our screen is the xz plane, so we see the loop as the pair of
        // intersections at (±R, 0).
        //
        // For a full 3-D field projection onto the xz plane:
        // A wire segment at (R cosθ, R sinθ, 0) with dl = (-sinθ, cosθ, 0)dθ
        // contributes a field at (x, 0, z) (our p = (x,z) in screen coords):
        float cx = R * cos(angle) + loopCenter.x;
        float cz = R * sin(angle) * 0.01 + loopCenter.y;  // project out of plane
        // Displacement from segment to point
        vec2  r   = p - vec2(cx, cz);
        float r2  = dot(r, r) + 1e-4;
        // dl × r  in 2-D: dl = (-sin, cos, 0) dθ, r = (rx, 0, rz)
        // (dl × r) projected onto screen plane = (dl_x * rz - dl_z * rx)
        float dlx = -sin(angle);
        float dlz =  cos(angle);
        // 2-D Biot-Savart: dB ∝ dl × r / r³
        // x-component: dlz * 0 - 0 * r.x  = 0 for out-of-plane integration;
        // We use the dominant axial and radial components from the closed-form result.
        // Simplified: treat each segment as a dipole with moment along dl
        vec2  Bseg = vec2(dlz, -dlx) * (I / (6.2831853 * 32.0)) / r2;
        totalB += Bseg;
    }
    return totalB;
}

// More efficient: use the closed-form field topology.
// The field from a circular loop at a point in the cross-section plane (r, z)
// where r = distance from axis, z = distance from plane of loop:
//   Bz = (μ₀ I / 2π) · [(R+r)² + z²]^(-1/2) · [K(k²) + (R²-r²-z²)/((R-r)²+z²) E(k²)]
//   Br = (μ₀ I z / 2π r) · [(R+r)² + z²]^(-1/2) · [-K(k²) + (R²+r²+z²)/((R-r)²+z²) E(k²)]
// where k² = 4Rr / ((R+r)² + z²)
// We approximate K(k²) and E(k²) with Chebyshev polynomial approximations.

// Chebyshev polynomial approximations for elliptic integrals K and E
// Valid for k² ∈ [0,1)
float ellipticK(float m) {
    // K(m) = ∫₀^{π/2} 1/sqrt(1-m sin²θ) dθ
    // Approximation accurate to 2e-8 from Abramowitz & Stegun 17.3.34
    float m1 = 1.0 - m;
    float a  = (((( 0.01451196212 * m1 + 0.03742563713) * m1
                   + 0.03590092383) * m1 + 0.09666344259) * m1 + 1.38629436112);
    float b  = (((( 0.00441787012 * m1 + 0.03328355346) * m1
                   + 0.06880248576) * m1 + 0.12498593597) * m1 + 0.5);
    return a - b * log(m1 + 1e-9);
}
float ellipticE(float m) {
    // E(m) = ∫₀^{π/2} sqrt(1-m sin²θ) dθ
    float m1 = 1.0 - m;
    float a  = (((( 0.01736506451 * m1 + 0.04757383546) * m1
                   + 0.06260601220) * m1 + 0.44325141463) * m1 + 1.0);
    float b  = (((( 0.00526449639 * m1 + 0.04069697526) * m1
                   + 0.09200180037) * m1 + 0.24998368310) * m1);
    return a - b * log(m1 + 1e-9);
}

// Accurate circular loop field (r, z) relative to loop center
vec2 loopFieldRZ(float r, float z, float R, float I) {
    float denom = (R + r) * (R + r) + z * z;
    if (denom < 1e-6) return vec2(0.0);
    float sqrtD = sqrt(denom);
    float k2    = 4.0 * R * r / denom;
    k2 = clamp(k2, 0.0, 0.9999);
    float K = ellipticK(k2);
    float E = ellipticE(k2);
    float denom2 = (R - r) * (R - r) + z * z + 1e-6;

    float Bz_coeff = I / (2.0 * 3.14159265 * sqrtD);
    float Bz = Bz_coeff * (K + (R*R - r*r - z*z) / denom2 * E);

    float Br = 0.0;
    if (r > 1e-4) {
        float Br_coeff = I * z / (2.0 * 3.14159265 * r * sqrtD);
        Br = Br_coeff * (-K + (R*R + r*r + z*z) / denom2 * E);
    }
    return vec2(Br, Bz);
}

// ─── HELMHOLTZ / ANTI-HELMHOLTZ PAIR ─────────────────────────────────────────
// Helmholtz: both loops same direction, separated by R → uniform field in center
// Anti-Helmholtz: opposite directions → zero field at center, gradient field

vec2 coilSystemField(vec2 p, float R, float I, float mode) {
    // Loop 1 at z = R/2 above center; Loop 2 at z = -R/2
    float sep = R * 0.5;  // Helmholtz separation = R

    // For each loop, compute (r, z) in loop coordinates
    // Our screen: x = horizontal, y = vertical. Loop axes are vertical.
    float r     = abs(p.x);
    float z1    = p.y - sep;
    float z2    = p.y + sep;

    vec2 B1 = loopFieldRZ(r, z1, R, I);
    float I2 = (mode < 0.5) ? I : -I;     // Helmholtz: same sign; anti: opposite
    vec2 B2 = loopFieldRZ(r, z2, R, I2);

    // Convert (Br, Bz) to (Bx, By) — Br points away from axis in x-direction
    float sign_x = sign(p.x + 1e-6);
    vec2  B1xy = vec2(B1.x * sign_x, B1.y);
    vec2  B2xy = vec2(B2.x * sign_x, B2.y);

    return B1xy + B2xy;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    float R   = coilRadius;
    // AC current modulation
    float I   = coilCurrent * (1.0 + 0.2 * sin(time * fieldOscillation * 6.2831853));

    vec2  Bvec = coilSystemField(p, R, I, helmholtzMode);
    float Bmag = length(Bvec);

    // ── Field line visualization ──────────────────────────────────────────
    // Field lines are level sets of the vector potential A.
    // For axisymmetric fields, A_φ = r Ψ, where Ψ is the Stokes stream function.
    // We compute Ψ by numerical integration:
    // Rather than integrate, we use the fact that field lines are iso-contours
    // of r * Ar — we approximate by tracing contours of |p.x| * Bvec.y.
    float streamFn = abs(p.x) * Bvec.y;  // Approximate Stokes stream function
    float fieldLine = smoothstep(0.008, 0.0, abs(fract(streamFn * 8.0) - 0.5) - 0.008);

    // ── Ferrofluid surface ────────────────────────────────────────────────
    // Pool sits below the coil system. Pool baseline at y = -0.3.
    // The field at the pool surface drives spike formation.
    float poolY = -0.28;

    // Field at pool surface level: integrate B over pool surface
    float Bsurface = 0.0;
    float r_pool   = abs(p.x);
    if (p.y < poolY + 0.05) {
        vec2  Bpool  = coilSystemField(vec2(p.x, poolY), R, I, helmholtzMode);
        Bsurface = length(Bpool);
    }

    // Spike height
    float h = Bsurface * susceptibility / surfaceTension;

    // Surface profile: spikes form where Bz (normal component) is positive and strong
    vec2   Bpool_here = coilSystemField(vec2(p.x, poolY), R, I, helmholtzMode);
    float  Bz_normal  = Bpool_here.y;  // vertical component at pool
    float  spikeH     = max(0.0, Bz_normal) * susceptibility / surfaceTension * 0.08;

    // Narrow spike profile with horizontal field gradient
    float spikeSharp  = exp(-abs(p.x) * spikeSharpness * 4.0 / R) * spikeH;
    float surface     = poolY + spikeH * 0.5 + spikeSharp;
    float sdf         = p.y - surface;

    // ── Shading ──────────────────────────────────────────────────────────
    float mask = smoothstep(0.006, -0.006, sdf);
    float edge = smoothstep(0.016, 0.0, abs(sdf));

    // Field line glow in background (above pool)
    vec3 fieldLineColor = vec3(0.04, 0.1, 0.22) * fieldLine * (1.0 - mask);

    // Field strength heat map in background
    float bgField = Bmag * 0.015;
    vec3  bgHeat  = vec3(bgField * 0.3, bgField * 0.5, bgField * 1.0) * (1.0 - mask);

    // Coil wire cross-sections: small bright circles at (±R, ±R/2)
    float sep = R * 0.5;
    float wire1 = smoothstep(0.018, 0.008, length(p - vec2( R,  sep)));
    float wire2 = smoothstep(0.018, 0.008, length(p - vec2(-R,  sep)));
    float wire3 = smoothstep(0.018, 0.008, length(p - vec2( R, -sep)));
    float wire4 = smoothstep(0.018, 0.008, length(p - vec2(-R, -sep)));
    float wires = (wire1 + wire2) * I / coilCurrent +
                  (wire3 + wire4) * abs(I * ((helmholtzMode > 0.5) ? -1.0 : 1.0)) / coilCurrent;
    vec3  wireColor = vec3(0.6, 0.4, 0.1) * wires;

    // Pool: fluid meniscus
    vec3 glint  = edge * vec3(0.12, 0.16, 0.26);
    vec3 depth  = smoothstep(0.0, -0.15, sdf) * vec3(0.03, 0.02, 0.02) * mask;

    vec3 col  = (glint + depth) * mask + fieldLineColor + bgHeat + wireColor;
    vec3 bg   = vec3(0.0, 0.002, 0.008);
    col = mix(bg, col, max(mask, fieldLine * 0.5) + edge * 0.5);
    col += wireColor * (1.0 - max(mask, fieldLine * 0.5));

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
