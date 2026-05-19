// audio_ferrofluid.glsl
// Audio-driven ferrofluid: FFT frequency bands modulate field strength and
// spike wavelength in real-time. Low bass → deep slow heave. High treble →
// micro-spike shimmer. The fluid is a loudspeaker made visible.
//
// Physical basis:
//   A voice-coil speaker IS an electromagnet driven by audio current. Place
//   ferrofluid on the cone: the oscillating Kelvin force drives capillary waves
//   whose frequency matches the audio. Frequency → capillary wavelength via
//       λ(f) = 2π · √(γ / (ρ(2πf)²))   [dispersive capillary waves]
//
// Parameters:
//   magnetStrength   — DC bias field [0..10], default 2.0
//   susceptibility   — fluid response [0.1..5], default 2.0
//   surfaceTension   — spike resistance [0.1..5], default 1.0
//   spikeSharpness   — tip acuity [0.1..3], default 1.5
//   // Audio band uniforms (0..1, driven by your FFT analysis)
//   audioBass        — 20–200 Hz band amplitude
//   audioMid         — 200–2000 Hz band amplitude
//   audioHigh        — 2000–20000 Hz band amplitude
//   audioTreble      — 4000–20000 Hz band (fine shimmer)
//   audioPeak        — instantaneous peak (any band) for flash events

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;   // default 2.0
uniform float susceptibility;   // default 2.0
uniform float surfaceTension;   // default 1.0
uniform float spikeSharpness;   // default 1.5
uniform float audioBass;        // default 0.0 (drive with FFT)
uniform float audioMid;         // default 0.0
uniform float audioHigh;        // default 0.0
uniform float audioTreble;      // default 0.0
uniform float audioPeak;        // default 0.0  (momentary peak)

// ─── NOISE ───────────────────────────────────────────────────────────────────
float hash(vec2 v)  { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float hash1(float n){ return fract(sin(n) * 43758.5453); }

float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i),          hash(i+vec2(1,0)), u.x),
               mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)), u.x), u.y);
}

// ─── DIPOLE FIELD (DC bias magnet beneath pool) ───────────────────────────
float dipoleField(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float ct = delta.y / r;
    return strength * sqrt(1.0 + 3.0 * ct * ct) / (r2 * r);
}

// ─── AUDIO SURFACE HEIGHT ────────────────────────────────────────────────────
// Layered capillary waves — each audio band drives a wave of its natural
// capillary wavelength. Physical capillary dispersion: ω² = γk³/ρ
// so k = (ρω²/γ)^(1/3); here we use the band center frequencies.

float audioSurface(vec2 p, float bass, float mid, float high, float treble) {
    float h = 0.0;

    // Bass (20–200 Hz) → λ_bass ≈ 40–60 mm at lab scale → wavenumber ~5
    float bassAngle = time * 1.8 + p.x * 0.5;  // very slow lateral drift
    h += bass * 0.06 * sin(length(p) * 4.0 - time * 6.28 * 0.5) *
         exp(-length(p) * 1.5);

    // Mid (200–2000 Hz) → medium wavelength waves
    h += mid * 0.03 * sin(p.x * 12.0 - time * 6.28 * 2.0) *
         cos(p.y * 8.0  - time * 6.28 * 1.5) *
         exp(-length(p) * 2.0);

    // High (2–20 kHz) → short-wavelength shimmer
    h += high * 0.015 * noise(p * 28.0 + time * 4.0);

    // Treble → micro-turbulence at surface
    h += treble * 0.008 * noise(p * 60.0 - time * 8.0);

    return h;
}

// ─── FREQUENCY-DRIVEN SPIKE DENSITY ─────────────────────────────────────────
// Bass → fewer, taller macro-spikes.
// Treble → many fine micro-spikes.
// The capillary wavelength λ_c ∝ f^(-2/3); high frequency → smaller λ → more spikes.

