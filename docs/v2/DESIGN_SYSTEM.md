# FoodGo v2.0 — Enterprise Visual Design System & Component Library

## Overview
The FoodGo v2.0 Design System establishes a unified visual language and component architecture engineered specifically for modern food delivery applications in Cambodia. It merges organic food aesthetics, glassmorphism UI depth, and bilingual Khmer-Latin typography into an accessible, high-performance UI library.

---

## 1. Design Tokens

### 1.1 Spatial Grid & Spacing Scale
All layout margins, paddings, and component dimensions adhere to the 8-point base spatial grid:

| Token | Dimension | Common Use Case |
| :--- | :--- | :--- |
| `space-xxs` | 2px | Micro borders, divider offsets |
| `space-xs` | 4px | Icon-to-text gaps, badge inner padding |
| `space-sm` | 8px | Button inner padding, chip spacing |
| `space-md` | 12px | Compact card padding, form element vertical rhythm |
| `space-lg` | 16px | Standard screen horizontal padding, card content padding |
| `space-xl` | 20px | Hero card padding, modal sheet header spacing |
| `space-2xl` | 24px | Section separation, header bottom margin |
| `space-3xl` | 32px | Dialog margin, empty state illustration margins |
| `space-4xl` | 48px | Top-level screen padding on desktop viewports |

---

### 1.2 Geometry & Corner Radii
Rounded corners reflect organic culinary shapes and tactile modern glassmorphism:

| Token | Radius Value | Component Applicability |
| :--- | :--- | :--- |
| `radius-xs` | 4px | Micronutrient tags, small status chips |
| `radius-sm` | 8px | Form text fields, dietary badges, small buttons |
| `radius-md` | 12px | Standard action buttons, restaurant cards, menu items |
| `radius-lg` | 16px | Food hero cards, modals, checkout drawer |
| `radius-xl` | 24px | Bottom sheet tops, promotional hero banners |
| `radius-pill` | 999px | Search bars, filter pills, counter stepper controls, floating nav |

---

### 1.3 Elevation & Shadows
Depth is achieved through multi-layered ambient occlusions rather than harsh black drop-shadows:

```dart
// Token definitions in GlassTheme
static final BoxShadow shadowSubtle = BoxShadow(
  color: Colors.black.withValues(alpha: 0.04),
  blurRadius: 8,
  offset: const Offset(0, 2),
);

static final BoxShadow shadowCard = BoxShadow(
  color: Colors.black.withValues(alpha: 0.08),
  blurRadius: 16,
  offset: const Offset(0, 4),
);

static final BoxShadow shadowModal = BoxShadow(
  color: Colors.black.withValues(alpha: 0.16),
  blurRadius: 32,
  offset: const Offset(0, 8),
);

static BoxShadow shadowGlow(Color primary) => BoxShadow(
  color: primary.withValues(alpha: 0.25),
  blurRadius: 20,
  spreadRadius: 1,
  offset: const Offset(0, 4),
);
```

---

### 1.4 Typography Hierarchy & Bilingual Font Rules

FoodGo v2.0 employs **Kantumruy Pro** for body and interface labels, **Battambang** for classical accents, **Moul** for cultural ceremonial titles, and **Inter** for clean Latin and numeric data.

| Style Role | Font Family | Size | Weight | Line Height | Khmer Letter Spacing |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Display Large** | Moul / Inter | 28px | Bold | 1.25 | `0.0` (zero tracking) |
| **Heading 1** | Kantumruy Pro / Inter | 22px | Bold (w700) | 1.30 | `0.0` |
| **Heading 2** | Kantumruy Pro / Inter | 18px | SemiBold (w600) | 1.35 | `0.0` |
| **Heading 3** | Kantumruy Pro / Inter | 16px | SemiBold (w600) | 1.40 | `0.0` |
| **Body Large** | Kantumruy Pro / Inter | 15px | Medium (w500) | 1.50 | `0.0` |
| **Body Regular** | Kantumruy Pro / Inter | 13.5px | Regular (w400) | 1.55 | `0.0` |
| **Caption / Badge** | Kantumruy Pro / Inter | 11.5px | Medium (w500) | 1.40 | `0.0` |
| **Numeric Price** | Inter / Kantumruy Pro | 16px | ExtraBold (w800)| 1.20 | `-0.2` (Latin only) |

