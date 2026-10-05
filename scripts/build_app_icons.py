import os
import subprocess

SVG_CONTENT = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512" fill="none">
  <defs>
    <linearGradient id="bg_grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#141F18" />
      <stop offset="100%" stop-color="#0E1511" />
    </linearGradient>
    <linearGradient id="foodgo_grad_primary" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#35B86B" />
      <stop offset="100%" stop-color="#289A57" />
    </linearGradient>
    <linearGradient id="foodgo_grad_leaf" x1="0%" y1="100%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#7FFFB3" />
      <stop offset="100%" stop-color="#35B86B" />
    </linearGradient>
    <linearGradient id="foodgo_grad_accent" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFB800" />
      <stop offset="100%" stop-color="#FF6A00" />
    </linearGradient>
    <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="10" result="blur" />
      <feComposite in="SourceGraphic" in2="blur" operator="over" />
    </filter>
  </defs>

  <!-- Dark Background Squircle -->
  <rect x="16" y="16" width="480" height="480" rx="110" fill="url(#bg_grad)" stroke="#35B86B" stroke-width="8" stroke-opacity="0.35" />

  <!-- Inner Soft Green Glow Circle -->
  <circle cx="256" cy="256" r="190" fill="url(#foodgo_grad_primary)" fill-opacity="0.12" stroke="url(#foodgo_grad_primary)" stroke-width="4" stroke-opacity="0.3" />

  <!-- Burger & Leaf Icon Scaled in Center -->
  <g transform="translate(96, 96) scale(3.2)">
    <!-- Fresh Leaf at Top -->
    <path d="M50 14 C56 12, 64 16, 62 25 C55 26, 49 20, 50 14 Z" fill="url(#foodgo_grad_leaf)" />
    <path d="M50 20 Q56 22 62 25" stroke="#35B86B" stroke-width="1.2" stroke-linecap="round" />

    <!-- Burger Top Bun -->
    <path d="M26 40 C26 27, 74 27, 74 40 C74 42, 26 42, 26 40 Z" fill="url(#foodgo_grad_primary)" />
    <!-- Sesame Seeds -->
    <circle cx="38" cy="33" r="1.5" fill="#FFFFFF" fill-opacity="0.85" />
    <circle cx="50" cy="30" r="1.5" fill="#FFFFFF" fill-opacity="0.85" />
    <circle cx="62" cy="34" r="1.5" fill="#FFFFFF" fill-opacity="0.85" />

    <!-- Fresh Lettuce Ribbon -->
    <path d="M23 44 C28 41, 31 47, 36 44 C41 41, 44 47, 50 44 C56 41, 59 47, 64 44 C69 41, 72 47, 77 44 C78 47, 76 49, 74 49 C69 49, 66 46, 61 48 C56 50, 53 46, 48 48 C43 50, 40 46, 35 48 C30 50, 27 46, 23 48 Z" fill="url(#foodgo_grad_leaf)" />

    <!-- Cheddar Cheese Melt -->
    <path d="M25 50 L75 50 L71 55 L58 55 L54 62 L48 55 L29 55 Z" fill="url(#foodgo_grad_accent)" />

    <!-- Patty Layer -->
    <rect x="25" y="56" width="50" height="9" rx="4.5" fill="#8D4925" />

    <!-- Burger Bottom Bun -->
    <path d="M27 68 C27 75, 73 75, 73 68 C73 67, 27 67, 27 68 Z" fill="url(#foodgo_grad_primary)" />
  </g>
</svg>'''

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    flutter_dir = os.path.join(base_dir, 'foodgo_flutter')
    temp_svg = os.path.join(flutter_dir, 'assets', 'svg', 'foodgo_app_icon.svg')

    with open(temp_svg, 'w', encoding='utf-8') as f:
        f.write(SVG_CONTENT)
    print(f"Created {temp_svg}")

    targets = [
        # (output_path, width, height)
        (os.path.join(flutter_dir, 'assets', 'icon.png'), 1024, 1024),
        (os.path.join(flutter_dir, 'web', 'favicon.png'), 32, 32),
        (os.path.join(flutter_dir, 'web', 'icons', 'Icon-192.png'), 192, 192),
        (os.path.join(flutter_dir, 'web', 'icons', 'Icon-512.png'), 512, 512),
        (os.path.join(flutter_dir, 'web', 'icons', 'Icon-maskable-192.png'), 192, 192),
        (os.path.join(flutter_dir, 'web', 'icons', 'Icon-maskable-512.png'), 512, 512),
        (os.path.join(flutter_dir, 'android', 'app', 'src', 'main', 'res', 'mipmap-mdpi', 'launcher_icon.png'), 48, 48),
        (os.path.join(flutter_dir, 'android', 'app', 'src', 'main', 'res', 'mipmap-hdpi', 'launcher_icon.png'), 72, 72),
        (os.path.join(flutter_dir, 'android', 'app', 'src', 'main', 'res', 'mipmap-xhdpi', 'launcher_icon.png'), 96, 96),
        (os.path.join(flutter_dir, 'android', 'app', 'src', 'main', 'res', 'mipmap-xxhdpi', 'launcher_icon.png'), 144, 144),
        (os.path.join(flutter_dir, 'android', 'app', 'src', 'main', 'res', 'mipmap-xxxhdpi', 'launcher_icon.png'), 192, 192),
    ]

    for path, w, h in targets:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        subprocess.run(['rsvg-convert', '-w', str(w), '-h', str(h), temp_svg, '-o', path], check=True)
        print(f"Generated: {path} ({w}x{h})")

    print("All app icons successfully generated!")

if __name__ == '__main__':
    main()
