#!/home/reny/Videos/FoodGo-Video-Studio/.venv/bin/python
"""Studio audio mixer for the FoodGo ACLEDA University Capstone Presentation.

Synthesizes an evolving D-major ambient keynote music bed (felt pad + gentle
marimba/Rhodes harmonic pulses across all 14 chapters), builds cohesive
in-key transition SFX in a shared stereo room, applies look-ahead vocal
sidechain ducking around the Khmer neural narration (km-KH-PisethNeural),
writes master_mix.wav (48 kHz stereo), and exports synchronized SRT/VTT.
"""

import json
import math
import os
import wave
import numpy as np

BASE = os.path.dirname(os.path.abspath(__file__))
SCRATCH_MASTER = "/home/reny/.gemini/antigravity/brain/cd7399e3-4f43-48fd-a82e-f7613f1cbe6e/scratch/foodgo_studio_master"
PLAN_PATH = (
    os.path.join(BASE, "plan_master.json")
    if os.path.exists(os.path.join(BASE, "plan_master.json"))
    else os.path.join(SCRATCH_MASTER, "plan_master.json")
)
OUT_MASTER_WAV = os.path.join(BASE, "master_mix.wav")
OUT_SRT = "/home/reny/FoodGo/output/subtitles/foodgo-presentation.srt"
OUT_VTT = "/home/reny/FoodGo/output/subtitles/foodgo-presentation.vtt"
SR = 48000
_RNG = np.random.default_rng(2026)

# ── Pure-NumPy Frequency-Domain DSP & Room Primitives ────────────────────────

def _fft_filter(x: np.ndarray, transfer_fn) -> np.ndarray:
    """Apply an exact zero-phase spectral transfer function along axis 0."""
    n = len(x)
    nfft = 1 << (n - 1).bit_length()
    freqs = np.fft.rfftfreq(nfft, 1.0 / SR)
    gain = transfer_fn(freqs)
    if x.ndim == 1:
        return np.fft.irfft(np.fft.rfft(x, nfft) * gain, nfft)[:n]
    return np.fft.irfft(np.fft.rfft(x, nfft, axis=0) * gain[:, None], nfft, axis=0)[:n]


