# 🔐 Permissions & RBAC Rules

## 🧠 Role System

* Doctor (full access)
* Assistant (operational access)
* Nurse (limited clinical access)

---

## 🧩 Core Principle

Permissions are **action-based, not screen-based**.

---

## 🚨 Rules

* No hardcoded role checks in UI
* No security logic inside widgets
* All permission checks go through a central system

---

## ⚙️ Enforcement Layers

1. GoRouter route guards
2. Riverpod permission provider
3. Domain-level validation (final safety layer)

---

## 🧠 Permission Model Example

* CAN_CREATE_PATIENT
* CAN_EDIT_VISIT
* CAN_CREATE_INVOICE
* CAN_VIEW_FINANCES

---

## 🧠 Golden Rule

UI must NEVER decide permissions directly
