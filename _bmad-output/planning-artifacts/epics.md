---
stepsCompleted: [1, 2, 3, 4]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-DocCentral-2026-05-21/prd.md
  - _bmad-output/planning-artifacts/architecture.md
---

# DocCentral - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for DocCentral, decomposing the requirements from the PRD and partial Architecture context into implementable stories.

## Requirements Inventory

### Functional Requirements

FR-1: On a fresh install, sign-up creates the Clinic, the initial Dentist User, and Role definitions for Dentist, Assistant, and Nurse. Clinic locale defaults to fr-TN / TND; signing-up User is the clinic owner with Dentist role.
FR-2: Sign in with email + password. Session persists across app restarts until explicit sign-out. Offline sign-in works against locally cached credentials after first online sign-in.
FR-3: Dentist adds a new Assistant or Nurse User from Clinic Settings (name, email, Role, initial password). New User can sign in and is constrained by their Role's permissions.
FR-4: Create a Patient with required fields: first name, last name, date of birth, phone number. Email optional. Cannot save with required fields missing.
FR-5: Paste or type paper file contents into a history_notes text field at Patient creation. Shown prominently above-the-fold on the Patient File. Not parsed.
FR-6: Search by partial first/last name or partial phone. Results within 300ms on up to 10,000 Patients. Soft-deleted Patients excluded.
FR-7: Patient File view renders identity, history notes, most recent 5 Visits, active Treatment Plan, Outstanding Balance, Attachments list. All sections expand on demand. Renders within 500ms for up to 50 Visits.
FR-8: [Dentist only] Soft-delete a Patient. Hidden from lists/search but retained for financial integrity. deleted_at set; no physical removal.
FR-9: Create an Appointment with start time, end time (default 30 min), assigned User (default Dentist), reason (free text), optional notes. Overlapping Appointments for same User require explicit override confirmation.
FR-10: Day-view calendar (Today's Calendar) shows current day's Appointments as time-grid — patient name, time, planned-treatment summary, status, Lab Work Flag, Outstanding Balance indicator. Loads within 500ms. Status changes update within 200ms.
FR-11: Week-view calendar shows Appointments across 7 days, navigable forward/backward. Loads within 1s. Statuses visually distinct.
FR-12: Check In on a scheduled Appointment creates a Visit in checked_in status, sets Visit.started_at = now(), transitions Appointment to checked_in.
FR-13: Cancel a scheduled Appointment with required reason (patient_cancelled / no_show / clinic_cancelled / rescheduled). For rescheduled, replacement Appointment created in same flow linked via rescheduled_to_appointment_id.
FR-14: Set Lab Work Flag on an Appointment with free-text note. Appears in calendar views and morning side panel.
FR-15: Transition a checked_in Visit to in_progress. Captures in_progress_at timestamp.
FR-16: Add Performed Treatments to an in_progress Visit: tooth number, procedure name (free text), unit price, quantity. Editable while in_progress.
FR-17: Edit diagnosis and clinical_notes fields while Visit is in_progress. Multi-line text. Autosave on field blur.
FR-18: Complete a Visit (in_progress → completed). Auto-generates Invoice in draft with Invoice Items copied from Performed Treatments. Locks Performed Treatments. Sets ended_at.
FR-19: [Dentist only] Unlock a completed Visit only if linked Invoice is in draft status (no Payments, not Finalized). Returns Visit to in_progress. Logged with actor + timestamp + optional reason.
FR-20: Add Planned Treatments to a Patient: procedure name (free text), tooth number, estimated unit price, sequence number, target date or "next available". Status starts as planned.
FR-21: When creating an Appointment, attach one or more Planned Treatments; their status transitions to scheduled. Appointment shows attached Planned Treatments as "planned for this Visit" list.
FR-22: In an in_progress Visit, mark attached Planned Treatments as performed. Creates corresponding Performed Treatment; Planned Treatment transitions scheduled → done.
FR-23: Invoice auto-created in draft on Visit completion. One Invoice per completed Visit. Invoice Items copy description, tooth number, quantity, unit price, total_price from Performed Treatments.
FR-24: Add Invoice Items with adjustment_type = discount or surcharge while Invoice is in draft. Adjustments immutable once Invoice exits draft.
FR-25: [Dentist only] Void an Invoice in any status. Records reason + timestamp. Voided Invoice contributes 0 to Outstanding Balance. Pre-existing Payments preserved with "refund owed" surface.
FR-26: Record a Payment against a non-void Invoice: amount, method (default cash), date (default today), optional notes. Multiple Payments per Invoice. Payment on a draft Invoice auto-finalizes it. Invoice status is derived (draft / unpaid / partially_paid / paid / void).
FR-27: Patient File shows Outstanding Balance = sum(Invoice.total − sum(Payments)) across non-void Invoices. Computed at read time. Updates within 100ms of a Payment.
FR-28: Dedicated screen lists Patients with Outstanding Balance > 0, sortable by balance descending and by days-since-last-Payment.
FR-29: Create an Inventory Item: name, category (cleaning / medicament / supply / other), unit, initial on-hand quantity, low-stock threshold (≥ 0).
FR-30: Record a Restock Event: quantity added, date (default today), optional supplier, optional notes. Increases on_hand. Logged with actor + timestamp.
FR-31: Direct stock adjustment to correct counting errors. Requires reason. Logs old quantity, new quantity, delta, reason, actor, timestamp separately from Restock Events.
FR-32: Computed list of Inventory Items where on_hand ≤ threshold. Appears on Low Stock view and as count badge on morning side panel. Refreshes on every stock change.
FR-33: Upload a file (PDF / JPG / PNG, max 10 MB) to a Patient or Visit. Stored locally; queued for sync to Supabase storage.
FR-34: Preview (image) or open (PDF) an Attachment from Patient File or Visit view. Images render inline; PDFs open in system default viewer.
FR-35: Day Closeout screen shows: count of completed Visits, sum of Payments by method, sum of new Invoices, count of outstanding (unpaid/partially_paid) Invoices for current day. Updates in real time.
FR-36: Assistant enters counted cash and optional notes, confirms. Creates Day Closeout record (expected, counted, delta, actor, timestamp). One per Clinic per date. Non-zero delta flagged but does not block.
FR-37: [Dentist only] Reopen a closed day. Unlocks counted_cash for re-entry. Logged with actor, timestamp, optional reason.
FR-38: Dentist-only operations: unlock completed Visit (FR-19), void Invoice (FR-25), soft-delete Patient (FR-8), add/remove Users (FR-3), reopen closed day (FR-37). Assistant can do everything else. Domain layer rejects unauthorized operations with PERMISSION_DENIED. UI hides/disables restricted controls for Assistant.
FR-39: Same permission predicate evaluated at router/route-guard, Riverpod provider, and domain operation layers. No permission-logic drift. Unit test enumerates all restricted operations and confirms all three layers use identical predicate function.
FR-40: All FRs work without internet on local Drift database. Sync resumes automatically when connectivity returns. End-to-end test with network disabled completes UJ-2, UJ-3, UJ-4, UJ-10.
FR-41: On connectivity, push pending local changes (sync_status = pending) to Supabase in batches. After success, records become synced. Push failures retry with exponential backoff capped at 10 min.
FR-42: Pull remote changes from Supabase incrementally (since last successful pull) and apply to local DB. Pull failures do not corrupt local data.
FR-43: Last-write-wins conflict resolution based on UTC updated_at. Conflicts on Invoice and Payment records surface as warning to User; do not silently overwrite.
FR-44: Switch UI language between FR / AR / EN from Settings. Persists per User across sessions. Switching to AR flips layout to RTL across all screens.
FR-45: Dates render per locale (FR: 21/05/2026; EN: 2026-05-21). Currency renders as TND. Time uses 24-hour format across all locales.
FR-46: Edit a Patient's identity fields and history_notes. Required fields cannot be cleared. Edit log records actor, timestamp, fields changed.
FR-47: Edit a scheduled Appointment's time, duration, assigned User, reason, Lab Work Flag, attached Planned Treatments, notes. Non-scheduled Appointments return APPT_NOT_EDITABLE. Time/duration edits trigger overlap check. Edit logged.
FR-48: Filter calendar by date range, Patient, status, assigned User. Filters compose (intersection). Single action clears all filters.
FR-49: Finalize an Invoice in draft status without a Payment. Transitions draft → unpaid. Locks Invoice Items. Logged with actor + timestamp. Re-opening requires Dentist's Visit unlock (FR-19) and no Payments.

### NonFunctional Requirements

NFR-1: Offline-first — all FRs work without internet; only initial device sign-in requires connectivity.
NFR-2: Sync resilience — sync failures, network drops mid-sync, and conflicts must not corrupt local data; Drift is authoritative at runtime.
NFR-3: Financial determinism — Invoice totals always computed from Items + adjustments + Payments; no UI path exposes a direct Invoice total field.
NFR-4: Immutability of paid records — once an Invoice has any Payment, Invoice Items are immutable; corrections require void (FR-25); once paid or void, no further edits.
NFR-5: Localization integrity — no hardcoded user-facing strings in code; all UI text from translation files.
NFR-6: RTL correctness — Arabic locale renders correctly in RTL for all screens (form fields, lists, modals).
NFR-7: Desktop performance baseline — cold launch < 4s; Today's Calendar < 2s after sign-in; screen navigation < 500ms. Validated on clinic's actual hardware.
NFR-8: Data residency — Supabase project in EU region (Frankfurt or Ireland).
NFR-9: Audit attribution — every Invoice, Payment, Void, Day Closeout, Closeout Reopen, Visit transition, Performed Treatment add/edit, Visit Unlock, Patient edit, and Appointment edit records actor_id + UTC timestamp. Schema enforces non-null on these fields.
NFR-10: Per-module test coverage discipline — every module ships with unit tests (domain logic), integration tests (repository/data layer), sync-aware tests (where module touches sync metadata). No percentage target; discipline contract.
NFR-11: Responsive layouts — screens use LayoutBuilder-based responsive layouts; only top-level pages access Riverpod; child widgets are pure.

### Additional Requirements

- Flutter desktop (Windows / macOS / Linux) — mobile, web, tablet out of scope
- Drift as local SQLite database — source of truth for all runtime operations
- Supabase as sync/auth backend — EU region; not a runtime dependency except initial device sign-in
- Riverpod for state management — only top-level pages may use Riverpod widgets; children are pure
- GoRouter for navigation — router-layer permission enforcement required
- Three-layer RBAC — same permission predicate at router guard, Riverpod provider, and domain operation
- Soft-delete pattern on all entities — deleted_at; no physical removal
- Sync metadata on every entity — sync_status, updated_at, created_at, deleted_at; enforced non-null
- SQLCipher or equivalent — encryption at rest (pending performance validation on clinic hardware)
- Single Clinic per deployment — schema multi-tenant for forward-compat; product is single-tenant MVP
- Cash-only payments in MVP — method field exists for v2 extensibility
- Project foundation work (Flutter scaffolding, Drift init, Supabase setup, GoRouter, base design system, Riverpod codegen) belongs in infrastructure epics alongside product epics — per PRD §10

### UX Design Requirements

_No UX Design document available. UX requirements derived from PRD user journeys (UJ-1 through UJ-10) and glossary._

UX-DR1: Today's Calendar (landing surface) — time-grid layout showing patient name, time, planned-treatment summary, status badge, Lab Work Flag indicator, Outstanding Balance indicator per Appointment row. Side panel shows low-stock consumables and appointments awaiting lab delivery.
UX-DR2: Patient File — unified view with above-the-fold identity + history_notes, then expandable sections: last 5 Visits, active Treatment Plan, Outstanding Balance, Attachments list. All sections load within 500ms for up to 50 Visits.
UX-DR3: Visit wrap-up flow — single screen to mark Performed Treatments (from Planned list or ad-hoc), add clinical note, complete Visit, review auto-generated Invoice, apply adjustments, take Payment, and optionally schedule next Appointment.
UX-DR4: Cancellation flow — search calendar by patient name, find Appointment, tap Cancel, pick reason; if rescheduled, prompt to create replacement Appointment and link the two in one gesture.
UX-DR5: Outstanding Balance list — sortable by balance descending and by days-since-last-payment; tapping a row opens the Patient File.
UX-DR6: Day Closeout screen — shows day summary (completed Visits, expected cash, Payment breakdown by method), input for counted cash, optional notes field, confirm button. Non-zero delta flagged visually.
UX-DR7: RTL layout flip — switching to Arabic must flip the entire layout tree (all screens, modals, form fields, lists) to RTL without requiring restart.
UX-DR8: Settings — language switcher (FR/AR/EN), Clinic profile, User management (Dentist only). Persists per-User.

### FR Coverage Map

| FR | Epic | Domain |
|---|---|---|
| FR-38, FR-39 | Epic 1 | RBAC framework |
| FR-1, FR-2, FR-3, FR-44, FR-45 | Epic 2 | Auth & Settings |
| FR-4, FR-5, FR-6, FR-7, FR-8, FR-46 | Epic 3 | Patient |
| FR-9, FR-10, FR-11, FR-12, FR-13, FR-14, FR-47, FR-48 | Epic 4 | Calendar |
| FR-15, FR-16, FR-17, FR-18, FR-19 | Epic 5 | Visit |
| FR-20, FR-21, FR-22 | Epic 6 | Treatment Plan |
| FR-23, FR-24, FR-25, FR-26, FR-27, FR-28, FR-49 | Epic 7 | Invoicing |
| FR-29, FR-30, FR-31, FR-32 | Epic 8 | Inventory |
| FR-33, FR-34 | Epic 9 | Attachments |
| FR-35, FR-36, FR-37 | Epic 10 | Day Closeout |
| FR-40, FR-41, FR-42, FR-43 | Epic 11 | Sync |

## Epic List

### Epic 1: App Foundation & Infrastructure
The app launches on desktop; all subsequent epics can be built on a consistent, offline-capable base. Flutter desktop scaffold, Drift + SQLCipher, Supabase client, Riverpod + codegen, GoRouter, l10n infrastructure, base design system, three-layer RBAC framework, sync metadata pattern, audit attribution schema, test infrastructure.
**FRs covered:** FR-38, FR-39
**NFRs addressed:** NFR-1 (partial), NFR-5, NFR-7, NFR-8, NFR-9, NFR-10, NFR-11

### Epic 2: Clinic Setup & Authentication
Dentist can sign up, provision the clinic, sign in with persistent session, add the Assistant user, and switch the app language (FR/AR/EN with RTL).
**FRs covered:** FR-1, FR-2, FR-3, FR-44, FR-45

### Epic 3: Patient Management
Assistant can create patients (including backfilling paper history), search by name or phone, open a full Patient File, edit patient details, and Dentist can soft-delete.
**FRs covered:** FR-4, FR-5, FR-6, FR-7, FR-8, FR-46

### Epic 4: Calendar & Appointments
Assistant can view day and week calendars, create/edit/cancel/filter appointments, check in patients, and flag appointments awaiting lab work.
**FRs covered:** FR-9, FR-10, FR-11, FR-12, FR-13, FR-14, FR-47, FR-48

### Epic 5: Clinical Visits
Dentist and Assistant can manage the full visit lifecycle — record performed treatments with tooth numbers, add clinical notes and diagnosis, complete the visit (auto-generating the invoice), and Dentist can unlock a completed visit if needed.
**FRs covered:** FR-15, FR-16, FR-17, FR-18, FR-19

### Epic 6: Treatment Planning *(subject to PRD Open Q1 validation)*
Dentist can plan multi-session treatments, link planned sessions to future appointments, and mark them as performed during visits.
**FRs covered:** FR-20, FR-21, FR-22

### Epic 7: Invoicing & Payments
Assistant can work with auto-generated invoices, add adjustments, finalize, take cash payments (including partial), and view outstanding balances. Dentist can void invoices.
**FRs covered:** FR-23, FR-24, FR-25, FR-26, FR-27, FR-28, FR-49

### Epic 8: Inventory Management
Assistant can manage consumable inventory — create items, record restocks, make manual adjustments, and see low-stock alerts on the morning dashboard.
**FRs covered:** FR-29, FR-30, FR-31, FR-32

### Epic 9: File Attachments
Assistant can upload X-ray images and PDFs to patients or visits, and preview them from the Patient File or Visit view.
**FRs covered:** FR-33, FR-34

### Epic 10: Day Closeout
Assistant can close the day with a cash reconciliation (expected vs. counted), and Dentist can reopen a closed day to correct a missed payment.
**FRs covered:** FR-35, FR-36, FR-37

### Epic 11: Offline-First Sync
All workflows function fully without internet (offline-capable from Epic 1's Drift foundation); this epic delivers the complete sync engine — push, pull, and conflict resolution surfacing to users.
**FRs covered:** FR-40, FR-41, FR-42, FR-43

---

---

## Epic 1: App Foundation & Infrastructure

The app launches on desktop; every subsequent epic is built on a consistent, offline-capable, RBAC-enforced, auditable base.

### Story 1.1: Flutter Desktop Project Bootstrap

As a developer,
I want a clean Flutter desktop project configured for Windows/macOS/Linux with Supabase, Riverpod, and GoRouter wired up,
So that every subsequent story has a consistent foundation to build on.

**Acceptance Criteria:**

**Given** a fresh checkout of the repository
**When** the app is run on a desktop platform (Windows, macOS, or Linux)
**Then** the app launches to a placeholder screen without errors

**Given** the pubspec.yaml
**When** reviewing dependencies
**Then** `supabase_flutter`, `flutter_riverpod`, `riverpod_annotation`, `go_router`, `flutter_localizations`, and `intl` are present; `firebase_auth` and `firebase_core` are removed

**Given** the project structure
**When** a developer runs `flutter build windows` (or macos/linux)
**Then** the build completes without warnings about unsupported platforms

### Story 1.2: Drift Local Database with Sync Metadata Pattern

As a developer,
I want a Drift database initialized with SQLCipher encryption and a sync metadata mixin that all future tables will use,
So that every entity is offline-capable and sync-trackable from day one.

**Acceptance Criteria:**

**Given** the app starts
**When** the Drift database is initialized
**Then** the database file is created at the platform-appropriate path, encrypted with SQLCipher

**Given** the sync metadata mixin
**When** any future table includes it
**Then** the table gains `id` (UUID PK), `created_at`, `updated_at`, `deleted_at` (nullable), and `sync_status` (`pending` / `synced` / `conflict`) columns — all non-null except `deleted_at`

**Given** a `clinics` table created as proof-of-concept using the mixin
**When** a Clinic row is inserted
**Then** the row is retrievable with all sync metadata fields populated correctly

**And** an integration test verifies the database initializes, inserts a row, and retrieves it correctly

### Story 1.3: Three-Layer RBAC Framework

As a developer,
I want a role-based permission system enforced at the router, Riverpod provider, and domain layers using a single shared predicate,
So that no Dentist-restricted operation can be reached or executed by an Assistant regardless of how navigation occurs.

**Acceptance Criteria:**

**Given** a `Role` enum (`dentist`, `assistant`, `nurse`) and a permission predicate function
**When** a Dentist-restricted operation is called with an `assistant` role
**Then** the domain layer throws `PermissionDeniedException` with error code `PERMISSION_DENIED`

**Given** the GoRouter configuration
**When** an Assistant navigates directly (via deep link) to a Dentist-only route
**Then** the router guard redirects to an unauthorized screen

**Given** a Riverpod provider that exposes a restricted data surface
**When** consumed by an Assistant role
**Then** the provider returns empty/unauthorized state rather than restricted data

**And** a unit test enumerates at least the 5 Dentist-restricted operations from FR-38 and confirms all three layers (router, provider, domain) use the identical predicate function

### Story 1.4: Localization Infrastructure (FR/AR/EN + RTL)

As a developer,
I want the l10n scaffold configured for French, Arabic (RTL), and English with locale-aware formatters,
So that no hardcoded user-facing strings exist anywhere in the codebase and Arabic layouts render correctly.

**Acceptance Criteria:**

**Given** the app is running
**When** the active locale is set to `ar`
**Then** the entire layout tree renders in RTL (mirrored layout, right-to-left text direction) without restart

**Given** the localization ARB files for `fr`, `ar`, and `en`
**When** a locale is switched
**Then** all UI strings render in the correct language with no fallback to another language

**Given** a locale-aware date formatter utility
**When** formatting the same date in `fr`, `en`, and `ar` locales
**Then** `fr` renders `DD/MM/YYYY`, `en` renders `YYYY-MM-DD`, currency renders as `TND`, and time uses 24-hour format in all locales

**And** a static analysis check (enforced via lint rule or test) fails if a hardcoded user-facing string is detected in widget code

### Story 1.5: Navigation Shell & Design System Tokens

As a developer,
I want a GoRouter-based navigation shell with LayoutBuilder-responsive layouts and Material 3 design tokens,
So that all screens follow a consistent visual and structural pattern and only top-level pages consume Riverpod.

**Acceptance Criteria:**

**Given** the app launches
**When** the navigation shell renders
**Then** a scaffold with placeholder routes for: Today's Calendar, Patient List, Inventory, Day Closeout, and Settings is visible

**Given** any screen in the app
**When** the window is resized (desktop)
**Then** the layout adapts via `LayoutBuilder` without horizontal scrolling at any reasonable desktop width (≥ 800px)

**Given** the widget architecture
**When** reviewing any non-page widget
**Then** no `ref.watch` / `ref.read` (Riverpod) calls exist in child widgets — only top-level page widgets consume providers

**And** Material 3 color scheme, typography scale, and spacing tokens are defined in a central theme file

---

## Epic 2: Clinic Setup & Authentication

Dentist can sign up, provision the clinic, sign in with persistent session, add the Assistant user, and switch the app language (FR/AR/EN with RTL).

### Story 2.1: First-Run Clinic Provisioning & Dentist Sign-Up

As a dentist,
I want to sign up with email and password on a fresh install to create my clinic and account in one flow,
So that DocCentral is ready for my practice without any manual database setup.

**Acceptance Criteria:**

**Given** the app is launched for the first time with no local Clinic data
**When** the Dentist completes the sign-up form (email, password, clinic name)
**Then** a Clinic record is created with locale defaults (`fr-TN`, currency `TND`), the User is assigned the Dentist role with `is_clinic_owner = true`, and Role records exist for Dentist, Assistant, and Nurse

**Given** a successful sign-up
**When** the app navigates post-signup
**Then** the user lands on Today's Calendar without requiring re-authentication

**Given** sign-up requires Supabase connectivity
**When** the device is offline during sign-up
**Then** an appropriate error is shown and no partial Clinic data is persisted locally

**And** a unit test confirms the Clinic creation domain operation creates all required Role records

### Story 2.2: Email + Password Sign-In with Persistent Session

As a clinic user (Dentist or Assistant),
I want to sign in once and have my session persist across app restarts,
So that I don't need to re-authenticate every time I open DocCentral.

**Acceptance Criteria:**

**Given** a registered User with valid credentials
**When** they sign in with correct email and password
**Then** they land on Today's Calendar and their session is persisted locally

**Given** a persisted session
**When** the app is closed and reopened
**Then** the user lands on Today's Calendar without re-authentication

**Given** a persisted session
**When** the user taps Sign Out
**Then** the session is cleared and the user is returned to the sign-in screen

**Given** the device is offline with a previously cached session
**When** the app is opened
**Then** the user can sign in using locally cached credentials and access all offline features

### Story 2.3: Add Staff User (Assistant / Nurse)

As a dentist,
I want to add an Assistant or Nurse user from Clinic Settings,
So that my staff can sign in to DocCentral with their own credentials and appropriate permissions.

**Acceptance Criteria:**

**Given** the Dentist is in Clinic Settings
**When** they fill in name, email, role (Assistant or Nurse), and initial password and confirm
**Then** a new User record is created linked to the Clinic with the assigned Role

**Given** the newly created Assistant User
**When** they sign in with the provided credentials
**Then** they access DocCentral with only Assistant-level permissions (Dentist-restricted operations are hidden/rejected)

**Given** an Assistant attempts to access the Add Staff User screen
**When** they navigate to Clinic Settings
**Then** the Add User control is hidden and the route is blocked by the router guard

**And** a domain-layer unit test confirms `PERMISSION_DENIED` is returned when a non-Dentist calls the add-user operation

### Story 2.4: Language Switch & Localized Formats

As a clinic user,
I want to switch the app language between French, Arabic, and English from Settings,
So that I can use DocCentral in my preferred language with correctly formatted dates and currency.

**Acceptance Criteria:**

**Given** the user opens Settings and selects a language
**When** they confirm the selection
**Then** all UI strings immediately render in the chosen language without requiring an app restart

**Given** the user switches to Arabic
**When** the app re-renders
**Then** the entire layout flips to RTL — navigation rail/drawer, form fields, lists, and modals all mirror correctly

**Given** a date displayed anywhere in the app
**When** the locale is `fr`
**Then** it renders as `DD/MM/YYYY`; when `en`, as `YYYY-MM-DD`; currency always renders as `TND`; time always uses 24-hour format

**Given** the user's language preference is set to Arabic
**When** they close and reopen the app
**Then** the app launches in Arabic RTL — the preference persisted per User across sessions

---

## Epic 3: Patient Management

Assistant can create patients (including backfilling paper history), search by name or phone, open a full Patient File, edit patient details, and Dentist can soft-delete.

### Story 3.1: Create Patient with Paper History Backfill

As an assistant,
I want to create a new patient record with their identity details and optionally paste their paper history,
So that returning patients from the paper system have their background available in DocCentral from day one.

**Acceptance Criteria:**

**Given** the Assistant opens the New Patient form
**When** they fill in first name, last name, date of birth, and phone number and save
**Then** a Patient record is created, linked to the Clinic, and visible in the patient list

**Given** any required field (first name, last name, DOB, phone) is empty
**When** the Assistant attempts to save
**Then** the form does not save and each missing field is highlighted with an error message

**Given** the Assistant pastes text into the `history_notes` field
**When** the patient is saved
**Then** the `history_notes` content is stored as-is (no parsing) and displayed prominently above-the-fold in the Patient File

**And** a unit test confirms a Patient cannot be created without all required fields

### Story 3.2: Patient Search

As an assistant,
I want to search for patients by partial name or partial phone number,
So that I can find a returning patient in seconds while they're standing at the desk.

**Acceptance Criteria:**

**Given** a patient list with up to 10,000 records
**When** the Assistant types a partial first name, last name, or last 4 digits of a phone number
**Then** matching results appear within 300ms

**Given** the search query "tra"
**When** results are returned
**Then** patients with "Trabelsi" in their name are included in results

**Given** a soft-deleted patient
**When** any search is performed
**Then** the soft-deleted patient does not appear in results

**Given** the search field is cleared
**When** the list re-renders
**Then** all active patients are shown (or a default landing state)

### Story 3.3: Patient File View

As an assistant or dentist,
I want to open a Patient File that shows identity, history notes, recent visits, active treatment plan, outstanding balance, and attachments,
So that I have the full picture of a patient before and during their appointment.

**Acceptance Criteria:**

**Given** a patient with up to 50 Visits
**When** their Patient File is opened
**Then** all sections (identity, history notes, last 5 Visits, active Treatment Plan, Outstanding Balance, Attachments list) render within 500ms

**Given** the Patient File is open
**When** viewing the Outstanding Balance
**Then** the balance is computed at read time as sum(Invoice.total − sum(Payments)) across non-void Invoices — never a stored value

**Given** sections beyond the initial view (e.g., full visit history)
**When** the user taps to expand a section
**Then** additional content loads on demand without navigating away

**And** the `history_notes` field is displayed prominently above-the-fold, visible without scrolling on a 1280×800 desktop window

### Story 3.4: Edit Patient

As an assistant,
I want to edit a patient's identity fields and history notes,
So that I can correct errors or update contact information without creating a duplicate record.

**Acceptance Criteria:**

**Given** the Assistant opens a Patient File and taps Edit
**When** they change any identity field (name, DOB, phone, email) or history notes and save
**Then** the patient record is updated and an edit log entry records actor, UTC timestamp, and the field names changed

**Given** the Assistant attempts to clear a required field (first name, last name, DOB, phone) during edit
**When** they attempt to save
**Then** the save is rejected and the field is highlighted with an error

**And** a unit test confirms the edit log entry is created with the correct actor and changed field names

### Story 3.5: Soft-Delete Patient

As a dentist,
I want to soft-delete a patient who is no longer active,
So that they disappear from day-to-day lists and search while their financial records are preserved.

**Acceptance Criteria:**

**Given** the Dentist opens a Patient File
**When** they confirm the soft-delete action
**Then** `deleted_at` is set on the Patient record; the patient no longer appears in search or patient lists

**Given** a soft-deleted patient with prior Invoices and Payments
**When** financial views (e.g., Outstanding Balance list) are loaded
**Then** the patient's Invoices and Payments remain visible and correctly totalled in financial contexts

**Given** an Assistant is viewing a Patient File
**When** they look for the delete option
**Then** the delete control is not visible; attempting the operation via any path returns `PERMISSION_DENIED`

---

## Epic 4: Calendar & Appointments

Assistant can view day and week calendars, create/edit/cancel/filter appointments, check in patients, and flag appointments awaiting lab work.

### Story 4.1: Day-View Calendar (Today's Calendar)

As an assistant or dentist,
I want to see today's appointments in a time-grid with patient name, status, planned treatment summary, lab work flag, and outstanding balance indicator,
So that I can see the full day at a glance the moment I open the app.

**Acceptance Criteria:**

**Given** the app launches after sign-in
**When** Today's Calendar renders
**Then** it loads within 500ms showing all of today's appointments in chronological time-grid order

**Given** an appointment in the calendar
**When** rendered in the grid
**Then** it displays: patient name, start time, planned-treatment summary, status badge (scheduled/checked-in/completed/cancelled), Lab Work Flag indicator, and Outstanding Balance indicator if applicable

**Given** an appointment status changes (check-in, completion, cancellation)
**When** the change is committed
**Then** the calendar row updates within 200ms without a full page reload

**Given** a side panel on the calendar
**When** rendered
**Then** it shows low-stock consumable alerts (count) and appointments flagged as awaiting lab delivery today

### Story 4.2: Week-View Calendar

As an assistant or dentist,
I want to navigate a 7-day week view of appointments,
So that I can plan ahead and spot scheduling gaps across the week.

**Acceptance Criteria:**

**Given** the user switches to week view
**When** it renders
**Then** all 7 days load within 1 second with appointments displayed per day

**Given** the week view is displayed
**When** appointment statuses are shown
**Then** scheduled, checked-in, completed, and cancelled are visually distinct (different color or badge)

**Given** the user taps the forward or backward navigation
**When** it renders
**Then** the view shifts by 7 days and loads within 1 second

### Story 4.3: Create & Edit Appointment

As an assistant,
I want to create a new appointment for a patient and edit scheduled appointments,
So that the calendar accurately reflects the clinic's planned schedule.

**Acceptance Criteria:**

**Given** the Assistant creates an appointment
**When** they set patient, start time, end time (default 30 min), assigned user (default Dentist), and reason
**Then** the appointment is created in `scheduled` status and appears in the calendar

**Given** two appointments overlap for the same assigned user
**When** the Assistant attempts to save
**Then** an explicit override confirmation is required before saving proceeds

**Given** a `scheduled` appointment
**When** the Assistant edits time, duration, assigned user, reason, or notes and saves
**Then** the appointment is updated; an edit log entry records actor, UTC timestamp, and fields changed

**Given** a non-scheduled appointment (checked-in, completed, cancelled, rescheduled)
**When** any edit is attempted
**Then** the operation is rejected with error code `APPT_NOT_EDITABLE`

### Story 4.4: Cancel & Reschedule Appointment

As an assistant,
I want to cancel an appointment with a required reason, and immediately create a replacement when rescheduling,
So that the calendar slot is freed and the patient's history accurately reflects what happened.

**Acceptance Criteria:**

**Given** a `scheduled` appointment
**When** the Assistant taps Cancel and selects reason `patient_cancelled`, `no_show`, or `clinic_cancelled`
**Then** the appointment transitions to `cancelled`, a Cancellation record is created with timestamp, actor, reason, and the slot is freed on the calendar

**Given** the Assistant selects reason `rescheduled`
**When** they confirm
**Then** the system immediately prompts to create a replacement appointment; the original is cancelled only after the replacement is saved; both are linked via `rescheduled_to_appointment_id`

**Given** a patient who has had repeated no-shows
**When** a future appointment for that patient is being prepared
**Then** the Patient File flags the no-show pattern

**And** a unit test confirms a Cancellation record is always created with a non-null reason, actor, and timestamp

### Story 4.5: Check In Patient

As an assistant,
I want to check in a patient when they arrive by tapping their appointment,
So that a Visit is automatically created and the appointment status reflects their arrival.

**Acceptance Criteria:**

**Given** a `scheduled` appointment
**When** the Assistant taps Check In
**Then** the appointment transitions to `checked_in`, a new Visit record is created in `checked_in` status linked to the appointment and patient, and `Visit.started_at` is set to now()

**Given** the check-in is complete
**When** the Assistant opens the appointment row
**Then** the Patient File is accessible from the same screen showing last 3 visits, current Treatment Plan, Outstanding Balance, and Attachments

### Story 4.6: Lab Work Flag & Appointment Filters

As an assistant,
I want to flag appointments awaiting lab work and filter the calendar by date, patient, status, or assigned user,
So that lab dependencies are visible at a glance and I can quickly find specific appointments.

**Acceptance Criteria:**

**Given** a scheduled appointment
**When** the Assistant sets the Lab Work Flag with a free-text note (e.g., "implant from LabX, ETA 2026-06-03")
**Then** the flag appears on the appointment in calendar views and in the morning side panel

**Given** filter controls on the calendar
**When** the Assistant filters by patient name
**Then** only that patient's appointments in the selected date range are shown

**Given** multiple filters applied (e.g., status = cancelled AND assigned user = Dentist)
**When** the calendar renders
**Then** it shows the intersection of all active filters

**Given** a single clear-all action
**When** triggered
**Then** all active filters are removed and the full calendar view is restored

---

## Epic 5: Clinical Visits

Dentist and Assistant can manage the full visit lifecycle — record performed treatments with tooth numbers, add clinical notes and diagnosis, complete the visit (auto-generating the invoice), and Dentist can unlock a completed visit if needed.

### Story 5.1: Start Visit & Mark In-Progress

As an assistant,
I want to transition a checked-in visit to in-progress when the patient enters the treatment room,
So that the visit lifecycle accurately tracks when clinical work begins.

**Acceptance Criteria:**

**Given** a Visit in `checked_in` status
**When** the Assistant taps to mark it in-progress
**Then** the Visit status transitions to `in_progress` and `in_progress_at` is captured as UTC now()

**Given** a Visit in `in_progress` status
**When** viewed
**Then** controls for adding Performed Treatments, editing diagnosis, and editing clinical notes are enabled

**And** an integration test confirms the `in_progress_at` timestamp is non-null after the transition

### Story 5.2: Record Performed Treatments

As an assistant or dentist,
I want to add, edit, and remove performed treatments on an in-progress visit,
So that the clinical record of what was done is accurate before the visit is completed and the invoice is generated.

**Acceptance Criteria:**

**Given** a Visit in `in_progress` status
**When** the user adds a Performed Treatment with tooth number, procedure name (free text), unit price, and quantity
**Then** the treatment is saved, timestamped, and attributed to the recording user

**Given** a Performed Treatment on an `in_progress` Visit
**When** the user edits or removes it
**Then** the change is saved and the treatment list updates immediately

**Given** a Visit that has transitioned to `completed`
**When** any edit or removal of a Performed Treatment is attempted
**Then** the operation is rejected — Performed Treatments are locked on completion

**And** a unit test confirms Performed Treatments cannot be modified on a `completed` Visit

### Story 5.3: Record Clinical Notes & Diagnosis

As an assistant or dentist,
I want to enter multi-line diagnosis and clinical notes on an in-progress visit,
So that the clinical record is complete and retrievable for future visits.

**Acceptance Criteria:**

**Given** a Visit in `in_progress` status
**When** the user edits the `diagnosis` or `clinical_notes` field
**Then** the content autosaves on field blur — no explicit save button required for these fields

**Given** both fields
**When** viewed
**Then** they support multi-line text of arbitrary length

**Given** a completed Visit
**When** the diagnosis or clinical notes are viewed
**Then** they are read-only and display the content captured at completion time

### Story 5.4: Complete Visit & Auto-Generate Invoice

As an assistant,
I want to complete an in-progress visit in one action,
So that the visit is locked and a draft invoice is automatically generated from the performed treatments — ready for review and payment.

**Acceptance Criteria:**

**Given** a Visit in `in_progress` status with at least one Performed Treatment
**When** the Assistant confirms completion
**Then** the Visit transitions to `completed`, `ended_at` is set, Performed Treatments are locked, and exactly one Invoice in `draft` status is created linked to the Visit

**Given** the auto-generated Invoice
**When** its Invoice Items are inspected
**Then** each item mirrors the corresponding Performed Treatment: description, tooth number, quantity, unit price, total_price

**Given** a `completed` Visit
**When** any field edit is attempted
**Then** the operation is rejected — the Visit is locked

**And** a unit test confirms one-and-only-one Invoice is created per Visit completion and its Items match the Performed Treatments exactly

### Story 5.5: Unlock Completed Visit

As a dentist,
I want to unlock a completed visit to correct a mistake before any payment has been taken,
So that clinical and billing errors can be fixed without voiding the entire invoice.

**Acceptance Criteria:**

**Given** a `completed` Visit whose linked Invoice is in `draft` status with no Payments
**When** the Dentist confirms the unlock
**Then** the Visit returns to `in_progress`, Performed Treatments become editable again, and the action is logged with actor, UTC timestamp, and optional reason

**Given** a `completed` Visit whose linked Invoice has at least one Payment
**When** the Dentist attempts to unlock
**Then** the operation is rejected with a message indicating that the Invoice must be voided first

**Given** a `completed` Visit whose Invoice has been Finalized (status `unpaid`)
**When** the Dentist attempts to unlock
**Then** the operation is rejected — Dentist must void the Invoice (FR-25) before unlocking

**Given** an Assistant
**When** they attempt to unlock a completed Visit via any path
**Then** the operation returns `PERMISSION_DENIED`

---

## Epic 6: Treatment Planning *(subject to PRD Open Q1 validation)*

Dentist can plan multi-session treatments, link planned sessions to future appointments, and mark them as performed during visits.

### Story 6.1: Create Treatment Plan

As a dentist,
I want to add planned treatments to a patient's treatment plan with sequence, tooth number, and target date,
So that multi-session procedures are tracked and visible to both the dentist and assistant when preparing appointments.

**Acceptance Criteria:**

**Given** the Dentist opens a Patient File and navigates to the Treatment Plan section
**When** they add a Planned Treatment with procedure name (free text), tooth number, estimated unit price, sequence number, and target date (or "next available")
**Then** the Planned Treatment is created in `planned` status and appears in sequence order on the Patient File

**Given** the Treatment Plan section on the Patient File
**When** viewed
**Then** Planned Treatments are listed in sequence order showing status (`planned`, `scheduled`, `in_progress`, `done`, `cancelled`), procedure name, tooth number, and target date

**And** a unit test confirms a Planned Treatment defaults to `planned` status on creation

### Story 6.2: Link Planned Treatment to Appointment

As an assistant,
I want to attach planned treatments to an appointment when scheduling,
So that the day-view calendar shows what procedure is planned and the dentist can see the session context before the patient arrives.

**Acceptance Criteria:**

**Given** the Assistant is creating or editing a `scheduled` appointment for a patient with a Treatment Plan
**When** they attach one or more Planned Treatments to the appointment
**Then** the Planned Treatments' status transitions from `planned` to `scheduled`

**Given** an appointment with attached Planned Treatments
**When** it appears in the day-view calendar
**Then** the planned-treatment summary column shows the linked procedure names

**Given** a Planned Treatment already linked to another appointment
**When** the Assistant attempts to link it to a second appointment
**Then** the system prevents double-booking of the same Planned Treatment

### Story 6.3: Mark Planned Treatments as Performed

As an assistant or dentist,
I want to mark attached planned treatments as performed during an in-progress visit,
So that the treatment plan progress is updated automatically and a corresponding performed treatment is created for invoicing.

**Acceptance Criteria:**

**Given** an `in_progress` Visit with attached Planned Treatments
**When** the user marks a Planned Treatment as performed
**Then** a Performed Treatment is created on the Visit with the same procedure name, tooth number, unit price, and quantity; the Planned Treatment status transitions from `scheduled` to `done`

**Given** a Treatment Plan viewed after performing a session
**When** the plan progress is shown
**Then** completed sessions are marked `done`, upcoming sessions remain `planned` or `scheduled`, giving a clear multi-session progress view

**And** a unit test confirms marking performed creates exactly one Performed Treatment with fields matching the source Planned Treatment

---

## Epic 7: Invoicing & Payments

Assistant can work with auto-generated invoices, add adjustments, finalize, take cash payments (including partial), and view outstanding balances. Dentist can void invoices.

### Story 7.1: Review & Adjust Draft Invoice

As an assistant,
I want to review the auto-generated draft invoice and add discounts or surcharges before presenting it to the patient,
So that the final invoice reflects any agreed adjustments as explicit line items.

**Acceptance Criteria:**

**Given** a Visit is completed
**When** the Assistant opens the linked Invoice
**Then** it is in `draft` status with one Invoice Item per Performed Treatment (description, tooth number, quantity, unit price, total_price)

**Given** a `draft` Invoice
**When** the Assistant adds an adjustment (discount or surcharge) with a description and amount
**Then** a new Invoice Item is created with the appropriate `adjustment_type`; the Invoice total updates to reflect it (discount reduces, surcharge increases)

**Given** an Invoice that has exited `draft` status
**When** any adjustment is attempted
**Then** the operation is rejected — adjustments are immutable once the Invoice is no longer draft

**And** a unit test confirms Invoice total = sum(treatment items) + sum(adjustments) and that no direct total field is writable

### Story 7.2: Finalize Invoice (No-Payment Path)

As an assistant,
I want to finalize a draft invoice without taking payment yet,
So that I can print or present a receipt to the patient before they pay.

**Acceptance Criteria:**

**Given** a `draft` Invoice
**When** the Assistant finalizes it
**Then** the Invoice transitions to `unpaid`, Invoice Items (including adjustments) are locked from further edit, and the action is logged with actor + UTC timestamp

**Given** a finalized (`unpaid`) Invoice with no Payments
**When** the Dentist unlocks the parent Visit
**Then** the Invoice returns to `draft` and Items become editable again

**Given** a finalized Invoice that has at least one Payment
**When** unlock is attempted
**Then** the operation is rejected — the Dentist must void the Invoice first

### Story 7.3: Record Payment (Full & Partial)

As an assistant,
I want to record a cash payment against an invoice — full or partial — with the amount, date, and optional notes,
So that the patient's outstanding balance is immediately updated and the payment history is fully auditable.

**Acceptance Criteria:**

**Given** a non-void Invoice in any status
**When** the Assistant records a Payment with amount, method (default `cash`), date (default today), and optional notes
**Then** the Payment is saved with `recorded_by_user_id` and UTC timestamp; the Invoice status is derived: `partially_paid` if sum(Payments) < total, `paid` if sum(Payments) ≥ total

**Given** a `draft` Invoice
**When** the first Payment is recorded
**Then** the Invoice is auto-finalized (transitions `draft → partially_paid` or `draft → paid`) — same effect as explicit Finalize

**Given** multiple Payments recorded against one Invoice
**When** the Invoice status is checked
**Then** it reflects the cumulative sum of all Payments

**Given** a recorded Payment
**When** any delete or edit of that Payment is attempted
**Then** the operation is rejected — Payments are immutable; corrections require a compensating Payment or void

**And** a unit test confirms Invoice status is always derived from Payment sum and never stored as a directly writable field

### Story 7.4: Void Invoice

As a dentist,
I want to void an invoice in any status,
So that billing mistakes can be corrected without corrupting the financial history.

**Acceptance Criteria:**

**Given** any non-void Invoice
**When** the Dentist confirms void with a required reason
**Then** the Invoice transitions to `void`, the reason and UTC timestamp are recorded, and the Invoice contributes 0 to the patient's Outstanding Balance

**Given** a voided Invoice with prior Payments
**When** the Invoice is viewed
**Then** the pre-existing Payments are preserved and displayed with a "refund owed" indicator — no automatic refund processing occurs

**Given** a voided Invoice
**When** viewed in financial history
**Then** it remains visible with a `void` status indicator — it is not hidden

**Given** an Assistant
**When** they attempt to void an Invoice via any path
**Then** the operation returns `PERMISSION_DENIED`

### Story 7.5: View Outstanding Balance & Patients with Balance

As an assistant,
I want to see each patient's outstanding balance on their file and view a clinic-wide list of patients who owe money,
So that I can follow up on unpaid balances without manually cross-referencing paper records.

**Acceptance Criteria:**

**Given** a Patient File with one or more non-void Invoices
**When** the Outstanding Balance is displayed
**Then** it equals sum(Invoice.total − sum(Payments)) across all non-void Invoices, computed at read time, and updates within 100ms of a Payment being recorded

**Given** the Outstanding Balance list screen
**When** opened
**Then** it shows only patients with Outstanding Balance > 0, with columns for patient name, balance amount, and days since last Payment

**Given** the Outstanding Balance list
**When** sorted by balance descending
**Then** the patient with the highest balance appears first; when sorted by days-since-last-payment, the longest-overdue patient appears first

**Given** a row in the Outstanding Balance list
**When** tapped
**Then** navigation goes directly to that patient's Patient File

---

## Epic 8: Inventory Management

Assistant can manage consumable inventory — create items, record restocks, make manual adjustments, and see low-stock alerts on the morning dashboard.

### Story 8.1: Create & View Inventory Items

As an assistant,
I want to create inventory items with a name, category, unit, initial quantity, and low-stock threshold,
So that the clinic's consumables are tracked in DocCentral from the start.

**Acceptance Criteria:**

**Given** the Assistant opens the Inventory screen and creates a new item
**When** they enter name, category (`cleaning` / `medicament` / `supply` / `other`), unit (e.g., "box of 100"), initial on-hand quantity, and low-stock threshold
**Then** the item is saved and appears listed under its category

**Given** a low-stock threshold
**When** entered
**Then** it must be ≥ 0; a negative threshold is rejected with a validation error

**Given** the Inventory screen
**When** viewed
**Then** items are grouped by category and show name, unit, current on-hand quantity, and threshold

### Story 8.2: Record Restock Event

As an assistant,
I want to log a restock event when new supplies arrive,
So that the on-hand quantity is updated and there's an auditable record of when stock was received.

**Acceptance Criteria:**

**Given** an Inventory Item
**When** the Assistant records a Restock Event with quantity added, date (default today), optional supplier, and optional notes
**Then** the item's `on_hand` quantity increases by the recorded amount and the event is logged with actor + UTC timestamp

**Given** a Restock Event is saved
**When** the item's history is viewed
**Then** the event appears with quantity added, date, supplier, and actor

**And** an integration test confirms `on_hand` after restock equals previous `on_hand` plus quantity added

### Story 8.3: Manual Stock Adjustment

As an assistant,
I want to directly adjust an inventory item's on-hand quantity to correct counting errors,
So that the recorded stock matches the physical count after a manual audit.

**Acceptance Criteria:**

**Given** an Inventory Item
**When** the Assistant sets a new on-hand quantity and provides a required reason
**Then** the item's `on_hand` updates to the new value and an adjustment log entry records old quantity, new quantity, delta, reason, actor, and UTC timestamp

**Given** an adjustment is submitted without a reason
**When** the Assistant attempts to save
**Then** the save is rejected and the reason field is highlighted as required

**Given** adjustment log entries
**When** viewed
**Then** they are displayed separately from Restock Events — two distinct audit trails

### Story 8.4: Low-Stock Alerts

As an assistant,
I want to see a list of inventory items that have fallen at or below their threshold, with a count badge on the morning dashboard,
So that I know what needs reordering before the day it actually runs out.

**Acceptance Criteria:**

**Given** an Inventory Item whose `on_hand` ≤ `threshold`
**When** the Low Stock view is opened
**Then** the item appears in the list immediately; items above threshold do not appear

**Given** a restock or adjustment that brings `on_hand` above `threshold`
**When** the change is saved
**Then** the item disappears from the Low Stock list immediately — no manual refresh required

**Given** the morning side panel on Today's Calendar
**When** rendered
**Then** a count badge shows the number of items currently at or below threshold; tapping it navigates to the Low Stock view

---

## Epic 9: File Attachments

Assistant can upload X-ray images and PDFs to patients or visits, and preview them from the Patient File or Visit view.

### Story 9.1: Upload Attachment to Patient or Visit

As an assistant,
I want to upload a PDF or image file to a patient or visit record,
So that X-rays, lab photos, and treatment diagrams are stored alongside the clinical record and available offline.

**Acceptance Criteria:**

**Given** the Assistant is on a Patient File or Visit view
**When** they upload a file (PDF, JPG, or PNG, max 10 MB)
**Then** the file is stored locally, an Attachment record is created linked to the Patient or Visit, and the attachment appears in the attachments list

**Given** a file exceeding 10 MB
**When** the Assistant attempts to upload it
**Then** the upload is rejected with a clear error message before any data is written

**Given** an unsupported file type (e.g., `.docx`, `.xlsx`)
**When** the Assistant attempts to upload it
**Then** the upload is rejected with a message indicating only PDF, JPG, and PNG are accepted

**Given** the device is offline when an attachment is uploaded
**When** the file is saved locally
**Then** the Attachment record is created with `sync_status = pending`; it is queued for upload to Supabase storage when connectivity resumes

### Story 9.2: View & Preview Attachment

As an assistant or dentist,
I want to preview images inline and open PDFs in the system viewer from the Patient File or Visit view,
So that I can review X-rays and documents without leaving DocCentral.

**Acceptance Criteria:**

**Given** an Attachment list on a Patient File or Visit view
**When** the user taps an image attachment (JPG or PNG)
**Then** the image renders inline within the DocCentral UI

**Given** an Attachment list
**When** the user taps a PDF attachment
**Then** the PDF opens in the system's default PDF viewer

**Given** the Attachments section on a Patient File
**When** rendered
**Then** each attachment shows its filename, file type, upload date, and the user who uploaded it

---

## Epic 10: Day Closeout

Assistant can close the day with a cash reconciliation (expected vs. counted), and Dentist can reopen a closed day to correct a missed payment.

### Story 10.1: Day Closeout Summary

As an assistant,
I want to see a real-time summary of today's completed visits, payments, and outstanding invoices before closing the day,
So that I know exactly what cash to expect when I count the till.

**Acceptance Criteria:**

**Given** the Assistant opens the Day Closeout screen at any point during the day
**When** it renders
**Then** it shows: count of `completed` Visits, sum of Payments recorded today broken down by method, sum of new Invoices generated today, and count of outstanding (`unpaid` / `partially_paid`) Invoices created today

**Given** a new Payment or Visit completion happens while the Closeout screen is open
**When** the data changes
**Then** the summary updates in real time without requiring a manual refresh

**Given** the summary
**When** scoped
**Then** it reflects only the current Clinic and current calendar date

### Story 10.2: Record & Confirm Day Closeout

As an assistant,
I want to enter the counted cash amount and confirm the day closeout,
So that there is a permanent record of expected vs. actual cash with any discrepancy noted.

**Acceptance Criteria:**

**Given** the Day Closeout screen
**When** the Assistant enters a counted cash amount and confirms
**Then** a Day Closeout record is created with: expected cash (sum of today's `cash` Payments), counted cash (entered value), delta (expected − counted), actor, and UTC timestamp

**Given** one Day Closeout record already exists for the current date
**When** the Assistant attempts to create a second one
**Then** the operation is rejected — one closeout per Clinic per date

**Given** the delta is non-zero (counted ≠ expected)
**When** the Assistant confirms
**Then** the discrepancy is flagged visually on the confirmation screen but does not block the closeout from being recorded

**And** a unit test confirms the delta is always computed as expected − counted and is never manually set

### Story 10.3: Reopen Closed Day

As a dentist,
I want to reopen a closed day to correct a missed payment recorded after closing,
So that the financial record for that day is accurate without creating a new closeout.

**Acceptance Criteria:**

**Given** a Day Closeout record for a past or current date
**When** the Dentist confirms reopen with an optional reason
**Then** the closeout's `counted_cash` field is unlocked for re-entry and the reopen is logged with actor, UTC timestamp, and reason

**Given** the Dentist re-enters the counted cash and confirms again
**When** saved
**Then** the Day Closeout record is updated with the new counted cash, new delta, and a new timestamp

**Given** an Assistant
**When** they attempt to reopen a closed day via any path
**Then** the operation returns `PERMISSION_DENIED`

---

## Epic 11: Offline-First Sync

All workflows function fully without internet (offline-capable from Epic 1's Drift foundation); this epic delivers the complete Supabase sync engine — push, pull, and conflict resolution surfacing to users.

### Story 11.1: Full Offline Functionality Verification

As a clinic user,
I want every DocCentral workflow to function completely without an internet connection,
So that the clinic is never blocked by connectivity issues during patient care.

**Acceptance Criteria:**

**Given** the device has no network connectivity
**When** the Assistant completes UJ-2 (receive patient, open Patient File), UJ-3 (wrap up visit and take payment), UJ-4 (handle cancellation), and UJ-10 (day closeout)
**Then** all four flows complete successfully with data persisted to the local Drift database

**Given** any screen in the app while offline
**When** rendered
**Then** no screen is gated, disabled, or shows an "offline" error — except the initial sign-in on a fresh device

**Given** records created or modified while offline
**When** connectivity is restored
**Then** all records have `sync_status = pending` and are queued for push to Supabase

**And** an end-to-end test with network access disabled confirms UJ-2, UJ-3, UJ-4, and UJ-10 complete without errors

### Story 11.2: Push Local Changes to Supabase

As a clinic user,
I want pending local changes to sync automatically to Supabase when connectivity is restored,
So that the remote backup is always up to date without any manual action.

**Acceptance Criteria:**

**Given** the device regains network connectivity with pending local changes (`sync_status = pending`)
**When** the sync engine detects connectivity
**Then** pending records are pushed to Supabase in batches; after each successful push, the record's `sync_status` transitions to `synced`

**Given** a push attempt fails (network error, Supabase timeout)
**When** the failure occurs
**Then** the sync engine retries with exponential backoff, capped at 10 minutes; local data is not corrupted by the failure

**Given** a batch push is in progress
**When** the user continues using the app
**Then** the sync is non-blocking — all UI interactions remain responsive

### Story 11.3: Pull Remote Changes from Supabase

As a clinic user,
I want the app to pull remote changes from Supabase incrementally when online,
So that changes made on another device are reflected locally without data loss.

**Acceptance Criteria:**

**Given** the device is online and a remote change exists since the last successful pull
**When** the sync engine pulls
**Then** remote changes are applied to the local Drift database incrementally (only records changed since last pull timestamp)

**Given** a pull fails mid-way (network drop)
**When** the failure occurs
**Then** local data already written is valid and consistent; the pull resumes from the last safe checkpoint on next attempt

**Given** a successful pull
**When** the user views affected screens (e.g., Patient File, calendar)
**Then** the updated data is visible without requiring a manual refresh

### Story 11.4: Conflict Resolution & User Notification

As a clinic user,
I want last-write-wins conflict resolution based on UTC timestamps, with explicit warnings for financial record conflicts,
So that sync conflicts are resolved automatically for most data while I am alerted when invoices or payments may have diverged.

**Acceptance Criteria:**

**Given** a local pending change and a newer remote change on the same non-financial record
**When** conflict resolution runs
**Then** the remote change wins (higher UTC `updated_at`); the local change is discarded silently

**Given** a local change is newer than the remote change on a non-financial record
**When** conflict resolution runs
**Then** the local change wins and is pushed to Supabase

**Given** a conflict on an Invoice or Payment record
**When** detected during sync
**Then** the conflict is surfaced as a visible warning to the user (not silently resolved); the system applies last-write-wins as a default but the warning remains until dismissed

**Given** any conflict resolution event
**When** it occurs
**Then** no data is permanently lost — the losing version is logged for forensic use
