---
title: PRD ↔ gaps.md Reconciliation
source-gaps: D:\Projects\DocCentral\gaps.md
source-prd: D:\Projects\DocCentral\_bmad-output\planning-artifacts\prds\prd-DocCentral-2026-05-21\prd.md
created: 2026-05-21
---

# Reconciliation: gaps.md against PRD draft

This document walks each of the 10 high-priority gaps from `gaps.md` and grades how the new PRD addresses it. Coverage grades:

- **Covered** — the PRD defines the canonical answer with explicit FR/NFR text.
- **Partial** — the PRD picks up the topic but drops nuance or leaves the qualitative depth of the gap unresolved.
- **Missed** — the PRD does not address the concern.

After the per-gap table, a **Silent Drops** section flags substantive ideas from `gaps.md` that the PRD did not pick up.

---

## Gap 1 — Workflow states are inconsistent

| Aspect | Detail |
|---|---|
| Gap concern | `todo.md` (`CHECKED_IN → COMPLETED → BILLED`) vs. `.rules/06-workflow.md`/`docs/usecases.md` (`IN_PROGRESS` present); invoice statuses also diverge. |
| PRD coverage | **Covered** |
| Where the PRD addresses it | Glossary §3 explicitly defines Visit lifecycle as `checked_in → in_progress → completed` and **drops** `BILLED` ("billed is derivable from existence of a non-DRAFT Invoice"). Appointment statuses fully enumerated (`scheduled`, `checked_in`, `completed`, `no_show`, `cancelled`, `rescheduled`). Invoice statuses canonicalized to `draft`, `unpaid`, `partially_paid`, `paid`, `void` — with status **derived** from payments. FR-12, FR-15, FR-18 mirror the Visit transitions; FR-26 mirrors the Invoice transitions. |
| Notes | The PRD takes an explicit decision (drop `BILLED`) rather than leaving ambiguity — strong resolution. |

## Gap 2 — Appointment-to-visit creation is ambiguous

| Aspect | Detail |
|---|---|
| Gap concern | Rules say visit must be created from appointment; usecases say "manually or automatically". |
| PRD coverage | **Covered** |
| Where the PRD addresses it | Glossary §3 ("A Visit is created when an Appointment is checked in"). FR-12 ("Check in a Patient ... transitions the Appointment to `checked_in` **and creates a corresponding Visit** in `checked_in` status"). The check-in **is** the visit-creation gesture; there is no manual/automatic ambiguity. |
| Notes | One canonical path. Clean. |

## Gap 3 — Testing requirements are not represented in the roadmap

| Aspect | Detail |
|---|---|
| Gap concern | `.rules/09-testing.md` requires unit, integration, sync-aware, optional UI tests per module; `todo.md` has zero test tickets. |
| PRD coverage | **Partial** |
| Where the PRD addresses it | Per-FR "Consequences (testable)" blocks make every FR independently verifiable. FR-39 mandates a unit test for permission-predicate parity. NFR-2 requires sync resilience be validated. SMC-3 counter-metric explicitly references `.rules/09-testing.md`. FR-40 prescribes an end-to-end test with network disabled. |
| What's still missing | The PRD does **not** require unit/integration/sync-aware/UI test categories per module as a delivery contract. SMC-3 actually pushes the other direction ("test coverage as a vanity metric"), which conflicts with the gap's intent. There is no NFR equivalent of "every module ships with the four test categories." Test discipline is left to downstream tickets. |

## Gap 4 — RBAC is underspecified

| Aspect | Detail |
|---|---|
| Gap concern | `.rules/07-permissions.md` requires action-based permissions enforced at **router**, **Riverpod**, and **domain** layers. `todo.md` only mentions role model + permission checking + route guards. |
| PRD coverage | **Partial** |
| Where the PRD addresses it | §4.10 introduces RBAC. FR-38 enumerates the Dentist-only operations (unlock visit, void invoice, soft-delete patient, add/remove users, reopen day closeout). FR-39 explicitly requires **the same predicate** be shared between UI control visibility, route guards, and domain-layer validation — and asks for a unit test to prove it. NFR-9 mandates audit attribution on financial actions. |
| What's still missing | "Action-based" granularity from `.rules/07-permissions.md` is **not** carried forward. The PRD enumerates Dentist-only operations as a hardcoded list (FR-38) rather than as a permission matrix. The Riverpod-layer enforcement is collapsed into "UI control visibility" — the three layers (router / Riverpod / domain) are reduced to two (UI / domain). No permission matrix artifact is committed to. §6.2 explicitly removes the configurable role/permission editor. |

## Gap 5 — The roadmap does not fully reflect the database model

