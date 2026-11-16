#!/usr/bin/env python3
"""Reproducible orchestrator for the FoodGo 8-10 min Studio Master Presentation.

Pipeline:
1. Synthesize Khmer neural voiceover (km-KH-PisethNeural) & timing plan -> plan_master.json
2. Mix narration + onetake sfx_palette room-reverbed accents -> master_mix.wav & .srt/.vtt
3. Render 14 Playwright Chromium HTML/Canvas overlays (phone destination-out cutouts +
   Khmer/EN captions) + composite live Flutter captures -> /home/reny/FoodGo/output/final/foodgo-presentation.mp4
"""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MASTER_DIR = os.path.join(HERE, "studio_master")
TTS_PYTHON = "/home/reny/FoodGo/backend/venv/bin/python"
AUDIO_PYTHON = "/home/reny/Videos/FoodGo-Video-Studio/.venv/bin/python" if os.path.exists("/home/reny/Videos/FoodGo-Video-Studio/.venv/bin/python") else sys.executable
RENDER_PYTHON = sys.executable


def main():
    vo_py = os.path.join(MASTER_DIR, "build_master_vo.py")
    audio_py = os.path.join(MASTER_DIR, "build_master_audio.py")
    render_py = os.path.join(MASTER_DIR, "render_studio_master.py")

    print("[1/3] Generating Khmer voiceover & master timeline...")
    subprocess.run([TTS_PYTHON, vo_py], check=True)

    print("[2/3] Mixing ambient music bed, SFX & exporting synced SRT/VTT subtitles...")
    subprocess.run([AUDIO_PYTHON, audio_py], check=True)

    print("[3/3] Rendering Chromium overlays, compositing Flutter recordings & mastering MP4...")
    subprocess.run([RENDER_PYTHON, render_py], check=True)


if __name__ == "__main__":
    main()