def lp(x: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    fc = max(30.0, float(fc))
    return _fft_filter(x, lambda f: 1.0 / np.sqrt(1.0 + (f / fc) ** (2 * order)))


def hp(x: np.ndarray, fc: float, order: int = 2) -> np.ndarray:
    fc = max(15.0, float(fc))
    return _fft_filter(x, lambda f: 1.0 / np.sqrt(1.0 + (fc / np.maximum(f, 1e-3)) ** (2 * order)))


def bell_eq(x: np.ndarray, fc: float, gain_db: float, q: float = 1.0) -> np.ndarray:
    """Smooth parametric bell EQ in log-frequency space."""
    lin = 10.0 ** (gain_db / 20.0)
    bw = 1.0 / max(0.25, q)
    def tf(f):
        log_d = np.log2(np.maximum(f, 1.0) / fc)
        shape = np.exp(-0.5 * (log_d / (0.65 * bw)) ** 2)
        return (1.0 - shape) + lin * shape
    return _fft_filter(x, tf)


def bp(x: np.ndarray, fc: float, q: float = 1.4) -> np.ndarray:
    fc = float(np.clip(fc, 40.0, SR * 0.45))
    bw = fc / max(0.3, q)
    return _fft_filter(x, lambda f: 1.0 / np.sqrt(1.0 + ((f - fc) / (0.5 * bw)) ** 2 + ((f + fc) / (10 * fc)) * 0.0))


def sweep_bp(x: np.ndarray, f0: float, f1: float, q: float = 1.3, blocks: int = 28) -> np.ndarray:
    n = len(x)
    out = np.zeros(n, dtype=np.float64)
    hop = max(64, n // blocks)
    win = np.hanning(min(n, hop * 2))
    pos = 0
    for i in range(blocks + 1):
        if pos >= n:
            break
        end = min(n, pos + hop * 2)
        f = f0 * (f1 / f0) ** min(1.0, i / max(1, blocks - 1))
        seg = bp(x[pos:end], f, q)
        w = win[: end - pos] if (end - pos) == len(win) else np.hanning(end - pos)
        out[pos:end] += seg * w
        pos += hop
    mx = float(np.max(np.abs(out)))
    return out / (mx + 1e-9)


def sat(x: np.ndarray, drive: float = 1.4) -> np.ndarray:
    return np.tanh(x * drive) / math.tanh(drive)


def fftconvolve_1d(sig: np.ndarray, ir: np.ndarray) -> np.ndarray:
    n = len(sig) + len(ir) - 1
    nfft = 1 << (n - 1).bit_length()
    return np.fft.irfft(np.fft.rfft(sig, nfft) * np.fft.rfft(ir, nfft), nfft)[:len(sig)]


# ── Physical & Harmonic Sound Primitives ─────────────────────────────────────

def air(dur: float = 0.48, f0: float = 220.0, f1: float = 1900.0, q: float = 1.4, peak_pos: float = 0.45) -> np.ndarray:
    n = int(SR * dur)
    noise = _RNG.standard_normal(n)
    x = lp(sweep_bp(noise, f0, f1, q), 4800.0)
    t = np.linspace(0.0, 1.0, n, endpoint=False)
    env = np.where(t < peak_pos, np.sin(0.5 * math.pi * t / peak_pos), np.cos(0.5 * math.pi * (t - peak_pos) / max(1e-4, 1.0 - peak_pos)))
    env = np.clip(env, 0.0, 1.0) ** 1.45
    y = x * env
    return y / (float(np.max(np.abs(y))) + 1e-9)


def sub(f: float = 58.0, dur: float = 0.72) -> np.ndarray:
    n = int(SR * dur)
    t = np.arange(n) / SR
    ph = np.cumsum(2.0 * math.pi * (f + f * 1.9 * np.exp(-t * 26.0)) / SR)
    body = np.sin(ph) * np.exp(-t * 5.2)
    transient = lp(_RNG.standard_normal(n), 420.0) * np.exp(-t * 85.0) * 0.45
    return sat(body * 1.0 + transient, 1.6)


def wood(f: float = 300.0, dur: float = 0.13) -> np.ndarray:
    n = int(SR * dur)
    t = np.arange(n) / SR
    body = np.sin(2.0 * math.pi * f * t * (1.0 + 0.25 * np.exp(-t * 85.0))) * np.exp(-t * 52.0)
    snap = bp(_RNG.standard_normal(n), 2800.0, 2.0) * np.exp(-t * 320.0) * 0.35
    return body * 0.85 + snap


def glass(f: float = 587.33, dur: float = 0.85, bright: float = 0.65) -> np.ndarray:
    n = int(SR * dur)
    t = np.arange(n) / SR
    attack = 1.0 - np.exp(-t * 140.0)
    s = (
        np.sin(2.0 * math.pi * f * t) * np.exp(-t * 4.8)
        + 0.28 * bright * np.sin(2.0 * math.pi * (f * 2.0) * t) * np.exp(-t * 9.5)
        + 0.12 * bright * np.sin(2.0 * math.pi * (f * 3.01) * t) * np.exp(-t * 16.0)
    ) * attack
    return s * 0.85


def bubble(f: float = 587.33, dur: float = 0.19) -> np.ndarray:
    n = int(SR * dur)
    t = np.arange(n) / SR
    ph = np.cumsum(2.0 * math.pi * (f * (1.0 + 0.55 * (1.0 - np.exp(-t * 32.0)))) / SR)
    return (np.sin(ph) * np.exp(-t * 24.0) * 0.85 + bp(_RNG.standard_normal(n), f * 2.5, 2.8) * np.exp(-t * 190.0) * 0.25)


def pan_of(x: float, width: float = 1920.0) -> float:
    return float(np.clip((x - width * 0.5) / (width * 0.5) * 0.55, -0.65, 0.65))


def make_room_impulse(t60: float = 0.72) -> np.ndarray:
    n = int(SR * t60 * 1.25)
    t = np.arange(n) / SR
    ir = _RNG.standard_normal((n, 2)) * np.exp(-6.9 * t / t60)[:, None]
    ir[:, 0] = lp(ir[:, 0], 3400.0)
    ir[:, 1] = lp(ir[:, 1], 3100.0)
    ir[: int(SR * 0.014)] = 0.0
    for d, g in ((0.018, 0.42), (0.031, 0.28), (0.047, 0.20)):
        idx = int(d * SR)
        ir[idx : idx + 2] += g * _RNG.uniform(0.5, 1.0, (2, 2))
    ir /= float(np.max(np.abs(ir).sum(axis=0))) + 1e-9
    return ir * 3.8


class RoomScore:
    def __init__(self, dur: float, t60: float = 0.72):
        self.dur = dur
        n = int(SR * (dur + 2.0))
        self.dry = np.zeros((n, 2), dtype=np.float64)
        self.wet = np.zeros((n, 2), dtype=np.float64)
        self.t60 = t60
        self.events = []

    def place(self, sig: np.ndarray, t: float, gain: float = 1.0, pan: float = 0.0, send: float = 0.25, pan_to=None):
        if t < 0.0 or t >= self.dur:
            return
        i0 = int(round(t * SR))
        n = min(len(sig), len(self.dry) - i0)
        if n <= 0:
            return
        sig = np.asarray(sig[:n], dtype=np.float64)
        p = np.linspace(pan, pan if pan_to is None else pan_to, n)
        left = np.sqrt(np.clip(0.5 * (1.0 - p), 0.0, 1.0))
        right = np.sqrt(np.clip(0.5 * (1.0 + p), 0.0, 1.0))
        self.dry[i0 : i0 + n, 0] += sig * gain * left
        self.dry[i0 : i0 + n, 1] += sig * gain * right
        self.wet[i0 : i0 + n, 0] += sig * gain * send * left
        self.wet[i0 : i0 + n, 1] += sig * gain * send * right
        self.events.append(round(t, 3))

    def mix(self, peak_db: float = -10.0) -> np.ndarray:
        ir = make_room_impulse(self.t60)
        rev_l = fftconvolve_1d(self.wet[:, 0], ir[:, 0])
        rev_r = fftconvolve_1d(self.wet[:, 1], ir[:, 1])
        m = self.dry + np.stack([rev_l, rev_r], axis=1) * 0.88
        m[:, 0] = hp(m[:, 0], 38.0)
        m[:, 1] = hp(m[:, 1], 38.0)
        mx = float(np.max(np.abs(m))) + 1e-9
        m = sat(m / mx * 0.88, 1.25)
        m = m / (float(np.max(np.abs(m))) + 1e-9) * (10.0 ** (peak_db / 20.0))
        return m[: int(round(self.dur * SR))]


# ── Ambient D-Major Keynote Music Bed Synthesizer ────────────────────────────

# Section-aware D-major chord progressions (root + triad/color pitches in Hz)
# Chosen in D3..E5 sweet spot so vocals (100-350 Hz core + 1.5-3.5 kHz presence) breathe clearly.
CHORD_THEMES = {
    # Theme A: Warm opening & vision (root + open upper D4-A5 voicings clear of 120-260 Hz chest vocal zone)
    "A": [
        [146.83, 293.66, 369.99, 440.00, 659.25],  # Dmaj9
        [138.59, 329.63, 440.00, 554.37, 659.25],  # Aadd9/C#
        [123.47, 293.66, 369.99, 440.00, 587.33],  # Bm7(11)
        [196.00, 293.66, 369.99, 493.88, 659.25],  # Gmaj9(13)
    ],
    # Theme B: Engineering, FinTech & Architecture
    "B": [
        [196.00, 329.63, 369.99, 440.00, 587.33],  # Gmaj9
        [220.00, 329.63, 369.99, 493.88, 659.25],  # A6/9
        [185.00, 293.66, 369.99, 440.00, 659.25],  # F#m7(11)
        [123.47, 293.66, 369.99, 554.37, 659.25],  # Bm9
    ],
    # Theme C: Live Demo Walkthrough
    "C": [
        [146.83, 329.63, 369.99, 493.88, 659.25],  # Dmaj9(13)
        [164.81, 293.66, 369.99, 493.88, 659.25],  # Em9
        [185.00, 293.66, 440.00, 554.37, 659.25],  # F#m7/Dmaj7
        [196.00, 293.66, 369.99, 440.00, 587.33],  # Gmaj9
    ],
    # Theme D: Results & Capstone Finale
    "D": [
        [196.00, 329.63, 369.99, 493.88, 659.25],  # Gmaj9
        [220.00, 329.63, 369.99, 493.88, 739.99],  # Aadd9
        [185.00, 293.66, 369.99, 440.00, 659.25],  # F#m7
        [146.83, 293.66, 369.99, 440.00, 659.25],  # Dmaj9 tonic
    ],
}


def _theme_for_seg(idx: int) -> str:
    if idx <= 4:
        return "A"
    if idx <= 8:
        return "B"
    if idx <= 12:
        return "C"
    return "D"


def _synth_felt_pluck(freq: float, dur: float = 0.58) -> np.ndarray:
    """Warm felt-mallet / soft Rhodes pluck at F4+ range (short tail, zero low-mid mud)."""
    n = int(SR * dur)
    t = np.arange(n) / SR
    att = 1.0 - np.exp(-t * 95.0)
    wave_mono = (
        np.sin(2.0 * math.pi * freq * t) * np.exp(-t * 5.8)
        + 0.24 * np.sin(2.0 * math.pi * (2.0 * freq) * t) * np.exp(-t * 14.0)
        + 0.06 * np.sin(2.0 * math.pi * (3.0 * freq) * t) * np.exp(-t * 24.0)
    ) * att
    return wave_mono * 0.45


def build_ambient_music_bed(total_dur: float, segments: list) -> np.ndarray:
    """Synthesize a continuous, non-repetitive D-major keynote pad + gentle pulse."""
    total_samples = int(round(total_dur * SR))
    pad = np.zeros((total_samples, 2), dtype=np.float64)
    plucks = np.zeros((total_samples, 2), dtype=np.float64)

    beat_dur = 60.0 / 76.0  # 76 BPM = 0.78947s per beat
    bar_dur = beat_dur * 4.0  # 3.15789s per bar
    chord_dur = bar_dur * 2.0  # 6.3158s per chord

    # Build time grid of chords aligned smoothly across sections
    t_cur = 0.0
    chord_idx = 0
    fade_s = 0.65
    fade_n = int(round(fade_s * SR))

    seg_starts = [(s["start"], s["idx"]) for s in segments]

    while t_cur < total_dur:
        # Match harmonic theme to current chapter at midpoint of this chord
        t_mid = min(total_dur - 0.1, t_cur + chord_dur * 0.5)
        cur_seg_idx = 1
        for st, s_idx in seg_starts:
            if t_mid >= st:
                cur_seg_idx = s_idx
        theme_key = _theme_for_seg(cur_seg_idx)
        prog = CHORD_THEMES[theme_key]
        notes = prog[chord_idx % len(prog)]
        # On the final closing bar, force final tonic Dmaj9
        if t_cur >= total_dur - chord_dur * 1.1:
            notes = CHORD_THEMES["D"][-1]

        w_start = max(0, int(round((t_cur - fade_s * 0.5) * SR)))
        w_end = min(total_samples, int(round((t_cur + chord_dur + fade_s * 0.5) * SR)))
        wn = w_end - w_start
        if wn <= 0:
            break

        t_vec = (np.arange(w_start, w_end, dtype=np.float64)) / SR
        chord_l = np.zeros(wn, dtype=np.float64)
        chord_r = np.zeros(wn, dtype=np.float64)

        for v_i, f0 in enumerate(notes):
            # Mono-compatible stereo chord layering: phase-aligned core + subtle detuned shimmer
            det_l = 1.0 - 0.0009 * ((v_i % 2) * 2 - 1)
            det_r = 1.0 + 0.0010 * ((v_i % 2) * 2 - 1)
            ph0 = 0.55 * v_i
            osc_l = (
                np.sin(2.0 * math.pi * f0 * det_l * t_vec + ph0)
                + 0.24 * np.sin(4.0 * math.pi * f0 * det_l * t_vec + ph0)
                + 0.07 * np.sin(6.0 * math.pi * f0 * det_l * t_vec + ph0)
            )
            osc_r = (
                np.sin(2.0 * math.pi * f0 * det_r * t_vec + ph0 + 0.08)
                + 0.24 * np.sin(4.0 * math.pi * f0 * det_r * t_vec + ph0 + 0.12)
                + 0.07 * np.sin(6.0 * math.pi * f0 * det_r * t_vec + ph0 + 0.15)
            )
            # Attenuate sub-240 Hz bass voice so low-mids stay lean & clear of vocal chest tones
            weight = 0.11 if v_i == 0 else (0.21 if v_i < 3 else 0.16)
            pan_v = (v_i - 2) * 0.11
            gl = math.sqrt(0.5 * (1.0 - pan_v)) * weight
            gr = math.sqrt(0.5 * (1.0 + pan_v)) * weight
            chord_l += osc_l * gl
            chord_r += osc_r * gr

        # Smooth raised-cosine crossfade window between adjacent chords
        env = np.ones(wn, dtype=np.float64)
        fi = min(fade_n, wn // 2)
        if fi > 0 and w_start > 0:
            env[:fi] = 0.5 * (1.0 - np.cos(math.pi * np.arange(fi) / fi))
        elif w_start == 0:
            # Soft 1.2s fade-in at video start
            fi0 = min(int(1.2 * SR), wn)
            env[:fi0] = 0.5 * (1.0 - np.cos(math.pi * np.arange(fi0) / fi0))
        if fi > 0 and w_end < total_samples:
            env[-fi:] = 0.5 * (1.0 + np.cos(math.pi * np.arange(fi) / fi))

        pad[w_start:w_end, 0] += chord_l * env
        pad[w_start:w_end, 1] += chord_r * env

        # Gentle high-mid keynote pluck accents (kept >= 329 Hz so bass never muddies)
        arp_notes = [n * 2.0 if n < 260.0 else n for n in notes[1:5]]
        beat_offsets = (0.0, 1.5, 3.0, 4.0, 5.5, 6.5) if theme_key in ("B", "C") else (0.0, 2.0, 4.0, 6.0)
        for b_i, b_off in enumerate(beat_offsets):
            tp = t_cur + b_off * beat_dur
            if tp >= total_dur - 3.5:
                continue
            pf = arp_notes[(b_i + chord_idx) % len(arp_notes)]
            # Keep pitch comfortably in 329..740 Hz sweet spot
            while pf < 329.0:
                pf *= 2.0
            while pf > 740.0:
                pf *= 0.5
            pl = _synth_felt_pluck(pf, dur=0.52)
            i0 = int(round(tp * SR))
            pn = min(len(pl), total_samples - i0)
            if pn > 0:
                pan_p = -0.28 if b_i % 2 == 0 else 0.28
                plucks[i0 : i0 + pn, 0] += pl[:pn] * math.sqrt(0.5 * (1.0 - pan_p)) * 0.42
                plucks[i0 : i0 + pn, 1] += pl[:pn] * math.sqrt(0.5 * (1.0 + pan_p)) * 0.42

        t_cur += chord_dur
        chord_idx += 1

    # Add gentle shared room tail to plucks & glue with warm pad
    room_ir = make_room_impulse(0.95)
    plucks_wet = np.stack(
        [fftconvolve_1d(plucks[:, 0], room_ir[:, 0]), fftconvolve_1d(plucks[:, 1], room_ir[:, 1])],
        axis=1,
    )
    bed = pad * 0.85 + (plucks * 0.72 + plucks_wet * 0.45)

    # Subtle 0.06 Hz breathing movement on upper pad warmth + spectral vocal pocket
    t_all = np.arange(total_samples, dtype=np.float64) / SR
    lfo = 0.88 + 0.12 * np.sin(2.0 * math.pi * 0.06 * t_all)
    bed *= lfo[:, None]

    for ch in (0, 1):
        bed[:, ch] = hp(bed[:, ch], 145.0, order=2)
        bed[:, ch] = lp(bed[:, ch], 4600.0, order=2)
        # De-mud 195 Hz vocal chest overlap & carve 1.85 kHz vocal clarity pocket
        bed[:, ch] = bell_eq(bed[:, ch], 195.0, gain_db=-4.5, q=0.9)
        bed[:, ch] = bell_eq(bed[:, ch], 1850.0, gain_db=-4.0, q=1.05)

    # Ensure solid mono-compatible stereo correlation (+0.60+ correlation target)
    mid = 0.5 * (bed[:, 0] + bed[:, 1])
    side = 0.5 * (bed[:, 0] - bed[:, 1]) * 0.62
    bed[:, 0] = mid + side
    bed[:, 1] = mid - side

    # Graceful 3.2s musical fade-out at video finale
    tail_n = min(int(3.2 * SR), total_samples)
    fade_out = 0.5 * (1.0 + np.cos(math.pi * np.arange(tail_n) / tail_n))
    bed[-tail_n:] *= fade_out[:, None]

    # Normalize raw music bed to comfortable -23.5 dBFS RMS baseline before ducking
    rms = math.sqrt(float(np.mean(bed ** 2)) + 1e-12)
    bed *= (10.0 ** (-23.5 / 20.0)) / rms
    return bed


# ── Subtitle Formatter ───────────────────────────────────────────────────────

def read_wav_mono(path: str) -> np.ndarray:
    with wave.open(path, "rb") as w:
        assert w.getframerate() == SR
        raw = w.readframes(w.getnframes())
        arr = np.frombuffer(raw, dtype=np.int16).astype(np.float64) / 32768.0
        if w.getnchannels() == 2:
            arr = arr.reshape(-1, 2).mean(axis=1)
        return arr


def fmt_ts(sec: float, vtt: bool = False) -> str:
    ms = int(round(max(0.0, sec) * 1000))
    h, rem = divmod(ms, 3600000)
    m, rem = divmod(rem, 60000)
    s, ms = divmod(rem, 1000)
    sep = "." if vtt else ","
    return f"{h:02d}:{m:02d}:{s:02d}{sep}{ms:03d}"


def _lookahead_duck(vo_mono: np.ndarray, min_gain: float, max_gain: float, lookahead_s: float = 0.11) -> np.ndarray:
    """Compute smooth look-ahead sidechain gain curve (prevents vocal clipping or pumping)."""
    n = len(vo_mono)
    win_n = int(0.07 * SR)
    rect = np.abs(vo_mono)
    # Fast moving average via cumulative sum
    csum = np.concatenate(([0.0], np.cumsum(rect)))
    env = (csum[win_n:] - csum[:-win_n]) / win_n
    env = np.pad(env, (win_n // 2, n - len(env) - win_n // 2))

    # Shift earlier by lookahead_s so bed gently ducks BEFORE voice onset
    la_n = int(lookahead_s * SR)
    if la_n > 0:
        env = np.concatenate((env[la_n:], np.zeros(la_n)))

    speech_active = (env > 0.014).astype(np.float64)
    # Asymmetric attack (~90 ms) & gentle release (~520 ms)
    att_k = 1.0 - math.exp(-1.0 / (0.09 * SR))
    rel_k = 1.0 - math.exp(-1.0 / (0.52 * SR))
    smooth = np.empty(n, dtype=np.float64)
    cur = speech_active[0]
    for i in range(0, n, 256):
        end_i = min(n, i + 256)
        block_target = float(np.max(speech_active[i:end_i]))
        k = att_k * 256 if block_target > cur else rel_k * 256
        nxt = cur + (block_target - cur) * min(1.0, k)
        smooth[i:end_i] = np.linspace(cur, nxt, end_i - i, endpoint=False)
        cur = nxt
    return max_gain - smooth * (max_gain - min_gain)


# ── Main Mixer ───────────────────────────────────────────────────────────────

def mix_all():
    plan = json.load(open(PLAN_PATH, encoding="utf-8"))
    total_dur = float(plan["total_dur"])
    total_samples = int(round(total_dur * SR))

    print(f"Mixing Studio Master audio ({total_dur:.2f}s, {len(plan['segments'])} chapters)...", flush=True)

    # 1. Voiceover track normalized per cue to -16.2 dBFS active speech RMS
    vo_mono = np.zeros(total_samples, dtype=np.float64)
    for seg in plan["segments"]:
        for lt in seg["lines"]:
            wav_p = lt["wav"]
            if not os.path.exists(wav_p):
                alt_p = wav_p.replace(
                    "/home/reny/FoodGo/output/scripts/studio_master", SCRATCH_MASTER
                )
                if os.path.exists(alt_p):
                    wav_p = alt_p
            arr = read_wav_mono(wav_p)
            rms = math.sqrt(float(np.mean(arr ** 2)) + 1e-12)
            arr = arr * ((10.0 ** (-16.2 / 20.0)) / rms)
            cap = 10.0 ** (-4.2 / 20.0)
            mx = float(np.max(np.abs(arr)))
            if mx > cap:
                arr = np.tanh(arr / cap) * cap
            i0 = int(round(lt["global_start"] * SR))
            i1 = min(total_samples, i0 + len(arr))
            vo_mono[i0:i1] += arr[: i1 - i0]

    # 2. Synthesize continuous D-major ambient music bed
    music_bed = build_ambient_music_bed(total_dur, plan["segments"])

    # 3. Score cohesive in-key transition SFX & visual proof cues inside shared room
    score = RoomScore(dur=total_dur + 1.0, t60=0.65)
    # D-major pentatonic pitches for subtle visual proof spotlight cues & chapter roots
    scale_notes = (587.33, 659.25, 739.99, 880.00, 987.77)  # D5, E5, F#5, A5, B5
    ch_roots = (293.66, 329.63, 369.99, 392.00, 440.00)     # D4, E4, F#4, G4, A4

    for seg in plan["segments"]:
        s_start = float(seg["start"])
        idx = int(seg["idx"])
        root_f = ch_roots[(idx - 1) % len(ch_roots)]

        # Pre-rise air breath leading into chapter switches (idx > 1)
        if idx > 1 and s_start > 0.35:
            score.place(
                air(0.42, 220.0, 1550.0, q=1.3, peak_pos=0.82),
                s_start - 0.32,
                gain=0.22,
                pan=0.45 if idx % 2 else -0.45,
                pan_to=0.0,
                send=0.32,
            )

        # Chapter landing: warm sub + studio air sweep + subtle in-key glass fifth
        score.place(sub(58.0, 0.72), s_start + 0.03, gain=0.40, pan=0.0, send=0.18)
        score.place(
            air(0.46, 260.0, 1950.0, q=1.4, peak_pos=0.40),
            s_start + 0.04,
            gain=0.34,
            pan=-0.38 if idx % 2 else 0.38,
            pan_to=0.0,
            send=0.28,
        )
        score.place(wood(280.0 + (idx % 4) * 35.0, 0.12), s_start + 0.34, gain=0.24, pan=pan_of(960), send=0.22)
        score.place(glass(root_f * 2.0, 0.85, bright=0.55), s_start + 0.08, gain=0.12, pan=-0.16, send=0.38)
        score.place(glass(root_f * 3.0, 0.72, bright=0.45), s_start + 0.14, gain=0.08, pan=0.18, send=0.42)

        for l_idx, lt in enumerate(seg["lines"]):
            if l_idx > 0:
                cue_t = max(0.0, float(lt["global_start"]) - 0.28)
                note_f = scale_notes[(idx + l_idx) % len(scale_notes)]
                # Tactile visual proof card switch: delicate tap + warm tuned bubble
                score.place(wood(360.0 + l_idx * 40.0, 0.09), cue_t, gain=0.14, pan=pan_of(1240), send=0.20)
                score.place(bubble(note_f, 0.18), cue_t + 0.015, gain=0.14, pan=pan_of(1260), send=0.30)

        # Live Demo confirmation chimes (Bakong KHQR & Driver Handover chapters)
        if seg["id"] in ("seg05b_features_khqr", "seg08c_demo_driver"):
            mid_t = s_start + float(seg["dur"]) * 0.52
            score.place(glass(739.99, 0.55, bright=0.5), mid_t, gain=0.10, pan=0.22, send=0.36)
            score.place(glass(880.00, 0.65, bright=0.5), mid_t + 0.14, gain=0.10, pan=0.26, send=0.38)

        if idx == 14:
            # Cadential D-major tonic harmonic confirmation on capstone finale
            last_end = float(seg["lines"][-1]["global_end"])
            score.place(glass(440.00, 0.90, bright=0.45), last_end + 0.18, gain=0.12, pan=-0.14, send=0.45)
            score.place(glass(587.33, 1.35, bright=0.40), last_end + 0.36, gain=0.14, pan=0.14, send=0.50)

    sfx_stereo = score.mix(peak_db=-11.2)[:total_samples]

    # 4. Look-ahead ducking: music breathes warmly during pauses while protecting Khmer voice clarity
    duck_music = _lookahead_duck(vo_mono, min_gain=0.25, max_gain=0.72, lookahead_s=0.11)
    duck_sfx = _lookahead_duck(vo_mono, min_gain=0.55, max_gain=1.00, lookahead_s=0.06)

    mix = (
        music_bed * duck_music[:, None]
        + sfx_stereo * duck_sfx[:, None]
        + vo_mono[:, None] * 1.12
    )

    peak = float(np.max(np.abs(mix)))
    ceiling = 10.0 ** (-2.8 / 20.0)
    if peak > ceiling:
        mix = np.tanh(mix / ceiling * 0.92) / math.tanh(0.92) * ceiling

    peak_db = 20.0 * math.log10(float(np.max(np.abs(mix))) + 1e-12)
    pcm = np.clip(np.rint(mix * 32767.0), -32767, 32767).astype(np.int16)
    with wave.open(OUT_MASTER_WAV, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())

    print(f"wrote {OUT_MASTER_WAV}: dur={total_dur:.2f}s peak={peak_db:.2f} dBFS", flush=True)

    # 5. Export synchronized SRT & VTT master captions
    os.makedirs(os.path.dirname(OUT_SRT), exist_ok=True)
    with open(OUT_SRT, "w", encoding="utf-8") as fs, open(OUT_VTT, "w", encoding="utf-8") as fv:
        fv.write("WEBVTT\n\n")
        for i, q in enumerate(plan["subs"], 1):
            fs.write(f"{i}\n{fmt_ts(q['start'])} --> {fmt_ts(q['end'])}\n{q['km']}\n{q['en']}\n\n")
            fv.write(f"{i}\n{fmt_ts(q['start'], True)} --> {fmt_ts(q['end'], True)}\n{q['km']}\n{q['en']}\n\n")
    print(f"wrote {OUT_SRT} & {OUT_VTT} ({len(plan['subs'])} cues)", flush=True)


if __name__ == "__main__":
    mix_all()
