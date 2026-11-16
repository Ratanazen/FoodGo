#!/usr/bin/env python3
"""Studio Master v4 Renderer for FoodGo Capstone Presentation (8-10 min).

Upgrades visual polish and embeds synchronized real Flutter app screenshots
AND live moving Flutter app video inside EVERY explanation chapter (01..10):
- Executive Navy Keynote & Architectural Pearl Studio themes
- Titanium Phone live app video window (332x722 @ x=56, y=122) across all 14 segments
- Synchronized In-App Visual Proof Panel (full screen + zoomed UI focus + filmstrip)
- Crisp Khmer (Kantumruy Pro) + English (Inter) captions rendered via Playwright
"""

import concurrent.futures
import json
import os
import subprocess
import time
from playwright.sync_api import sync_playwright

BASE = os.path.dirname(os.path.abspath(__file__))
HTML_URL = f"file://{BASE}/comp_studio.html"
SCRATCH_MASTER = "/home/reny/.gemini/antigravity/brain/cd7399e3-4f43-48fd-a82e-f7613f1cbe6e/scratch/foodgo_studio_master"
PLAN_PATH = os.path.join(BASE, "plan_master.json") if os.path.exists(os.path.join(BASE, "plan_master.json")) else os.path.join(SCRATCH_MASTER, "plan_master.json")
AUDIO_WAV = os.path.join(BASE, "master_mix.wav") if os.path.exists(os.path.join(BASE, "master_mix.wav")) else os.path.join(SCRATCH_MASTER, "master_mix.wav")
CACHE_ROOT = "/tmp/foodgo_render_v4"
STAGES_DIR = os.path.join(CACHE_ROOT, "stages")
CLIPS_DIR = os.path.join(CACHE_ROOT, "clips")
REC_DIR = "/home/reny/FoodGo/output/capcut-pack/media/01_raw_mobile_clips"
ASSETS_DIR = os.path.join(BASE, "assets")
OUT_MP4 = "/home/reny/FoodGo/output/final/foodgo-presentation.mp4"

# Phone screen recording map across ALL 14 segments: (abs_path, start_sec, clean_cap_sec, theme)
REC_MAP = {
    "seg01_intro":         (f"{REC_DIR}/ch01_intro.mp4",             0.5, 52.0, "dark"),
    "seg02_problem":       (f"{REC_DIR}/ch03_auth_portals.mp4",      0.5, 40.0, "paper"),
    "seg03_objectives":    (f"{REC_DIR}/ch04_home_localization.mp4", 0.4, 22.0, "paper"),
    "seg04_solution":      (f"{REC_DIR}/ch05_explore_theme.mp4",     0.4, 40.0, "dark"),
    "seg05a_features_ui":  (f"{REC_DIR}/ch06_cart_checkout.mp4",     0.4, 36.0, "paper"),
    "seg05b_features_khqr":(f"{REC_DIR}/ch07_bakong_khqr.mp4",       0.4, 38.0, "dark"),
    "seg06_tech_stack":    (f"{REC_DIR}/ch05_explore_theme.mp4",    18.0, 21.5, "paper"),
    "seg07_architecture":  (f"{ASSETS_DIR}/ch_arch_4portals.mp4",    0.0, 31.0, "dark"),
    "seg08a_demo_checkout":(f"{REC_DIR}/ch08_orders_receipt.mp4",    0.4, 35.5, "paper"),
    "seg08b_demo_gps":     (f"{REC_DIR}/ch09_live_tracking.mp4",     0.4, 33.8, "dark"),
    "seg08c_demo_driver":  (f"{REC_DIR}/ch10_driver_portal.mp4",     0.5, 27.0, "paper"),
    "seg08d_demo_admin":   (f"{REC_DIR}/ch11_owner_admin.mp4",       0.5, 47.0, "dark"),
    "seg09_results":       (f"{REC_DIR}/ch11_owner_admin.mp4",      24.0, 22.0, "paper"),
    "seg10_conclusion":    (f"{ASSETS_DIR}/ch_finale_montage.mp4",   0.0, 35.0, "dark"),
}

FPS = 30
CYCLE_FPS = 15
CYCLE_FRAMES = 30  # exact 2.000s (sin(t*PI) periodic)


