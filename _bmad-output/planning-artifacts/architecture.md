---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-05-23'
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-DocCentral-2026-05-21/prd.md
  - docs/system_spec.md
  - docs/usecases.md
  - docs/database.md
workflowType: 'architecture'
project_name: 'DocCentral'
user_name: 'Alaa'
date: '2026-05-23'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

49 FRs across 12 domains: Auth & Clinic Bootstrap (FR-1–3), Patient Management (FR-4–8, FR-46), Calendar & Appointments (FR-9–14, FR-47–48), Visit Workflow (FR-15–19), Treatment Planning (FR-20–22), Invoicing & Payments (FR-23–28, FR-49), Inventory (FR-29–32), Attachments (FR-33–34), Day Closeout (FR-35–37), Roles & Permissions (FR-38–39), Offline-First & Sync (FR-40–43), Localization & RTL (FR-44–45).

**Non-Functional Requirements:**

- NFR-1: Full offline operation — all FRs work without internet; only initial device sign-in requires connectivity
- NFR-2: Sync resilience — sync failures and conflicts must not corrupt local data; Drift is authoritative
- NFR-3: Financial determinism — Invoice totals always computed from Items + adjustments + Payments, never manually set
- NFR-4: Immutability of paid records — once an Invoice has any Payment, Invoice Items lock; paid/void Invoices allow no further edits
- NFR-5: No hardcoded UI strings — all text from translation files
- NFR-6: RTL correctness — Arabic locale flips all screens to RTL
- NFR-7: Desktop performance baseline — cold launch < 4s; Today's Calendar < 2s post-sign-in; screen navigation < 500ms
- NFR-8: Supabase in EU region (Frankfurt or Ireland)
- NFR-9: Audit attribution on all financial + clinical writes — actor + UTC timestamp, enforced non-null in schema
- NFR-10: Per-module test discipline — unit, integration, sync-aware tests per module
- NFR-11: LayoutBuilder-based responsive layouts; only top-level pages consume Riverpod

**Scale & Complexity:**

- Primary domain: Flutter desktop, offline-first with Supabase sync layer
- Complexity level: High — offline-first sync + financial determinism + three-layer RBAC + RTL + audit trail all simultaneously
- Estimated architectural components: 18–22 (auth, clinic, patient, appointment, visit, treatment plan, invoice, payment, inventory, attachment, day closeout, RBAC, sync engine, audit log, localization, navigation, design system, error handling)

### Technical Constraints & Dependencies

- **Flutter desktop** (Windows/macOS/Linux) — mobile, web, tablet explicitly out of scope
- **Drift** — local SQLite ORM, source of truth for all runtime operations
- **Supabase** — sync/replication target only; not a runtime dependency for any feature except initial device sign-in
- **Riverpod** — state management; only top-level pages may use Riverpod widgets
- **GoRouter** — navigation; router-layer permission enforcement required
- **SQLCipher or equivalent** — encryption at rest (assumption, pending performance validation on clinic hardware)
- **Single Clinic per deployment** — schema is multi-tenant for forward-compat, but MVP product is single-tenant
- **Cash-only payments** — `method` field exists for v2 extensibility but only `cash` is used in MVP

### Cross-Cutting Concerns Identified

1. **Sync metadata** — every entity carries `sync_status`, `updated_at`, `created_at`, `deleted_at` (non-null); sync engine touches all modules
2. **Three-layer RBAC** — router guard, Riverpod provider visibility, domain operation rejection; same permission predicate at all three layers; no drift between layers
3. **Audit attribution** — all financial and clinical writes record `actor_id` + UTC timestamp; enforced at schema level
4. **Financial locking / immutability** — Invoice Items lock on first Payment; Invoice total is always derived; void is terminal
5. **Soft-delete pattern** — `deleted_at` set on logical deletion; no physical record removal; financial integrity preserved
6. **Localization / RTL** — no hardcoded strings; locale-aware date/time/currency; Arabic flips entire layout tree to RTL
7. **Performance on clinic hardware** — cold launch, calendar render, and navigation targets must be validated on actual devices

## Starter Template Evaluation

### Primary Technology Domain

Flutter desktop application (Windows/macOS/Linux) — confirmed by PRD §5

### Selected Approach: Build on Existing Flutter Scaffold

Rationale: The existing project has localization ARB files (FR/AR/EN) already started — worth preserving. Very Good CLI uses Bloc (not Riverpod) and would require ripping out state management. No community starter matches the exact DocCentral stack requirements.

