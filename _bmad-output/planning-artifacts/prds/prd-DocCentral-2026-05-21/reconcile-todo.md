# Reconciliation: `todo.md` (pre-existing 9-phase backlog) vs PRD draft

**Inputs**
- `D:\Projects\DocCentral\todo.md` — 9-phase, ~33-item backlog the user authored before this PRD.
- `D:\Projects\DocCentral\_bmad-output\planning-artifacts\prds\prd-DocCentral-2026-05-21\prd.md` — new PRD that supersedes `todo.md`.

**Headline status:** The PRD **mostly** covers `todo.md`'s MVP scope. Every phase has substantive PRD coverage, but two classes of gaps exist: (a) `todo.md`'s explicit *foundational/architectural* tickets (Phase 0, parts of Phase 7) are largely invisible in the PRD because the PRD is product-scoped rather than build-scoped — that is fine but worth flagging since downstream ticketing must still create them; (b) the PRD *expands the product surface* well beyond `todo.md`'s MVP completion criteria (inventory, treatment planning, day closeout, attachments, payments-as-first-class, outstanding-balance views, lab flag, multi-language including Arabic RTL). The user should consciously accept or trim that expansion.

---

## Per-phase reconciliation

### Phase 0 — Project Foundation
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| SETUP-001 Project initialization (Flutter desktop, Riverpod, GoRouter, l10n EN/FR/AR) | Implied by NFR-1 (offline-first), §4.12 (FR-44, FR-45), and §11 (top-level surfaces). Stack choice (Flutter / Riverpod / GoRouter / Drift) is *referenced* (NFR-2 names Drift, §4.11 names Drift + Supabase) but not specified as a project-init deliverable. | **Silently dropped as a deliverable** but covered as a constraint. Need a ticket downstream. |
| SETUP-002 Core architecture scaffolding (domain/data/presentation layers, base entity, repo contracts, error handling) | Not in PRD. PRD references "domain layer" enforcement (FR-39) and `.rules/05-ui.md` (top-level pages access Riverpod) but does not require scaffolding as a deliverable. | **Silently dropped.** Downstream architecture skill / epic must restore it. |
| SETUP-003 Drift setup (init, migrations, shared timestamp/sync helpers) | Drift is named as local source of truth (§4.11, NFR-2). Sync metadata is in Glossary ("Sync Status") and migration flow is implicit. No standalone ticket. | **Silently dropped as a setup task** (functionally covered by sync FRs but not as an explicit scaffolding deliverable). |
| SETUP-004 Supabase setup (project, auth, mirrored schema, API access) | Covered by §4.1 (FR-1, FR-2, FR-3) and §4.11 (Supabase as sync target). Region constraint added (NFR-8 — EU region). | **Covered + tightened** (EU region, INPDP note). |

**Phase 0 verdict:** PRD is product-spec, not build-spec. Three of four SETUP tickets need to be re-created as architecture/build tasks downstream — they are not "in" the PRD by name.

---

### Phase 1 — Core Identity and Access
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| AUTH-001 Authentication system (email/password, session persistence, logout) | **FR-2** | Covered. |
| AUTH-002 User and clinic bootstrap (first-signup clinic, doctor user, default role) | **FR-1**, **FR-3** | Covered. PRD also adds `is_clinic_owner` flag (new). |
| AUTH-003 RBAC (doctor/assistant/nurse roles, permission checking, route guards) | **§4.10 FR-38, FR-39** | Covered. Note: PRD *demotes Nurse to data-model-only* (no MVP UX); `todo.md` AUTH-003 included nurse role checking. PRD makes that an explicit Non-Goal (§5 — no nurse UX). |

**Phase 1 verdict:** Fully covered. The Nurse-UX demotion is a deliberate PRD scope cut.

---

### Phase 2 — Patient Module
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| PAT-001 Patient entity + Drift table + sync fields | Implied across §4.2 + Glossary + NFR-2. No standalone deliverable. | **Implicit, not named** — needs build ticket downstream. |
| PAT-002 Patient CRUD (create, edit, soft delete, search, filter) | **FR-4** (create), **FR-6** (search), **FR-8** (soft delete). | Mostly covered. **Gaps:** (i) PRD does not explicitly call out *Patient edit* as an FR (FR-4 covers create only); (ii) PRD does not specify *filtering* beyond search. |
| PAT-003 Patient profile screen (details + appointment/visit/invoice history) | **FR-7** — Patient File view (identity, history notes, 5 most recent Visits, active Treatment Plan, Outstanding Balance, Attachments). | Covered and **expanded** (Treatment Plan + Outstanding Balance + Attachments are new). |

**Phase 2 verdict:** Covered, but Patient *edit* and *list filtering* are silent gaps. Patient File is significantly richer in the PRD.

---

