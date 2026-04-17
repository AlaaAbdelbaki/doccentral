# 🗄 Data Layer Rules (Drift)

## 🧠 Core Principle

Drift is the **single source of truth** for all persisted data.

---

## 🏗 Structure Rules

* Every table must have a UUID primary key
* Every mutable table must include timestamps

---

## ⚡ Streams Rule

* Use `.watch()` for all list queries
* Prefer reactive streams over one-time fetches

---

## 🚨 Forbidden

* No direct DB access in UI
* No business logic inside DAOs
* No computed financial logic inside DB layer

---

## 🧩 Allowed Responsibilities

DAOs may only:

* Insert data
* Update data
* Delete data
* Expose streams

---

## 🧠 Architecture Rule

UI → Riverpod → Repository → Drift → Stream → UI