def render_segment_worker(seg: dict):
    """Render all Chromium RGBA stage frames & subtitle strips for one chapter."""
    seg_id = seg["id"]
    seg_dir = os.path.join(STAGES_DIR, seg_id)
    os.makedirs(seg_dir, exist_ok=True)
    _, _, _, theme = REC_MAP[seg_id]
    ent_dur = 1.60 if seg_id == "seg09_results" else 1.20
    ent_frames = int(round(ent_dur * FPS))
    n_lines = len(seg["lines"])

    expected_total = ent_frames + n_lines * CYCLE_FRAMES + n_lines
    existing = [f for f in os.listdir(seg_dir) if f.endswith(".png")]
    if len(existing) >= expected_total:
        return seg_id, "cached", expected_total

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 1920, "height": 1080}, device_scale_factor=1)
        page.goto(HTML_URL, wait_until="networkidle")
        page.evaluate("() => Promise.all([document.fonts.ready, window.__readyPromise])")

        # 1. Kinetic Entrance Frames (0 .. ent_dur @ 30 FPS, spotlight line 0)
        for k in range(ent_frames):
            out_p = os.path.join(seg_dir, f"ent_{k:04d}.png")
            if not os.path.exists(out_p):
                t = k / float(FPS)
                page.evaluate(f"window.__setStage('{seg_id}', {t:.4f}, 0)")
                page.screenshot(path=out_p, omit_background=True)

        # 2. Periodic 2.0s Subtle Living Breathing Loops (30 frames @ 15 FPS per active cue)
        for l_idx in range(n_lines):
            for f in range(CYCLE_FRAMES):
                out_p = os.path.join(seg_dir, f"c{l_idx}_{f:04d}.png")
                if not os.path.exists(out_p):
                    t_cyc = ent_dur + (f / float(CYCLE_FPS))
                    page.evaluate(f"window.__setStage('{seg_id}', {t_cyc:.4f}, {l_idx})")
                    page.screenshot(path=out_p, omit_background=True)

        # 3. Dedicated 1920x114 Chromium Subtitle Pill Strip per cue
        cap_page = browser.new_page(viewport={"width": 1920, "height": 114}, device_scale_factor=1)
        cap_page.goto(HTML_URL, wait_until="networkidle")
        cap_page.evaluate("() => Promise.all([document.fonts.ready, window.__readyPromise])")
        for l_idx, lt in enumerate(seg["lines"]):
            cap_p = os.path.join(seg_dir, f"cap_{l_idx:02d}.png")
            if not os.path.exists(cap_p):
                km_js = json.dumps(lt["cap_km"], ensure_ascii=False)
                en_js = json.dumps(lt["cap_en"], ensure_ascii=False)
                cap_page.evaluate(f"window.__renderCaptionOnly({km_js}, {en_js}, '{theme}')")
                cap_page.screenshot(path=cap_p, omit_background=True)

        browser.close()
    return seg_id, "rendered", expected_total


