# Structural Polish Review — DocCentral MVP PRD

**Verdict:** trim aggressively

The PRD is roughly 30–40% over its stated 5–8 page target for "learning project with one real customer" stakes. Multiple sections duplicate each other (Non-Goals vs MVP Out-of-Scope is the worst offender), an entire Appendix and Index re-encode content already inline, and several "earned its place" sections (Doc Purpose, Migration, IA) are doing furniture work rather than load-bearing work.

---

## Proposed Cuts (high-confidence)

### Cut entirely

- **§0 Document Purpose.** Says "this is a PRD, it supersedes other docs, FRs are grouped under features, downstream goes to beads." None of this is product content; it's meta-narration for an audience that won't read it. Remove; move the one load-bearing sentence ("FRs grouped under features; UJ-N numbered globally; `[NEEDS VALIDATION]` tags mark inferences") into a one-line note under the title.

- **§14 Assumptions Index.** Every entry is already tagged inline as `[ASSUMPTION: ...]` at the FR it affects. A flat re-list adds no signal — the validation interview will hit them via the FR cross-refs in Q1. Cut and rely on inline tags + Open Questions Q1.

- **Appendix A — Validation Interview Question Sheet.** Useful operational document, but it is not PRD content. Move to a separate `validation-interview.md` sibling file, or to the addendum. Removing it alone reclaims ~1 page.

- **§11 Information Architecture.** Seven bullets listing screens already implied by §4 Features, plus a pointer to `.rules/05-ui.md`. The IA decision belongs in the UX spec, not the PRD. Cut.

- **Risk row "Sync conflicts on financial records cause data loss"** in §12. Not a risk — the mitigation (FR-43) is already a hard requirement. It's a restatement of an FR. Cut row.

- **Risk row "Encryption-at-rest performance impact"** in §12. Severity "Low–Medium" with mitigation "revisit during deployment" — this is an Open Question (and is already Q5), not a risk. Cut row, keep Q5.

- **SMC-3 (Test coverage as vanity metric)** in §7. This is a process rule about how to write tests, not a product counter-metric. Cut.

- **§2.4 Non-Users** redundancy with **§5 Non-Goals**: "no patients", "no nurses UX", "no multi-clinic", "no accountants", "no lab portal" all reappear verbatim in Non-Goals. Cut §2.4 entirely; Non-Goals already covers it. (Or, less aggressively, reduce §2.4 to a single sentence.)

### Trim heavily

- **§1 Vision.** Three paragraphs where one would do. ¶1 and ¶2 say the same thing twice ("replaces paper + Excel + WhatsApp", "wins by being faster than paper + Excel + WhatsApp"). Cut ¶2 entirely; the four felt pains can move into a single sentence inside the JTBD section if needed.

- **§2.1 / §2.2 Persona prose.** The biographical paragraphs ("She is the most active app user...", "He is the sole clinical practitioner...") restate facts that drive no decisions a reader couldn't infer from the JTBD list. Reduce each persona to: one-line role descriptor + the JTBD list. Drop the prose.

- **§3 Glossary.** ~25 entries, several of which add no information beyond the obvious (Clinic = "the tenant root", User = "person with login credentials", Sync Status = "per-record marker"). Cut entries that don't introduce non-obvious semantics: **Clinic, User, Role, Attachment, Restock Event, Low-Stock Alert, Sync Status.** Keep entries that encode contested or domain-specific meaning: Visit, Procedure, Performed Treatment, Treatment Plan, Invoice, Invoice Item, Payment, Outstanding Balance, Cancellation, Lab Work Flag, Day Closeout.

- **§10 Migration from Paper.** Five bullets where two would do. The "Downstream build tickets in beads" bullet is meta-process, not migration; cut it. The "Parallel-running period" bullet is a deployment decision that explicitly says "the PRD does not prescribe a cutover strategy" — so cut it.

---

## Proposed Merges

- **§5 Non-Goals + §6.2 MVP Out of Scope → one section.** These are 95% the same list with minor wording differences. Reader hits the same content twice within two pages. Merge into a single "Out of Scope (MVP)" section. Keep §6.1 In Scope as the recap of §4.

- **§13 Open Questions + §14 Assumptions Index.** Every Assumptions Index entry maps to either an inline `[ASSUMPTION]` tag (already discoverable) or an Open Question. Fold the few Index entries that aren't already in Open Questions into Open Questions; cut the Index.

