# PRD Quality Review — DocCentral MVP

## Overall verdict

This is a **strong** PRD for what it is: a learning-project / single-clinic MVP authored honestly by a drafter who knows the engineering surface but not the user's workflows. The thesis ("paper-and-WhatsApp's replacement, not enterprise EHR"), the disciplined `[NEEDS VALIDATION WITH CLINIC]` tagging, the data-model determinism around money, and the counter-metrics (SMC-1/2/3) all show real product judgment. What's at risk is **done-ness clarity in two scope-poisoning places**: the cross-feature implications of "Assistant has wide default permissions" vs. the Dentist-only FR-38 list, and the silent assumption that the procedure catalog exists as a first-class entity without any FR to create/manage it. A handful of cross-references and ID gaps also need cleanup before this becomes a downstream source-of-truth for stories.

## Decision-readiness — strong

The PRD reads like decisions, not deliberations. The Vision (§1) commits to a specific competitor ("paper folder, Excel sheet, WhatsApp thread combined") rather than the safe "comprehensive clinic software" framing. §2.4 Non-Users is unusually disciplined — it names patients, nurses, multi-clinic operators, accountants, and lab techs as *out* with reasons. §4.11 commits to last-write-wins with "financial records surface conflict, do not block" — that's a real call, not a hedge. The decision log shows where pivots happened (Coaching → Fast-path mid-session) and they land in the PRD with explicit tags rather than being papered over.

Open Questions are genuinely open — Q1 explicitly defers procedure-catalog-vs-free-text, Q3 explicitly defers single-vs-multi-device sync (which has dramatic architectural implications), Q8/Q9 acknowledge real "could-creep-into-MVP" tensions. The `[NOTE FOR PM]` callouts on §5 Non-Goals (PDF invoice export, appointment reminders) sit at *real* tensions where the dentist might push back, not at safe checkpoints.

One area of dodge: §4.5 Treatment Planning is flagged for possible scope reduction, but Risks (row 3) says "can be removed from MVP without affecting Visit, Invoice, or Calendar flows" — which is contradicted by FR-22, where mark-performed creates Performed Treatments. Removing Treatment Plans without rewriting the Visit flow leaves an orphan FR.

### Findings
- **medium** Treatment-Plan-removability claim contradicts FR-22 (§12 Risks row 3 vs §4.5 FR-22) — Risks says §4.5 is isolated and removable, but FR-22 binds Treatment Plan state transitions into the Visit lifecycle. *Fix:* either weaken the Risk row to "removable with a 1-day Visit-flow refactor" or sever FR-22 so Performed Treatments are always created ad-hoc on the Visit, with planned-treatment selection as a pure UI affordance.
- **low** §1 Vision phrasing "paper-and-WhatsApp's replacement" reads as a typo for "paper and WhatsApp's replacement" or "paper-and-WhatsApp replacement." *Fix:* normalize to "the replacement for paper + WhatsApp."

## Substance over theater — strong

No persona theater — exactly two personas surfaced in UI plus one "preserved for forward-compat" (Nurse) with explicit rationale. Both personas drive concrete FRs (the Assistant is named in 23 places; the Dentist-only restrictions in FR-38 traceably reflect the clinical-vs-administrative divide). No innovation theater — there is no "differentiation" section pretending DocCentral is a category creator; instead §1 is honest that the wedge is "faster and more legible than paper + Excel + WhatsApp."

NFRs (§8) mostly avoid boilerplate: NFR-3 ("no path exists for UI to set Invoice total directly") and NFR-9 ("schema enforces *_by_user_id and timestamp not null") are product-specific thresholds, not "system must be secure." NFR-7 has real numbers (4s cold-launch, 2s landing, 500ms navigation). NFR-2 ("Local DB is authoritative") is a real architectural call.

The few weak spots: NFR-1 ("Offline-first") restates §4.11 and could be merged. NFR-6 ("RTL correctness... for all screens, including form fields, lists, and modals") is closer to an acceptance criterion than an NFR — without a verification approach, it's an aspiration. NFR-8 on data residency is half-decision, half-deferral (EU region picked, but with `[ASSUMPTION]` and no consequence-if-wrong).

