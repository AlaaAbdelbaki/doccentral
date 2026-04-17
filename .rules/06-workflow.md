# 🏥 Clinic Workflow Rules (CRITICAL)

## 🧠 Core Flow

Appointment → Visit → Treatment → Invoice

---

## 📅 Appointment Rules

* Appointment is only scheduling
* It does NOT contain medical execution

---

## 🦷 Visit Rules

* Visit must be created from an appointment
* Visit represents real medical activity
* Visit has lifecycle:

  * CHECKED_IN
  * IN_PROGRESS
  * COMPLETED
  * BILLED

---

## 🛠 Treatment Rules

* Treatments belong ONLY to visits
* Treatments cannot exist outside visits
* Must be immutable after visit completion

---

## 🧾 Invoice Rules

* Invoice is generated from completed visits
* Invoice is financial representation of treatments
* No manual total editing allowed

---

## 💰 Financial Rule

All adjustments MUST be explicit line items:

* Discount
* Surcharge

---

## 🧠 Golden Rule

Appointment schedules time
Visit represents medical reality
Invoice represents financial outcome