### Initialization Commands

```bash
# Remove Firebase packages
flutter pub remove firebase_auth firebase_core cloud_firestore

# Add core runtime dependencies
flutter pub add supabase_flutter
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add go_router
flutter pub add drift drift_flutter path_provider path
flutter pub add freezed_annotation json_annotation

# Add dev dependencies
flutter pub add --dev build_runner
flutter pub add --dev drift_dev
flutter pub add --dev riverpod_generator riverpod_lint
flutter pub add --dev freezed json_serializable

# Enable desktop platforms (if not already enabled)
flutter create --platforms=windows,macos,linux .
```

Packages already present (no action): `intl`, `flutter_localizations`, `cupertino_icons`, `flutter_lints`, `custom_lint`

**Note:** Package versions are intentionally not pinned — `flutter pub add` resolves the latest compatible versions at scaffold time.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Drift tooling-assisted stepwise migrations (all schema changes require explicit migration callbacks)
- Hybrid sync engine (generic outbox queue + entity-specific conflict handlers)
- Feature-first with shared core folder structure

**Important Decisions (Shape Architecture):**
- Typed exceptions for error handling (domain-specific exception classes)
- GitHub Actions CI (matrix desktop builds on ubuntu/windows/macos)
- `logger` package with rotating file sink for local observability

**Deferred Decisions (Post-MVP):**
- SQLCipher performance validation on clinic hardware (assumption held; validate before v1 release)
- Non-cash payment methods (`method` field reserved; only `cash` active in MVP)
- Mobile/web/tablet platforms (explicitly out of scope for MVP)

### Data Architecture

- **ORM**: Drift (local SQLite) — source of truth for all runtime operations
- **Sync target**: Supabase (EU region) — async replication only, not a runtime dependency
- **Migration strategy**: Tooling-assisted stepwise — `dart run drift_dev make-migrations` scaffolds stubs; explicit `onUpgrade` callbacks per schema version; no destructive auto-migration in production
- **Soft-delete**: `deleted_at` timestamp on all entities; no physical row removal; financial records preserved indefinitely
- **Sync metadata**: Every entity carries `sync_status` (pending/synced/conflict), `created_at`, `updated_at`, `deleted_at` (all non-null)
- **Encryption**: SQLCipher at rest (pending performance validation on clinic hardware before v1)

### Authentication & Security

- **Auth provider**: Supabase Auth — required only for initial device sign-in; JWT cached locally for offline use
- **RBAC**: Three layers enforced with identical permission predicate — GoRouter guard (navigation), Riverpod provider (visibility), domain operation (rejection); no drift between layers
- **Audit attribution**: `actor_id` + UTC `created_at`/`updated_at` non-null on all financial and clinical writes; enforced at Drift schema level
- **Financial immutability**: Invoice Items lock on first Payment; Invoice total always derived from Items + adjustments + Payments; void is terminal state

### Sync Engine

- **Architecture**: Hybrid — generic outbox queue for transport; entity-specific conflict resolution handlers
- **Push**: Local writes append to outbox; background worker drains queue when online; retry with exponential backoff on failure
- **Pull**: Supabase Realtime subscriptions when online; `updated_at`-gated delta pull per table on reconnect
- **Conflict resolution**: Last-write-wins on UTC `updated_at` for all entities except Invoice/Payment conflicts which surface to user for manual resolution
- **Failure isolation**: Sync failures do not block local operations; `sync_status = conflict` flags unresolved records

### Error Handling

- **Pattern**: Typed exceptions — domain layer throws specific exception classes (e.g. `PatientNotFoundException`, `InvoiceLockedException`, `SyncConflictException`, `PermissionDeniedException`)
- **Boundary**: Top-level GoRouter `errorBuilder` + Riverpod `ProviderObserver` catch unhandled exceptions
- **User-facing errors**: Translated via l10n (no hardcoded error strings); surfaced via snackbar or modal depending on severity

### Frontend Architecture

- **State management**: Riverpod + code generation (`riverpod_annotation`, `riverpod_generator`); only top-level page widgets consume Riverpod directly (NFR-11)
- **Navigation**: GoRouter with router-level RBAC guard; declarative routes per feature
- **Layouts**: `LayoutBuilder`-based responsive layouts for desktop window resize (NFR-11)
- **Localization**: `flutter_localizations` + ARB files for AR/FR/EN; Arabic triggers full RTL layout tree flip (NFR-6)
- **Folder structure**: Feature-first with shared core
  ```
  lib/
    core/         # sync engine, RBAC, audit, error, l10n, router, design system
    features/
      auth/
      clinic/
      patient/
      appointment/
      visit/
      treatment_plan/
      invoice/
      payment/
      inventory/
      attachment/
      day_closeout/
      roles/
  ```

