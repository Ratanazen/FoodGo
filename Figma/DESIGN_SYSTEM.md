# FoodGo v2.0 — Emerald Glass Design System (EGDS)

**Version**: 2.0.0  
**Design Foundations**: Glassmorphism, Material 3, Dynamic Theming, and Cambodian Localization  

---

## 1. Color Palette Tokens

### 1.1 Brand & Semantic Colors
- **Emerald Primary (`#10B981` / `#059669`)**: Core identity color representing freshness, quality, and prompt delivery.
- **Angkor Gold (`#F59E0B` / `#D97706`)**: Accent color for ratings, special promotions, and culinary highlights.
- **Bakong Crimson (`#E1232E`)**: Official NBC Bakong / KHQR payment standard crimson badge.
- **Canvas Light (`#F8FAFC`)**: Clean, crisp background for light mode.
- **Canvas Dark (`#0A110D`)**: Deep forest obsidian background for OLED-friendly dark mode.

### 1.2 Glass Surface Tokens
- **Glass Card Fill (Light)**: `rgba(255, 255, 255, 0.78)` with `backdrop-filter: blur(18px)`.
- **Glass Card Fill (Dark)**: `rgba(22, 34, 27, 0.78)` with `backdrop-filter: blur(18px)`.
- **Glass Border Highlight**: 1.2px solid `rgba(255, 255, 255, 0.65)` (Light) / `rgba(255, 255, 255, 0.12)` (Dark).

---

## 2. Typography & Khmer Alignment

- **Latin Font Family**: Plus Jakarta Sans / Inter / Roboto.
- **Khmer Font Family**: Kantumruy Pro / Siemreap / Battambang.
- **Hierarchy**:
  - `Display Large`: 32px / Bold (900)
  - `Headline Medium`: 24px / Bold (800)
  - `Title Medium`: 18px / Semi-Bold (700)
  - `Body Regular`: 15px / Regular (400) & Medium (500)
  - `Caption`: 12px / Medium (500)
  - `Badge / Micro`: 10.5px / Heavy (800)

---

## 3. Component Geometry & Elevation
- **Border Radii**:
  - Small / Badges: `10px`
  - Cards & Buttons: `16px` – `20px`
  - Hero Cards: `28px`
  - Bottom Sheets: `32px`
- **Glow Shadow**: `BoxShadow(color: Color(0x4710B981), blurRadius: 22, offset: Offset(0, 8))`