| Aspect | Detail |
|---|---|
| Gap concern | `docs/database.md` defines clinics, users, roles, and join tables; `todo.md` skipped identity/clinic persistence. |
| PRD coverage | **Covered** |
| Where the PRD addresses it | Glossary §3 defines Clinic, User, Role explicitly. §4.1 covers clinic provisioning (FR-1), persistent session (FR-2), and adding staff (FR-3). FR-1's testable consequences enumerate Clinic record, initial Dentist with `is_clinic_owner=true`, and the three Role records (Dentist/Assistant/Nurse) with default permission bundles. NFR-9 mandates audit fields on financial entities. The schema is explicitly multi-tenant by `clinic_id` (§2.4). |
| Notes | Identity and clinic persistence are first-class. Whether the join tables from `docs/database.md` survive verbatim is a downstream schema decision. |

## Gap 6 — Sync behavior needs more operational detail

| Aspect | Detail |
|---|---|
| Gap concern | Drift authoritative, sync-tracked entities, last-write-wins — but `todo.md` only had generic push/pull tasks. Queue states, conflict scope, per-entity behavior unclear. |
| PRD coverage | **Partial** |
| Where the PRD addresses it | §4.11 has dedicated feature with FR-40 (offline), FR-41 (push), FR-42 (pull), FR-43 (last-write-wins on `updated_at`). FR-43 carves out **financial records (Invoice, Payment)** as conflict-surfaced-not-silent — this is real per-entity behavior. Glossary §3 defines Sync Status enum (`pending`, `synced`, `conflict`). NFR-1, NFR-2 reinforce. §9.2 says system MUST NOT silently overwrite financial records. |
| What's still missing | The Sync Status enum is defined but the **queue model** (ordering, batching, idempotency, retry behavior beyond exponential backoff cap) is left implicit. No per-entity table that says "Patient: silent LWW; Invoice: surface conflict; Attachment: ???". No explicit treatment of attachment-blob sync semantics vs. row sync. No specification of "what counts as a conflict" beyond `updated_at` comparison. |

## Gap 7 — Financial rules are not fully pinned down

| Aspect | Detail |
|---|---|
| Gap concern | `docs/usecases.md` had `UNPAID` and `PARTIALLY_PAID`; `todo.md` collapsed to `DRAFT → PAID → VOID`. |
| PRD coverage | **Covered** |
| Where the PRD addresses it | Glossary §3 defines Invoice with full status set: `draft`, `unpaid`, `partially_paid`, `paid`, `void` — and clarifies status is **derived** from payments (except `void` which is explicit). FR-26 specifies the exact state-machine transitions on payment recording. FR-27, FR-28 make Outstanding Balance and the "patients who owe" list first-class. NFR-3 (deterministic computation), NFR-4 (immutability of paid records) reinforce. |
| Notes | This is the most thoroughly resolved gap in the PRD. Voiding semantics, refund-deferral, and per-payment attribution are all explicit. |

## Gap 8 — Localization requirements are too shallow in the roadmap

| Aspect | Detail |
|---|---|
| Gap concern | `.rules/08-l10n.md` requires no hardcoded strings + Arabic RTL; `todo.md` only said EN/FR/AR. |
| PRD coverage | **Covered** |
| Where the PRD addresses it | §4.12 dedicated feature. FR-44 (three-language switch + RTL flip on AR + per-User persistence). FR-45 (locale-aware date/time/currency formats, no restart). NFR-5 ("No hardcoded user-facing strings in code. All UI text loaded from translation files."). NFR-6 ("Arabic locale renders correctly in RTL for all screens, including form fields, lists, and modals."). |
| Notes | NFR-5 and NFR-6 lift the `.rules` requirements to explicit acceptance criteria. Translation storage mechanism (file format, key convention) is intentionally not specified — architecture concern. |

## Gap 9 — UI architecture constraints are not explicitly planned

| Aspect | Detail |
|---|---|
| Gap concern | `.rules/05-ui.md` requires page-only Riverpod access, dumb child widgets, LayoutBuilder-based responsive layouts; `todo.md` had only design system + module screens. |
| PRD coverage | **Partial** |
| Where the PRD addresses it | §11 acknowledges the rule: "Per `.rules/05-ui.md`, only top-level pages access Riverpod; child widgets are pure. The PRD takes no further position on UI implementation — handed to the UX skill and the architecture skill." |
| What's still missing | The page-only Riverpod constraint is **named** but not lifted into an enforceable NFR. The "dumb child widgets" expectation is restated. The **LayoutBuilder-based responsive layouts** requirement is **silently dropped** — desktop-only is asserted (§5) but responsive intra-window behavior is not. The PRD does not commit to enforcing these as acceptance criteria; they live as a delegation to downstream artifacts. |

## Gap 10 — Auditability and clinic administration are not explicit roadmap items

