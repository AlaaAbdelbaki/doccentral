# 🧭 Routing Rules (GoRouter)

## 🧠 Core Principle

Routes represent **workflows, not screens**.

---

## 🧭 Mandatory Route Registry Pattern

### 1. Route Paths (Abstract Class)

```dart
abstract class AppRoutesPath {
  static const login = '/login';
  static const dashboard = '/dashboard';

  static const patients = '/patients';
  static const patientDetails = '/patients/:id';

  static const appointments = '/appointments';
  static const visits = '/visits/:id';
  static const invoices = '/invoices/:id';
}
```

---

### 2. Route Names (Abstract Class)

```dart
abstract class AppRoutesName {
  static const login = 'login';
  static const dashboard = 'dashboard';

  static const patients = 'patients';
  static const patientDetails = 'patientDetails';

  static const appointments = 'appointments';
  static const visits = 'visits';
  static const invoices = 'invoices';
}
```

---

## 🚨 Rules

### ✅ Allowed

- Always use AppRoutesPath for defining routes
- Always use AppRoutesName for navigation
- Always use named navigation for params

---

### ❌ Forbidden

- Hardcoded route strings in UI
- Inline navigation paths
- Duplicating route definitions

---

## 🧭 Navigation Example

```dart
context.goNamed(
  AppRoutesName.patientDetails,
  pathParameters: {'id': patientId},
);
```

---

## 🧠 Why this matters

- Prevents route duplication
- Enables safe refactoring
- Simplifies parameter passing
- Scales cleanly in large systems

```
```