def encode_segment(seg: dict) -> str:
    """Composite Chromium overlays, real Flutter app video & Chromium captions for 1 segment."""
    seg_id = seg["id"]
    seg_dir = os.path.join(STAGES_DIR, seg_id)
    out_mp4 = os.path.join(CLIPS_DIR, f"{seg_id}.mp4")
    if os.path.exists(out_mp4) and os.path.getsize(out_mp4) > 100000:
        return out_mp4

    ent_dur = 1.60 if seg_id == "seg09_results" else 1.20
    ent_frames = int(round(ent_dur * FPS))
    total_frames = int(seg["frames"])
    seg_dur = total_frames / float(FPS)
    lines = seg["lines"]
    n_lines = len(lines)

    rec_path, rec_start, rec_cap_dur, _ = REC_MAP[seg_id]

    cue_bounds = []
    for k in range(n_lines):
        if k == 0:
            s_frame = ent_frames
        else:
            s_frame = max(ent_frames, int(round((lines[k]["local_start"] - 0.15) * FPS)))
        if k + 1 < n_lines:
            e_frame = max(s_frame + 1, int(round((lines[k + 1]["local_start"] - 0.15) * FPS)))
        else:
            e_frame = total_frames
        cue_bounds.append((k, s_frame, e_frame))

    cmd = ["ffmpeg", "-y", "-v", "error"]
    cmd += ["-framerate", str(FPS), "-i", os.path.join(seg_dir, "ent_%04d.png")]
    for k, s_f, e_f in cue_bounds:
        cmd += ["-stream_loop", "-1", "-framerate", str(CYCLE_FPS), "-i", os.path.join(seg_dir, f"c{k}_%04d.png")]

    cap_in_start = 1 + n_lines
    for l_idx in range(n_lines):
        cmd += ["-loop", "1", "-t", f"{seg_dur:.4f}", "-i", os.path.join(seg_dir, f"cap_{l_idx:02d}.png")]

    # Real Flutter Phone Video Input cleanly sliced to safe non-glitch range & looped inside FFmpeg filtergraph
    phone_in_idx = cap_in_start + n_lines
    cmd += ["-ss", f"{rec_start:.2f}", "-t", f"{rec_cap_dur + 0.4:.2f}", "-i", rec_path]

    fc_lines = [f"[0:v]fps={FPS},format=rgba,setpts=PTS-STARTPTS[ov_ent]"]
    ov_inputs = ["[ov_ent]"]
    for idx_in, (k, s_f, e_f) in enumerate(cue_bounds, start=1):
        need_f = max(1, e_f - s_f)
        fc_lines.append(
            f"[{idx_in}:v]fps={FPS},format=rgba,trim=start_frame=0:end_frame={need_f},setpts=PTS-STARTPTS[ov_c{k}]"
        )
        ov_inputs.append(f"[ov_c{k}]")

    fc_lines.append(
        f"{''.join(ov_inputs)}concat=n={len(ov_inputs)}:v=1:a=0,trim=start_frame=0:end_frame={total_frames},setpts=PTS-STARTPTS[stage_rgba]"
    )

    cap_f = int(round(rec_cap_dur * FPS))
    fc_lines.append(
        f"[{phone_in_idx}:v]fps={FPS},scale=332:722:flags=lanczos,trim=start_frame=0:end_frame={cap_f},setpts=PTS-STARTPTS,"
        f"loop=loop=-1:size={cap_f}:start=0,trim=start_frame=0:end_frame={total_frames},setpts=PTS-STARTPTS,"
        f"pad=1920:1080:56:122:color=#080D16[phone_bg]"
    )
    fc_lines.append("[phone_bg][stage_rgba]overlay=0:0:eof_action=pass[scene0]")

    cur = "scene0"
    for l_idx, lt in enumerate(lines):
        cap_idx = cap_in_start + l_idx
        t0 = max(0.0, float(lt["local_start"]) - 0.05)
        t1 = min(seg_dur, float(lt["local_end"]) + 0.12)
        nxt = f"scene{l_idx + 1}"
        fc_lines.append(
            f"[{cur}][{cap_idx}:v]overlay=0:896:eof_action=pass:enable='between(t,{t0:.3f},{t1:.3f})'[{nxt}]"
        )
        cur = nxt

    fade_out_st = max(0.3, seg_dur - 0.22)
    fc_lines.append(f"[{cur}]fade=t=in:st=0:d=0.22,fade=t=out:st={fade_out_st:.3f}:d=0.22,format=yuv420p[vout]")

    cmd += [
        "-filter_complex", ";".join(fc_lines),
        "-map", "[vout]",
        "-t", f"{seg_dur:.4f}",
        "-c:v", "libx264", "-preset", "fast", "-crf", "14",
        "-pix_fmt", "yuv420p", "-r", str(FPS), "-an",
        out_mp4,
    ]
    subprocess.run(cmd, check=True)
    return out_mp4


def main():
    t_start = time.time()
    os.makedirs(STAGES_DIR, exist_ok=True)
    os.makedirs(CLIPS_DIR, exist_ok=True)
    os.makedirs(os.path.dirname(OUT_MP4), exist_ok=True)

    plan = json.load(open(PLAN_PATH, encoding="utf-8"))
    segments = plan["segments"]
    print(f"Rendering {len(segments)} studio chapters ({plan['total_dur']:.2f}s = {plan['total_dur']/60:.2f} min)...")

    with concurrent.futures.ProcessPoolExecutor(max_workers=4) as pool:
        for seg_id, status, cnt in pool.map(render_segment_worker, segments):
            print(f"  [CHROMIUM {status.upper():8s}] {seg_id:22s} ({cnt} RGBA overlays)", flush=True)

    clip_paths = []
    for seg in segments:
        p = encode_segment(seg)
        clip_paths.append(p)
        print(f"  [COMPOSIT] {seg['id']:22s} -> {os.path.basename(p)} ({seg['dur']:.2f}s / {seg['frames']}f)", flush=True)

    concat_txt = os.path.join(CLIPS_DIR, "concat_master.txt")
    with open(concat_txt, "w", encoding="utf-8") as f:
        for cp in clip_paths:
            f.write(f"file '{cp}'\n")

    print("Mastering final 1080p30 H.264 + 48kHz AAC deliverable...", flush=True)
    subprocess.run(
        [
            "ffmpeg", "-y", "-v", "error",
            "-f", "concat", "-safe", "0", "-i", concat_txt,
            "-i", AUDIO_WAV,
            "-map", "0:v:0", "-map", "1:a:0",
            "-c:v", "libx264", "-preset", "medium", "-crf", "18",
            "-pix_fmt", "yuv420p", "-r", str(FPS),
            "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
            "-movflags", "+faststart", "-shortest",
            OUT_MP4,
        ],
        check=True,
    )
    elapsed = time.time() - t_start
    print(f"DONE: {OUT_MP4} built in {elapsed:.1f}s")


if __name__ == "__main__":
    main()
