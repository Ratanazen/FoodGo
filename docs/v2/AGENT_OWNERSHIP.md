# FoodGo v2.0 — Agent Ownership & Responsibility Matrix

**Lead Integration Agent:** Agent A (Lead Architect)  
**Coordination Model:** Coordinated AI Coding Team (Agents A through F)  
**Strict Boundary Invariant:** No agent may edit files assigned exclusively to another agent without architectural consensus.

---

## 1. Ownership & File Boundaries

| Agent Role | Assigned Scope & Responsibilities | Exclusive File / Folder Ownership |
| :--- | :--- | :--- |
| **Agent A — Lead Architect** | Architecture design, cross-agent coordination, master plan, release gates | `docs/v2/*`, `pyproject.toml`, root configuration, `run_all.sh` |
| **Agent B — UI/UX & Visual Design** | Visual design system, vector artwork, typography, themes, components | `foodgo_flutter/lib/core/theme/*`, `foodgo_flutter/assets/*`, `foodgo_flutter/lib/widgets/*` |
| **Agent C — Customer & Driver Features** | Screen layouts, customer discovery, cart, checkout, driver dashboard | `foodgo_flutter/lib/features/*`, `foodgo_flutter/lib/providers/*` |
| **Agent D — Backend & Reliability** | Django APIs, Daphne ASGI, models, migrations, Cloudflare worker | `backend/core/models.py`, `backend/core/views.py`, `backend/config/*`, `worker.js` |
| **Agent E — Payment & Security** | Bakong KHQR, ABA, ACLEDA, SMS OTP, serializer PII redaction | `backend/core/payments/*`, `backend/core/payment_views.py`, `backend/core/phone_views.py`, `backend/core/serializers.py` |
| **Agent F — QA, Review & Automation** | Test suites, CI/CD, Gradle build, static analysis, ADB verification | `foodgo_flutter/test/*`, `backend/core/tests*`, `.github/workflows/*`, `foodgo_flutter/android/*` |

---

## 2. Interface Contracts & Communication Rules

1. **Backend-Frontend API Contract:** Any change to API request/response shapes must be documented in `docs/v2/TASK_PLAN.md` before implementation.
2. **Theme Token Consumption:** All redesigned UI components must consume tokens from `GlassTheme`, `AppPalette`, and `AppTypography`. Hardcoded raw colors or hex codes are strictly prohibited.
3. **Secret Hygiene:** No secret keys, `.env` entries, or keystores may ever be committed, logged, or referenced in source code.
4. **Authoritative Financial Verification:** Frontend clients are strictly prohibited from mutating payment or order fulfillment status directly; all financial state transitions require cryptographic backend validation.