### Phase 3 — Appointment Module
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| APP-001 Appointment entity + DB model + status enum | Glossary + §4.3. Statuses in PRD: `scheduled / checked_in / completed / no_show / cancelled / rescheduled`. `todo.md` did not enumerate. | Covered + statuses defined. |
| APP-002 Appointment CRUD + calendar views (day, week) | **FR-9** (create), **FR-10** (day view), **FR-11** (week view), **FR-13** (cancel). | Covered. **Gap:** PRD has *no explicit FR for appointment edit/update* (only create and cancel). `todo.md` APP-002 included "update". |
| APP-003 Appointment filtering (date, patient, status) | Not in PRD. | **Silent drop.** No filter FR. |

**Phase 3 verdict:** Mostly covered. PRD silently drops (a) appointment edit/update as a named FR and (b) the entire filter feature. PRD significantly extends appointments via **FR-14 lab-work flag** (new scope).

---

### Phase 4 — Visit Module
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| VIS-001 Visit entity + lifecycle (`CHECKED_IN`, `COMPLETED`, `BILLED`) | **§4.4 + Glossary.** PRD lifecycle is `checked_in → in_progress → completed`. **PRD explicitly drops `BILLED`** (Glossary: "billed" is derivable from invoice existence) and **adds `in_progress`** as a discrete state. | Covered with a deliberate state-machine change. User should confirm `in_progress` adds value vs. complicates UX. |
| VIS-002 Visit creation from appointment / check-in flow | **FR-12** | Covered. |
| VIS-003 Visit management UI (status updates, diagnosis, clinical notes) | **FR-15** (in-progress), **FR-17** (diagnosis + notes), **FR-18** (complete). | Covered. |
| VIS-004 Treatment system (add/edit/remove, lock after completion) | **FR-16** (add Performed Treatments), **FR-18** (lock on complete), **FR-19** (unlock by Dentist). | Covered + **expanded**: tooth numbers, optional procedure catalog (Open Q2), explicit unlock-by-Dentist path. |

**Phase 4 verdict:** Covered with two deliberate changes — `BILLED` removed, `in_progress` added, and a Dentist-only unlock workflow (FR-19) introduced.

---

### Phase 5 — Invoice Module
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| INV-001 Invoice + invoice items tables | Glossary + §4.6 throughout. | Covered. |
| INV-002 Invoice generation engine (auto-create from visit, copy treatments) | **FR-23** | Covered. |
| INV-003 Invoice management (viewing, status changes `DRAFT/PAID/VOID`, discounts/surcharges via items) | **FR-24** (adjustments), **FR-25** (void). Statuses in PRD: `draft / unpaid / partially_paid / paid / void` — **expanded** beyond `todo.md`'s 3-state model. Status is **derived from Payments**, not manually set. | Covered + significantly **expanded** (5 states, derived status). |
| INV-004 Invoice locking rules (lock after PAID/VOID, total consistency validation) | **NFR-3** (no manual total), **NFR-4** (immutable once paid/void), **FR-24** (adjustments locked after `draft`). | Covered with a stricter rule set. |

**Phase 5 verdict:** Covered and **substantially expanded**. The new bits — `unpaid`, `partially_paid`, derived status, first-class Payment entity — flow from a new scope decision (see §4.6 below in "new scope").

---

### Phase 6 — Sync Engine
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| SYNC-001 Sync metadata system (sync_status, deleted_at, updated_at) | Glossary ("Sync Status") + NFR-2. | Covered. |
| SYNC-002 Push engine (detect pending, batch upload, mark synced) | **FR-41** | Covered. |
| SYNC-003 Pull engine (fetch remote, apply to Drift, conflict resolution LWW) | **FR-42, FR-43** | Covered. **Refinement:** PRD adds "financial conflicts surface to user, never silent" (FR-43, NFR-2) — stronger than `todo.md`. |
| SYNC-004 Sync controller (Riverpod controller, start/stop/state, offline mode) | Implied by FR-40 + NFR-1 + NFR-2 but no standalone "controller" FR. | **Implicit, not named** as a deliverable. Build ticket needed. |

**Phase 6 verdict:** Functionally covered. Implementation-side "controller" is implicit only.

---

### Phase 7 — UI System
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| UI-001 Design system (desktop-first theme, responsive layout) | Not in PRD as an FR. NFR-7 (perf baseline) and §11 (IA) gesture at it. PRD explicitly defers UI specifics to the UX skill (§11). | **Silently dropped as a deliverable.** Will be picked up by UX skill / design phase. |
| UI-002 Navigation system (GoRouter, route abstraction, named routes) | Not in PRD as an FR. NFR-7 references inter-screen navigation perf. | **Silently dropped** — build ticket needed. |
| UI-003 Module screens (patients, appointments, visits, invoices) | **§11 IA** names 7 top-level surfaces; all four `todo.md` modules covered, plus Inventory, Outstanding Balances, Day Closeout, Settings. | Covered + **expanded**. |
| UI-004 Role-based UI rendering (feature visibility by role, route protection) | **FR-38, FR-39** | Covered. |

