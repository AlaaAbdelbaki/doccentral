# 📌 DocCentral – SYSTEM SPECIFICATION (Canonical)

# 🧠 1. System Overview
DocCentral is an offline-first, multi-device dental clinic management system.

Architecture:
- Drift = local source of truth
- Supabase = sync layer only
- RBAC = role-based access control
- Invoice-based financial system
- Appointment → Visit → Invoice workflow

# 🧭 2. Core Domain Principles
Appointment schedules time
Visit represents medical reality
Invoice represents financial outcome

# 🏗 3. Architecture Rules
- Offline-first: everything works without internet
- Local DB is authoritative
- Sync is async and non-blocking
- Financial logic is deterministic

# 🔐 4. RBAC
Roles:
- DOCTOR
- ASSISTANT
- NURSE

Enforcement layers:
- UI layer
- Router layer
- Domain layer (mandatory)

# 🧑‍⚕️ 5. Core Entities
- Clinic
- User
- Patient
- Appointment
- Visit
- Treatment
- Invoice

# 🔄 6. State Machines

Appointment:
SCHEDULED → COMPLETED → MISSED → CANCELLED

Visit:
CHECKED_IN → IN_PROGRESS → COMPLETED → BILLED

Invoice:
DRAFT → UNPAID → PARTIALLY_PAID → PAID → VOID

# 🧑‍⚕️ 7. Workflow Rules
- Appointment does NOT auto-create Visit
- Visit is created on patient check-in
- Invoice is generated only when Visit is COMPLETED
- Paid/VOID invoices are immutable

# 🧾 8. Financial Rules
- Invoice = sum of treatments
- No manual total editing
- Discounts/surcharges are explicit items

# 🔄 9. Sync Rules
- Drift = source of truth
- Supabase = replication only
- Last-write-wins conflict resolution
- Required fields: id, created_at, updated_at, deleted_at

# 🧪 10. Testing Rules
Every module must include:
- Unit tests
- Integration tests
- Sync tests (if applicable)

# 🎨 11. UI Rules
- Desktop-first
- Responsive via LayoutBuilder
- Only top-level pages use Riverpod widgets
- Children are pure widgets

# 🌐 12. Localization
- EN / FR / AR
- No hardcoded strings
- Arabic supports RTL

# 🚀 13. System Guarantee
- Fully offline functional
- Deterministic financial system
- Consistent sync across devices
