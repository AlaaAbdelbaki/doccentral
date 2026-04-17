# DocCentral Feature Backlog

Status values: Backlog, Ready, In Progress, Blocked, Done.
Priority values: High, Medium, Low.

---

# Phase 0 - Project Foundation

## SETUP-001 - Project initialization
- Status: Backlog
- Priority: High
- Scope: Flutter desktop-first app, clean folder structure, Riverpod codegen, GoRouter, and l10n for EN/FR/AR.
- Acceptance criteria:
  - The app boots on desktop.
  - The codebase has clear app, core, data, domain, and presentation folders.
  - Riverpod, GoRouter, and localization are wired into the app.

## SETUP-002 - Core architecture scaffolding
- Status: Backlog
- Priority: High
- Scope: Domain, data, and presentation layer scaffolding with base entity, repository contracts, and error handling.
- Acceptance criteria:
  - The architecture layers exist and are referenced by feature code.
  - A base entity model and repository interfaces are defined.
  - Errors are handled through a shared application layer.

## SETUP-003 - Drift setup for local database
- Status: Backlog
- Priority: High
- Scope: Drift database initialization, migration flow, and shared table helpers for timestamps and sync metadata.
- Acceptance criteria:
  - Drift is initialized and ready for tables and DAOs.
  - Migrations can be added without restructuring the database layer.
  - Shared column helpers exist for timestamps and sync fields.

## SETUP-004 - Supabase setup
- Status: Backlog
- Priority: High
- Scope: Supabase project setup, authentication, mirrored schema planning, and API access configuration.
- Acceptance criteria:
  - Supabase auth can be used by the app.
  - The backend schema maps cleanly to the local data model.
  - API access is configured securely for the client.

---

# Phase 1 - Core Identity and Access

## AUTH-001 - Authentication system
- Status: Backlog
- Priority: High
- Scope: Email and password login, session persistence, and logout flow.
- Acceptance criteria:
  - Users can sign in with email and password.
  - Sessions survive app restarts.
  - Users can log out and return to the auth flow.

## AUTH-002 - User and clinic bootstrap
- Status: Backlog
- Priority: High
- Scope: First-signup clinic creation, doctor user creation, and default role assignment.
- Acceptance criteria:
  - A new clinic is created on first signup.
  - The signing user becomes the clinic doctor user.
  - A default role is assigned automatically.

## AUTH-003 - RBAC system
- Status: Backlog
- Priority: High
- Scope: Role model, permission checking, and route guard integration.
- Acceptance criteria:
  - Roles exist for doctor, assistant, and nurse.
  - Permissions can be checked consistently in app code.
  - Unauthorized routes are blocked or redirected.

---

# Phase 2 - Patient Module

## PAT-001 - Patient entity and Drift table
- Status: Backlog
- Priority: High
- Scope: Patient domain model, Drift table, repository implementation, and sync fields.
- Acceptance criteria:
  - Patients can be stored locally in Drift.
  - The repository exposes the expected patient operations.
  - Sync metadata is included in the table design.

## PAT-002 - Patient CRUD
- Status: Backlog
- Priority: High
- Scope: Create, edit, soft delete, search, and filter for patients.
- Acceptance criteria:
  - Users can create and edit a patient record.
  - Deletes are soft deletes.
  - Search and filtering work on the patient list.

## PAT-003 - Patient profile screen
- Status: Backlog
- Priority: Medium
- Scope: Patient details view with appointment, visit, and invoice history.
- Acceptance criteria:
  - A patient profile page shows core patient details.
  - The profile lists related clinical and financial history.
  - Navigation to related records works from the profile.

---

# Phase 3 - Appointment Module

## APP-001 - Appointment entity and database model
- Status: Backlog
- Priority: High
- Scope: Appointment entity, local table, and status enum.
- Acceptance criteria:
  - Appointments are represented in the domain and database layers.
  - Status values are defined centrally.
  - The table supports the fields needed by scheduling screens.

