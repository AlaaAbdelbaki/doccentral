---
title: DocCentral MVP
status: final
created: 2026-05-21
updated: 2026-05-21
---

# PRD: DocCentral MVP

*Working title — confirm.*

## 0. Document Purpose

This PRD scopes the **Minimum Viable Product** of DocCentral, a desktop-first, offline-capable dental clinic management app, French-primary, built for a single dental practice in Tunisia (solo dentist + combined-role assistant). Built as a learning project with a real first customer, with deliberate architectural optionality for commercialization later. This PRD supersedes `docs/` and `todo.md` where they conflict. Inline `[ASSUMPTION]` and `[NEEDS VALIDATION WITH CLINIC]` tags mark inferences requiring confirmation. Downstream artifacts (epics, stories, tickets) live in **beads (`bd`)**, not markdown.

## 1. Vision

DocCentral runs the day-to-day operations of a small dental practice: appointments, patient files, clinical visits, treatments, invoicing, cash payments, and consumable inventory. It works fully offline; sync across devices via Supabase resumes when connectivity returns. The MVP wins by being faster and more legible than the current setup — paper folders, an Excel calendar, and ad-hoc WhatsApp threads — for four felt pains: payments slipping through the cracks, calendar drift, inventory blind spots, and patient history that is hard to retrieve when a returning patient is in the chair. Within 6–12 months success means the family member's clinic uses DocCentral as their actual primary system over paper for the workflows it covers — earning the right to extend toward commercialization.

## 2. Target Users

### 2.1 Primary Persona — The Assistant (combined role)

Receptionist, secretary, and chairside dental assistant — one person, all three jobs — at a solo-dentist practice in Tunisia. She is the most active app user: runs the calendar, checks patients in, prepares files, supports the dentist during procedures, captures what was done after the visit, takes cash payments, records partial-payment balances, monitors consumable stock, closes the day. Current tooling: paper, Excel, WhatsApp. Speaks French primarily, Arabic for patient interaction.

### 2.2 Secondary Persona — The Dentist

The sole clinical practitioner and clinic owner. Performs procedures, decides multi-session treatment plans, reviews the day's roster. Wants visibility over everything — appointments, patient histories, treatment plans, financial state — but is a low-frequency user of administrative screens. The assistant prepares his day; he consumes that preparation. [NEEDS VALIDATION WITH CLINIC: how much clinical-note entry the dentist does himself vs. dictates to the assistant.]

### 2.3 Jobs To Be Done

**The Assistant**
- Know who is coming in today and what for, without flipping through paper folders.
- Find a returning patient's prior visits, diagnoses, and outstanding balance in seconds.
- Record what happened during a visit before the next patient walks in.
- Take cash payments and capture partial-payment situations without losing track of balances.
- See — at a glance — which patients owe the clinic money.
- See when consumables are running low *before* the day they run out.
- Close the day knowing the cash count matches what was collected.

**The Dentist**
- Walk in and see the day's plan without asking.
- Look up a patient's last visit and treatment plan before they sit in the chair.
- Capture what was diagnosed and performed during a visit, while it's fresh.
- Plan multi-session treatments (e.g., a three-session root canal) and have those sessions reliably scheduled.

### 2.4 Key User Journeys

Improvised UJs are tagged `[NEEDS VALIDATION]`; the cancellation flow is designed-from-scratch to address the calendar-drift pain.

- **UJ-1. The Assistant opens the day.** *[NEEDS VALIDATION]*
  Launches DocCentral, lands on Today's Calendar. Sees the day's appointments chronologically — each row shows patient name, time, planned-treatment summary (if any), and flags (awaiting lab work, partial payment due from prior visit). A side panel lists low-stock consumables and any appointments awaiting lab delivery today.

- **UJ-2. The Assistant receives a patient and prepares the Patient File.**
  Patient walks in. Assistant taps the appointment row → **Check In**. The same screen exposes the **Patient File**: last 3 Visits, current Treatment Plan, Outstanding Balance, Attachments. She glances, brings the patient to the dentist.

- **UJ-3. The Assistant wraps up a Visit and takes payment.**
  Dentist signals done. Assistant opens the Visit → marks Performed Treatments (from the Planned list, or ad-hoc) → adds a brief clinical note if dictated → marks Visit `completed`. The system auto-generates an Invoice in `draft`. She reviews it with the patient, applies any discount/surcharge as line items, and either: (a) takes full cash → Invoice → `paid`; (b) takes partial cash → records the amount → Invoice → `partially_paid`, balance owed visible on the Patient File and on the Outstanding Balance list. Optionally schedules the next Appointment from the same screen.

- **UJ-4. The Assistant handles a cancellation.** *[Designed-from-scratch.]*
  Phone rings: "I can't come tomorrow at 10." Assistant searches the calendar by patient name → finds the Appointment → taps **Cancel** → picks a reason (`patient_cancelled` / `no_show` / `clinic_cancelled` / `rescheduled`). If `rescheduled`, the system prompts to create the replacement Appointment immediately and links the two via `rescheduled_to_appointment_id`. The Cancellation is recorded on the Patient File with timestamp + reason + actor. The slot is freed on the calendar in the same gesture. **Edge case:** if the patient has an Outstanding Balance and is a repeat no-show, the Patient File flags the pattern when preparing future Appointments.

- **UJ-5. The Dentist consumes the day's plan.** *[NEEDS VALIDATION]*
  Opens DocCentral → lands on Today's Calendar (same surface as UJ-1, possibly with denser clinical detail). Taps into any Patient File to review history before they arrive.

