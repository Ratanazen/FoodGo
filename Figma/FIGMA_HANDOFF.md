# FoodGo v2.0 — Figma Developer Handoff Document

**Design Tool**: Figma  
**Design System**: Emerald Glass Design System (EGDS)  
**Code Mapping**: Flutter 3.13 Widgets  

---

## 1. Component to Code Mapping

| Figma Component Name | Flutter Source Code Widget | File Location |
|---|---|---|
| `FG / Button / Primary` | `GlassButton` | `lib/widgets/glass/glass_widgets.dart` |
| `FG / Card / FoodGrid` | `GlassFoodCard` | `lib/widgets/glass/glass_food_card.dart` |
| `FG / Card / GlassCard` | `GlassCard` | `lib/widgets/glass/glass_widgets.dart` |
| `FG / Navigation / BottomBar` | `GlassBottomNavigation` | `lib/widgets/glass/glass_bottom_navigation.dart` |
| `FG / Modal / FoodCustomizer` | `GlassFoodCustomizerModal` | `lib/widgets/glass/glass_food_customizer_modal.dart` |
| `FG / Modal / KHQRPay` | `GlassQrPayModal` | `lib/widgets/glass/glass_qr_pay_modal.dart` |
| `FG / Portal / DriverDashboard` | `DriverDashboardScreen` | `lib/features/driver/presentation/driver_dashboard_screen.dart` |
| `FG / Portal / AdminKDS` | `AdminDashboardScreen` | `lib/features/admin/presentation/admin_dashboard_screen.dart` |

---

## 2. Figma MCP Connection Guidelines

- **MCP Status in Current Environment**: Disconnected (Plugin not installed).
- **Marketplace Plugin**: `antigravity-plugins-partners/plugin/figma`
- **Supported Endpoint**: `https://mcp.figma.com/mcp`
- **Action for User**: To sync live design files and export Figma tokens via Code Connect, install the Figma plugin from the Agent Marketplace card and sign in with your Figma account.