| Aspect | Detail |
|---|---|
| Gap concern | `docs/usecases.md` includes clinic profile, staff administration, auditability; `todo.md` has none of these as tickets. |
| PRD coverage | **Partial** |
| Where the PRD addresses it | **Staff administration:** FR-1 (clinic + initial user provisioning), FR-3 (Dentist adds Assistant/Nurse Users from Clinic Settings). **Clinic profile:** §11 lists Settings → "clinic profile, users & roles, language preference" as a top-level surface. **Audit attribution on financial actions:** NFR-9 ("Every Invoice, Payment, Void, Day Closeout, and Closeout Reopen records `*_by_user_id` and a UTC timestamp."). FR-13 (Cancellation actor), FR-19 (unlock logged), FR-31 (stock adjustment log), FR-37 (reopen-day logged) all carry per-action attribution. |
| What's still missing | **No general audit-log feature.** Attribution is scattered across individual FRs as `recorded_by_user_id`/timestamp pairs — there is no single "audit trail" entity, no audit-view screen, no append-only audit log. The clinic profile management FR is implied by §11 but not actually written as an FR. Auditability is satisfied as "attribution exists" but not as "audit trail is browsable / exportable / immutable as a system property." There is also no audit coverage for **clinical** actions (visit edits, diagnosis changes) — only financial. |

---

## Summary Counts

| Grade | Count | Gaps |
|---|---|---|
| Covered | 4 | 1, 2, 5, 7, 8 (5 actually) |
| Partial | 5 | 3, 4, 6, 9, 10 |
| Missed | 0 | — |

(Re-counting: Covered = 1, 2, 5, 7, 8 → **5**. Partial = 3, 4, 6, 9, 10 → **5**. Missed = **0**.)

---

## Silent Drops

Substantive concerns from `gaps.md` (or its Suggested Follow-Ups, §gaps.md lines 60-67) that the PRD does **not** carry forward. These are the items the user may want to know were dropped.

1. **The "every module ships with unit + integration + sync-aware + (optional) UI tests" delivery contract from `.rules/09-testing.md`.** The PRD acknowledges testing exists (per-FR Consequences, FR-39's permission-parity test, FR-40's offline E2E test) but actively **deprioritizes** test discipline as a metric (SMC-3). The four test categories are not lifted into an NFR. *Severity: high — this is a deliberate inversion of the gap's intent, not just an omission.*

2. **The three-layer permission enforcement model (router / Riverpod / domain) from `.rules/07-permissions.md`.** The PRD collapses this to two layers ("UI control visibility" + "domain") in FR-39. Riverpod-level enforcement is not mentioned. The "action-based" granularity is replaced by a hardcoded enumeration of Dentist-only operations in FR-38. No permission matrix artifact is promised. *Severity: medium-high — the gap explicitly called out three layers and they are silently merged.*

3. **A per-entity sync behavior matrix.** FR-43 carves out financial records as conflict-surfaced, but no equivalent treatment is given for Patient, Visit, Treatment Plan, Inventory, Attachment, or Day Closeout. The Sync Status enum is defined but the **queue mechanics** (batching strategy, ordering guarantees, idempotency, what constitutes a conflict beyond `updated_at`, how attachment binaries sync versus their row metadata) are left implicit. *Severity: medium — the gap explicitly asked for per-entity behavior.*

4. **LayoutBuilder-based responsive layouts from `.rules/05-ui.md`.** The page-only Riverpod and dumb-children expectations are at least named in §11. The responsive-layout requirement is **completely absent** from the PRD — there is no FR or NFR that says screens must adapt to window size. Desktop-only is asserted but window resizing behavior is unspecified. *Severity: low-medium — easy to recover in downstream artifacts but a clean drop here.*

5. **A general audit-trail entity / surface.** NFR-9 covers attribution on financial actions only. There is no audit log for clinical actions (visit edits, diagnosis changes, treatment-plan edits), no audit-viewing screen, no notion of an append-only audit table. The gap's "auditability" concern is satisfied narrowly (financial attribution) rather than broadly (system-wide audit trail). *Severity: medium — depending on whether the dentist treats the clinic as a regulated entity, this could become a compliance gap at commercialization.*

6. **The "acceptance criteria per roadmap item so completion is unambiguous" suggestion from gaps.md line 67.** The PRD does meet this in spirit via per-FR "Consequences (testable)" blocks — but those Consequences are not labeled as acceptance criteria, are not lifted to a per-FR contract, and the testable Consequences are inconsistent in depth. *Severity: low — substantively met, formally not.*

7. **Conflict UX detail.** The PRD says conflicts on financial records are "surfaced as a warning to the User" (FR-43) but does not describe **what the surface looks like**, who acts on it, whether it blocks further work, or how a user reconciles the conflict. The Consequences for FR-43 stop at "based on `updated_at`". Open Question 1 acknowledges FR-43 needs validation. *Severity: medium — the gap flagged conflict scope as unclear, and the PRD adds policy ("never silent for finance") but no UX.*

---

## What the PRD did especially well

For balance, the PRD over-delivered on three gaps:

- **Gap 7 (financial rules)** is exhaustively pinned down — derived status, immutability, void semantics, refund deferral, payment attribution, outstanding-balance computation are all explicit.
- **Gap 1 (workflow states)** is resolved with explicit decisions (drop `BILLED`, derive invoice status) rather than reconciled by enumeration alone.
- **Gap 8 (l10n)** lifts both `.rules/08-l10n.md` requirements into NFRs (no hardcoded strings, RTL correctness) rather than treating language list as the whole concern.

---

*End of reconciliation.*
