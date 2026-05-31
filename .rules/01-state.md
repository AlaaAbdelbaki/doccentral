# 🧠 State Management Rules (Riverpod)

## 🧩 Core Principle

Riverpod is the **application state layer**, not UI state.

---

## ✅ Allowed Patterns

All providers MUST use `@riverpod` code generation (Riverpod 3.x.x). Two forms only:

- **Function-based** (`@riverpod` on a function) — for immutable, read-only, or derived state
- **Class-based** (`@riverpod` on a class extending `_$ClassName`) — for mutable state with create/update/delete actions

```dart
// Immutable — function-based
@riverpod
Stream<List<Patient>> patients(Ref ref) {
  return ref.watch(patientRepositoryProvider).watchAll();
}

// Mutable — class-based
@riverpod
class PatientController extends _$PatientController {
  @override
  FutureOr<void> build() {}

  Future<void> create(Patient patient) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientRepositoryProvider).create(patient),
    );
  }
}
```

---

## 🚫 Forbidden

- `FutureProvider` — use a function-based `@riverpod` provider instead
- `StreamProvider` — use a function-based `@riverpod` provider instead
- `AsyncNotifier` / `AsyncNotifierProvider` — use a class-based `@riverpod` provider instead
- `setState` for business logic
- No manual state syncing
- No DB access in widgets
- No mixing UI with repositories

---

## 🗄 Data Rule

- Drift = single source of truth
- UI = pure consumer of state
- State = derived or controlled via Riverpod providers
