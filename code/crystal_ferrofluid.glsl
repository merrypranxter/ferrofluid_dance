// crystal_ferrofluid.glsl
// Magnetic field as crystal growth director: ferrofluid spikes arrested mid-growth
// and crystallized into ordered mineral structures. The instability is frozen.
// Iron oxide lattice. Magnetite dendrites. Field lines made stone.
//
// Concept:
//   Real magnetite (Fe₃O₄) is the mineral form of the same nanoparticles in ferrofluid.
//   Natural magnetite crystals grow along the lines of the Earth's magnetic field —
//   the crystal lattice orientation is biased by the field during nucleation.
//   This shader visualizes that limit: ferrofluid caught at the moment of
//   crystallization, the spike pattern frozen into mineral geometry.
//
//   Two growth regimes:
//   1. DENDRITIC: spikes branch fractally, following field gradient lines,
//      like ice dendrites but in iron oxide
//   2. EUHEDRAL: the crystal lattice imposes octahedral/cubic symmetry on
//      the growth front, creating faceted crystal faces
//
// Parameters:
//   magnetStrength   — field intensity driving growth [0..10], default 4.0
//   susceptibility   — crystal preference [0.1..5], default 2.5
//   surfaceTension   — interfacial energy (controls dendrite width) [0.1..5], default 0.6
//   fieldOscillation — growth oscillation / annealing speed [0..5], default 0.15
//   crystalAge       — 0=fresh fluid, 1=fully crystallized [0..1], default 0.6
//   dendriticMode    — 0=faceted crystal, 1=fractal dendritic, default 0.7
//   latticeSymmetry  — 3=hexagonal, 4=cubic, 6=trigonal, default 4.0

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 4.0
uniform float susceptibility;   // default 2.5
uniform float surfaceTension;   // default 0.6
uniform float fieldOscillation; // default 0.15
uniform float crystalAge;       // default 0.6
uniform float dendriticMode;    // default 0.7
uniform float latticeSymmetry;  // default 4.0

// ─── HASH / NOISE ─────────────────────────────────────────────────────────────
float hash1(float n) { return fract(sin(n) * 43758.5453); }
float hash(vec2 v)   { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}
float fbm(vec2 v, int oct) {
    float s = 0.0, a = 0.5;
    for (int i = 0; i < 8; i++) {
        if (i >= oct) break;
        s += noise(v) * a;
        v *= 2.13; a *= 0.47;
    }
    return s;
}

// ─── DIPOLE FIELD ─────────────────────────────────────────────────────────────
float dipoleField(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float ct = delta.y / r;
    return strength * sqrt(1.0 + 3.0 * ct * ct) / (r2 * r);
}

vec2 dipoleFieldVec(vec2 delta, float strength) {
    float r2  = dot(delta, delta) + 1e-4;
    float r   = sqrt(r2);
    vec2  m   = vec2(0.0, 1.0);
    float mdr = dot(m, delta / r);
    return strength * (3.0 * mdr * (delta / r) - m) / (r2 * r);
}

// ─── LATTICE ANISOTROPY ───────────────────────────────────────────────────────
// Crystal lattice imposes preferred growth directions.
// Symmetry N means growth is fastest along N directions at 360°/N intervals.
// For magnetite (cubic): N=4 (along <100> directions), or N=8 for <110>.

float latticeAnisotropy(vec2 dir, float N) {
    float angle = atan(dir.y, dir.x);
    // The anisotropy function has N-fold symmetry; max along preferred axes
    return (1.0 + cos(angle * N)) * 0.5;
}

// ─── DENDRITIC GROWTH ─────────────────────────────────────────────────────────
// We simulate dendrite pattern using iterated function systems / diffusion
// limited aggregation (DLA) approximation:
// The growth front advances fastest along the field direction + lattice maxima.
// The result looks like fractal snowflakes but in iron-oxide topology.

float dendriticPattern(vec2 p, vec2 mp, float strength, float age, float sym) {
    float totalGrowth = 0.0;
    float scale = 1.0;

    for (int level = 0; level < 5; level++) {
        float fl = float(level);
        // At each level, the dendrites are finer (higher spatial frequency)
        vec2  q       = p * scale;
        vec2  delta   = q - mp * scale;
        float B       = dipoleField(delta, strength);
        vec2  Bvec    = dipoleFieldVec(delta, strength);
        float Blen    = length(Bvec);
        vec2  Bdir    = (Blen > 1e-5) ? Bvec / Blen : vec2(0.0, 1.0);

        // Anisotropy: growth is fastest along lattice directions
        float aniso   = latticeAnisotropy(Bdir, sym);
        // DLA-like growth: crystal fills the field gradient landscape
        float growth  = B * aniso * susceptibility / surfaceTension;
        // Scale down at finer levels (self-similar dendritic branching)
        growth *= age * pow(0.6, fl);

        totalGrowth += growth / scale;
        scale *= 3.0;

        // Sidebranching noise at each scale
        float branch = fbm(p * scale * 0.5, 3);
        totalGrowth += branch * growth * 0.3 * dendriticMode;
    }
    return totalGrowth;
}