float audioSpikes(vec2 p, vec2 magnetCenter, float bass, float mid, float high) {
    float total = 0.0;

    // Macro-spikes (bass-driven) — large spacing, tall amplitude
    float macroDensity = 3.0 + bass * 4.0;
    vec2  qM = p * macroDensity;
    vec2  cellM = floor(qM);
    vec2  fracM = fract(qM) - 0.5;
    float seedM  = hash(cellM);
    vec2  jitterM = vec2(hash(cellM + 13.7), hash(cellM + 29.3)) * 0.35;
    vec2  localM  = fracM - jitterM;
    float phase   = time * 0.8 + seedM * 6.28;
    float ageM    = 0.5 + 0.5 * sin(phase);
    float distM   = length(localM);
    total += bass * 0.10 * ageM * exp(-distM * distM * 40.0);

    // Mid-range spikes
    float midDensity = 6.0 + mid * 8.0;
    vec2  qMid = p * midDensity;
    vec2  cellMid = floor(qMid);
    vec2  fracMid = fract(qMid) - 0.5;
    vec2  jitterMid = vec2(hash(cellMid + 7.1), hash(cellMid + 53.9)) * 0.3;
    float distMid   = length(fracMid - jitterMid);
    float ageMid    = 0.5 + 0.5 * sin(time * 1.8 + hash(cellMid) * 6.28);
    total += mid * 0.05 * ageMid * exp(-distMid * distMid * 80.0);

    // Treble micro-spikes
    total += high * 0.02 * noise(p * 40.0 + time * 3.0);

    return total;
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    // DC bias magnet (voice coil center)
    vec2 mp    = vec2(0.0, 0.28);
    vec2 delta = p - mp;
    float B    = dipoleField(delta, magnetStrength);

    // Static Rosensweig layer
    float staticH = B * susceptibility / surfaceTension * 0.07;

    // Audio-driven wave and spike layers
    float waveH  = audioSurface(p, audioBass, audioMid, audioHigh, audioTreble);
    float spikeH = audioSpikes(p, mp, audioBass, audioMid, audioHigh);

    float surface = -0.08 + staticH + waveH + spikeH;

    // Spike-tip profile: bass-driven spikes are sharper
    float spikeProfile = exp(-abs(delta.x) * spikeSharpness * (5.0 + audioBass * 4.0)) *
                         staticH * 0.9;
    float sdf = p.y - surface - spikeProfile;

    // ─── SHADING ─────────────────────────────────────────────────────────────
    float mask = smoothstep(0.005, -0.005, sdf);
    float edge = smoothstep(0.018, 0.0, abs(sdf));

    // Base meniscus: cool blue-white
    vec3 glint = edge * vec3(0.12, 0.16, 0.24);

    // Bass pulse: low-frequency deep heave adds warm reddish glow from below
    float bassGlow = audioBass * 0.08 * smoothstep(0.0, -0.25, sdf);
    glint += vec3(0.3, 0.05, 0.02) * bassGlow * mask;

    // Mid shimmer: thin bright rings of wave crests
    float crestLine = smoothstep(0.006, 0.0, abs(fract(length(p) * 10.0 - time * 1.8) - 0.9));
    glint += vec3(0.08, 0.15, 0.25) * crestLine * audioMid * mask * 0.3;

    // Treble flash: momentary white peak on audio transients
    vec3  peakFlash = vec3(0.2, 0.22, 0.3) * audioPeak * edge * 2.0;
    glint += peakFlash;

    // High-frequency shimmer at surface
    float shimmer = noise(p * 80.0 + time * 10.0) * audioTreble * 0.05;
    glint += vec3(0.1, 0.2, 0.35) * shimmer * edge;

    vec3 col = glint;
    vec3 bg  = vec3(0.0, 0.002, 0.008) * (1.0 + audioBass * 0.3);
    col = mix(bg, col, mask + edge * 0.5);

    // Full-frame percussion flash on peak transients
    col += vec3(0.02, 0.025, 0.04) * audioPeak * (1.0 - mask) * 0.5;

    gl_FragColor = vec4(col, 1.0);
}