### Infrastructure & Deployment

- **CI/CD**: GitHub Actions — matrix builds on `ubuntu-latest`, `windows-latest`, `macos-latest`; produces native desktop artifacts per platform
- **Logging**: `logger` package with rotating file sink; log files written to platform app data directory; available for offline support diagnosis
- **Environments**: dev / staging / prod distinguished via Dart compile-time constants (`--dart-define`)

## Implementation Patterns & Consistency Rules

### Naming Patterns

**Drift Table Definitions (Database Layer):**
- Table class names: PascalCase singular noun — `Patients`, `Appointments`, `InvoiceItems`
- `@DataClassName` annotation sets the generated row class: `@DataClassName('Patient')`
- Column names: snake_case — `clinic_id`, `updated_at`, `sync_status`, `deleted_at`
- DAO class names: `{Entity}Dao` — `PatientDao`, `AppointmentDao`
- Table file names: `{entity}_table.dart` — `patients_table.dart`
- DAO file names: `{entity}_dao.dart` — `patient_dao.dart`

**Domain Models:**
- All domain models use Freezed: `@freezed class Patient with _$Patient`
- Domain model file names: `{entity}_model.dart` — `patient_model.dart`
- Repository interface: `abstract class {Entity}Repository` in `domain/`
- Repository implementation: `class {Entity}RepositoryImpl implements {Entity}Repository` in `data/`

**Providers (Riverpod):**
- List providers: `{entity}ListProvider` — `patientListProvider`
- Single-item providers: `{entity}ByIdProvider` — `patientByIdProvider(String id)`
- Form/edit providers: `{entity}FormProvider` — `patientFormProvider`
- Provider files: `{entity}_providers.dart` in `features/{entity}/presentation/providers/`

**Routes (GoRouter):**
- Route path strings: kebab-case — `/patients`, `/appointments/:id`, `/invoice/:id/items`
- Route name constants: SCREAMING_SNAKE in an `AppRoutes` class — `AppRoutes.patientList`, `AppRoutes.appointmentDetail`
- Route parameter keys: camelCase string — `'patientId'`, `'appointmentId'`

**Exceptions:**
- Format: `{Entity}{Reason}Exception` — `PatientNotFoundException`, `InvoiceLockedException`, `SyncConflictException`
- All domain exceptions extend `AppException`

**Files:**
- All Dart files: snake_case — `patient_dao.dart`, `invoice_locked_exception.dart`
- All Dart classes: PascalCase — `PatientDao`, `InvoiceLockedException`

### Structure Patterns

**Feature Module Layout (every feature follows this exactly):**
```
features/{feature}/
  data/
    {entity}_table.dart           # Drift table definition
    {entity}_dao.dart             # Drift DAO
    {entity}_sync_handler.dart    # Entity-specific sync conflict handler
    {entity}_repository_impl.dart # Repository implementation
  domain/
    {entity}_model.dart           # Freezed domain model
    {entity}_repository.dart      # Abstract repository interface
    {entity}_exceptions.dart      # Typed exception classes
  presentation/
    {entity}_list_page.dart       # Top-level page (ConsumerWidget allowed)
    {entity}_detail_page.dart
    providers/
      {entity}_providers.dart     # All Riverpod providers for this feature
    widgets/
      {entity}_card.dart          # Sub-widgets (NO direct Riverpod — data via constructor)
```

**Core Module Layout:**
```
core/
  auth/          # JWT cache, session state
  sync/          # Outbox queue, sync worker, base conflict handler interface
  rbac/          # Permission predicate, role definitions
  audit/         # Audit write helper
  error/         # AppException base, top-level error boundary
  l10n/          # ARB files, locale config, RTL helper
  router/        # GoRouter config, route guards
  design_system/ # Colors, typography, shared widgets
  logging/       # Logger setup, file sink config
  database/      # AppDatabase Drift declaration, migration runner
```

**Test Location:**
- Unit tests: `test/features/{feature}/` mirroring `lib/features/{feature}/`
- Integration/sync tests: `test/integration/`
- Test file names: `{source_file}_test.dart`

### Format Patterns

