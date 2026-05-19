// emotional_ferrofluid.glsl
// Emotional state drives magnetic susceptibility and oscillation patterns.
// Five moods → five distinct fluid behaviors.
//
// Parameters:
//   magnetStrength   — base field intensity [0.0 .. 10.0], default 3.0
//   susceptibility   — base fluid response [0.1 .. 5.0], default 2.0
//   surfaceTension   — spike resistance [0.1 .. 5.0], default 1.0
//   emotion          — 0=calm, 0.25=anger, 0.5=fear, 0.75=joy, 1.0=grief [0..1]
//   emotionIntensity — strength of emotional modulation [0.0 .. 1.0], default 0.8

#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2  resolution;
uniform float magnetStrength;    // default 3.0
uniform float susceptibility;    // default 2.0
uniform float surfaceTension;    // default 1.0
uniform float emotion;           // default 0.0  (calm)
uniform float emotionIntensity;  // default 0.8

// ─── EMOTION DEFINITIONS ─────────────────────────────────────────────────────
// 0.00 = CALM    — flat, mirror, slow breathing
// 0.25 = ANGER   — violent spikes, rapid oscillation, splashing
// 0.50 = FEAR    — erratic micro-spikes, twitching tremor
// 0.75 = JOY     — rhythmic flowing waves, organic spiral
// 1.00 = GRIEF   — slow collapse, tears, flat black pool

struct EmotionalState {
    float fieldFreq;      // oscillation speed multiplier
    float spikeAmp;       // spike height multiplier
    float noiseAmp;       // erratic noise amplitude
    float poolLevel;      // rest surface height
    float edgeBrightness; // meniscus luminance
    vec3  edgeColor;      // tint of glint
};

EmotionalState getEmotion(float e, float intensity) {
    EmotionalState calm;
    calm.fieldFreq      = 0.1;
    calm.spikeAmp       = 0.4;
    calm.noiseAmp       = 0.0;
    calm.poolLevel      = -0.06;
    calm.edgeBrightness = 0.3;
    calm.edgeColor      = vec3(0.2, 0.25, 0.35);

    EmotionalState anger;
    anger.fieldFreq      = 4.0;
    anger.spikeAmp       = 2.5;
    anger.noiseAmp       = 0.06;
    anger.poolLevel      = -0.04;
    anger.edgeBrightness = 0.6;
    anger.edgeColor      = vec3(0.5, 0.1, 0.05);

    EmotionalState fear;
    fear.fieldFreq      = 2.5;
    fear.spikeAmp       = 0.8;
    fear.noiseAmp       = 0.12;
    fear.poolLevel      = -0.05;
    fear.edgeBrightness = 0.2;
    fear.edgeColor      = vec3(0.1, 0.18, 0.28);

    EmotionalState joy;
    joy.fieldFreq      = 1.5;
    joy.spikeAmp       = 1.4;
    joy.noiseAmp       = 0.02;
    joy.poolLevel      = -0.08;
    joy.edgeBrightness = 0.5;
    joy.edgeColor      = vec3(0.25, 0.4, 0.6);

    EmotionalState grief;
    grief.fieldFreq      = 0.15;
    grief.spikeAmp       = 0.15;
    grief.noiseAmp       = 0.005;
    grief.poolLevel      = -0.12;
    grief.edgeBrightness = 0.1;
    grief.edgeColor      = vec3(0.05, 0.07, 0.1);

    // Blend between adjacent states
    float blend4 = e * 4.0;
    int   idx    = int(blend4);
    float t      = fract(blend4);

    EmotionalState a = calm, b = calm;
    if (idx == 0) { a = calm;  b = anger; }
    if (idx == 1) { a = anger; b = fear;  }
    if (idx == 2) { a = fear;  b = joy;   }
    if (idx == 3) { a = joy;   b = grief; }

    EmotionalState out;
    out.fieldFreq      = mix(a.fieldFreq,      b.fieldFreq,      t);
    out.spikeAmp       = mix(a.spikeAmp,       b.spikeAmp,       t);
    out.noiseAmp       = mix(a.noiseAmp,       b.noiseAmp,       t);
    out.poolLevel      = mix(a.poolLevel,      b.poolLevel,      t);
    out.edgeBrightness = mix(a.edgeBrightness, b.edgeBrightness, t);
    out.edgeColor      = mix(a.edgeColor,      b.edgeColor,      t);

    // Scale by emotionIntensity (lerp between calm and full emotion)
    out.fieldFreq      = mix(calm.fieldFreq,      out.fieldFreq,      intensity);
    out.spikeAmp       = mix(calm.spikeAmp,       out.spikeAmp,       intensity);
    out.noiseAmp       = mix(0.0,                 out.noiseAmp,       intensity);
    out.poolLevel      = mix(calm.poolLevel,      out.poolLevel,      intensity);
    out.edgeBrightness = mix(calm.edgeBrightness, out.edgeBrightness, intensity);
    out.edgeColor      = mix(calm.edgeColor,      out.edgeColor,      intensity);
    return out;
}