**Phase 7 verdict:** UI-003 and UI-004 covered; UI-001 (design system) and UI-002 (router) are foundation-build tasks invisible to the PRD — both must be re-introduced downstream.

---

### Phase 8 — Offline and Stability
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| OFF-001 Offline detection (network state, sync pause/resume) | **FR-40, FR-41** (push resumes on connectivity), NFR-1. | Covered. |
| OFF-002 Conflict handling MVP (LWW on timestamps) | **FR-43** + NFR-2. | Covered, **with refinement** (financial conflicts surface to user). |
| OFF-003 Data integrity checks (orphan prevention, invoice total validation, visit/invoice consistency) | **NFR-3** (total computed, never manually set), **NFR-4** (immutability), §9.2 Safety (no silent overwrite, no hard delete). | Covered as cross-cutting NFRs rather than as a discrete "integrity checks" deliverable. |

**Phase 8 verdict:** Covered.

---

### Phase 9 — Polish
| `todo.md` item | PRD coverage | Verdict |
|---|---|---|
| POL-001 Localization (EN, FR, AR + RTL) | **§4.12 FR-44, FR-45**, NFR-5, NFR-6. PRD makes **French the default** (and primary persona language) — a clarification beyond `todo.md`. | Covered + clarified. |
| POL-002 Export system (desktop invoice PDF export) | **Explicitly Non-Goal in §5 and §6.2** with a `[NOTE FOR PM]` flag (Open Q8). | **PRD deliberately drops this from MVP.** `todo.md` had it as MVP Polish. Worth a user check. |
| POL-003 Performance optimization (Drift query optimization, pagination for large lists) | NFR-7 (perf baseline targets) + FR-6 (300ms search on 10k patients). No explicit pagination FR. | **Partially covered** as perf targets, but pagination as a deliverable is not named. |

**Phase 9 verdict:** Localization tightened; **PDF export dropped from MVP** (deferred to v2 pending validation); pagination implicit. The PDF export drop is the most consequential gap in Phase 9.

---

### MVP Completion Criteria (`todo.md` block)
| `todo.md` criterion | PRD coverage | Verdict |
|---|---|---|
| Patient → Appointment → Visit → Invoice flow end-to-end | UJ-2 + UJ-3 + FR-12 + FR-18 + FR-23 + FR-26. | Covered. |
| Sync works across two devices | FR-40–FR-43; §4.11 explicitly scoped to "two desktop machines"; **Open Q3 flags this for validation**. | Covered, with the *requirement itself* questioned in the PRD (Open Q3). |
| Offline mode does not lose data | NFR-1, NFR-2, §9.2. | Covered. |
| Role-based access enforced throughout | FR-38, FR-39. | Covered. |

**MVP block verdict:** Fully covered. The only nuance: the PRD *questions whether two-device sync is needed* (Open Q3), which could simplify MVP if the answer is "one device".

---

## New scope introduced by the PRD (not in `todo.md`)

These are PRD features whose presence the user should consciously accept or trim — they expand MVP scope beyond what `todo.md` proposed.

1. **Inventory module (§4.7, FR-29–FR-32).** Entire module is new. Inventory Item entity, categories, on-hand quantity, low-stock thresholds, Restock Events, manual adjustments, low-stock alert surface. The PRD itself flags `[NEEDS VALIDATION WITH CLINIC]`. This is probably the single largest scope addition.

2. **Treatment Planning module (§4.5, FR-20–FR-22).** Multi-session Planned Treatments, sequence numbering, linking Planned Treatments to Appointments, mark-performed-during-Visit copy semantics. `todo.md` VIS-004 covered *Performed* Treatments during a visit; Planned/multi-session is new. PRD itself flags this for scope reduction (§4.5 header + Open Q1).

3. **First-class Payment entity + partial payments + Outstanding Balance views (§4.6, FR-26–FR-28).** `todo.md` INV-003 mentioned status changes among `DRAFT/PAID/VOID` only. PRD introduces:
   - Payment as a first-class entity (amount, method, date, recorded_by_user_id, multiple per Invoice).
   - `partially_paid` and `unpaid` Invoice statuses, *derived* from Payments.
   - Per-Patient Outstanding Balance (FR-27, computed).
   - Dedicated "Patients with Outstanding Balance" screen (FR-28).
   This is core to UJ-9 and SM-3 in the PRD's product narrative.