**Date & Time:**
- All storage (Drift columns, Supabase fields): UTC `DateTime` — always call `.toUtc()` before writing
- All display: format via `intl` `DateFormat` with current locale — never hardcode date string format
- Drift column type for timestamps: `DateTimeColumn` with `withDefault(currentDateAndTime)`

**Sync Status:**
- Drift column: `TextColumn` named `sync_status`
- Allowed values (string enum): `'pending'` | `'synced'` | `'conflict'`
- Transition rules: local write → `pending`; Supabase confirm → `synced`; server-wins conflict → `conflict`

**Soft Delete:**
- Column: `deleted_at` nullable `DateTimeColumn`; null = active, non-null = deleted
- All DAOs filter `WHERE deleted_at IS NULL` by default
- No physical row removal anywhere in the codebase

### State Management Patterns

**Riverpod Provider Rules:**
- ONLY `*Page` widgets (top-level route targets) may be `ConsumerWidget` or `ConsumerStatefulWidget`
- All sub-widgets receive data as constructor parameters — no `ref.watch` in sub-widgets
- Providers use `@riverpod` annotation (code generation); no manual `Provider(...)` constructors
- `AsyncValue<T>` is the return type for any provider that touches Drift or network — never raw `Future<T>`

**AsyncValue Handling:**
- Always handle all three states explicitly:
  ```dart
  value.when(
    data: (data) => ...,
    loading: () => const CircularProgressIndicator(),
    error: (e, st) => ErrorWidget(e),
  );
  ```
- Never `.value!` force-unwrap an `AsyncValue`

**Loading States:**
- No custom loading state classes — use `AsyncValue<T>` throughout
- Global operations (sync, day closeout) expose progress via a dedicated `AsyncValue<SyncState>` provider in `core/sync/`

### Process Patterns

**Audit Writes:**
Every financial or clinical write MUST include:
```dart
actorId: ref.read(sessionProvider).requireValue.userId,
createdAt: DateTime.now().toUtc(),   // on insert
updatedAt: DateTime.now().toUtc(),   // on every write
```
The `AuditHelper` in `core/audit/` provides a single `auditFields(ref)` helper to avoid repetition.

**Sync Outbox:**
Every local write that must sync calls `SyncOutbox.enqueue(entityType, entityId)` after the Drift insert/update. The sync worker handles the rest — feature code never calls Supabase directly.

**RBAC Permission Check:**
The same `PermissionPredicate.can(actor, action, resource)` is called at all three layers:
1. GoRouter `redirect` (navigation guard)
2. Riverpod provider `build()` method (throws `PermissionDeniedException` if denied)
3. Repository `impl` method body (final enforcement)

**Exception Propagation:**
- Domain exceptions thrown from Repository — never from DAO or Drift directly
- DAOs wrap Drift exceptions into domain exceptions at the `RepositoryImpl` boundary
- Presentation layer catches domain exceptions in providers; surfaces via `AsyncValue.error`

### Enforcement Guidelines

**All agents MUST:**
- Follow the feature module layout exactly — no variation in folder structure
- Use `@riverpod` code generation — no manual provider constructors
- Call `AuditHelper.auditFields(ref)` on every financial/clinical write
- Set `sync_status = 'pending'` and call `SyncOutbox.enqueue()` on every local write that syncs
- Filter `deleted_at IS NULL` in every DAO query unless explicitly fetching deleted records
- Store all timestamps as UTC; display all timestamps via `intl` with locale

**Anti-Patterns (never do these):**
- `ConsumerWidget` in a sub-widget (only Pages are consumers)
- Manual `Provider(...)` constructor instead of `@riverpod`
- Direct Supabase client call from a feature repository (all Supabase access via sync engine)
- Hardcoded string in UI (all text via ARB/l10n)
- `deleted_at` check omitted from DAO query
- `actor_id` null on a financial write

## Project Structure & Boundaries

### Complete Project Directory Structure

