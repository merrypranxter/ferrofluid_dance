// inverse_ferrofluid.glsl
// INVERTED scenario: ferrofluid is the MINORITY PHASE in a non-magnetic
// carrier fluid. Instead of spikes pointing up from a black pool, you see:
// - Black ferrofluid BUBBLES / DROPLETS suspended in a light carrier
// - Negative-curvature meniscus (concave, not convex) at ferrofluid surfaces
// - "Anti-spikes": the ferrofluid is pulled TOWARD the magnet while the
//   carrier is pushed away
// - Bubble elongation, coalescence, splitting
// - Wormlike channels threading through the carrier
//
// Physical basis:
//   If χ_fluid >> χ_carrier (ferrofluid more magnetic), the Kelvin force
//   pulls ferrofluid toward the magnet. But if we reverse: put the magnet
//   in a high-χ background and use low-χ droplets, the droplets are EXPELLED.
//   This creates Ferrofluid Inverse Emulsions (FIE).
//
//   More practically: when ferrofluid is injected as droplets into oil
//   and a magnet is brought close, the droplets elongate along field lines
//   (prolate deformation), then at critical field, form a chain (wormlike
//   micelles of ferrofluid). At very high field, the chain creates a column
//   that reaches the magnet — the "magnetic Rayleigh-Taylor instability" in reverse.
//
// Parameters:
//   magnetStrength   — field intensity [0..10], default 5.0
//   susceptibility   — ferrofluid droplet susceptibility [0.1..5], default 3.0
//   surfaceTension   — interfacial tension [0.1..5], default 0.8
//   fieldOscillation — magnet modulation [0..5], default 0.4
//   dropletCount     — number of droplets [1..20], default 8
//   chainMode        — 0=independent droplets, 1=chaining, default 0.5

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 5.0
uniform float susceptibility;   // default 3.0
uniform float surfaceTension;   // default 0.8
uniform float fieldOscillation; // default 0.4
uniform float dropletCount;     // default 8.0
uniform float chainMode;        // default 0.5

// ─── HASH / NOISE ─────────────────────────────────────────────────────────────
float hash1(float n) { return fract(sin(n) * 43758.5453); }
float hash(vec2 v)   { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}

// ─── MAGNET POSITION ─────────────────────────────────────────────────────────
vec2 magnetPos(float t) {
    return vec2(sin(t * fieldOscillation * 1.5) * 0.1, 0.3);
}

// Dipole field magnitude
float dipoleField(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float ct = delta.y / r;
    return strength * sqrt(1.0 + 3.0 * ct * ct) / (r2 * r);
}

// Dipole field vector (for droplet elongation direction)
vec2 dipoleFieldVec(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float r5 = r2 * r2 * r;
    // B = (μ₀/4π)[3(m̂·r̂)r̂ - m̂] / r³, m̂ = (0,1) (vertical dipole)
    vec2 m  = vec2(0.0, 1.0);
    float mdotr = dot(m, delta / r);
    return strength * (3.0 * mdotr * (delta / r) - m) / (r2 * r);
}

// ─── DROPLET SDF ─────────────────────────────────────────────────────────────
// A single ferrofluid droplet deforms into a prolate ellipsoid along the
// field direction. Elongation ratio depends on the Bond number.
float dropletSDF(vec2 p, vec2 center, float radius, vec2 fieldDir, float deform) {
    // Transform to ellipse coordinates
    vec2  d     = p - center;
    // Project onto field and perpendicular
    float along = dot(d, fieldDir);
    vec2  fdperp = vec2(-fieldDir.y, fieldDir.x);
    float perp  = dot(d, fdperp);

    // Prolate ellipse: semi-axes (radius * (1+deform)) along field, (radius / sqrt(1+deform)) perp
    float a = radius * (1.0 + deform);
    float b = radius / sqrt(1.0 + deform);

    return (along * along) / (a * a) + (perp * perp) / (b * b) - 1.0;
}

