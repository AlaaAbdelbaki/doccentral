# 🧠 Domain Layer Rules

## 🧩 Core Purpose

The domain layer defines **business logic independent of Flutter and DB**.

---

## 📦 Contains

* Entities
* Repository interfaces
* Services (business logic — maps to the "Service" layer in the architecture flow)

---

## 🚨 Forbidden

* No Flutter imports
* No Riverpod imports
* No Drift imports

---

## 🧠 Business Logic Rule

All business logic MUST live in:

* Services (domain layer)

NOT in UI, providers, or data layer

---

## 🧾 Entities Rule

Entities must be:

* Immutable
* Pure Dart objects
* No serialization logic

---

## 🏥 Clinic Rule

Core workflow logic must follow:

Appointment → Visit → Treatment → Invoice