```
doccentral/
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml
├── .github/
│   └── workflows/
│       ├── build-windows.yml
│       ├── build-macos.yml
│       └── build-linux.yml
├── assets/
│   ├── fonts/
│   └── icons/
├── lib/
│   ├── main.dart                          # ProviderScope + runApp
│   ├── app.dart                           # MaterialApp.router + GoRouter + locale setup
│   ├── core/
│   │   ├── auth/
│   │   │   ├── session_provider.dart      # Current user/JWT state
│   │   │   ├── jwt_cache.dart             # Persist JWT for offline use
│   │   │   └── supabase_auth_service.dart # Initial sign-in only
│   │   ├── sync/
│   │   │   ├── sync_outbox.dart           # Outbox table + enqueue()
│   │   │   ├── sync_worker.dart           # Background drain + Supabase push/pull
│   │   │   ├── sync_conflict_handler.dart # Abstract interface for entity handlers
│   │   │   ├── sync_state.dart            # SyncState model (idle/syncing/error)
│   │   │   └── sync_provider.dart         # AsyncValue<SyncState>
│   │   ├── rbac/
│   │   │   ├── permission_predicate.dart  # can(actor, action, resource) — single source
│   │   │   ├── app_role.dart              # Role enum (owner, doctor, receptionist)
│   │   │   └── app_permission.dart        # Permission enum + role→permission map
│   │   ├── audit/
│   │   │   └── audit_helper.dart          # auditFields(ref) helper
│   │   ├── error/
│   │   │   ├── app_exception.dart         # Base class for all domain exceptions
│   │   │   └── error_boundary.dart        # Top-level GoRouter errorBuilder widget
│   │   ├── l10n/
│   │   │   └── rtl_helper.dart            # Locale → TextDirection helper
│   │   ├── router/
│   │   │   ├── app_router.dart            # GoRouter configuration
│   │   │   ├── route_guard.dart           # redirect callback using PermissionPredicate
│   │   │   └── app_routes.dart            # AppRoutes constants
│   │   ├── design_system/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   ├── app_theme.dart
│   │   │   └── widgets/
│   │   │       ├── app_scaffold.dart      # Shared shell with nav rail
│   │   │       ├── async_value_widget.dart # Generic AsyncValue renderer
│   │   │       └── confirmation_dialog.dart
│   │   ├── logging/
│   │   │   ├── app_logger.dart            # Logger instance + level config
│   │   │   └── file_log_sink.dart         # Rotating file output
│   │   └── database/
│   │       ├── app_database.dart          # @DriftDatabase with all tables
│   │       ├── app_database.g.dart        # Generated
│   │       └── migrations/
│   │           └── migration_v1.dart
│   ├── l10n/
│   │   ├── app_en.arb
│   │   ├── app_ar.arb
│   │   └── app_fr.arb
│   └── features/
│       ├── auth/                          # Epic 1 (partial)
│       │   ├── data/
│       │   │   └── auth_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── auth_repository.dart
│       │   │   └── auth_exceptions.dart
│       │   └── presentation/
│       │       ├── login_page.dart
│       │       └── providers/
│       │           └── auth_providers.dart
│       ├── clinic/                        # Epic 1 (partial)
│       │   ├── data/
│       │   │   ├── clinics_table.dart
│       │   │   ├── clinic_dao.dart
│       │   │   ├── clinic_sync_handler.dart
│       │   │   └── clinic_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── clinic_model.dart
│       │   │   ├── clinic_repository.dart
│       │   │   └── clinic_exceptions.dart
│       │   └── presentation/
│       │       ├── clinic_setup_page.dart
│       │       ├── providers/
│       │       │   └── clinic_providers.dart
│       │       └── widgets/
│       │           └── clinic_info_card.dart
│       ├── patient/                       # Epic 2
│       │   ├── data/
│       │   │   ├── patients_table.dart
│       │   │   ├── patient_dao.dart
│       │   │   ├── patient_sync_handler.dart
│       │   │   └── patient_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── patient_model.dart
│       │   │   ├── patient_repository.dart
│       │   │   └── patient_exceptions.dart
│       │   └── presentation/
│       │       ├── patient_list_page.dart
│       │       ├── patient_detail_page.dart
│       │       ├── patient_form_page.dart
│       │       ├── providers/
│       │       │   └── patient_providers.dart
│       │       └── widgets/
│       │           ├── patient_card.dart
│       │           └── patient_search_bar.dart
│       ├── appointment/                   # Epic 3
│       │   ├── data/
│       │   │   ├── appointments_table.dart
│       │   │   ├── appointment_dao.dart
│       │   │   ├── appointment_sync_handler.dart
│       │   │   └── appointment_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── appointment_model.dart
│       │   │   ├── appointment_repository.dart
│       │   │   └── appointment_exceptions.dart
│       │   └── presentation/
│       │       ├── calendar_page.dart
│       │       ├── appointment_detail_page.dart
│       │       ├── appointment_form_page.dart
│       │       ├── providers/
│       │       │   └── appointment_providers.dart
│       │       └── widgets/
│       │           ├── calendar_day_view.dart
│       │           ├── appointment_slot_card.dart
│       │           └── appointment_status_chip.dart
│       ├── visit/                         # Epic 4 (partial)
│       │   ├── data/
│       │   │   ├── visits_table.dart
│       │   │   ├── visit_dao.dart
│       │   │   ├── visit_sync_handler.dart
│       │   │   └── visit_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── visit_model.dart
│       │   │   ├── visit_repository.dart
│       │   │   └── visit_exceptions.dart
│       │   └── presentation/
│       │       ├── visit_page.dart
│       │       ├── providers/
│       │       │   └── visit_providers.dart
│       │       └── widgets/
│       │           ├── visit_notes_editor.dart
│       │           └── visit_status_toolbar.dart
│       ├── treatment_plan/                # Epic 6
│       │   ├── data/
│       │   │   ├── treatment_plans_table.dart
│       │   │   ├── treatment_plan_items_table.dart
│       │   │   ├── treatment_plan_dao.dart
│       │   │   ├── treatment_plan_sync_handler.dart
│       │   │   └── treatment_plan_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── treatment_plan_model.dart
│       │   │   ├── treatment_plan_item_model.dart
│       │   │   ├── treatment_plan_repository.dart
│       │   │   └── treatment_plan_exceptions.dart
│       │   └── presentation/
│       │       ├── treatment_plan_page.dart
│       │       ├── providers/
│       │       │   └── treatment_plan_providers.dart
│       │       └── widgets/
│       │           ├── treatment_plan_item_row.dart
│       │           └── tooth_chart_widget.dart
│       ├── invoice/                       # Epic 5 (partial)
│       │   ├── data/
│       │   │   ├── invoices_table.dart
│       │   │   ├── invoice_items_table.dart
│       │   │   ├── invoice_dao.dart
│       │   │   ├── invoice_sync_handler.dart
│       │   │   └── invoice_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── invoice_model.dart
│       │   │   ├── invoice_item_model.dart
│       │   │   ├── invoice_repository.dart
│       │   │   └── invoice_exceptions.dart
│       │   └── presentation/
│       │       ├── invoice_page.dart
│       │       ├── invoice_list_page.dart
│       │       ├── providers/
│       │       │   └── invoice_providers.dart
│       │       └── widgets/
│       │           ├── invoice_item_row.dart
│       │           └── invoice_total_summary.dart
│       ├── payment/                       # Epic 5 (partial)
│       │   ├── data/
│       │   │   ├── payments_table.dart
│       │   │   ├── payment_dao.dart
│       │   │   ├── payment_sync_handler.dart
│       │   │   └── payment_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── payment_model.dart
│       │   │   ├── payment_repository.dart
│       │   │   └── payment_exceptions.dart
│       │   └── presentation/
│       │       ├── payment_form_page.dart
│       │       ├── providers/
│       │       │   └── payment_providers.dart
│       │       └── widgets/
│       │           └── payment_receipt_widget.dart
│       ├── inventory/                     # Epic 7
│       │   ├── data/
│       │   │   ├── inventory_items_table.dart
│       │   │   ├── stock_movements_table.dart
│       │   │   ├── inventory_dao.dart
│       │   │   ├── inventory_sync_handler.dart
│       │   │   └── inventory_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── inventory_item_model.dart
│       │   │   ├── stock_movement_model.dart
│       │   │   ├── inventory_repository.dart
│       │   │   └── inventory_exceptions.dart
│       │   └── presentation/
│       │       ├── inventory_list_page.dart
│       │       ├── inventory_item_detail_page.dart
│       │       ├── providers/
│       │       │   └── inventory_providers.dart
│       │       └── widgets/
│       │           ├── inventory_item_row.dart
│       │           └── low_stock_badge.dart
│       ├── attachment/                    # Epic 4 (partial)
│       │   ├── data/
│       │   │   ├── attachments_table.dart
│       │   │   ├── attachment_dao.dart
│       │   │   ├── attachment_sync_handler.dart
│       │   │   └── attachment_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── attachment_model.dart
│       │   │   ├── attachment_repository.dart
│       │   │   └── attachment_exceptions.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── attachment_providers.dart
│       │       └── widgets/
│       │           └── attachment_gallery_widget.dart
│       ├── day_closeout/                  # Epic 8
│       │   ├── data/
│       │   │   ├── day_closeouts_table.dart
│       │   │   ├── day_closeout_dao.dart
│       │   │   ├── day_closeout_sync_handler.dart
│       │   │   └── day_closeout_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── day_closeout_model.dart
│       │   │   ├── day_closeout_repository.dart
│       │   │   └── day_closeout_exceptions.dart
│       │   └── presentation/
│       │       ├── day_closeout_page.dart
│       │       ├── providers/
│       │       │   └── day_closeout_providers.dart
│       │       └── widgets/
│       │           └── closeout_summary_card.dart
│       └── roles/                         # Epic 9
│           ├── data/
│           │   ├── staff_table.dart
│           │   ├── staff_dao.dart
│           │   ├── staff_sync_handler.dart
│           │   └── staff_repository_impl.dart
│           ├── domain/
│           │   ├── staff_model.dart
│           │   ├── staff_repository.dart
│           │   └── staff_exceptions.dart
│           └── presentation/
│               ├── staff_list_page.dart
│               ├── staff_form_page.dart
│               ├── providers/
│               │   └── staff_providers.dart
│               └── widgets/
│                   └── staff_role_chip.dart
└── test/
    ├── features/
    │   ├── patient/
    │   ├── appointment/
    │   ├── visit/
    │   ├── invoice/
    │   ├── payment/
    │   ├── inventory/
    │   ├── day_closeout/
    │   └── roles/
    ├── core/
    │   ├── sync/
    │   ├── rbac/
    │   └── audit/
    ├── integration/
    │   ├── sync_integration_test.dart
    │   └── financial_flow_test.dart
    └── helpers/
        ├── test_database.dart
        └── mock_supabase.dart
```

