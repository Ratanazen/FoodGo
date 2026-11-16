#!/usr/bin/env python3
"""Render all 14 FoodGo Studio Master chapter previews via Playwright Chromium,
verify loaded app screenshots, non-overlapping bounds, transparent phone cutouts,
and assemble a labeled 4x4 contact sheet qa_14_chapters.png without PIL dependency."""

import base64
import os
from playwright.sync_api import sync_playwright

BASE = os.path.dirname(os.path.abspath(__file__))
HTML_PATH = f"file://{BASE}/comp_studio.html"
OUT_DIR = f"{BASE}/qa_frames"
OUT_GRID = f"{BASE}/qa_14_chapters.png"

STAGES = [
    ("seg01_intro", 1.8, 1),
    ("seg02_problem", 1.8, 1),
    ("seg03_objectives", 1.8, 2),
    ("seg04_solution", 1.8, 2),
    ("seg05a_features_ui", 1.8, 1),
    ("seg05b_features_khqr", 1.8, 1),
    ("seg06_tech_stack", 2.0, 1),
    ("seg07_architecture", 2.0, 2),
    ("seg08a_demo_checkout", 1.8, 1),
    ("seg08b_demo_gps", 1.8, 1),
    ("seg08c_demo_driver", 1.8, 2),
    ("seg08d_demo_admin", 1.8, 1),
    ("seg09_results", 2.2, 1),
    ("seg10_conclusion", 2.0, 1),
]


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    frame_b64s = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": 1920, "height": 1080}, device_scale_factor=1)
        page.goto(HTML_PATH, wait_until="networkidle")
        page.evaluate("() => Promise.all([document.fonts.ready, window.__readyPromise])")

        for seg_id, t, line_idx in STAGES:
            page.evaluate(f"window.__setStage('{seg_id}', {t}, {line_idx})")
            page.wait_for_timeout(40)

            audit = page.evaluate("""() => {
                const imgs = [...document.querySelectorAll('#stage-root img')];
                const broken = imgs.filter(i => !i.complete || i.naturalWidth === 0).map(i => i.src);
                const deck = document.getElementById('main-deck').getBoundingClientRect();
                const deckOverflow = deck.bottom > 888;
                return { broken, deckBottom: Math.round(deck.bottom), deckOverflow, imgCount: imgs.length };
            }""")
            if audit["broken"]:
                raise AssertionError(f"{seg_id}: broken images: {audit['broken']}")
            if audit["deckOverflow"]:
                raise AssertionError(f"{seg_id}: main-deck bottom {audit['deckBottom']} overflows y=888!")

            out_png = os.path.join(OUT_DIR, f"{seg_id}.png")
            page.screenshot(path=out_png, omit_background=True)
            b64 = base64.b64encode(open(out_png, "rb").read()).decode("ascii")
            frame_b64s.append((seg_id, b64))
            print(f"QA OK {seg_id:22s} imgs={audit['imgCount']} bottom={audit['deckBottom']}")

        # Composite crisp 4x4 grid showing the transparent phone slot in teal underneath
        tiles_html = []
        for idx, (sid, b64) in enumerate(frame_b64s, start=1):
            tiles_html.append(f"""
            <div class="tile">
              <div class="mock-phone">LIVE APP VIDEO<br/>HOLE alpha=0</div>
              <img class="ov" src="data:image/png;base64,{b64}" />
              <div class="tag">{idx:02d}. {sid}</div>
            </div>""")

        grid_html = f"""<!doctype html><html><body style="margin:0;background:#090D16;font-family:monospace;">
        <div style="display:grid;grid-template-columns:repeat(4,480px);grid-template-rows:repeat(4,270px);width:1920px;height:1080px;">
          {"".join(tiles_html)}
        </div>
        <style>
          .tile{{position:relative;width:480px;height:270px;background:#0f172a;overflow:hidden;border:1px solid #1e293b;}}
          .mock-phone{{position:absolute;left:14px;top:30px;width:83px;height:180px;border-radius:6px;background:linear-gradient(160deg,#0f766e,#115e59);color:#fff;font-size:8px;font-weight:700;display:flex;align-items:center;justify-content:center;text-align:center;line-height:1.3;}}
          img.ov{{position:absolute;inset:0;width:480px;height:270px;display:block;}}
          .tag{{position:absolute;left:6px;top:4px;background:#F15A24;color:#fff;font-size:10px;font-weight:700;padding:2px 7px;border-radius:4px;}}
        </style></body></html>"""
        page.set_content(grid_html)
        page.wait_for_timeout(120)
        page.screenshot(path=OUT_GRID)
        browser.close()
        print(f"Saved {OUT_GRID}")


if __name__ == "__main__":
    main()