## APP-002 - Appointment CRUD
- Status: Backlog
- Priority: High
- Scope: Create, update, cancel, and calendar views for appointments.
- Acceptance criteria:
  - Users can create and update appointments.
  - Appointments can be canceled.
  - Day and week calendar views are available.

## APP-003 - Appointment filtering
- Status: Backlog
- Priority: Medium
- Scope: Filter appointments by date, patient, and status.
- Acceptance criteria:
  - Date filters narrow appointment results correctly.
  - Filtering by patient and status works consistently.
  - Filter combinations behave predictably.

---

# Phase 4 - Visit Module

## VIS-001 - Visit entity and database model
- Status: Backlog
- Priority: High
- Scope: Visit entity, local table, and lifecycle status model.
- Acceptance criteria:
  - Visits are stored locally and mapped to the domain model.
  - The lifecycle covers CHECKED_IN, COMPLETED, and BILLED.
  - The database model supports visit progression.

## VIS-002 - Visit creation flow
- Status: Backlog
- Priority: High
- Scope: Visit creation from appointment and patient check-in flow.
- Acceptance criteria:
  - A visit can be created from an appointment.
  - A patient can be checked in through the app flow.
  - The visit is linked to the source appointment when relevant.

## VIS-003 - Visit management UI
- Status: Backlog
- Priority: High
- Scope: Visit status updates, diagnosis entry, and clinical notes.
- Acceptance criteria:
  - Users can update the visit status.
  - Diagnosis and clinical notes can be edited.
  - The UI reflects the current visit state.

## VIS-004 - Treatment system
- Status: Backlog
- Priority: High
- Scope: Treatments table, add/edit/remove actions, and locking after completion.
- Acceptance criteria:
  - Treatments can be managed during an open visit.
  - Treatments are locked after the visit is completed.
  - The data model supports invoice generation later.

---

# Phase 5 - Invoice Module

## INV-001 - Invoice entity and database model
- Status: Backlog
- Priority: High
- Scope: Invoices table and invoice items table.
- Acceptance criteria:
  - Invoices and invoice items are modeled separately.
  - The schema supports line items and totals.
  - The data layer can persist invoices locally.

## INV-002 - Invoice generation engine
- Status: Backlog
- Priority: High
- Scope: Auto-create invoice from visit and copy treatments into invoice items.
- Acceptance criteria:
  - An invoice can be generated from a completed visit.
  - Treatments are copied into invoice items.
  - Generated invoices start in a valid initial state.

## INV-003 - Invoice management
- Status: Backlog
- Priority: High
- Scope: Invoice viewing, status changes, discounts, and surcharges via items.
- Acceptance criteria:
  - Invoices can be viewed and updated.
  - Status transitions support DRAFT, PAID, and VOID.
  - Discounts and surcharges can be represented as items.

## INV-004 - Invoice locking rules
- Status: Backlog
- Priority: High
- Scope: Locking after PAID or VOID and total consistency validation.
- Acceptance criteria:
  - Paid or voided invoices cannot be edited.
  - Totals remain consistent after all item changes.
  - Invalid invoice state transitions are blocked.

---

# Phase 6 - Sync Engine

## SYNC-001 - Sync metadata system
- Status: Backlog
- Priority: High
- Scope: Sync status, deleted_at handling, and updated_at consistency across tables.
- Acceptance criteria:
  - Tables share the same sync metadata conventions.
  - Soft delete state is represented consistently.
  - Updated timestamps are normalized for sync logic.

## SYNC-002 - Push engine
- Status: Backlog
- Priority: High
- Scope: Detect pending changes, batch upload to Supabase, and mark records as synced.
- Acceptance criteria:
  - Pending local changes are detected reliably.
  - Records are uploaded in batches.
  - Successfully pushed rows are marked synced.