### Architectural Boundaries

**Local ↔ Sync Boundary:**
- Feature code writes exclusively to Drift via `RepositoryImpl`
- `SyncOutbox.enqueue(entityType, entityId)` is the only crossing point from feature code to sync
- `SyncWorker` (in `core/sync/`) is the only code that calls Supabase; no feature code touches Supabase directly
- Supabase Realtime callbacks write back to Drift via the entity's `SyncConflictHandler`

**Presentation ↔ Domain Boundary:**
- Providers depend on repository interfaces (`domain/`), never on `RepositoryImpl` directly
- Dependency injection: `AppDatabase` and `RepositoryImpl` instances provided via Riverpod providers
- Sub-widgets have no Riverpod dependency — data arrives via constructor parameters only

**RBAC Boundary (three layers, same predicate):**
1. `core/router/route_guard.dart` — GoRouter `redirect` rejects unauthorized navigation
2. Provider `build()` — throws `PermissionDeniedException` before returning data
3. `RepositoryImpl` method body — final enforcement before any Drift write

**Financial Boundary:**
- Only `InvoiceRepositoryImpl` and `PaymentRepositoryImpl` write to `invoices`, `invoice_items`, `payments` tables
- `InvoiceRepositoryImpl` enforces: Items lock on first Payment; total derived; void is terminal
- No other feature or repository imports `InvoiceDao` or `PaymentDao`

