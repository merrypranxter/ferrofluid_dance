# Audio-Driven Ferrofluid

## The Physics of Magnetic Loudspeakers

### Why Audio and Ferrofluid Are Inseparable

Ferrofluid was introduced to loudspeakers in the 1970s by Ferrofluidics Corporation, where it is used today in virtually every high-quality dynamic driver. The fluid sits in the voice coil gap — a thin annular space between the coil and the magnet — where it:

1. **Conducts heat**: Ferrofluid is ~10× more thermally conductive than air, increasing power handling by 2–5× (the coil doesn't overheat)
2. **Damps resonance**: The viscous drag reduces unwanted resonance peaks in the frequency response
3. **Centers the coil**: Surface tension holds the coil precisely in position in the magnetic gap

The irony: the material that makes ferrofluid *visible* (the strong magnetic field driving spike formation) is the same configuration as a loudspeaker. A speaker is a ferrofluid art installation with a cone attached.

### The Voice Coil as Electromagnet

The voice coil of a speaker carries audio current I(t) through a permanent magnetic field B₀. The resulting Lorentz force F = BIL drives the cone. But the coil is also an electromagnet — it creates its own field:

```
B_coil(t) = μ₀ N I(t) / l
```

where N is the number of turns and l is the coil length. This field exists in the gap and acts on any ferrofluid present.

**For artistic use**: Replace the speaker cone with an open ferrofluid pool. The audio-frequency electromagnetic field from the voice coil directly drives the fluid. The fluid surface IS the speaker cone — but a cone made of liquid, one that shows you what the sound looks like.

---

## Capillary Wave Dispersion in Ferrofluid

### How Frequency Maps to Wavelength

When a ferrofluid surface is driven by a periodic magnetic field at frequency f, capillary waves form at that frequency. The wavelength of the resulting surface wave depends on the dispersion relation.

For pure capillary waves (surface tension dominated, no gravity):

```
ω² = γ k³ / ρ
```

where:
- ω = 2πf (angular frequency)
- k = 2π/λ (wavenumber)
- γ = surface tension (N/m)
- ρ = fluid density (kg/m³)

Solving for wavelength:

```
λ(f) = 2π · (γ / (ρ(2πf)²))^(1/3)
```

For ferrofluid (γ ≈ 0.03 N/m, ρ ≈ 1200 kg/m³):

| Frequency | Wavelength | Visual Scale |
|-----------|-----------|--------------|
| 20 Hz | ~85 mm | Large, slow heaves |
| 100 Hz | ~25 mm | Medium waves visible to eye |
| 500 Hz | ~9 mm | Small ripples |
| 1 kHz | ~6 mm | Fine ripple texture |
| 5 kHz | ~2.5 mm | Micro-shimmer |
| 10 kHz | ~1.8 mm | Sub-spike-spacing texture |

**Key insight**: The Rosensweig spike spacing (~10–15 mm) falls right in the 100–300 Hz range. Audio in this frequency range directly excites individual spike motion. Bass notes shake the whole spike array; mid-range notes resonate with individual spike natural frequencies.

### The Parametric Resonance Zone

The Rosensweig spike has a natural oscillation frequency. For a spike of capillary length l_c:

```
f_spike ≈ (1/2π) · √(g / l_c)
```

For l_c = 2 mm: f_spike ≈ 11 Hz. This is in the sub-bass range — the "feel" of very deep bass, below the audible threshold of the loudspeaker itself.

When the audio frequency is a harmonic of f_spike (11, 22, 33... Hz), the fluid shows **parametric resonance**: spike amplitudes grow dramatically. This is why very low bass (if the speaker can produce it) creates violent, almost discontinuous spike eruptions — you're driving the fluid at resonance.

### Faraday Waves

When the field oscillates at exactly twice the spike natural frequency (2f_spike ≈ 22 Hz), a different instability occurs: **Faraday waves**. These are sub-harmonic oscillations where the surface oscillates at HALF the driving frequency. The pattern is spectacular: a standing wave of spikes at f/2 = 11 Hz, driven by a 22 Hz field.

Faraday wave patterns in ferrofluid show:
- Square symmetry at low amplitude (vs. hexagonal Rosensweig symmetry)
- Transition to hexagonal as amplitude increases
- Quasiperiodic patterns near the transition — look like fivefold Penrose tilings
- Chaos at high drive amplitude

---

## The Four Frequency Bands and Their Visual Signatures

### Bass Band: 20–200 Hz

**Physical effect**: The field oscillates slowly enough that the fluid can fully respond between cycles. Each bass cycle drives a full Rosensweig-like event:
- Spikes grow on the positive half-cycle
- Spikes collapse on the negative half-cycle (or field reversal)
- The entire surface heaves as a slow, deep wave

**Acoustic energy**: Bass carries the most mechanical energy. A strong bass note will literally move the ferrofluid pool if it's sitting on the speaker.

**Visual signature in `audio_ferrofluid.glsl`**:
- Large-scale surface heave (low wavenumber wave)
- Tall, slow-growing spikes appear and recede at the beat
- Warm reddish glow from below the surface (bass pressure wave)
- Spike array breathes collectively — all spikes rise and fall together

**Artistic use**: Map kick drum to bass → the ferrofluid "stamps" with each beat. Map sub-bass rumble to bass → the fluid is always unsettled, always just at the threshold of eruption.

### Mid Band: 200–2000 Hz

**Physical effect**: Frequencies in this range create capillary waves with wavelengths of 5–30 mm — comparable to the Rosensweig spike spacing. This means mid-frequency audio RESONATES with the spike array rather than driving the whole surface.

Individual spikes resonate at their natural frequency. The spike array acts as a mechanical filter: mid frequencies near f_spike couple strongly, others pass through without visible effect.

**Visual signature**:
- Distinct ripple rings propagating outward from the magnet
- Individual spikes show different heights depending on local field + wave superposition
- The array becomes "textured" — no longer all spikes at the same height
- Standing wave patterns appear when the frequency matches the pool dimensions

**Artistic use**: Map a melody line to mid → the ferrofluid sings the pitch. Different frequencies create different ripple patterns. Harmonic intervals (octave, fifth) create reinforcing standing wave patterns; dissonant intervals create chaotic interference.

### High Band: 2000–8000 Hz

**Physical effect**: Wavelengths of 2–8 mm — smaller than the spike spacing. The fluid surface can't form distinct capillary waves at these frequencies within the spike field region; instead, the energy appears as fine-scale surface texture (microripples) on the spike sides and at the pool surface between spikes.

The spike tips are particularly responsive: the intense field at the tip amplifies the local oscillation. At 3 kHz, spike tips can vibrate in the vertical direction at 3000 times per second — invisible to the eye but the tips appear slightly blurred.

**Visual signature**:
- Fine-scale shimmer texture on the fluid surface
- Spike tips appear slightly diffuse (micro-oscillation)
- The surface between spikes shows small traveling ripples
- Under high-speed camera, the surface looks like a texture map being live-updated

**Artistic use**: Synthesizer pad → a constant high shimmer. Cymbals → a bright wash of surface texture. Breath sounds → extremely fine, cloud-like surface disturbance.

### Treble Band: 8000–20000 Hz

**Physical effect**: At these frequencies, the fluid's viscous response time τ ≈ ρ/(ηk²) becomes comparable to the oscillation period. For k corresponding to 10 kHz, τ is in the microsecond range. The fluid cannot fully respond — the wave is overdamped. Instead of capillary waves, the energy appears as:
- Acoustic streaming: slow DC flow driven by the high-frequency oscillation
- Micro-cavitation: tiny temporary vacuoles in high-intensity regions
- Surface roughening: stochastic micro-scale deformation

**Visual signature**:
- Subtle noise texture on the surface (roughening)
- No distinct wave structures — the pattern is random-looking
- Under backlighting: the surface appears to breathe slightly
- Combined with bass: the bass heave has a textured surface (not glassy-smooth)

**Artistic use**: Treble is the "grain" in the ferrofluid. White noise → maximum grain. A pure sine tone → no grain, smooth surface. Acoustic texture / ambiance → maps to ferrofluid surface quality.

---

## Implementation: Connecting FFT to the Shader

### Web Audio API Setup

```javascript
// Create analyser
const audioCtx = new AudioContext();
const analyser  = audioCtx.createAnalyser();
analyser.fftSize = 2048;
const dataArray = new Float32Array(analyser.frequencyBinCount);

// Connect your audio source
source.connect(analyser);

// Helper: RMS energy in a frequency range
function bandRMS(loHz, hiHz) {
    analyser.getFloatFrequencyData(dataArray);  // dB values
    const nyquist = audioCtx.sampleRate / 2;
    const binCount = analyser.frequencyBinCount;
    const loIdx = Math.floor(loHz / nyquist * binCount);
    const hiIdx = Math.floor(hiHz / nyquist * binCount);
    let sum = 0;
    for (let i = loIdx; i <= hiIdx; i++) {
        sum += Math.pow(10.0, dataArray[i] / 20.0);  // dB → linear amplitude
    }
    return Math.sqrt(sum / (hiIdx - loIdx + 1));
}

// Update shader uniforms each frame
function updateAudioUniforms() {
    const bass    = Math.min(1.0, bandRMS(20, 200)    * 4.0);
    const mid     = Math.min(1.0, bandRMS(200, 2000)  * 3.5);
    const high    = Math.min(1.0, bandRMS(2000, 8000) * 3.0);
    const treble  = Math.min(1.0, bandRMS(8000, 20000)* 2.5);

    // Onset detection for audioPeak (kick drum, transient)
    const totalRMS = Math.min(1.0, bandRMS(20, 200) * 5.0);
    const peak = Math.max(0.0, totalRMS - prevTotalRMS);
    prevTotalRMS = totalRMS;

    gl.uniform1f(loc.audioBass,   bass);
    gl.uniform1f(loc.audioMid,    mid);
    gl.uniform1f(loc.audioHigh,   high);
    gl.uniform1f(loc.audioTreble, treble);
    gl.uniform1f(loc.audioPeak,   peak);
}
```

### The Gain Multipliers

The `* 4.0`, `* 3.5` etc. scale factors are tuning parameters. They depend on the loudness of your audio source. Start with the values above and adjust until the ferrofluid shows a full range of motion at typical listening volume.

**Calibration approach**:
1. Play a bass-heavy track at normal volume
2. Adjust `* 4.0` until `audioBass` reaches 0.8–1.0 at the loudest bass moments
3. Repeat for each band

### MIDI-Driven Alternative

For generative / performance contexts, you may not have audio — drive the uniforms directly from MIDI:
```javascript
// Map MIDI note velocity to audioBass
navigator.requestMIDIAccess().then(midi => {
    midi.inputs.forEach(input => {
        input.onmidimessage = (event) => {
            if (event.data[0] === 0x90) {  // Note On
                const note     = event.data[1];
                const velocity = event.data[2] / 127.0;
                // Map low notes to bass, high notes to treble
                if (note < 48)       gl.uniform1f(loc.audioBass,   velocity);
                else if (note < 72)  gl.uniform1f(loc.audioMid,    velocity);
                else if (note < 84)  gl.uniform1f(loc.audioHigh,   velocity);
                else                 gl.uniform1f(loc.audioTreble,  velocity);
                // Trigger peak on any note
                gl.uniform1f(loc.audioPeak, velocity * 0.8);
            }
        };
    });
});
```

---

## Physical Installation: Hardware Audio-Driven Ferrofluid

For physical (non-simulated) audio-driven ferrofluid installations:

### Amplifier Setup
- Use a Class-D amplifier (efficient, low heat)
- Power: 20–100W is sufficient for small pools (150mm diameter)
- Frequency range: Optimize for 20–500 Hz (the most visually effective range)
- Do NOT use the ferrofluid as the speaker load directly — use a separate coil

### Electromagnet Design
- Voice coil diameter: match to your ferrofluid pool diameter (~50% of pool diameter)
- Core: ferrite preferred (low eddy current losses at audio frequencies)
- Air gap: 5–15 mm above the fluid surface (field falls as 1/d³)
- Drive with audio signal + DC bias: bias keeps the fluid in the active spike region

### Ferrofluid Selection
- For audio response: lower viscosity (APG 512, η ≈ 5 mPa·s) gives faster response
- For slower, more dramatic motion: higher viscosity (APG 314, η ≈ 25 mPa·s)
- Pool depth: 5–15 mm for spike formation; deeper pools damp high-frequency response

### Safety Notes
- Ferrofluid stains everything permanently. Use a sealed container.
- The electromagnetic field can erase credit cards, damage hard drives
- Keep small metallic objects away from the setup

---

## Artistic Precedents

### Sachiko Kodama — "Protrude, Flow" (2001)

The original audio-driven ferrofluid work. Kodama and Minako Takeno drove ferrofluid via electromagnets controlled by a custom DSP system that analyzed incoming music. The ferrofluid grew and collapsed in sync with the music — not as a simple amplitude mapping, but as a processed interpretation of the sonic structure.

**Critical observation**: Kodama did not map audio amplitude directly to field strength. She used the music's rhythmic and melodic structure as a choreography score, letting the physics of the fluid "interpret" the score in its own time. The fluid's inertia and relaxation time became part of the performance.

### Contemporary Practice

Current audio-ferrofluid artists typically:
1. Extract frequency bands via FFT
2. Map each band to a separate electromagnet in a coil array
3. Use the spatial pattern of magnets to create 2-D "images" of the sound
4. Overlay the ferrofluid pool with projection mapping to add color and texture

The result: the ferrofluid topography IS the frequency spectrum, read spatially rather than temporally. A bass note creates a large-scale landscape feature; a treble note creates surface texture. Walk around the pool and you experience the music spatially.

---

## References

- Rosensweig, R.E. et al. (1983). Ferrohydrodynamic and magnetizable fluid apparatus. *US Patent 4,381,453*.
- Kodama, S. & Takeno, M. (2001). Protrude, Flow. *SIGGRAPH 2001 Art Gallery*.
- Moxon, W.G. (1990). Improvement of loudspeaker performance using ferrofluid. *Journal of the Audio Engineering Society*, 38(1).
- Voit, A., Balz, J., & Bihn, M. (2019). Real-time audio visualization in ferrofluid. *CHI Extended Abstracts*.
