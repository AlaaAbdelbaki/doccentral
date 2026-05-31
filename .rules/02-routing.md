# 🧭 Routing Rules (GoRouter)

## 🧠 Core Principle

Routes represent **workflows, not screens**.

---

## 🧭 Mandatory Route Registry Pattern

### 1. Route Paths (Abstract Class)

Sub-route paths must **not** repeat the parent segment — GoRouter composes them automatically.

```dart
abstract class AppRoutesPath {
  static const login = '/login';
  static const dashboard = '/dashboard';

  static const patients = '/patients';
  static const patientDetails = ':id';      // ✅ NOT '/patients/:id'

  static const appointments = '/appointments';
  static const visits = '/visits';
  static const visitDetails = ':id';        // ✅ NOT '/visits/:id'

  static const invoices = '/invoices';
  static const invoiceDetails = ':id';      // ✅ NOT '/invoices/:id'
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

## 🧭 Sub-Route Nesting Rule

Sub-routes MUST be declared in the `routes` property of their parent `GoRoute`. The path must **only** contain the new segment — never the full path.

```dart
GoRoute(
  path: AppRoutesPath.patients,
  name: AppRoutesName.patients,
  builder: (_, __) => const PatientsPage(),
  routes: [
    GoRoute(
      path: AppRoutesPath.patientDetails,  // ':id', not '/patients/:id'
      name: AppRoutesName.patientDetails,
      builder: (_, state) => PatientDetailsPage(id: state.pathParameters['id']!),
    ),
  ],
),
```

---

## 🚨 Rules

### ✅ Allowed

- Always use AppRoutesPath for defining routes
- Always use AppRoutesName for navigation
- Always use named navigation for params
- Sub-routes nested in parent `routes: [...]` property
- Sub-route paths contain only the new segment (no parent prefix)

---

### ❌ Forbidden

- Hardcoded route strings in UI
- Inline navigation paths
- Duplicating route definitions
- Sub-route paths that repeat the parent path (e.g., `/patients/:id` as a child of `/patients`)
- Flat route list for routes that have a parent/child relationship

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