### Findings
- **low** NFR-6 "RTL correctness" lacks a verification bound (§8 NFR-6) — "renders correctly in RTL for all screens" with no way to fail it. *Fix:* either name a specific RTL test pass (e.g., "all screens in Appendix A render without visual regression against FR layout baseline") or move this to a §11 IA constraint.
- **low** NFR-1 duplicates §4.11 (§8 NFR-1 vs §4.11 description) — restates "offline-first works without internet" already covered by FR-40. *Fix:* delete NFR-1 or compress to a pointer.

## Strategic coherence — strong

The PRD has a clear thesis stated twice for emphasis (§1 ¶2 and §1 ¶3): **win on legibility-vs-paper, not feature-parity-vs-enterprise; earn v2 by landing v1 at one clinic**. Every feature in §6.1 traces to one of the four "felt pains" named in §1: payment tracking → §4.6, calendar drift → §4.3 + FR-13, inventory blind spots → §4.7, patient history retrieval → §4.2. Treatment Planning (§4.5) is the one feature that doesn't traceably serve a stated felt pain — and it's appropriately flagged for validation/possible cut.

Success Metrics validate the thesis, not activity: SM-1 measures adoption against the four pain points (not DAU); SM-2 directly validates the calendar-drift wedge; SM-3 validates the financial integrity claim. The counter-metrics are unusually mature for an MVP — SMC-1 explicitly de-prioritizes feature count, SMC-2 names the most likely failure mode ("optimizing for the commercial branch before v1 lands"), SMC-3 is sharp on the test-coverage trap.

MVP scope kind is correctly identified as problem-solving (felt-pain wedges) rather than experience or platform. The scope logic matches.

One subtle coherence gap: §1 names "patient history that is hard to retrieve when a returning patient is in the chair" as a felt pain, and FR-7 addresses it — but there is no SM that validates *retrieval speed in the moment of care*. SM-1 collectively addresses it via informal survey, but the most concrete pain-point gets the loosest measurement.