// Smooth minimum — for droplet coalescence / chaining
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    vec2  mp   = magnetPos(time);
    float Bfield = dipoleField(p - mp, magnetStrength);

    int N = int(clamp(dropletCount, 1.0, 20.0));

    // Compute the composite SDF for all droplets
    float minSDF  = 1e9;
    float totalAct = 0.0;  // for coloring

    for (int i = 0; i < 20; i++) {
        if (i >= N) break;
        float fi = float(i);

        // Initial droplet positions: distributed in the pool
        vec2 initPos = vec2((hash1(fi * 2.3 + 1.1) - 0.5) * 0.7,
                             hash1(fi * 3.7 + 0.5) * 0.4 - 0.3);

        // Droplet drifts toward the magnet due to Kelvin force
        // Velocity ∝ ∇(B²) ∝ -∇(1/r^6) for dipole → toward the magnet
        vec2  toMag      = mp - initPos;
        float toMagLen   = length(toMag);
        float BatDroplet = dipoleField(initPos - mp, magnetStrength);
        // Drift amplitude: scales with susceptibility, inversely with viscosity-like surfaceTension
        float drift = BatDroplet * susceptibility * 0.003 / surfaceTension;
        vec2  driftVec = normalize(toMag + 1e-5) * drift;
        // Accumulate drift over time (with oscillatory component for realism)
        float phase  = hash1(fi + 50.0) * 6.2831853;
        vec2  pos    = initPos + driftVec * (time * 0.2 + sin(time * fieldOscillation * 2.0 + phase) * 0.01);

        // Clamp to a sensible range so droplets don't leave the frame
        pos = clamp(pos, vec2(-0.6, -0.45), vec2(0.6, 0.4));

        // Droplet radius (some variation)
        float radius = 0.04 + hash1(fi + 77.0) * 0.03;

        // Elongation: field strength at droplet location drives deformation
        float B_here = dipoleField(pos - mp, magnetStrength);
        float deform = clamp(B_here * susceptibility / (surfaceTension * 10.0), 0.0, 2.0);

        // Field direction at droplet position (for elongation axis)
        vec2  Bvec  = dipoleFieldVec(pos - mp, 1.0);
        float Blen  = length(Bvec);
        vec2  Bdir  = (Blen > 1e-4) ? Bvec / Blen : vec2(0.0, 1.0);

        float dSDF = dropletSDF(p, pos, radius, Bdir, deform);
        totalAct  += B_here;

        // Chaining mode: blend SDFs of adjacent droplets together
        float chainK = chainMode * 0.04;
        minSDF = smin(minSDF, dSDF, chainK);
    }

    // Field lines through the carrier (visible as faint streaks)
    float streamFn  = atan(p.y - mp.y, p.x - mp.x) / 6.2831853;
    float fieldLine = smoothstep(0.01, 0.0, abs(fract(streamFn * 12.0 + 0.5) - 0.5) - 0.005);

    // ─── SHADING ─────────────────────────────────────────────────────────────
    // Inside droplets = jet black ferrofluid
    // Outside = bright carrier fluid (amber/gold to suggest oil)

    float droplet = smoothstep(0.01, -0.01, minSDF);  // 1 inside droplet
    float edge    = smoothstep(0.025, 0.0, abs(minSDF));

    // Carrier: warm amber/gold
    vec3  carrierColor = vec3(0.7, 0.55, 0.25);

    // Field gradient in carrier: brighter near magnet
    float fieldShade = Bfield * 0.01;
    carrierColor = mix(carrierColor, carrierColor * 1.3, fieldShade);

    // Ferrofluid interior: jet black with subtle subsurface brownish tint at edges
    vec3  dropletColor = vec3(0.0);
    float innerEdge    = smoothstep(0.0, -0.06, minSDF);  // positive = closer to surface
    dropletColor += vec3(0.08, 0.04, 0.01) * innerEdge;   // reddish-brown subsurface

    // Edge meniscus: thin bright ring (the concave meniscus in inverted scenario
    // is slightly narrower/darker than the convex case)
    vec3 edgeColor = vec3(0.15, 0.1, 0.04) * edge;

    // Field line overlay in carrier
    vec3 fieldLineC = vec3(0.1, 0.08, 0.02) * fieldLine * (1.0 - droplet) * 0.4;

    // Magnet pole glow
    float poleGlow = exp(-length(p - mp) * 12.0) * 0.15;
    vec3  poleC    = vec3(0.4, 0.3, 0.1) * poleGlow;

    // Combine
    vec3 col = mix(carrierColor, dropletColor, droplet) + edgeColor + fieldLineC + poleC;
    col = clamp(col, 0.0, 1.0);

    gl_FragColor = vec4(col, 1.0);
}
