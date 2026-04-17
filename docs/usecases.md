# 📌 DocCentral – MVP Use Cases (Dental Offline + Sync System)

---

# 🧠 System Overview

DocCentral is an **offline-first, multi-device dental clinic management system**.

It operates with:

- Local-first database (Drift = source of truth)
- Remote synchronization (Supabase = replication layer)
- Multi-role access (Doctor, Assistant, Nurse)

---

# 🧭 Core Domain Principles

Appointment schedules time  
Visit represents medical reality  
Invoice represents financial outcome  

---

# 🧑‍⚕️ User Management

## Doctor
- Register clinic account (email + password)
- Login/logout
- Manage clinic profile
- Manage assistants and nurses
- Assign roles and permissions to users
- View full clinic financial and clinical data

## Assistant
- Login/logout
- Operate within assigned clinic workspace
- Manage appointments (create / update / cancel)
- Register patients
- Create and manage visits (check-in / check-out)
- Generate invoices from completed visits
- Update invoice status:
  - DRAFT
  - UNPAID
  - PARTIALLY_PAID
  - PAID
  - VOID

## Nurse (optional role)
- View patients and appointments
- Add clinical notes (if permitted)
- Assist during visits (read/write limited clinical data)

---

# 🧑‍⚕️ Patient Management

- Add new patient (first name, last name, DOB, contact info)
- Search and filter patients
- Edit patient details
- View patient profile:
  - Appointment history
  - Visit history
  - Invoice history
- Add clinical notes to patient record

---

# 📅 Appointment Management

- Schedule appointments (patient, date/time, assigned staff, notes)
- View calendar (daily / weekly)
- Update or cancel appointments
- Filter by date, patient, or status
- Mark appointment as:
  - scheduled
  - completed
  - missed
- Appointment may result in a visit (manual or automatic creation based on workflow)

---

# 🦷 Visit Management (CORE MODULE)

- Create visit from appointment when patient arrives (check-in)
- Track visit lifecycle:
  - CHECKED_IN
  - IN_PROGRESS
  - COMPLETED
  - BILLED
- Add diagnosis and clinical notes
- Add treatments:
  - tooth number
  - procedure name
  - quantity
  - unit price
- Edit treatments only before visit completion
- Lock visit after completion (requires admin override if needed)

---

# 🛠 Treatment Management

- Treatments belong strictly to a visit
- Can be added/edited during active visit
- System calculates totals automatically
- Treatments become immutable after visit completion
- Financial adjustments are handled inside invoice items only

---

# 🧾 Invoice & Billing Management

- Auto-generate invoice when visit is marked COMPLETED
- Invoice is derived from visit treatments
- Add invoice adjustments:
  - discount
  - surcharge
- Track invoice status:
  - DRAFT
  - UNPAID
  - PARTIALLY_PAID
  - PAID
  - VOID
- Invoice represents the full financial record of a visit
- View invoice history per patient
- Export / print invoice (future desktop feature)

---

# 💰 Financial Rules (SYSTEM ENFORCEMENT)

- Invoice total is always computed from invoice items
- No manual editing of invoice totals
- Discounts and surcharges must be explicit line items
- Paid invoices are locked (no edits allowed)
- VOID invoices are final and cannot be reused
- All financial operations must be auditable
- Invoice status is used as the ONLY payment tracking mechanism

---

# 🔐 Access Control & Permissions (RBAC)

- Doctor: full system access
- Assistant: operational access (clinical + billing)
- Nurse: restricted clinical access only

## Permission Model
- Action-based permissions (not screen-based)
- Example:
  - CAN_CREATE_VISIT
  - CAN_EDIT_INVOICE
  - CAN_VIEW_PATIENTS

---

# ⚙️ System Behavior (OFFLINE + SYNC)

## Offline-first behavior
- All operations work without internet
- All data is written to local database first (Drift)

## Sync behavior
- Changes are queued locally (pending sync)
- Supabase is used as replication layer
- Sync is asynchronous and non-blocking

## Conflict handling (MVP)
- Last write wins based on updatedAt timestamp
- Soft deletes using deletedAt

---

# 🔄 Sync-Aware Rules

- Every entity is sync-tracked
- Changes are propagated across devices
- No reliance on cloud for correctness
- Local DB is always authoritative at runtime

---

# 🧠 Auditability Rules (Recommended)

- Track created/updated timestamps for all entities
- Optional: track deviceId for debugging sync issues
- Optional future: activity log per clinic action

---

# ⚠️ Critical System Rule

The system must always function fully without network access.

Supabase is a synchronization layer only, not the system dependency.

---

# 🚀 Key Architectural Insight

This system is:

- Offline-first medical system
- Multi-device synchronized workspace
- Financially deterministic system
- Workflow-driven clinical system

---