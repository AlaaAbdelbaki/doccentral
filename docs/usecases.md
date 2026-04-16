# 📌 DocCentral – MVP Use Cases (Dental Offline System)

---

## 🧑‍⚕️ User Management

### Doctor
- Register clinic account (email + password)
- Login/logout
- View and update personal profile
- Manage assistants (create / disable accounts)
- Assign roles to users (assistant, nurse, etc.)

### Assistant
- Login/logout
- Access assigned clinic workspace
- Manage appointments (create, update, cancel)
- Create patient records
- Create and manage visits (check-in / check-out patients)
- Generate invoices from completed visits
- Update invoice status (DRAFT, UNPAID, PARTIALLY_PAID, PAID, VOID)

### Nurse (optional role)
- View patient list
- Add clinical notes to visits (if permitted)
- View appointments schedule

---

## 🧑‍⚕️ Patient Management
- Add new patient (first name, last name, DOB, contact info)
- Search and filter patients
- Edit patient details
- View patient profile including:
  - Appointment history
  - Visit history
  - Invoice history
- Add clinical notes to patient record

---

## 📅 Appointment Management
- Schedule new appointment (patient, date/time, assigned doctor, notes)
- View calendar (daily/weekly)
- Update or cancel appointments
- Filter appointments by status and date
- Mark appointment as completed or missed
- Appointment may result in a visit (not automatic)

---

## 🦷 Visit Management (CORE MODULE)
- Create visit from appointment when patient arrives (check-in)
- Track visit status:
  - CHECKED_IN
  - IN_PROGRESS
  - COMPLETED
  - BILLED
- Add diagnosis and clinical notes (dentist)
- Add treatments (dentist):
  - tooth number
  - procedure name
  - quantity
  - pricing
- Close visit when treatment is completed
- Prevent modifications after completion (or require override permission)

---

## 🛠 Treatment Management
- Add treatment inside a visit
- Edit or remove treatment (before visit is completed)
- Define unit price and quantity
- System calculates total per item
- Support adjustments via invoice system (not directly here)

---

## 🧾 Invoice & Billing Management
- Auto-generate invoice when visit is marked COMPLETED
- Invoice contains all treatments from visit
- Add invoice adjustments:
  - discount
  - surcharge
- Track invoice status:
  - DRAFT
  - UNPAID
  - PARTIALLY_PAID
  - PAID
  - VOID
- View invoice history per patient
- Print/export invoice (future desktop feature)

---

## 💰 Financial Rules (System Behavior)
- Invoice total is always calculated from invoice items
- No manual editing of invoice totals
- Discounts and adjustments are explicit invoice items
- All financial changes are auditable

---

## 🔐 Access Control & Permissions
- Role-based access control (RBAC)
- Doctor has full access
- Assistant has operational access (appointments, visits, invoices)
- Nurse has limited clinical read access
- Permissions are enforced per action, not only per screen

---

## ⚙️ Settings (MVP Scope)
- Clinic information (name, address, phone)
- Invoice footer customization
- Basic system configuration

---

## 🧠 Key Architecture Rule

Appointment schedules time  
Visit represents medical reality  
Invoice represents financial outcome