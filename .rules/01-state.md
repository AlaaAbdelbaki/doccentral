# 🧠 State Management Rules (Riverpod)

## 🧩 Core Principle

Riverpod is the **application state layer**, not UI state.

---

## ✅ Allowed Patterns

- Use @riverpod for all providers
- Use StreamProviders for Drift watches
- Use Notifier / AsyncNotifier for actions

---

## 🚫 Forbidden

- No setState for business logic
- No manual state syncing
- No DB access in widgets
- No mixing UI with repositories

---

## 🗄 Data Rule

- Drift = single source of truth
- UI = pure consumer of state
- State = derived or controlled via Riverpod

---

## ⚡ Streams Rule

Use StreamProviders for:

- patients
- appointments
- visits
- invoices

---

## ⚙️ Async Rule

Use AsyncNotifier for:

- create / update / delete
- login / logout
- transactional workflows