// ─── NOISE ───────────────────────────────────────────────────────────────────
float hash(vec2 v) { return fract(sin(dot(v, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 v) {
    vec2 i = floor(v), f = fract(v);
    float a = hash(i), b = hash(i + vec2(1,0));
    float c = hash(i + vec2(0,1)), d = hash(i + vec2(1,1));
    vec2  u = f * f * (3.0 - 2.0 * f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

// ─── DIPOLE FIELD ────────────────────────────────────────────────────────────
float dipoleField(vec2 delta, float strength) {
    float r2 = dot(delta, delta) + 1e-4;
    float r  = sqrt(r2);
    float ct = delta.y / r;
    return strength * sqrt(1.0 + 3.0 * ct * ct) / (r2 * r);
}

// ─── MAIN ────────────────────────────────────────────────────────────────────
void main() {
    vec2 uv     = gl_FragCoord.xy / resolution;
    vec2 aspect = vec2(resolution.x / resolution.y, 1.0);
    vec2 p      = (uv - 0.5) * aspect;

    EmotionalState es = getEmotion(emotion, emotionIntensity);

    // Magnet position driven by emotion
    float t   = time * es.fieldFreq;
    vec2  mp  = vec2(sin(t * 0.7) * 0.2, 0.25 + sin(t) * 0.1);
    vec2  delta = p - mp;

    float B = dipoleField(delta, magnetStrength);

    // Erratic noise overlay (fear/anger)
    float n = noise(p * 15.0 + time * es.fieldFreq * 0.5) * es.noiseAmp;

    // Surface height
    float h   = B * susceptibility * es.spikeAmp / surfaceTension;
    float surface = es.poolLevel + h * 0.1 + n;
    float sdf = p.y - surface - exp(-abs(delta.x) * 8.0) * h * 0.08;

    // --- Shading ---
    float mask = smoothstep(0.006, -0.006, sdf);
    float edge = smoothstep(0.018, 0.0, abs(sdf));
    vec3  col  = edge * es.edgeColor * es.edgeBrightness;

    // Grief: tears — slow vertical streaks collapsing downward
    if (emotion > 0.85) {
        float tear = smoothstep(0.005, 0.0, abs(fract(p.x * 8.0 + 0.3) - 0.5) - 0.005);
        float falloff = smoothstep(0.0, -0.3, p.y + 0.1) * smoothstep(-0.12, 0.0, p.y + 0.12);
        col += vec3(0.04, 0.05, 0.08) * tear * falloff * emotionIntensity;
    }

    vec3 bg = vec3(0.0, 0.002, 0.006);
    col = mix(bg, col, mask + edge * 0.4);

    gl_FragColor = vec4(col, 1.0);
}