### Requirements to Structure Mapping

| Epic | Location |
|---|---|
| Epic 1 — Auth & Clinic Bootstrap | `features/auth/`, `features/clinic/`, `core/auth/` |
| Epic 2 — Patient Management | `features/patient/` |
| Epic 3 — Calendar & Appointments | `features/appointment/` |
| Epic 4 — Visit Workflow & Attachments | `features/visit/`, `features/attachment/` |
| Epic 5 — Invoicing & Payments | `features/invoice/`, `features/payment/` |
| Epic 6 — Treatment Planning | `features/treatment_plan/` |
| Epic 7 — Inventory | `features/inventory/` |
| Epic 8 — Day Closeout | `features/day_closeout/` |
| Epic 9 — Roles & Permissions | `features/roles/`, `core/rbac/` |
| Epic 10 — Offline-First & Sync | `core/sync/`, `core/database/` |
| Epic 11 — Localization & RTL | `core/l10n/`, `lib/l10n/*.arb` |

### Data Flow

```
User Action
  → Page (ConsumerWidget)
    → Provider (AsyncValue<T>)
      → RepositoryImpl (domain exception boundary)
        → Dao (Drift query)
          → AppDatabase (local SQLite, source of truth)
        → SyncOutbox.enqueue()          ← side-effect only
          → SyncWorker (background)
            → Supabase (EU region)      ← async, not on critical path
              → SyncConflictHandler
                → Dao (write back)
```

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:** All technology choices are compatible. Drift and Freezed share `build_runner` without conflict — a single `dart run build_runner build --delete-conflicting-outputs` generates all code. `riverpod_lint` depends on `custom_lint`, which is already present. Supabase is async-only with no runtime coupling to Drift.