## SYNC-003 - Pull engine
- Status: Backlog
- Priority: High
- Scope: Fetch remote updates, apply them to Drift, and resolve conflicts with last write wins.
- Acceptance criteria:
  - Remote changes can be fetched incrementally.
  - Local storage is updated from remote records.
  - Conflicts resolve predictably with last write wins.

## SYNC-004 - Sync controller
- Status: Backlog
- Priority: High
- Scope: Riverpod controller for start, stop, state monitoring, and offline mode handling.
- Acceptance criteria:
  - Sync can be started and stopped from app state.
  - The current sync state is observable.
  - Offline mode pauses sync safely.

---

# Phase 7 - UI System

## UI-001 - Design system
- Status: Backlog
- Priority: Medium
- Scope: Desktop-first theme and responsive layout system.
- Acceptance criteria:
  - The app has a consistent theme and component style.
  - Layout adapts using responsive constraints.
  - Core screens share the same design language.

## UI-002 - Navigation system
- Status: Backlog
- Priority: High
- Scope: GoRouter setup and route abstraction with names and paths constants.
- Acceptance criteria:
  - Navigation uses a centralized routing setup.
  - Named routes and path constants are defined once.
  - Route usage is consistent across the app.

## UI-003 - Module screens
- Status: Backlog
- Priority: High
- Scope: Screens for patients, appointments, visits, and invoices.
- Acceptance criteria:
  - Each module has at least a basic screen entry point.
  - Navigation between module screens works.
  - Screens can host CRUD flows later without restructuring.

## UI-004 - Role-based UI rendering
- Status: Backlog
- Priority: High
- Scope: Feature visibility by role and route protection.
- Acceptance criteria:
  - Restricted features are hidden for unauthorized roles.
  - Protected routes reject access when needed.
  - UI and route checks use the same permission rules.

---

# Phase 8 - Offline and Stability

## OFF-001 - Offline detection
- Status: Backlog
- Priority: High
- Scope: Network state monitoring and sync pause or resume behavior.
- Acceptance criteria:
  - The app detects connectivity changes.
  - Sync pauses and resumes based on connectivity.
  - Offline state is visible to app logic.

## OFF-002 - Conflict handling MVP
- Status: Backlog
- Priority: High
- Scope: Last write wins resolution based on timestamps.
- Acceptance criteria:
  - Conflicting updates are resolved deterministically.
  - The resolution strategy is timestamp-based.
  - Conflict handling does not corrupt local data.

## OFF-003 - Data integrity checks
- Status: Backlog
- Priority: High
- Scope: Orphan prevention, invoice total validation, and visit-to-invoice consistency.
- Acceptance criteria:
  - Orphaned records are prevented or detected.
  - Invoice totals are validated before persistence.
  - Visit and invoice relationships stay consistent.

---

# Phase 9 - Polish

## POL-001 - Localization
- Status: Backlog
- Priority: Medium
- Scope: EN, FR, and AR translations across the app.
- Acceptance criteria:
  - The app can switch between supported locales.
  - Strings exist for all three languages.
  - RTL behavior works for Arabic screens.

## POL-002 - Export system
- Status: Backlog
- Priority: Medium
- Scope: Desktop invoice PDF export.
- Acceptance criteria:
  - Invoices can be exported as PDF.
  - The export works on desktop platforms.
  - The generated document is readable and complete.

## POL-003 - Performance optimization
- Status: Backlog
- Priority: Medium
- Scope: Drift query optimization and pagination for large datasets.
- Acceptance criteria:
  - Expensive queries are reduced or streamed efficiently.
  - Large lists paginate instead of loading everything at once.
  - The UI remains responsive with larger data volumes.

---

# MVP Completion Criteria

- Status: Backlog
- Priority: High
- Scope: Full offline-first workflow and role-based access across devices.
- Acceptance criteria:
  - The Patient -> Appointment -> Visit -> Invoice flow works end to end.
  - Sync works across two devices.
  - Offline mode does not lose data.
  - Role-based access is enforced throughout the app.