- **§12 Risks + §13 Open Questions.** Multiple "risks" in §12 are actually open questions awaiting validation ("Improvised assistant journey is wrong" → Q1; "Inventory over/under-built" → Q1's scope-of-consumables item; "Treatment Plans aren't how this dentist works" → Q1). The genuine risks are Adoption Failure and Scope Expansion. Reduce §12 to those two rows; everything else folds into Open Questions.

---

## Proposed Reorganizations

- **Move §10 Migration from Paper** to immediately after §6 MVP Scope (or fold into §6 as §6.3 Migration Constraint). It is currently buried after Constraints/NFRs/IA, but it materially shapes what "in scope" means (FR-5 only exists because of paper migration). Reading order should be: Vision → Personas → Glossary → Features → Scope (in/out + migration) → Success → NFRs → Risks/Questions.

- **§4 Features ordering.** Auth & Bootstrap (§4.1) is correctly first as a gate, but Roles & Permissions (§4.10) is placed at the end though it modifies every feature above it. Either move §4.10 to §4.2 (right after Auth, since RBAC is a cross-cutting model that the FRs reference), or absorb FR-38/FR-51/FR-39 into NFRs as a single permission contract. The current placement makes a reader hit FR-38 and have to backtrack to interpret earlier "Dentist-only" mentions.

- **§7 Success Metrics** comes after §6 Scope, which is fine — but SM-4 "render within 2 seconds" duplicates NFR-7 ("Today's Calendar < 2s after sign-in"). Either cite NFR-7 from SM-4 or drop SM-4 — but don't restate the threshold.

---

## Feature Internal Structure

- **§4.10 Roles & Permissions: FR-38 + FR-51 should merge.** FR-38 ("Dentist-only operations: X, Y, Z") and FR-51 ("Assistant can do everything EXCEPT X, Y, Z") are the same permission contract stated twice from opposite directions. Pick one direction (recommend FR-51's positive-Assistant + negative-Dentist list, since it's complete) and cut the other. As-is, a future schema change requires editing two FRs and risks drift — the exact failure mode FR-39 warns about.

- **§4.6 Invoicing: FR-26 + FR-50 boundary is muddy.** FR-26 (Record Payment) describes "Recording a Payment on a `draft` Invoice **finalizes the Invoice** as a side-effect", which mostly subsumes FR-50 (explicit finalize). FR-50 only adds the "finalize without payment" case. Consider folding FR-50 into FR-26 as a sub-consequence, or rename FR-50 to "Finalize without payment" so its scope is obvious from the title. Currently a reader meets FR-26's derived-status table and then FR-50 contradicts the implicit lifecycle.

- **§4.3 Calendar: FR-10 (day-view) and FR-11 (week-view) are over-decomposed.** Two FRs for two views of the same calendar widget, with near-identical Consequences. Merge as FR-10 "Calendar day and week views" with both performance targets as consequences.

- **§4.11 Sync: FR-41 + FR-42 + FR-43 could be one FR.** Push, Pull, and Conflict Resolution are three facets of one sync engine. Reader gets nothing from the trichotomy. Combine as a single "Bidirectional sync with last-write-wins conflict resolution" FR with three labeled consequence groups.

- **§4.7 Inventory: FR-30 (Restock) + FR-31 (Manual adjustment) could merge.** Both mutate `on_hand`; "restock" is just an adjustment with a supplier label. Combine as one FR with adjustment type (`restock` | `correction`).

- **FR-2 (sign-in offline) has an `[ASSUMPTION]` that is load-bearing for the entire offline-first claim.** This isn't an FR problem per se but a calibration one — flagging because the PRD currently buries a v2-blocker assumption inside a single FR's consequence bullet.

---

## Numbering and Cross-References

- **FR numbering gaps detected:** FR-1 through FR-51 referenced. Gaps: **FR-49 is intentionally skipped (noted in prompt).** No other FR gaps detected. Sequence appears continuous through FR-48, then jumps to FR-50, FR-51 (FR-49 skipped). Re-numbering after merges/cuts would consolidate this.

- **UJ-N references** are correct throughout. Each FR's "Realizes UJ-X" pointers all resolve.

- **§4.5 Treatment Planning Open Question 1 reference.** §4.5 cites "Open Question 1" but Q1 in §13 is the validation interview catchall, not a Treatment-Plan-specific question. The intended reference is probably Q1's sub-bullet "§4.5 entire Treatment Plan module". Tighten the cross-ref.

---

## Dead Furniture (specific lines/paragraphs)

- §1 Vision ¶3 ("In 6–12 months, success looks like...") — restates SM-1. Cut.
- §2.5 lead paragraph ("Numbered globally. Each UJ is tagged with the persona who drives it. Journeys derived from improvised narration...") — process commentary; the tags speak for themselves. Cut.
- §3 Glossary lead sentence ("Downstream artifacts must use these terms exactly. New domain nouns introduced in §4 are added here in the same pass.") — process commentary. Cut.
- §4 lead ("Each feature lists a behavioral description, FRs nested with global numbering, and optional feature-specific NFRs. Feature ordering reflects user-facing prominence, not implementation phase.") — process commentary. Cut.
- §7 lead paragraph about counter-metrics being "load-bearing because the temptation to over-build the app for future commercial value is the most likely failure mode" — useful only because SMC-1 and SMC-2 exist, and they already say the same thing. Cut.
- §8 lead ("System-wide non-functional requirements not tied to a single feature.") — definition of NFR. Cut.
- §9.2 Safety. Two bullets: "MUST NOT silently overwrite financial records" duplicates NFR-2 + FR-43; "MUST NOT delete records, only soft-delete" duplicates FR-8 + NFR-4. Cut §9.2.
- The closing italicized line "*End of PRD draft. Status: `draft`. Next step: walk through with user...*" — meta. Cut.

---

## Bloat Calibration vs. Stakes

For a single-clinic learning-project MVP, the load-bearing content is:

1. Who the users are and what hurts (Personas + JTBD) — currently bloated.
2. What gets built and what doesn't (Features + Scope) — appropriately sized, but In/Out duplication wastes space.
3. What "done" looks like (Success Metrics) — appropriately sized.
4. What we're not sure about (Open Questions) — appropriately sized.

Sections that **don't** need to exist at all at these stakes:

- Document Purpose (process)
- Information Architecture (UX skill's job)
- Assumptions Index (duplicates inline tags)
- Validation Interview Sheet (operational, separate doc)
- Migration section as a top-level §10 (fold into Scope)
- Safety section §9.2 (duplicates NFRs)

Cutting these and merging Non-Goals + Out-of-Scope + dedupe within Risks/Open-Questions should reclaim ~30–40% of the document and land it in the 5–8 page target.