// ─── FACETED CRYSTAL FACES ───────────────────────────────────────────────────
// The euhedral crystal has flat faces corresponding to the lattice planes.
// We use the Voronoi-like distance to nearest lattice face.

float facetedCrystal(vec2 p, vec2 mp, float strength, float sym) {
    vec2  d   = p - mp;
    float r   = length(d);
    if (r < 1e-4) return 1.0;
    vec2  dn  = d / r;
    float B   = dipoleField(d, strength);

    // Crystal facets: the field strength at each angular position is
    // modulated by the lattice anisotropy
    float faceAniso = 0.0;
    float step_ang  = 6.2831853 / sym;
    for (int k = 0; k < 12; k++) {
        if (float(k) >= sym) break;
        float faceAngle = float(k) * step_ang;
        vec2  faceDir   = vec2(cos(faceAngle), sin(faceAngle));
        float alignment = max(0.0, dot(dn, faceDir));
        // Facet: bright if aligned with a lattice direction
        faceAniso += pow(alignment, 6.0) / sym;
    }

    float crystalR = B * susceptibility * faceAniso / surfaceTension * 0.15;
    return max(0.0, crystalR - r + 0.02);
}

// ─── MAGNETITE TEXTURE ───────────────────────────────────────────────────────
// Real magnetite has a distinctive dark grey metallic luster with octahedral
// cleavage planes. We approximate this with directional specular highlights
// at crystal face orientations.

float mineralSheen(vec2 p, vec2 mp, float sym) {
    vec2  d     = p - mp;
    float angle = atan(d.y, d.x);
    float sheen = 0.0;
    float step_ang = 6.2831853 / sym;
    for (int k = 0; k < 12; k++) {
        if (float(k) >= sym) break;
        float faceAngle = float(k) * step_ang;
        float diff = angle - faceAngle;
        sheen += exp(-diff * diff * 200.0);
    }
    return sheen / sym;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    // Slow annealing of the crystal — it grows slowly as the field is sustained
    float age  = crystalAge * (0.7 + 0.3 * sin(time * fieldOscillation * 6.2831853));
    float sym  = max(3.0, floor(latticeSymmetry));

    // Static magnet (frozen field)
    vec2  mp   = vec2(0.0, 0.28);
    vec2  delta = p - mp;
    float B    = dipoleField(delta, magnetStrength);

    // Dendritic growth field
    float dendrite = dendriticPattern(p, mp, magnetStrength, age, sym);
    // Faceted crystal SDF (0 = at face, positive = outside crystal)
    float faceted  = facetedCrystal(p, mp, magnetStrength, sym);
    // Blend dendritic and faceted modes
    float crystal = mix(faceted, dendrite * 0.04, dendriticMode);

    // Pool base: the fluid that hasn't crystallized yet
    float poolH = B * susceptibility / surfaceTension * 0.06 * (1.0 - age);
    float sdf   = p.y - (-0.08 + poolH + crystal);

    // ─── SHADING ─────────────────────────────────────────────────────────────
    float mask = smoothstep(0.006, -0.006, sdf);
    float edge = smoothstep(0.02, 0.0, abs(sdf));

    // Mineral sheen: facet highlights
    float sheen = mineralSheen(p, mp, sym) * mask;

    // Magnetite color: dark grey with hints of iron-blue
    vec3 mineralColor = vec3(0.04, 0.04, 0.06) * mask;
    // Facet specular: bright glints at cleavage angles
    vec3 facetSpec    = vec3(0.25, 0.28, 0.35) * sheen * (0.5 + 0.5 * age);
    // Crystal interior: reddish-brown deeper in (Fe₃O₄ suboxide tones)
    float depth  = smoothstep(0.0, -0.25, sdf);
    vec3  ironTint = vec3(0.12, 0.04, 0.02) * depth * mask;

    // Dendritic branch tips: slightly brighter (newer growth, more reflective)
    float tipBright = clamp(dendrite * 10.0, 0.0, 1.0) * mask;
    vec3  tipColor  = vec3(0.15, 0.16, 0.2) * tipBright;

    // Edge: the liquid-crystal interface (still-molten meniscus)
    vec3 glint = edge * mix(vec3(0.1, 0.14, 0.22),     // fluid mode: blue-white
                            vec3(0.2, 0.22, 0.25),      // crystal mode: silver
                            age);

    // Uncrystallized fluid (liquid ferrofluid rim)
    float fluidRim = (1.0 - age) * mask;
    vec3  fluidCol = vec3(0.0, 0.005, 0.01) * fluidRim;

    vec3 col = mineralColor + facetSpec + ironTint + tipColor + glint + fluidCol;
    vec3 bg  = vec3(0.0, 0.001, 0.004);

    // Background: faint field line overlay for context
    float Bfield = B * 0.01;
    bg += vec3(0.02, 0.02, 0.04) * Bfield;

    col = mix(bg, col, mask + edge * 0.5);

    gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