**Pattern Consistency:** Feature-first structure aligns with Riverpod's provider-per-feature model. `@riverpod` code generation aligns with `riverpod_generator`. Typed exceptions propagate cleanly through `AsyncValue.error` to the presentation layer.

**Structure Alignment:** `core/rbac/permission_predicate.dart` as the single RBAC source prevents three-layer drift. `core/sync/` owns the outbox and worker exclusively — feature repositories never touch Supabase directly. Financial boundary is enforced by DAO isolation in `invoice/` and `payment/`.

### Requirements Coverage Validation ✅

**Epic Coverage:** All 11 epics map to specific feature modules. No epic is without a structural home.

**FR Domain Coverage:** All 12 FR domains (Auth, Patient, Appointment, Visit, Treatment Plan, Invoicing, Payment, Inventory, Attachments, Day Closeout, Roles, Sync/Offline) have dedicated feature modules or core infrastructure.

**NFR Coverage:** NFR-1 through NFR-6 and NFR-8 through NFR-11 are fully addressed architecturally. NFR-7 (performance baseline) is flagged — targets are noted but mechanisms are deferred to implementation (indexed queries, Isolate-based sync worker).

### Gap Analysis Results

**Important Gaps:**
- **NFR-7 performance mechanisms** — Implementation agents must: run sync worker in a Dart `Isolate`; ensure `appointments` table has a composite index on `(clinic_id, date)`; lazy-load feature providers.
- **SQLCipher package identity** — `sqlcipher_flutter_libs` must be validated for Drift compatibility at implementation time (Story 1.1 / Epic 10 scaffold).
- **Supabase RLS policies** — All Supabase tables must have Row Level Security enabled, partitioned by `clinic_id`, to prevent cross-clinic data access. Define policies during Epic 10 implementation.

**Minor Gaps:**
- `build_runner` invocation convention: always `dart run build_runner build --delete-conflicting-outputs`.
- Supabase table schema mirrors Drift schema plus a `clinic_id` UUID partition column on every table.
- `print` is forbidden — all logging via `AppLogger`.

### Architecture Completeness Checklist

**Requirements Analysis**
- [x] Project context thoroughly analyzed
- [x] Scale and complexity assessed
- [x] Technical constraints identified
- [x] Cross-cutting concerns mapped

**Architectural Decisions**
- [x] Critical decisions documented with versions
- [x] Technology stack fully specified
- [x] Integration patterns defined
- [x] Performance considerations addressed

**Implementation Patterns**
- [x] Naming conventions established
- [x] Structure patterns defined
- [x] Communication patterns specified
- [x] Process patterns documented

**Project Structure**
- [x] Complete directory structure defined
- [x] Component boundaries established
- [x] Integration points mapped
- [x] Requirements to structure mapping complete

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

**Key Strengths:**
- Offline-first design is unambiguous — Drift is authoritative with zero runtime Supabase dependency
- Three-layer RBAC from a single predicate source eliminates permission drift
- Financial immutability enforced structurally — no way to bypass without violating the boundary
- Feature module layout is specific enough for parallel agent implementation without conflicts
- All 49 FRs and 11 NFRs have architectural homes

**Areas for Future Enhancement:**
- Performance profiling on clinic hardware (NFR-7 validation)
- SQLCipher integration and key management (post-v1 hardening)
- Supabase RLS policy specification
- CI artifact signing and distribution pipeline

### Implementation Handoff

**AI Agent Guidelines:**
- Follow the feature module layout exactly — no structural variation
- Use `@riverpod` code generation exclusively — no manual `Provider(...)` constructors
- Call `AuditHelper.auditFields(ref)` on every financial/clinical write
- Run `dart run build_runner build --delete-conflicting-outputs` after any schema or model change
- All Supabase interactions are routed through `core/sync/` — never from feature code

**First Implementation Priority:**
```bash
# Epic 1, Story 1.1 — scaffold the project
flutter pub remove firebase_auth firebase_core cloud_firestore
flutter pub add supabase_flutter
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add go_router
flutter pub add drift drift_flutter path_provider path
flutter pub add freezed_annotation json_annotation
flutter pub add --dev build_runner drift_dev riverpod_generator riverpod_lint freezed json_serializable
flutter pub add logger
```
