# 🦷 DocCentral – Development TODO (Feature-Based + Riverpod + GoRouter)

This roadmap is structured for an offline-first dental clinic system using Flutter, Riverpod, GoRouter, and a feature-based architecture.

---

# 🟢 PHASE 0 – Project Foundation

- [ ] Create Flutter desktop project
- [ ] Setup feature-based architecture structure
- [ ] Setup Riverpod (code generation optional)
- [ ] Setup GoRouter
- [ ] Setup local database (Drift recommended)
- [ ] Setup UUID generation utility
- [ ] Setup dependency injection (if needed)
- [ ] Create base app shell (router + layout)

---

# 🟢 PHASE 1 – Architecture Setup

- [ ] Define folder structure:
  - core/
  - domain/
  - features/
  - shared/
- [ ] Define domain models:
  - Patient
  - User
  - Appointment
  - Visit
  - Treatment
  - Invoice
- [ ] Define enums:
  - VisitStatus
  - InvoiceStatus
  - Roles

---

# 🟢 PHASE 2 – Authentication & RBAC

- [ ] Create local authentication system
- [ ] Implement login/logout flow
- [ ] Create User model
- [ ] Implement Role system (DB-based, not enum)
- [ ] Implement Permission system (RBAC logic)
- [ ] Create route guards using GoRouter + Riverpod
- [ ] Restrict access by role

---

# 🟢 PHASE 3 – Patient Feature

- [ ] Patient CRUD (local DB)
- [ ] Patient list screen
- [ ] Search & filtering
- [ ] Patient profile screen
- [ ] Display:
  - Appointments
  - Visits
  - Invoices
- [ ] Add patient notes

---

# 🟢 PHASE 4 – Appointment Feature

- [ ] Appointment CRUD
- [ ] Calendar UI (daily / weekly)
- [ ] Appointment statuses:
  - Scheduled
  - Cancelled
  - Completed
  - Missed
- [ ] Link appointment to patient
- [ ] Assign doctor/assistant to appointment

---

# 🟢 PHASE 5 – Visit Feature (CORE SYSTEM)

- [ ] Create visit from appointment (check-in)
- [ ] Visit lifecycle:
  - CHECKED_IN
  - IN_PROGRESS
  - COMPLETED
  - BILLED
- [ ] Add diagnosis field
- [ ] Add clinical notes
- [ ] Add visit locking after completion
- [ ] Prevent unauthorized edits
- [ ] Allow dentist-only modifications

---

# 🟢 PHASE 6 – Treatment Feature

- [ ] Create treatment inside visit
- [ ] Treatment fields:
  - name
  - tooth number
  - quantity
  - unit price
  - total price (computed in app)
- [ ] Edit/delete treatment (before visit completion)
- [ ] Link treatments to visit
- [ ] Ensure immutability after visit completion

---

# 🟢 PHASE 7 – Invoice Feature

- [ ] Auto-create invoice on visit completion
- [ ] Invoice includes all treatments
- [ ] Invoice item system:
  - treatments
  - adjustments (discount/surcharge)
- [ ] Invoice statuses:
  - DRAFT
  - UNPAID
  - PARTIALLY_PAID
  - PAID
  - VOID
- [ ] Ensure invoice total = sum of items
- [ ] Prevent manual total editing

---

# 🟢 PHASE 8 – Financial Rules Engine

- [ ] Implement invoice calculation logic
- [ ] Add adjustment handling:
  - discount
  - surcharge
- [ ] Ensure auditability of all changes
- [ ] Validate invoice before finalization
- [ ] Lock invoice after PAID (optional)

---

# 🟢 PHASE 9 – GoRouter Navigation

- [ ] Setup route structure:
  - /login
  - /dashboard
  - /patients
  - /patients/:id
  - /appointments
  - /visits/:id
  - /invoices/:id
- [ ] Add route guards (RBAC)
- [ ] Handle unauthorized access
- [ ] Persist navigation state where needed

---

# 🟢 PHASE 10 – Riverpod State Management

- [ ] Setup authProvider
- [ ] Setup currentUserProvider
- [ ] Setup patientsProvider
- [ ] Setup appointmentsProvider
- [ ] Setup activeVisitProvider
- [ ] Setup invoiceDraftProvider
- [ ] Setup permissionsProvider

---

# 🟢 PHASE 11 – UI Core Screens

- [ ] Login screen
- [ ] Dashboard (today overview)
- [ ] Patient list + profile
- [ ] Appointment calendar
- [ ] Visit workflow screen
- [ ] Treatment editor
- [ ] Invoice screen

---

# 🟡 PHASE 12 – Data Integrity & UX

- [ ] Input validation everywhere
- [ ] Error handling system
- [ ] Offline persistence reliability
- [ ] Prevent invalid state transitions
- [ ] Improve workflow UX (reduce clicks)

---

# 🔵 PHASE 13 – Export & Desktop Features

- [ ] PDF invoice export
- [ ] Print invoice
- [ ] Local file storage handling
- [ ] Backup/export database (optional)

---

# 🚫 FUTURE (NOT MVP)

- Inventory management
- Notifications (SMS/email)
- AI suggestions
- Analytics dashboard
- Cloud sync
- Multi-clinic SaaS system

---

# 🧠 CORE BUILD RULE

Build in this order:

1. Patient system
2. Appointment system
3. Visit system (MOST IMPORTANT)
4. Treatments
5. Invoice system
6. RBAC security
7. UI polish

---

# 🦷 IMPORTANT ARCHITECTURE RULE

Appointment = scheduling  
Visit = medical reality  
Invoice = financial output