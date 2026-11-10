# FOODGO VIDEO STUDIO DESIGN SYSTEM & UI TOKENS

**Version**: 2.0.0  
**Target Application**: `artifacts/foodgo-project-video/studio/`  
**Brand Identity**: FoodGo Digital Platform (Modern Food Delivery & Video Production Suite)  

---

## 1. Color System

The design system employs a professional dark theme as the default to ensure color accuracy, reduce eye strain during editing sessions, and emulate industry-standard creative suites (DaVinci Resolve, Adobe Premiere Pro, Linear). A high-contrast light theme is also fully supported.

### 1.1 Color Tokens (Dark Theme - Default)

| Token Name | Hex Value | Semantic Usage |
| :--- | :--- | :--- |
| `--bg-canvas` | `#0B0F17` | Deep backdrop canvas, outer window frame |
| `--bg-surface` | `#111622` | Primary panel backgrounds (sidebar, inspector, cards) |
| `--bg-surface-elevated` | `#182030` | Elevated containers, header bars, modal sheets |
| `--bg-surface-hover` | `#222D42` | Interactive element hover states, active list rows |
| `--border-subtle` | `rgba(255, 255, 255, 0.08)` | Internal card dividers, inactive tabs |
| `--border-default` | `rgba(255, 255, 255, 0.16)` | Card borders, input field outlines |
| `--border-focus` | `#F15A24` | 2px high-contrast active keyboard focus ring |
| `--text-primary` | `#F8FAFC` | Primary headlines, titles, active label text |
| `--text-secondary` | `#94A3B8` | Subtitles, timecodes, descriptions, metadata |
| `--text-muted` | `#64748B` | Disabled hints, placeholder text, shortcut keys |

### 1.2 Brand & Status Accents

| Token Name | Hex Value | Semantic Usage |
| :--- | :--- | :--- |
| `--accent-primary` | `#F15A24` | FoodGo vibrant brand orange; primary CTA buttons, active timeline playhead |
| `--accent-primary-hover` | `#D94A17` | Hover state for primary action buttons |
| `--accent-primary-subtle`| `rgba(241, 90, 36, 0.15)` | Selected scene clip backgrounds, active navigation badge |
| `--accent-cyan` | `#06B6D4` | Media video clips, timecode highlights, technology badges |
| `--accent-green` | `#22C55E` | Verified statuses, audio narration track, passing tests |
| `--accent-amber` | `#F59E0B` | In-progress tasks, unsaved changes warning, warning badges |
| `--accent-purple` | `#8B5CF6` | Subtitles track, typography highlights |

---

## 2. Typography Scale

The studio uses **DM Sans** for legible UI labels and data displays, and **Manrope** for crisp structural headings and numerical readouts.

| Role | Font Family | Size | Weight | Line Height | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display Header** | Manrope | 24px | 800 | 1.2 | -0.5px |
| **Section Title** | Manrope | 18px | 700 | 1.3 | -0.2px |
| **Card Header** | Manrope | 14px | 700 | 1.4 | 0px |
| **Body Primary** | DM Sans | 13px | 500 | 1.5 | 0px |
| **Body Secondary**| DM Sans | 12px | 400 | 1.5 | 0px |
| **Timecode / Code**| Consolas, monospace | 12px | 600 | 1.2 | 0.5px |
| **Caption / Badge** | DM Sans | 10px | 700 | 1.2 | 0.8px (Caps) |

---

## 3. Spacing & Radius Scales

### Spacing Scale
- `4px` (`--space-xs`): Tight icon spacing, badge padding
- `8px` (`--space-sm`): Control gaps, internal item padding
- `12px` (`--space-md`): Standard toolbar padding, list row spacing
- `16px` (`--space-lg`): Card padding, grid gaps
- `24px` (`--space-xl`): Page margins, modal padding

