# 🧠 AI Development Rules – DocCentral

This project uses:

- Flutter (Desktop-first)
- Riverpod (code generation)
- GoRouter (navigation)
- Drift (offline database + streams)
- Clean Architecture (feature-based)
- L10n (EN / FR / AR)

---

## 🧠 Core Principles

- Offline-first is mandatory
- Drift is the single source of truth
- UI never contains business logic
- State is handled only via Riverpod
- Navigation is workflow-driven (not screen-driven)
- All financial data must be immutable once finalized

---

## 🏗 Architecture Flow

UI → Riverpod → Use Cases → Repositories → Drift → Streams → UI
