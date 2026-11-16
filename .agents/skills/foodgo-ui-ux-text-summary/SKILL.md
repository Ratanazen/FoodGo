---
name: foodgo-ui-ux-text-summary
description: Authoritative Design System, Khmer/English Text & Summary Rendering, Accessibility, API Error Sanitization, and UI/UX Quality Guide for FoodGo (Flutter + Django).
---

# FoodGo UI/UX, Text/Summary Rendering & Quality Engineering Skill

Use this skill whenever building, auditing, or upgrading UI screens, text/document viewers, order/payment receipts, summaries, forms, or API error states in FoodGo (`foodgo_flutter/` and `backend/`).

## 1. Typography & Bilingual Khmer/English Text Rendering

- **Centralized Typography (`AppTypography`)**:
  - Always use `AppTypography` (`lib/core/theme/app_typography.dart`) or inherit from `Theme.of(context).textTheme` with explicit fallback families:
    `['Kantumruy Pro', 'Battambang', 'Noto Sans Khmer', 'Inter', 'Roboto']`.
  - Line heights (`height`):
    - Body & document prose: `1.5` – `1.65` (prevents clipping of Khmer stacked subscripts/vowels such as ្ and ុ/ូ).
    - Headings & titles: `1.22` – `1.32`.
    - Metadata, badges & captions: `1.35` – `1.40`.
- **Content Width & Overflow Prevention**:
  - Constrain long-form reading, summaries, receipts, and dialogs to readable widths (`520px` – `860px` via `ConstrainedBox` or `ResponsiveWebContainer`).
  - Wrap dynamic labels in `Flexible` or `Expanded` inside `Row` widgets to prevent `RenderFlex` horizontal overflow.
  - Never silently truncate critical receipt, summary, or payload data; use selectable blocks or expandable structured sections.

## 2. Structured Summary & Plain-TXT Viewer Pattern (`StructuredSummaryViewer`)

When presenting documents, legal policies, receipts, support ticket summaries, or technical payloads (such as EMVCo KHQR strings):
1. **Executive Summary / Key Points**: Display a clear summary callout at the top before long prose or raw data.
2. **View Mode Toggle (`Formatted` vs `Plain TXT`)**:
   - **Formatted View**: Renders structured sections, headings, bullet points, and key-value metadata rows.
   - **Plain TXT View**: Renders a clean, monospace or readable plain-text representation preserving line breaks and indentation inside a `SelectableText` / `SelectionArea`.
3. **Interactive Utilities**:
   - **Find in Text**: Real-time case-insensitive search/filter with match counter and clear button.
   - **Copy TXT / Copy Summary**: Uses `Clipboard.setData` and confirms with a floating `SnackBar`.
4. **Safe Plain-Text Sanitization**:
   - Never render untrusted text as executable HTML. Strip or escape `<script>`, `<iframe>`, `javascript:` URIs, and inline event handlers via `StructuredSummaryViewer.sanitizePlainText`.

## 3. Theme Contrast, Accessibility & Motion (`GlassTheme` & `AppMotion`)

- **Dark & Light Theme Contrast**:
  - Never hardcode `Colors.white` or `Colors.white70` on cards that switch background color in Light mode (`Theme.of(context).brightness == Brightness.light`).
  - Use theme-aware colors:
    - Primary text: `AppTypography.primaryTextColor(brightness)` (or `isDark ? Colors.white : GlassTheme.textInverseDark` `#111827`)
    - Secondary text: `AppTypography.secondaryTextColor(brightness)` (or `isDark ? Colors.white70 : const Color(0xFF4B5563)`)
    - Muted text: `GlassTheme.textMuted` (`#8E95A2`)
    - High-contrast Light Mode status accents: `#15803D` (green), `#B45309` (amber), `#0369A1` (blue), `#7E22CE` (purple) instead of pale tints.
  - Test coverage: enforce every theme-aware screen has a corresponding test in `test/light_mode_contrast_test.dart`.
- **GoogleFonts Runtime Guard for Headless Tests**:
  - In `app_typography.dart`, always guard dynamic font styles: `if (!GoogleFonts.config.allowRuntimeFetching) return null;`.
  - In unit/widget tests (`setUpAll`), disable runtime fetching to prevent offline network failures: `GoogleFonts.config.allowRuntimeFetching = false;`.
- **Reduced Motion**:
  - Respect `AppMotion.shouldReduceMotion(context)` (`MediaQuery.disableAnimations` and `ThemeProvider.reducedMotion`).

## 4. State Management & Concurrent Requests (`Provider` Pattern)

- **Atomic Request Tracking (Preventing premature `_isLoading = false` race conditions)**:
  - Never use a simple boolean `_isLoading = false` when multiple asynchronous requests can be triggered concurrently or in `Future.wait([...])`.
  - Use an active request counter:
    ```dart
    int _activeRequests = 0;
    bool get isLoading => _activeRequests > 0;

    Future<T> _trackRequest<T>(Future<T> Function() action) async {
      _activeRequests++;
      notifyListeners();
      try {
        return await action();
      } finally {
        _activeRequests = math.max(0, _activeRequests - 1);
        notifyListeners();
      }
    }
    ```

## 5. Form Validation & Human-Readable API Error Formatting

- **Never Display Raw `DioException` Boilerplate**:
  - Always format errors through `ApiService.formatError(error)` so HTTP 400/401/403/500 responses extract field-level DRF messages (e.g., `"Image URL: Enter a valid URL."` or `"Price must be greater than zero."`) instead of printing `DioException [bad response]: This exception was thrown because...`.
- **Resilient Optional URL Fields (`ApiService.normalizeOptionalUrl`)**:
  - When a form includes an optional URL input (such as `Image URL` in `Add Food Item`), treat empty strings or placeholder words (`"no"`, `"none"`, `"n/a"`, `"null"`, `"-"`) as `""` (no image) and auto-prefix `https://` for bare domains (`unsplash.com/...`) so users are never blocked by a 400 validation error when adding items without a photo.
- **Modal & Dialog `TextEditingController` Lifecycle (Preventing `_dependents.isEmpty`)**:
  - Never dispose `TextEditingController`s immediately inside `showModalBottomSheet(...).whenComplete(...)` or `showDialog(...).whenComplete(...)` when the modal reads `MediaQuery.of(ctx).viewInsets.bottom` (soft keyboard insets), because `whenComplete` fires as soon as `Navigator.pop()` is called while the 250ms reverse exit animation is still rebuilding.
  - Instead, extract complex bottom sheets (such as `AddFoodItemBottomSheet`) into a dedicated `StatefulWidget` and dispose controllers strictly in `State.dispose()` after the route unmounts.

## 6. Web QA Automation & Browser Testing (Playwright / DevTools)

- **Flutter Web CanvasKit / HTML Element Stability**:
  - Standard Playwright `locator.click()` may hang waiting for actionability/stability when continuous animations (`flutter_animate`, particle effects) are active.
  - **Resolution**:
    1. Activate the semantics tree: `await page.evaluate("document.querySelector('flt-semantics-placeholder')?.click()");`.
    2. Retrieve element bounding box with `await locator.bounding_box()`.
    3. Perform direct coordinates click: `await page.mouse.click(box['x'] + box['width']/2, box['y'] + box['height']/2)` or pass `force=True`.

## 7. Verification Checklist

1. `flutter analyze --no-fatal-infos` must report **0 issues**.
2. `flutter test` must pass all unit and widget tests (including Khmer/English Unicode, long text, empty states, search-in-text, HTML sanitization, light-mode contrast, and optional URL normalization).
3. `backend/venv/bin/python backend/manage.py test` must pass all Django backend tests.