### Radius Scale
- `4px`: Badges, timeline clips, progress bars
- `8px`: Standard buttons, input fields, select dropdowns
- `12px`: Cards, panels, video canvas frame
- `16px`: Dialog modals, floating toolbars
- `9999px`: Fully rounded pill buttons, status dots

---

## 4. Components & Interactive States

### 4.1 Buttons
- **Primary Button** (`.btn-primary`): Solid FoodGo orange background (`#F15A24`), white bold text, subtle shadow `0 2px 8px rgba(241, 90, 36, 0.3)`.
- **Secondary / Outline** (`.btn-secondary`): Surface background with subtle border, secondary text, hover elevates surface.
- **Icon Button** (`.btn-icon`): Square 32x32px or 36x36px target, center-aligned SVG icon, clear hover background, explicit `aria-label`.
- **Destructive Button** (`.btn-danger`): Subdued red border and text, deep red on hover.

### 4.2 Form Inputs
- Background: `--bg-surface-elevated`
- Border: `1px solid var(--border-default)`
- Hover: Border transitions to `--border-subtle-hover`
- Focus: `outline: 2px solid var(--accent-primary); outline-offset: 1px`
- Disabled: Opacity 0.5, cursor `not-allowed`

### 4.3 Multi-Track Timeline
- **Track Layout**:
  - `V1: Video / Scenes`: Primary visual scene sequence with proportional clip widths.
  - `V2: App Footage`: Screen recording overlays and capture thumbnails.
  - `A1: Khmer Voice`: Master speech waveform audio track.
  - `A2: Ambient Music`: Background audio pad track.
  - `S1: Subtitles`: Synchronized English subtitle cue blocks.
- **Playhead**: Vertical red/orange scrubber line with timecode tag that updates video playback in real time.
- **Ruler**: Time intervals labeled in `MM:SS` format.

---

## 5. Keyboard Shortcuts System

| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| **`Space`** | Play / Pause video preview | Global |
| **`J` / `←`** | Rewind 5 seconds | Global |
| **`K`** | Pause | Global |
| **`L` / `→`** | Fast Forward 5 seconds | Global |
| **`Ctrl + S` / `Cmd + S`** | Save project metadata | Global |
| **`Ctrl + Z` / `Cmd + Z`** | Undo previous edit | Global |
| **`Ctrl + Y` / `Cmd + Shift + Z`** | Redo edit | Global |
| **`↑` / `↓`** | Select Previous / Next scene | Global |
| **`M`** | Mute / Unmute audio | Global |
| **`F`** | Toggle Fullscreen preview | Canvas |
| **`?`** | Open Keyboard Shortcuts cheatsheet | Global |

---

## 6. Accessibility Standards (WCAG 2.2 AA)

1. **Color Contrast**: All text elements meet or exceed 4.5:1 contrast against their respective backgrounds; large headlines meet 3.0:1.
2. **Non-Color Indicators**: Status badges combine color with explicit text labels (`Passed`, `Blocked`, `Saved`, `Unsaved`) and unique iconography.
3. **Keyboard Focus**: All interactive buttons, inputs, and links feature a high-contrast focus ring (`outline: 2px solid #F15A24`).
4. **ARIA Attributes**: Modal dialogs feature `role="dialog"` with `aria-modal="true"` and `aria-labelledby`. Icon buttons include unambiguous `aria-label` tags.

---

## 7. Responsive Breakpoints

- **Wide Desktop (`>= 1440px`)**: Full 3-column studio layout (Sidebar: 240px, Center Stage/Timeline: 1fr, Inspector: 320px).
- **Standard Desktop (`1024px – 1439px`)**: Streamlined 3-column layout (Sidebar: 200px, Center: 1fr, Inspector: 280px).
- **Small Desktop / Tablet (`768px – 1023px`)**: Collapsible sidebar, inspector converts into bottom tab drawer, full-width canvas.
- **Compact Mobile (`< 768px`)**: Stacked single-column view with bottom navigation bar and drawer panels.