- **UJ-6. The Dentist records what was done.** *[NEEDS VALIDATION]*
  After a procedure, the dentist opens the active Visit → adds diagnosis + clinical note + marks Performed Treatments (with tooth numbers for dental procedures) → returns to the calendar.

- **UJ-7. The Dentist plans a multi-session treatment.** *[NEEDS VALIDATION]*
  During a Visit, the dentist decides three sessions are needed. Opens the Patient's **Treatment Plan** → adds three Planned Treatments with target dates or "next available". The assistant later schedules the corresponding Appointments. The plan shows which sessions are done, scheduled, and pending.

- **UJ-8. Inventory low-stock alert turns into a reorder note.**
  Assistant glances at the morning side panel — "Cotton rolls" is below threshold → notes a reorder externally (WhatsApp the supplier) → records a future **Restock Event** when the supply arrives, updating on-hand quantity. [NEEDS VALIDATION: auto-decrement-per-treatment vs manual only.]

- **UJ-9. The Assistant finds out who owes the clinic money.**
  Opens **Patients with Outstanding Balance** → sees the list sorted by balance descending or by days-since-last-payment → picks one → opens the Patient File → optionally records a Payment.

- **UJ-10. The Assistant closes the day.**
  End of day. Opens **Day Closeout** → sees the day's summary: completed Visits, total cash expected (sum of Payments dated today, method `cash`), space to enter counted cash, optional discrepancy note. Confirming creates a Day Closeout record. Reopening requires explicit Dentist action.

## 3. Glossary

Downstream artifacts must use these terms exactly.