4. **Day Closeout module (§4.9, FR-35–FR-37).** Entirely new. End-of-day reconciliation between expected cash (sum of today's cash Payments) and counted cash. Dentist-only reopen (FR-37). UJ-10 in the PRD.

5. **Attachments (§4.8, FR-33, FR-34).** Generic file (PDF / JPG / PNG, ≤10 MB) attachments on Patients and Visits, synced to Supabase storage. Not in `todo.md`.

6. **Lab Work Flag on Appointments (§4.3, FR-14, Glossary).** Free-text flag on Appointments to indicate "awaiting lab work, ETA …". Not in `todo.md`.

7. **Cancellation as a first-class event with reason taxonomy (§4.3, FR-13).** `todo.md` APP-002 included "cancel"; PRD makes it a structured Cancellation entity with reason enum (`patient_cancelled / no_show / clinic_cancelled / rescheduled`), actor, timestamp, and forced replacement-Appointment creation when `rescheduled`. Significant elaboration.

8. **Patient history backfill via freeform text (FR-5).** New field to support paper → DocCentral migration (§10). Not in `todo.md`.

9. **Visit `in_progress` state (Glossary + §4.4).** New intermediate state between `checked_in` and `completed`. `todo.md` VIS-001 had only `CHECKED_IN / COMPLETED / BILLED`.

10. **Dentist-only Visit unlock workflow (FR-19).** `todo.md` VIS-004 said "treatments are locked after the visit is completed" — full stop. PRD adds an unlock path gated by Dentist role and "no payments yet" condition.

11. **Procedure catalog (FR-16, Open Q2 + Q4).** Optional Clinic-defined catalog of procedures with default prices. Flagged as `[ASSUMPTION]` and Open Q2. Not in `todo.md`.

12. **Encryption at rest with SQLCipher (§9.1).** Local DB encrypted at rest. Not in `todo.md`.

13. **EU Supabase region requirement / INPDP discussion (§9.1, NFR-8).** Regulatory framing not in `todo.md`.

14. **Audit attribution NFR-9.** Every financial action (Invoice, Payment, Void, Closeout, Reopen) carries `*_by_user_id` and UTC timestamp, enforced at schema level. Stricter than `todo.md`'s INV-004.

15. **Patient soft-delete restricted to Dentist (FR-8 + FR-38).** `todo.md` PAT-002 said "Deletes are soft deletes" with no role gate; PRD restricts to Dentist.

16. **Outstanding-balance / repeat-no-show flag pattern on Patient (UJ-4 edge case).** UX-level requirement that does not appear in `todo.md`.

---

## Silent drops (items `todo.md` had that the PRD does not cover)

Most consequential first:

1. **PDF invoice export (POL-002).** `todo.md` had this in MVP Polish. PRD explicitly moves to Non-Goals (§5, §6.2) with an Open Q8 flag. **Decision needed.**
2. **Appointment filtering (APP-003).** Filter appointments by date, patient, status. No PRD FR. (Date is implicit in calendar views; patient/status filters are not covered.)
3. **Appointment edit/update as an explicit FR.** `todo.md` APP-002 included "update". PRD has create (FR-9), cancel (FR-13), check-in (FR-12), lab flag (FR-14) — but no general "edit a scheduled appointment" FR. Likely an oversight.
4. **Patient edit as an explicit FR.** `todo.md` PAT-002 included edit. PRD has FR-4 (create), FR-6 (search), FR-7 (view), FR-8 (soft-delete), but no edit FR. Likely an oversight.
5. **Project foundation tickets (SETUP-001, 002, 003).** Flutter project init, layer scaffolding, Drift setup. Not in PRD because PRD is product-scoped. Must be re-created as build tickets downstream — flagging so they aren't forgotten.
6. **UI design system + GoRouter setup (UI-001, UI-002).** Same as above — foundation-build work the PRD assumes will happen but does not specify.
7. **Sync controller as a named deliverable (SYNC-004).** Functionally covered by FR-40/41/42/43 + NFR-1/2 but not called out as a Riverpod controller component.
8. **Performance/pagination as a discrete deliverable (POL-003).** Perf *targets* are in NFR-7 + FR-6, but pagination is not a named feature.

---

## Recommendation snapshot

- **Confirm with user:** the 16 "new scope" items above — especially Inventory, Treatment Planning, Day Closeout, Attachments, first-class Payments + partial-payment workflow. The PRD itself flags several with `[NEEDS VALIDATION]`; this reconcile makes the cumulative expansion visible.
- **Decisions needed:**
  - PDF export: drop from MVP (PRD position) vs. keep in MVP (todo.md position)?
  - Appointment filtering: explicitly drop or add FR?
  - Appointment edit + Patient edit FRs: add or leave as implicit?
- **Downstream build tickets to re-create from `todo.md`** (PRD does not capture them because they are not product behavior): SETUP-001, SETUP-002, SETUP-003, UI-001, UI-002, SYNC-004, POL-003 (pagination).