### Findings
- **medium** Patient-history retrieval pain has no dedicated SM (§7 vs §1 ¶2 pain #4) — three felt pains have dedicated SMs (calendar drift → SM-2, payments → SM-3, plus general SM-1), but "hard-to-retrieve patient history in the chair" gets only SM-1's informal survey. *Fix:* add an SM around Patient File open-to-history-visible time (FR-7 already specs 500ms) — measured weekly by the assistant or by app instrumentation.

## Done-ness clarity — adequate (with two material gaps)

Most FRs are well-formed: behavioral statement + testable consequences with measurable outcomes (300ms search, 500ms file render, "Patient does not appear in search," "Visit ended_at is set"). FR-6, FR-7, FR-12, FR-13, FR-18, FR-23, FR-26 all read like an engineer could write the test before the code. That's strong.

**Two material gaps:**

1. **The procedure catalog has no CRUD FR.** FR-16 says "procedure name (free text or selected from a Clinic-defined catalog [ASSUMPTION: catalog is in MVP scope — see Open Question 4])," FR-20 says "procedure name" without referencing a catalog. But there is no FR-N for "create/edit a procedure catalog entry," no glossary entry for "Procedure" or "Procedure Catalog," and the data model implication (catalog table with default unit prices, scoped to Clinic) is unsaid. If Q1/Q2 resolves "yes catalog," at least one FR is missing and the §6.1 in-scope list doesn't mention it. *(Note: Open Question 2 is "procedure catalog," not Q4 as FR-16 mis-references.)*

2. **The Assistant's permission scope is implicit-by-omission.** §2.1 says she is "the most active app user" with implicit wide permissions; FR-38 lists what the Dentist *can* do that the Assistant cannot, and FR-39 says permission rules are shared across UI and domain — but there is no FR-N stating "any non-restricted operation is permitted for the Assistant role." A literal reading of FR-39 with no positive Assistant-permission spec would leave the permission matrix indeterminate.

Other gaps:

- FR-26 status-transition phrasing has a bug: "Invoice status transitions automatically: `draft → unpaid` on first attempt to set non-draft." There is no event "first attempt to set non-draft" defined elsewhere — `draft` is the auto-created state from FR-23, and `unpaid` should be reached when the user *finalizes* the Invoice (leaves draft mode) or *records the first Payment*. As written, an engineer can't implement this consequence.
- FR-17 "Edits autosave or are explicitly saved [ASSUMPTION: autosave on field blur]" is two different products. Pick one.
- FR-19 ("Unlock a completed Visit") says unlock is rejected if any Payment exists; but the FR-26 consequence says Payments can be recorded against `unpaid` Invoices and Invoice status moves through `partially_paid → paid`. There's no FR specifying *when* the Invoice transitions out of `draft` — i.e., when the "finalize this Invoice and accept Payments" action happens. Without that, FR-19's "Invoice still in draft" gate is undefined in time.
- FR-37 reopen-day window is left to Open Question 10 — fine, but FR-37 should state the assumed-default behavior pending resolution.

### Findings
- **critical** Procedure catalog is referenced but unspecified (§4.4 FR-16, §4.5 FR-20, §3 Glossary, §6.1, §14 Assumption 6) — Assumption 6 says "catalog is in MVP scope" but no FR creates/edits catalog entries, no Glossary term defines them, §6.1 in-scope list omits them. *Fix:* add FR-N "Manage Procedure Catalog" under §4.4 or a new sub-section; add **Procedure** and **Procedure Catalog Entry** to §3 Glossary; cross-reference correctly (FR-16 says "see Open Question 4" but procedure catalog is Q2). If catalog is deferred pending validation, the assumption needs to flip to "free-text procedure entry in MVP, catalog is v2" and FR-16/FR-20 need to reflect that.
- **high** Assistant's permission scope is undefined (§4.10 FR-38, FR-39) — Dentist-only restrictions are enumerated, but no FR states the Assistant's positive permissions. *Fix:* add FR-N "Assistant default permissions" listing the operations she can perform (everything not in FR-38), or restructure §4.10 around a permission matrix.
- **high** Invoice state transition "draft → unpaid" trigger is undefined (§4.6 FR-26 consequence 2) — "on first attempt to set non-draft" is not a defined event anywhere. *Fix:* either add an explicit "Finalize Invoice" FR (Assistant action that takes Invoice from `draft → unpaid`), or change the rule to "`draft → unpaid` when the first Payment is recorded" (and define what happens to a `draft` Invoice with no Payments — does it linger forever?).
- **medium** FR-17 autosave vs. explicit-save left open inside the FR itself (§4.4 FR-17) — the ASSUMPTION tag is inside the consequence, not deferring the FR's behavior. *Fix:* pick one for the draft; let validation flip it if needed.
- **medium** FR-19 unlock gate references an Invoice state ("still in draft or unpaid") whose entry condition isn't defined (§4.4 FR-19) — couples to the FR-26 issue above. *Fix:* resolves with FR-26 fix.
- **low** FR-37 reopen-day default unstated (§4.9 FR-37) — Q10 defers the window but FR-37 should still state the MVP default (likely "no time limit"). *Fix:* add "default: no time limit; revisit per Q10."

## Scope honesty — strong

§5 Non-Goals is doing real work: 14 explicit exclusions, each at a place where an engineer (or the dentist) might silently assume the opposite. The `[NOTE FOR PM]` callouts on PDF invoice export and appointment reminders sit at exactly the tensions where scope creep is most likely. §6.2 restates Non-Goals in MVP-scope language — slight duplication, but reinforces the boundary.

The `[ASSUMPTION]` discipline is real: 15 indexed assumptions, each cross-referenced to an FR. The `[NEEDS VALIDATION WITH CLINIC]` tags are honest about the journey-narration weakness (§2.5 UJ-1, UJ-5, UJ-6, UJ-7 — i.e., 4 of 10 UJs flagged) — which would be a blocker if the stakes were "ship to enterprise" but is correctly calibrated for "improvised second-hand by the engineer."

Open Question density (10 items) is **right** for a learning-project MVP with deliberate validation gaps. None of the 10 is a rhetorical question; all have material implications.

The migration section (§10) is honest about its limits: parallel running for 2–4 weeks acknowledged but not prescribed; no retro-data import for historical Visits/Invoices is explicit.

One soft area: §9.2 Safety has two bullets ("MUST NOT silently overwrite financial records," "MUST NOT delete records — only soft-delete") and feels thin given the stakes (PHI, money). For a learning project this is acceptable, but Safety as a section is presented as more comprehensive than it is.

### Findings
- **low** §9.2 Safety section is thinner than it presents (§9.2) — two bullets for a domain that handles PHI + financial records. *Fix:* either add 2–3 more bullets (e.g., "audit log is append-only," "no SQL operation can bypass the domain layer for financial entities") or remove the §9.2 header and merge with §9.1.

## Downstream usability — adequate

The PRD is meant to feed beads issues (per §0 and decision log), which is a *moderate* downstream demand — not full UX → architecture → stories chain, but enough that traceability matters. Most pieces are in place:

- **Glossary (§3) is unusually thorough** — 19 entries, each used by FRs. The "Visit is distinct from Appointment," "Invoice status is derived from Payments," "Outstanding Balance is computed never stored" definitions will save downstream conversations.
- **FR IDs are contiguous from FR-1 to FR-45**, no gaps. **NFR IDs FR-1 to NFR-9** clean. **UJ-1 to UJ-10** clean. **SM-1 to SM-5 + SMC-1 to SMC-3** clean.
- **Cross-references mostly resolve**: FR-13 → UJ-4, FR-23 → FR-18, FR-25 → FR-19 → FR-25, FR-38 → FR-3/8/19/25/37.

**But:**

- **FR-16 cross-reference is broken**: "[ASSUMPTION: catalog is in MVP scope — see Open Question 4]" — Open Question 4 is "Default appointment duration." Procedure catalog is **Open Question 2**.
- **Glossary drift on "User"**: §3 defines User as "a person with login credentials"; FR-3 says "send invite (or set initial password)" — fine; but FR-26 says "amount, method (default: `cash`), date, `recorded_by_user_id`" while FR-36 says "actor, and timestamp." Inconsistent — sometimes `*_by_user_id`, sometimes "actor." NFR-9 uses `*_by_user_id`. The Glossary doesn't name "actor" as a synonym.
- **Glossary missing terms** that get used: "Procedure" / "Procedure Catalog" (used in FR-16, FR-20), "Performed Treatment" exists but "Planned Treatment" is defined under Treatment Plan rather than as its own entry, "Day Closeout" entry doesn't explicitly say the entity stores `delta` even though FR-36 does.
- **UJ persona linkage is clean** — every UJ names "The Assistant" or "The Dentist" by §2 label.
- **Each section pulled out alone**: works for §4.x features; less for §7 SMs ("Validates FR-4 through FR-37 collectively" is a lot of FRs for an SM to validate).

### Findings
- **medium** FR-16 cross-reference points to the wrong Open Question (§4.4 FR-16) — "see Open Question 4" should be Open Question 2. *Fix:* change reference to Q2.
- **medium** "Actor" vs. "recorded_by_user_id" drift across FRs/NFRs (§3 Glossary, FR-13, FR-19, FR-26, FR-30, FR-36, FR-37, NFR-9) — terminology mixed. *Fix:* pick one (NFR-9 already standardizes on `*_by_user_id`); make Glossary "User" entry explicit, and replace "actor" prose with "recording User" or the field name.
- **low** Glossary missing **Procedure / Procedure Catalog Entry** (§3) — used in FR-16, FR-20 but not defined. *Fix:* add after resolving the catalog scope question.
- **low** §7 SM-1 validates "FR-4 through FR-37 collectively" (§7 SM-1) — that's a 34-FR collective validation, which is effectively "the whole product works." *Fix:* either narrow to the felt-pain FRs (FR-4–8, 12–14, 23–28, 29–32, 35–37) or accept that SM-1 is the global adoption metric and SM-2/3/4/5 are the narrow ones.

## Shape fit — strong

The PRD is correctly shaped for what it is: **internal tool / single-clinic deployment** with multi-stakeholder (two-persona) UX where journeys *are* load-bearing because the engineer doesn't know the workflows. The Personas + Journeys path was the right call given the engineer's information gap — and the resulting PRD is honest that the journeys are improvised (`[NEEDS VALIDATION]` on 4 of 10 UJs).

Length (~12-13 effective pages by section count, though the user's decision log says they aimed for ~5-8pp) is on the high side for a single-clinic MVP. The expansion is mostly in §3 Glossary (justified — it'll be referenced downstream), §4 Features (justified — FRs are the artifact downstream needs), §13 Open Questions (justified — they're the validation interview agenda), and Appendix A (justified — it's literally the validation interview question sheet). Nothing is bloat.

The PRD does NOT overformalize for a brownfield migration: §10 Migration is a half-page rather than a full migration plan, which is correct (deployment is downstream).

The PRD also does not under-formalize: there are FRs not aspirations, an Assumptions Index not free-floating hedges, Risks with severity ratings, Counter-metrics.

One shape-fit nit: §11 Information Architecture is a list of 7 top-level surfaces, which is borderline UX territory rather than PRD territory. §0 says "handed to the UX skill and the architecture skill" — fine, but if §11 is in the PRD it should either say more (e.g., "navigation model: sidebar vs top-nav left to UX") or less (cut and let UX own it). As written, it's a peek into UX decisions without committing.

### Findings
- **low** §11 IA section straddles PRD/UX boundary (§11) — lists 7 top-level surfaces but disclaims further position. *Fix:* either reduce to a single sentence ("The MVP exposes ~7 primary surfaces — list TBD by UX") or keep the list and add the constraint it implies (e.g., "no top-level surface for Treatment Plans — they live under Patient File"; "no top-level surface for Reports").

## Mechanical notes

- **ID continuity:** clean. FR-1..45, NFR-1..9, UJ-1..10, SM-1..5, SMC-1..3, Q1..10 all contiguous. No duplicates.
- **Assumptions Index roundtrip:** 15 entries indexed, all match inline `[ASSUMPTION]` tags. Checked: §4.1 FR-2 ✓, §4.3 FR-9 (two assumptions) ✓, §4.3 FR-10 ✓, §4.4 FR-16 ✓, §4.4 FR-17 ✓, §4.6 FR-26 ✓, §4.7 FR-29 ✓, §4.8 FR-33 ✓, §4.8 FR-34 ✓, §4.11 FR-41 ✓, §4.11 FR-43 ✓, §4.12 FR-45 ✓, §9.1 SQLCipher ✓, §9.1/NFR-8 EU region ✓. Round-trip is clean.
- **UJ persona linkage:** all 10 UJs name a defined §2 persona by exact label ("The Assistant" or "The Dentist"). Clean.
- **Glossary drift:** "actor" vs. "recorded_by_user_id" (medium, noted above). "Visit" / "Appointment" / "Invoice" / "Payment" used consistently. "Performed Treatment" vs. "Planned Treatment" both used consistently.
- **Broken cross-reference:** FR-16 → "Open Question 4" should be "Open Question 2" (medium, noted above).
- **Required sections present for stakes:** Vision ✓, Persona ✓ (2), JTBD ✓, Non-Users ✓, UJs ✓, Glossary ✓, Features+FRs ✓, Non-Goals ✓, MVP Scope ✓, SMs ✓, NFRs ✓, Constraints ✓, Migration ✓, IA ✓, Risks ✓, Open Questions ✓, Assumptions Index ✓, Validation Interview Sheet ✓. Nothing missing for the agreed stakes.
- **Status:** `draft`. Reviewer gate at Finalize will catch the critical FR (catalog) and high FRs (Assistant permissions, FR-26 trigger) before close.