- **Clinic.** Tenant root. One Clinic per MVP deployment; schema supports many. Owns all other entities.
- **User.** Person with login credentials, scoped to a Clinic. MVP: Dentist and Assistant.
- **Role.** Named permission bundle scoped to a Clinic. MVP UI surfaces Dentist and Assistant; Nurse exists in the role table for forward-compat but has no MVP UX.
- **Patient.** Person whose dental care is managed by the Clinic.
- **Patient File.** Unified view of a Patient: identity + history (Visits, Performed Treatments, Invoices, Payments, Outstanding Balance) + active Treatment Plan + Attachments.
- **Appointment.** Scheduled future time slot with a Patient and an assigned User. Statuses: `scheduled`, `checked_in`, `completed`, `no_show`, `cancelled`, `rescheduled`.
- **Visit.** Clinical encounter that actually happens — distinct from the Appointment that triggered it. Lifecycle: `checked_in → in_progress → completed`. Created when an Appointment is checked in. The legacy `BILLED` state from `usecases.md` is dropped; billed-ness is derivable from the linked Invoice.
- **Procedure.** A type of dental act (e.g., extraction, composite filling, scaling). Entered as free text in MVP. A configurable Procedure catalog is deferred (Open Q2).
- **Performed Treatment.** A Procedure performed during a Visit. Records: tooth number (where applicable), procedure name, unit price, quantity. Locked when the parent Visit transitions to `completed`.
- **Treatment Plan.** Sequence of **Planned Treatments** for a Patient, spanning one or more future Visits. Planned Treatment statuses: `planned`, `scheduled` (linked to an Appointment), `in_progress`, `done`, `cancelled`.
- **Invoice.** Financial artifact of a `completed` Visit. Auto-created when the Visit transitions to `completed`. Statuses: `draft`, `unpaid`, `partially_paid`, `paid`, `void`. Status is **derived** from the lifecycle state and Payments, never manually set, except for `void` (explicit Dentist action).
- **Invoice Item.** Line on an Invoice — either a snapshot of a Performed Treatment, or a manual adjustment (discount, surcharge). Adjustments are line items, never edits to the Invoice total.
- **Payment.** First-class record of money received against an Invoice. Records: amount, method (default `cash`), date, `recorded_by_user_id`, optional notes. Multiple Payments per Invoice are allowed.
- **Outstanding Balance.** Per Patient: sum of (Invoice.total − sum(Payments)) over the Patient's non-`void` Invoices. Computed, never stored.
- **Cancellation.** Event on an Appointment recording: reason (`patient_cancelled` / `no_show` / `clinic_cancelled` / `rescheduled`), timestamp, actor, optional notes. If reason = `rescheduled`, `rescheduled_to_appointment_id` is required.
- **Attachment.** File (image or PDF) associated with a Patient or a Visit. Stored as binary blob locally, mirrored to Supabase storage on sync. Manual upload only.
- **Lab Work Flag.** Optional status on an Appointment: `awaiting_lab` with a free-text note. No structured lab-order entity in MVP.
- **Inventory Item.** A Clinic-tracked consumable — cleaning products, medicaments, basic supplies (cotton rolls, gloves, anesthetic). Records: name, category, unit, on-hand quantity, low-stock threshold.
- **Restock Event.** Logged increase to an Inventory Item's on-hand quantity: quantity added, date, optional supplier, actor.
- **Low-Stock Alert.** Computed surface listing Inventory Items where `on_hand ≤ threshold`.
- **Day Closeout.** End-of-day record per Clinic per date: expected cash (sum of today's `cash` Payments), counted cash, delta, optional notes, actor, timestamp.
- **Sync Status.** Per-record marker (`pending`, `synced`, `conflict`) used by the offline-first sync engine. Combined with `updated_at` for last-write-wins resolution.

## 4. Features

Unless explicitly restricted, FRs are permitted to **both roles**. Restricted operations are enumerated in FR-38. Each FR is imperative; the actor is named when restriction applies. FRs are numbered globally for stable cross-reference.

### 4.1 Authentication & Clinic Bootstrap

**Description.** A User signs in with email + password to a Supabase-backed session. First sign-up creates the Clinic, the initial Dentist User, and default Role definitions. Subsequent Users (the Assistant) are added by the Dentist from Clinic Settings. Sessions persist across app restarts. Realizes UJ-1, UJ-5.

#### FR-1: First-run Clinic provisioning

On a fresh install with no local Clinic data, sign-up creates the Clinic, the initial Dentist User, and Role definitions for Dentist, Assistant, and Nurse.

**Consequences:**
- A Clinic record is created with locale defaults: language `fr-TN`, currency `TND`.
- The signing-up User is assigned the Dentist Role with `is_clinic_owner = true`.
- Role records exist for Dentist, Assistant, and Nurse with their default permission bundles.

#### FR-2: Email + password sign-in with persistent session

Sign in with email + password. The session persists across app restarts until explicit sign-out.

**Consequences:**
- Reopening the app reuses the previous session; the User lands on Today's Calendar without re-authentication.
- Sign-out clears the session and returns to the sign-in screen.
- Sign-in works offline against locally cached credentials [ASSUMPTION: Supabase refresh tokens cached locally; revisit if false]. [NEEDS VALIDATION: is "online sign-in required once per week" acceptable to the Clinic?]

#### FR-3: Add a Clinic staff User

The Dentist adds a new Assistant or Nurse User from Clinic Settings: name, email, Role, initial password.

**Consequences:**
- A new User record is created, linked to the Clinic, with the assigned Role.
- The new User can sign in and is constrained by their Role's permissions.

### 4.2 Patient Management

**Description.** The Patient File unifies identity, history, Treatment Plan, Outstanding Balance, and Attachments. New Patients support a freeform `history_notes` backfill — the family member's clinic migrates from paper, see §10. Realizes UJ-2, UJ-9.

#### FR-4: Create a Patient

Create a Patient with required fields: first name, last name, date of birth, phone number. Email optional.

**Consequences:**
- Cannot save with any required field missing.
- Phone is stored as entered; search treats it as a string.
- A Patient is owned by exactly one Clinic.

#### FR-5: Backfill freeform history on Patient creation

Paste or type the contents of the paper file into a `history_notes` text field at Patient creation. Not parsed.

**Consequences:**
- A `history_notes` field is shown prominently in the Patient File header (above-the-fold on default 1280×800 desktop window).
- No structured parsing is attempted.

#### FR-6: Search Patients by name or phone

Search by partial first or last name, or partial phone number. Results return within 300ms on a local DB of up to 10,000 Patients.

**Consequences:**
- "tra" returns "Trabelsi, Mohamed" within 300ms.
- Last 4 phone digits return matches.
- Soft-deleted Patients are excluded.

#### FR-7: Patient File view

Opening a Patient renders: identity, history notes, most recent 5 Visits, active Treatment Plan, Outstanding Balance, Attachments list. Sections expand on demand.

**Consequences:**
- All sections render within 500ms on a Patient with up to 50 Visits.
- Outstanding Balance is computed at read time, not stored.

#### FR-8: Soft-delete a Patient

**Restricted to the Dentist.** Soft-deleted Patients are hidden from default lists and search but retained for financial integrity.

**Consequences:**
- The Patient no longer appears in search or calendar.
- Invoices and Payments remain visible in financial views.
- `deleted_at` is set; no physical removal.

#### FR-46: Edit a Patient

Edit a Patient's identity fields and `history_notes`.

**Consequences:**
- Required fields cannot be cleared by edit.
- An edit log entry records actor, timestamp, fields changed (field-name level).

### 4.3 Calendar & Appointments

**Description.** Day-view and week-view calendars. The Assistant creates, edits, reschedules, and cancels Appointments. Lab Work Flags surface in calendar views. Realizes UJ-1, UJ-2, UJ-4, UJ-5.

#### FR-9: Create an Appointment

Create an Appointment for a Patient with start time, end time (default duration 30 min [ASSUMPTION]), assigned User (default: Dentist), reason (free text), optional notes.

**Consequences:**
- Overlapping Appointments for the same assigned User require an explicit override confirmation [ASSUMPTION: overlap detection is on].
- An Appointment is created in `scheduled` status.

#### FR-10: Day-view calendar

The default landing surface (Today's Calendar) shows the current day's Appointments as a time-grid [ASSUMPTION], each row showing patient name, time, planned-treatment summary, status, Lab Work Flag, Outstanding Balance indicator.

**Consequences:**
- The day view loads within 500ms.
- Status changes (check-in, completion, cancellation) update the view within 200ms.

#### FR-11: Week-view calendar

A week view shows Appointments across 7 days, navigable forward and backward.

**Consequences:**
- Loads within 1s.
- Status (scheduled / checked-in / completed / cancelled) is visually distinct.

#### FR-12: Check in a Patient

Tap **Check In** on a `scheduled` Appointment when the Patient arrives. Transitions the Appointment to `checked_in` and creates a Visit in `checked_in` status.

**Consequences:**
- A new Visit record is created, linked to the Appointment and Patient.
- The Appointment's status updates to `checked_in`.
- Visit `started_at` is set to `now()`.

#### FR-13: Cancel an Appointment

Cancel a `scheduled` Appointment with a required reason (`patient_cancelled` / `no_show` / `clinic_cancelled` / `rescheduled`). For `rescheduled`, the replacement Appointment must be created in the same flow. Realizes UJ-4.

**Consequences:**
- The Appointment transitions to `cancelled` or `rescheduled`.
- A Cancellation record stores timestamp, actor, reason, optional notes.
- For `rescheduled`, the new Appointment is linked via `rescheduled_to_appointment_id`.
- The cancelled slot becomes free in the calendar (no longer renders as an occupied block).

#### FR-14: Flag an Appointment as awaiting lab work

Set the **Lab Work Flag** with a free-text note (e.g., "implant from LabX, ETA 2026-06-03").

**Consequences:**
- The flag appears in calendar views and the morning side panel.
- No structured lab-order entity is created.

#### FR-47: Edit a scheduled Appointment

Edit a `scheduled` Appointment's time, duration, assigned User, reason, Lab Work Flag, attached Planned Treatments, notes. Editing `checked_in`, `completed`, `cancelled`, or `rescheduled` Appointments is rejected — those require the formal workflows (cancellation, unlock).

**Consequences:**
- An edit to non-`scheduled` Appointment returns a domain-layer rejection with the error code `APPT_NOT_EDITABLE`.
- Time / duration edits trigger the same overlap check as FR-9.
- An edit log entry records actor, timestamp, fields changed.

#### FR-48: Filter Appointments

Filter the calendar by date range, Patient, status, and assigned User. Filters compose.

**Consequences:**
- Filtering by Patient name returns all of that Patient's Appointments in range.
- Filtering by status `cancelled` returns only cancelled Appointments.
- Combined filters return the intersection.
- A single action clears all filters.

### 4.4 Visit Workflow

**Description.** Visits capture what actually happened: Performed Treatments, clinical notes, diagnosis. Lifecycle `checked_in → in_progress → completed`. Once `completed`, the Visit is locked; only the Dentist can unlock, and only if no Payment exists on the linked Invoice. Realizes UJ-3, UJ-6.

#### FR-15: Mark a Visit as in-progress

Transition a `checked_in` Visit to `in_progress` when the Patient enters the operating room.

**Consequences:**
- Visit status changes to `in_progress`.
- An `in_progress_at` timestamp is captured.

#### FR-16: Add Performed Treatments during a Visit

Add Performed Treatments to an `in_progress` Visit: tooth number (where applicable), procedure name (free text — see Open Q2), unit price, quantity.

**Consequences:**
- Treatments can be added, edited, removed while the Visit is `in_progress`.
- Each Treatment is timestamped and attributed to the recording User.

#### FR-17: Record clinical notes and diagnosis

Edit the `diagnosis` field and `clinical_notes` field while the Visit is `in_progress`.

**Consequences:**
- Both fields support multi-line text.
- Edits autosave on field blur [ASSUMPTION].

#### FR-18: Complete a Visit

Transition an `in_progress` Visit to `completed`. On completion, the system auto-generates an Invoice in `draft` with Invoice Items copied from the Visit's Performed Treatments.

**Consequences:**
- Visit status becomes `completed`.
- An Invoice in `draft` exists, linked to the Visit, with one Invoice Item per Performed Treatment.
- Performed Treatments are locked from further edit.
- Visit `ended_at` is set.

#### FR-19: Unlock a completed Visit

**Restricted to the Dentist.** Unlock a `completed` Visit only if the linked Invoice is in `draft` status (no Finalize, no Payments).

**Consequences:**
- Unlock returns the Visit to `in_progress` and the Invoice to `draft` for edit.
- The action is logged with actor, timestamp, optional reason.
- Unlock is rejected if any Payment exists or if the Invoice has been Finalized (FR-49) — Dentist must void the Invoice (FR-25) first.

### 4.5 Treatment Planning *(may reduce — see Open Q1)*

**Description.** A Treatment Plan captures "this Patient needs 3 sessions for a root canal". Planned Treatments link to Appointments; when the Visit happens, marking them performed copies them to Performed Treatments. Realizes UJ-7. **[NEEDS VALIDATION: confirm dentist uses multi-session plans today.]**

#### FR-20: Create a Treatment Plan

Add Planned Treatments to a Patient: procedure name (free text — see Open Q2), tooth number, estimated unit price, sequence number, target date or "next available".

**Consequences:**
- A Planned Treatment is created in `planned` status.
- Planned Treatments are listed in sequence order on the Patient File.

#### FR-21: Link a Planned Treatment to an Appointment

When creating an Appointment for a Patient, attach one or more Planned Treatments; their status transitions to `scheduled`.

**Consequences:**
- The Appointment shows the attached Planned Treatments as its "planned for this Visit" list.
- The day-view planned-treatment summary draws from this list.

#### FR-22: Mark Planned Treatments as performed during a Visit

In an `in_progress` Visit, mark attached Planned Treatments as performed. Each marked-performed Planned Treatment creates a corresponding Performed Treatment on the Visit and transitions its own status to `done`.

**Consequences:**
- A new Performed Treatment is created with the same fields (procedure, tooth, price, quantity).
- The Planned Treatment status transitions `scheduled → done`.

### 4.6 Invoicing & Payments

**Description.** Invoices auto-generate from `completed` Visits. Status is **derived** from lifecycle + sum(Payments). Partial payments are first-class. Refunds and credit notes are out of scope; voiding an Invoice with prior payments surfaces "refund owed" but does not process it. Realizes UJ-3, UJ-9.

#### FR-23: Auto-generate Invoice on Visit completion

When a Visit transitions to `completed` (FR-18), an Invoice in `draft` is created, with Invoice Items copied from the Visit's Performed Treatments.

**Consequences:**
- One Invoice per `completed` Visit.
- Invoice Items copy: description, tooth number, quantity, unit price, total_price.
- Invoice total = sum(Invoice Items with `adjustment_type IS NULL`) + sum(adjustments).

#### FR-24: Add or edit Invoice adjustments (discount/surcharge)

Add Invoice Items with `adjustment_type = discount` or `surcharge` while the Invoice is in `draft`. Adjustments impact the Invoice total directly (discount negative, surcharge positive).

**Consequences:**
- A discount line reduces the Invoice total.
- Adjustments are immutable once the Invoice exits `draft`.

#### FR-25: Void an Invoice

**Restricted to the Dentist.** Void an Invoice in any status. Voiding records a reason and timestamp.

**Consequences:**
- A voided Invoice contributes 0 to its Patient's Outstanding Balance.
- A voided Invoice remains visible in financial history with a `void` indicator.
- Pre-existing Payments on a voided Invoice are preserved and surfaced as "refund owed" — refund processing is out of MVP scope.

#### FR-26: Record a Payment

Record a Payment against an Invoice in any non-`void` status: amount, method (default `cash`), date (default today), optional notes. Multiple Payments per Invoice are allowed. A Payment on a `draft` Invoice **auto-finalizes** it (same effect as FR-49).

**Consequences:**
- The Payment is timestamped and attributed (`recorded_by_user_id`).
- Invoice status is derived:
  - `draft` while no Payment exists AND the Invoice has not been Finalized (FR-49).
  - `unpaid` once the Invoice is Finalized (by FR-49 or by first Payment) AND sum(Payments) = 0.
  - `partially_paid` when 0 < sum(Payments) < Invoice.total.
  - `paid` when sum(Payments) ≥ Invoice.total.
  - `void` only via FR-25, terminal.
- Invoice Items become immutable as soon as the Invoice exits `draft`.
- Payments cannot be deleted; corrections require a compensating Payment or void.

#### FR-27: View Outstanding Balance per Patient

The Patient File shows the Outstanding Balance — sum(Invoice.total − sum(Payments)) across non-`void` Invoices.

**Consequences:**
- Computed at read time, not stored.
- Updates within 100ms of a Payment being recorded.

#### FR-28: List Patients with Outstanding Balance

A dedicated screen lists Patients with Outstanding Balance > 0, sortable by balance descending and by days-since-last-Payment.

**Consequences:**
- Excludes Patients with balance = 0.
- Days-since-last-Payment uses the most recent Payment date across the Patient's Invoices.

#### FR-49: Finalize an Invoice (explicit, no-payment path)

Finalize an Invoice in `draft` status without recording a Payment (e.g., to print a receipt before payment). Finalize is one-way.

**Consequences:**
- The Invoice transitions `draft → unpaid`.
- Invoice Items (including adjustments) lock from further edit.
- The action is logged with actor + timestamp.
- Re-opening requires the Dentist's Visit unlock (FR-19), allowed only if no Payment exists.

### 4.7 Inventory (Consumables)

**Description.** Manual stock tracking for consumables — cleaning products, medicaments, basic supplies. The Assistant manually adjusts quantities; the system surfaces Low-Stock Alerts. No per-Treatment auto-decrement, no batch/expiry. Realizes UJ-8. **[NEEDS VALIDATION: confirm consumables scope and auto-decrement preference.]**

#### FR-29: Create an Inventory Item

Create an Inventory Item: name, category (`cleaning` / `medicament` / `supply` / `other` [ASSUMPTION]), unit (e.g., "box of 100"), initial on-hand quantity, low-stock threshold.

**Consequences:**
- Items are listed under their category.
- Threshold must be ≥ 0.

#### FR-30: Record a Restock Event

Record a Restock Event: quantity added, date (default today), optional supplier, optional notes.

**Consequences:**
- The Inventory Item's `on_hand` increases by the recorded quantity.
- The event is logged with actor + timestamp.

#### FR-31: Manual stock adjustment

Directly adjust an Inventory Item's on-hand quantity to correct counting errors. Adjustments require a reason.

**Consequences:**
- Adjustments log separately from Restock Events.
- Each entry records: old quantity, new quantity, delta, reason, actor, timestamp.

#### FR-32: Low-Stock Alerts surface

A computed list of Inventory Items where `on_hand ≤ threshold` appears on a dedicated **Low Stock** view and as a count badge on the morning side panel (UJ-1).

**Consequences:**
- Items appear immediately when on_hand crosses the threshold.
- The list refreshes on every stock change.

### 4.8 Attachments

**Description.** Generic file attachments on Patients or Visits — scanned X-rays, treatment-plan diagrams, lab photos. Manual upload only; no specialized imaging tooling.

#### FR-33: Upload an Attachment

Upload a file (PDF / JPG / PNG, max 10 MB [ASSUMPTION]) to a Patient or a Visit. Stored locally; queued for sync to Supabase storage.

**Consequences:**
- The Attachment record references the file by ID; the binary is stored separately.
- Attachments appear in the Patient File or Visit view.

#### FR-34: View an Attachment

Preview (image) or open (PDF) an Attachment from the Patient File or Visit view.

**Consequences:**
- Images render inline.
- PDFs open in the system default viewer [ASSUMPTION].

### 4.9 Day Closeout

**Description.** End-of-day cash reconciliation between expected (sum of today's `cash` Payments) and counted (entered by the Assistant). Realizes UJ-10.

#### FR-35: Generate Day Closeout summary

At any time, the Day Closeout screen shows the day's: count of `completed` Visits, sum of Payments recorded today by method, sum of new Invoices generated today, count of Outstanding (unpaid/partially_paid) Invoices created today.

**Consequences:**
- The summary updates in real time as the day progresses.
- Scopes to the current Clinic and date.

#### FR-36: Record Day Closeout

The Assistant enters counted cash and optional notes, then confirms. The system creates a Day Closeout record (expected, counted, delta, actor, timestamp).

**Consequences:**
- One Day Closeout per Clinic per date.
- A non-zero delta is flagged in the UI but does not block confirmation.

#### FR-37: Reopen a closed day

**Restricted to the Dentist.** Reopen a closed day to correct a missed Payment recorded after closing.

**Consequences:**
- Reopen unlocks the Day Closeout's `counted_cash` for re-entry.
- The action is logged with actor, timestamp, optional reason.

### 4.10 Roles & Permissions

**Description.** Two MVP roles (Dentist, Assistant) with permission checks enforced at three layers per `.rules/07-permissions.md`. The Nurse role is defined in the data model but has no MVP UX.

#### FR-38: Permission contract

Operations restricted to the **Dentist** role: unlock a `completed` Visit (FR-19), void an Invoice (FR-25), soft-delete a Patient (FR-8), add or remove Users (FR-3), reopen a closed day (FR-37). The **Assistant** role can perform every other MVP operation in this PRD — create / edit Patients, create / edit / cancel Appointments, run Visits including Performed Treatments and clinical notes, create Treatment Plans, add Invoice adjustments, Finalize Invoices, record Payments, upload Attachments, manage Inventory, set the Lab Work Flag, open and confirm Day Closeouts.

**Consequences:**
- An Assistant attempting any Dentist-restricted operation is rejected at the domain layer with the error code `PERMISSION_DENIED`.
- The UI hides or disables Dentist-restricted controls for the Assistant.
- A unit test enumerates the Assistant's allowed operations and confirms each is permitted at the domain layer.

#### FR-39: Permission enforcement at three layers

The same permission predicate is evaluated at **router/route-guard**, **Riverpod provider** (UI control visibility / data exposure), and **domain operation** layers — no permission-logic drift between layers. Per `.rules/07-permissions.md`.

**Consequences:**
- A unit test confirms, for each restricted operation, that all three layers use the identical permission predicate function.
- A restricted route is blocked at the router for unauthorized roles (deep-link navigation is rejected).
- A Riverpod provider exposing data for a restricted screen returns empty / unauthorized for users without the permission.
- The domain operation rejects the action even when the UI was bypassed.

### 4.11 Offline-First & Multi-Device Sync

**Description.** The app works fully without internet. Drift is the local source of truth. Supabase is the sync target. Sync is asynchronous, non-blocking. Last-write-wins conflict resolution based on `updated_at`. Multi-device sync targets two desktop machines [NEEDS VALIDATION: does the clinic actually have two devices? See Open Q3].

#### FR-40: Full functionality offline

All FRs in this PRD work without an internet connection on the local Drift database. Sync to Supabase resumes automatically when connectivity returns.

**Consequences:**
- An end-to-end test with network disabled completes UJ-2, UJ-3, UJ-4, UJ-10 successfully.
- No UI surface is gated by online status, except initial sign-in on a fresh device (FR-2).

#### FR-41: Push pending changes when online

On detecting connectivity, the app pushes pending local changes (sync_status = `pending`) to Supabase in batches.

**Consequences:**
- After a successful push, affected records' sync_status becomes `synced`.
- Push failures retry with exponential backoff, capped at 10 min [ASSUMPTION].

#### FR-42: Pull remote changes when online

The app pulls remote changes from Supabase incrementally (since the last successful pull) and applies them to the local DB.

**Consequences:**
- After a pull, locally observable records reflect remote updates.
- Pull failures do not corrupt local data.

#### FR-43: Last-write-wins conflict resolution

When a local pending change conflicts with a more recent remote change, the remote change wins (based on UTC `updated_at`); when local is newer, local wins.

**Consequences:**
- Resolution is based on `updated_at` (UTC).
- Conflicts on Invoice and Payment records surface as a warning to the User; they do not silently overwrite. [ASSUMPTION: surface-but-do-not-block; revisit during validation.]
- The per-entity sync behavior matrix for non-financial entities is deferred to the architecture skill (see Open Q11).

### 4.12 Localization & RTL

**Description.** Ships with French (default), Arabic (RTL), English. No hardcoded user-facing strings. Locale-aware date, time, and currency formats.

#### FR-44: Three-language UI

Switch UI language between FR / AR / EN from Settings. The choice persists across sessions per User.

**Consequences:**
- All user-facing strings render in the chosen language.
- Switching to AR flips layout to RTL across all screens.

#### FR-45: Localized formats

Dates render per locale (FR: 21/05/2026; EN: 2026-05-21). Currency renders as TND. Time uses 24-hour format across all locales [ASSUMPTION].

**Consequences:**
- Switching locale reformats visible dates, times, and currency without restart.

## 5. Non-Goals & Out of MVP

The MVP **will not**:

- Run on mobile, web, or tablet. Desktop only (Windows/macOS/Linux).
- Provide a patient-facing surface (no portal, no self-booking, no patient login).
- Integrate with insurance, payer claims, e-prescribing, lab portals, or external imaging systems.
- Process card / online / non-cash payments. Cash only; `method` exists for v2 extensibility.
- Track refunds or issue credit notes. Voiding an Invoice with prior payments surfaces "refund owed" but does not process it.
- Track lab-order status beyond the appointment-level Lab Work Flag.
- Auto-decrement Inventory per Performed Treatment. Inventory is manually adjusted.
- Track batch numbers, expiry dates, or lot-level inventory.
- Provide reporting/analytics dashboards beyond the Day Closeout summary.
- Export data — no CSV, no accounting integration, no PDF invoice export. PDF invoice export deferred to v2. [NOTE FOR PM: this is a small ask that may creep into MVP if the dentist insists during validation — see Open Q8.]
- Send appointment reminders to patients (SMS / WhatsApp / email). [NOTE FOR PM]
- Support telehealth or remote consultations.
- Provide a configurable role/permission editor. The three roles are hardcoded; only role assignment is configurable.
- Support multiple Clinics in a single instance. The schema is multi-tenant for future-proofing only.
- Provide an admin override / supervisor role beyond the Dentist role.
- Perform OCR or paper-document scanning. Backfilled history is freeform text only.
- Surface Nurse-specific flows. The Nurse role exists in the data model for forward-compat but has no MVP UX.

## 6. MVP Scope (In Scope)

- Sign-in, Clinic provisioning, adding the Assistant User (§4.1).
- Patient creation with backfilled paper history, search, Patient File, edit, soft-delete (§4.2).
- Day and week calendar, Appointment create/edit/cancel/filter, check-in (§4.3).
- Visit lifecycle, Performed Treatments with tooth numbers, clinical notes, diagnosis, complete-and-lock with Dentist unlock (§4.4).
- Multi-session Treatment Plans linked to future Appointments (§4.5) — *subject to validation*.
- Auto-generated Invoices, discount/surcharge as line items, void, Finalize, first-class Payments, derived Invoice status, Outstanding Balance per Patient, Patients-with-Balance list (§4.6).
- Inventory: consumables with low-stock thresholds, manual adjustments, Restock Events, Low-Stock Alerts (§4.7).
- Attachments on Patients and Visits (image/PDF, manual upload) (§4.8).
- Day Closeout with expected/counted cash and Dentist reopen (§4.9).
- Two-role RBAC enforced at router + Riverpod + domain (§4.10).
- Full offline-first operation; sync to Supabase with last-write-wins; multi-device sync across two desktop machines (§4.11).
- FR / AR (RTL) / EN UI with locale-aware formats (§4.12).

## 7. Success Metrics

Stakes calibrated to "learning project with one real customer." Counter-metrics matter as much as primaries because over-building for a hypothetical commercial future is the dominant failure mode.

**Primary**
- **SM-1.** The clinic uses DocCentral as their primary system for the four pain points within 30 days of go-live. Validation: weekly check-in with the dentist and assistant — "did you use paper for this today or DocCentral?" across patient flow, payment, calendar, inventory. Validates FR-4 through FR-37 collectively.
- **SM-2.** Calendar drift events drop to zero. Definition: no `scheduled` Appointments where the Patient did not show *and* the Appointment is still `scheduled` the next day. Validation: weekly query. Validates FR-13.
- **SM-3.** Outstanding Balance list reflects reality. Definition: when the Assistant cross-checks the Patients-with-Balance list against the paper record, no Patient is missing and no Patient is wrongly flagged. Validation: monthly spot-check. Validates FR-27, FR-28.

**Secondary**
- **SM-4.** Sign-in + Today's Calendar render within 2 seconds on the clinic's actual hardware. Validates §4.11 and FR-10.
- **SM-5.** Day Closeout delta = 0 at least 90% of business days within 60 days post-launch. Validates FR-26, FR-36.
- **SM-6.** Patient history retrieval is fast enough to use mid-conversation — from "Patient walks in" to "Patient File open with prior Visits visible" in ≤10 seconds on the clinic's hardware, with up to 5,000 Patient records. Validation: timed observation. Validates FR-6, FR-7.

**Counter-metrics (do not optimize)**
- **SMC-1.** Feature count. Adding features beyond §6 before SM-1 lands is a failure mode.
- **SMC-2.** Multi-Clinic readiness. The schema is multi-tenant; the *product* is single-tenant until SM-1 lands.
- **SMC-3.** Test coverage as a vanity metric. Tests should follow validated assumptions, not pre-empt them — but per `.rules/09-testing.md` and NFR-10, the discipline contract still applies once an FR is implemented.

## 8. Cross-Cutting NFRs

- **NFR-1. Offline-first.** All FRs work without internet. Only initial sign-in on a fresh device requires online (FR-2).
- **NFR-2. Sync resilience.** Sync failures, network drops mid-sync, and conflicts must not corrupt local data. Drift is authoritative.
- **NFR-3. Financial determinism.** Invoice totals are always computed from Items + adjustments + Payments, never manually set. No UI path exposes a direct Invoice total field.
- **NFR-4. Immutability of paid records.** Once an Invoice has any Payment, the Invoice Items are immutable; corrections require void (FR-25). Once an Invoice is `paid` or `void`, no further edits are possible.
- **NFR-5. Localization integrity.** No hardcoded user-facing strings in code. All UI text loaded from translation files.
- **NFR-6. RTL correctness.** Arabic locale renders correctly in RTL for all screens — form fields, lists, modals.
- **NFR-7. Desktop performance baseline.** On the clinic's actual hardware [NEEDS VALIDATION: confirm hardware]: cold-launch < 4s; landing on Today's Calendar < 2s after sign-in; navigating between Patient / Visit / Calendar screens < 500ms.
- **NFR-8. Data residency.** Supabase project deployed in the EU region (Frankfurt or Ireland) for proximity to Tunisia and alignment with health-data hygiene. INPDP (Tunisian Loi 2004-63) does not strictly require local residency for a single-Clinic internal-use deployment. [ASSUMPTION: EU region is acceptable.]
- **NFR-9. Audit attribution on financial AND clinical actions.** Every Invoice, Payment, Void, Day Closeout, Closeout Reopen, Visit transition, Performed Treatment add/edit, Visit Unlock, Patient edit, and Appointment edit records actor and UTC timestamp. The local DB schema enforces these fields non-null. An audit-viewing surface is not in MVP; data is captured for forensic use and v2 reporting.
- **NFR-10. Per-module test coverage discipline.** Per `.rules/09-testing.md`, every implementation module ships with unit tests for domain logic, integration tests for repository / data-layer behavior, sync-aware tests where the module touches sync metadata, and optional UI / widget tests for non-trivial widgets. Discipline contract, not a percentage target.
- **NFR-11. Responsive layouts via LayoutBuilder.** Per `.rules/05-ui.md`, screens use `LayoutBuilder`-based responsive layouts so the UI adapts to the clinic's actual desktop window sizes without horizontal scrolling. Only top-level pages access Riverpod; child widgets remain pure.

## 9. Constraints and Guardrails

### 9.1 Privacy

- DocCentral handles **PHI** (patient demographics, diagnoses, clinical notes, tooth-level procedure history).
- Under **Tunisian INPDP / Loi 2004-63**, health data is sensitive personal data. For a single-Clinic deployment used internally by the data controller (the dentist), no INPDP declaration is currently required. Declaration becomes necessary if commercialized — flagged for v2.
- **Data minimization.** Patient model carries only the fields used: name, DOB, phone, optional email, freeform history.
- **Local encryption at rest.** Drift database encrypted at rest using SQLCipher or equivalent [ASSUMPTION: in MVP; revisit if performance impact is non-trivial — see Open Q5].
- **Transport encryption.** All Supabase traffic uses HTTPS.

### 9.2 Safety

- The system MUST NOT silently overwrite financial records. Sync conflicts on Invoice / Payment surface to the User (FR-43, NFR-2).
- The system MUST NOT delete records — only soft-delete with `deleted_at` set.

## 10. Migration from Paper

The family member's clinic runs on paper + Excel + WhatsApp. The MVP supports a realistic onboarding path:

- **Patient backfill via freeform text** (FR-5): the Assistant pastes the contents of the paper file into `history_notes` at Patient creation.
- **Inventory seeding**: the Assistant manually creates each Inventory Item with its current count. No bulk import.
- **No retro-data import** for prior Visits, Invoices, or Payments. Historical financial state stays on paper; DocCentral's financial state starts at go-live.
- **Parallel-running period**: expect paper + DocCentral in parallel for 2–4 weeks during onboarding. Cutover strategy is a deployment decision, not a PRD decision.
- **Downstream build tickets in beads**: project-foundation work (Flutter scaffolding, Drift initialization, Supabase setup, GoRouter, base design system, Riverpod codegen — equivalent to `todo.md` SETUP-001 through SETUP-004, UI-001, UI-002) is not authored as PRD FRs because it's infrastructure, not product surface. These tickets are created in **beads (`bd`)** during the epics/stories phase, alongside product epics derived from §4 Features.

## 11. Risks and Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Adoption fails: clinic falls back to paper for the hard cases | High | Migration plan §10 acknowledges parallel running; SM-1 measures actual adoption; lean MVP scope reduces "too many features to learn" risk. |
| Scope expansion ("just one more feature for the commercial future") | High | Counter-metric SMC-1 explicitly de-prioritizes feature count until SM-1 lands. Open Questions §12 surface the temptations. |

Other validation-pending items (improvised assistant journey, inventory depth, Treatment Plan adoption, sync conflict UX, hardware baseline, encryption-at-rest performance) are tracked as Open Questions §12, not as risks — a risk is something that hurts the MVP if untrue; these are decisions awaiting information.

## 12. Open Questions

Resolve via validation interview (`validation-interview.md`) or PRD-owner decision before ticket cutting.

1. **Validation interview.** Confirm or correct UJ-1, UJ-5, UJ-6, UJ-7, FR-17 (autosave vs explicit save), FR-19 (unlock UX), FR-22 (mark-performed UX), FR-43 (conflict surfacing UX), NFR-7 (hardware baseline), §4.5 entire Treatment Plan module.
2. **Procedure catalog.** Pre-defined catalog with default prices, or free-text only? Affects FR-16, FR-20, Invoicing.
3. **Multi-device need.** Does the clinic actually have, or plan to acquire, two desktop devices that both write? If single-device, sync requirements simplify.
4. **Default Appointment duration.** Is 30 min sensible, or should the Assistant always set duration explicitly?
5. **Encryption-at-rest performance.** Does the clinic's hardware tolerate SQLCipher overhead? If not, MVP may ship without it with a `[NOTE FOR PM]` to revisit at commercialization.
6. **Discount/surcharge usage patterns.** Percentage? Fixed amount? "Family rate"? Shapes the UI for FR-24.
7. **Appointment overlap policy.** Does the dentist ever intentionally double-book?
8. **PDF invoice export — push back into MVP?** Currently Non-Goal; competitive scan flags this as a common ask; the clinic may want to hand patients a receipt. Confirm with dentist.
9. **Appointment reminders to patients — push back into MVP?** WhatsApp share or SMS. Same question.
10. **Reopen-day window.** Forever (MVP draft) or limited to the prior business day?
11. **Per-entity sync behavior.** FR-43 special-cases financial records. For non-financial entities, the default is silent last-write-wins. The architecture skill will need to author a per-entity sync matrix: which entities support which sync states, attachment-blob sync mechanics, queue ordering, what constitutes a "conflict" per entity. Belongs in `addendum.md` or in the architecture document, not in the PRD.

---

*End of PRD. Status: `draft`. Next step: validation interview (`validation-interview.md`), then Finalize close-out and downstream handoff (UX design → architecture → beads epics/stories).*