> [!IMPORTANT]
> **Khmer Typography Invariant:** Never apply negative `letterSpacing` to Khmer text strings. Negative tracking causes subscripts (ជើងអក្សរ) and vowel diacritics (ស្រៈលើ-ក្រោម) to collide and clip visually.

---

### 1.5 Motion & Micro-Interactions

| Interaction Type | Duration | Curve | Behavior / Accessible Fallback |
| :--- | :--- | :--- | :--- |
| **Button Tap Feedback** | 120ms | Curves.easeInOut | Scales to `0.96` with light haptic click |
| **Card Lift on Hover** | 200ms | Curves.easeOutCubic | Elevates `4px` with glow expansion |
| **Modal Sheet Entrance** | 350ms | Curves.fastOutSlowIn | Slide from bottom + fade in |
| **Cart Badge Count Bounce** | 300ms | Curves.elasticOut | Scale from `0.5` to `1.2` then settles at `1.0` |
| **Backdrop Waves & Skins** | 12000ms | Curves.linear | Harmonic sine loop; paused when `reducedMotion == true` |

---

## 2. Reusable Component Specifications

### 2.1 Buttons & Controls
- **`GlassButton`**: High-contrast primary CTA. Accepts `text`, optional `icon`, `loading`, and `onPressed`. Uses dynamic theme primary color with minimum WCAG AA contrast.
- **`GlassSecondaryButton`**: Subdued action button with 1px border and transparent fill.
- **`GlassIconButton`**: Circular pressable container (40x40 or 48x48) with ripple animation and accessible tooltip.
- **`GlassQuantityControl`**: Compact pill with `-` button, animated counter text, and `+` button. Triggers haptic feedback on increment/decrement.

### 2.2 Form Inputs & Verification
- **`GlassTextField`**: Ergonomic text field with glass container backdrop, label text, prefix icon, optional clear button, error text, and keyboard action binding.
- **`ModernOtpInput`**: 6-box individual glass character fields with auto-focus advance, paste listener, and error shake animation.
- **`SearchField`**: Pill-shaped input with search icon, instant clear button, voice search placeholder, and filter bottom sheet trigger.

### 2.3 Food & Restaurant Cards
- **`FeaturedFoodCard`**: Vertical card featuring a 16:9 hero food photograph, organic farm badge, restaurant title, ratings badge, dual pricing (`$4.50 • ៛18,450`), and direct "+ Add" action.
- **`RestaurantRowCard`**: Horizontal kitchen card with brand avatar, estimated delivery time (`15-20 min`), delivery fee badge (`Free Delivery`), and cuisine tags (Khmer, Asian, Organic).
- **`DietaryTagBadge`**: Compact pill chip with color-coded background (Green for Organic/Vegan, Amber for Spicy, Blue for Halal).

### 2.4 Navigation & Drawers
- **`GlassBottomNavigation`**: Floating pill navigation bar with 5 destinations (Home, Explore, Orders, Cart, Profile), unread badge counts, and dynamic active indicator.
- **`FloatingMiniCartBar`**: Slide-up glass bar showing total cart count, primary restaurant title, total amount, and "View Cart" CTA button.

### 2.5 Feedback & State Indicators
- **`VectorEmptyView`**: Centered vector illustration, title, descriptive message, and action button for zero-state scenarios.
- **`AppErrorView`**: Network or server error view with diagnostic error code, friendly explanation, and "Try Again" CTA.
- **`GlassSkeletonLoader`**: Shimmering glass placeholder rectangles for card lists, headers, and profile summaries.
- **`ModernStatusBadge`**: Pill badge indicating order status (Pending = Amber, Cooking = Blue, In Transit = Purple, Delivered = Green, Cancelled = Gray).
