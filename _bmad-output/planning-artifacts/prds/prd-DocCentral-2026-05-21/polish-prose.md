# PRD Prose Polish — Findings

Sentence-level review of `prd.md`. Each finding lists location, issue, and suggested rewrite. No structural changes proposed.

---

## A. Glossary Drift (terminology used inconsistently with §3 Glossary)

### A-1. "patient profile" vs "Patient File"
- **Locations:** UJ-2 ("exposes the patient's **profile** with last 3 visits..."); UJ-4 ("recorded on the patient file"); UJ-9 ("opens the patient profile"); FR-7 title says **"Patient File view"** but FR-7 body says "Opening a Patient shows...".
- **Issue:** Glossary defines "Patient File" as the canonical term. "Profile" and lowercase "patient file" drift from it. UJ-2 in particular uses bold **profile** as if it were a UI label.
- **Suggested rewrite:** Replace "patient profile" / "patient file" with **Patient File** (capitalized, exact glossary term) everywhere in UJ-2, UJ-4, UJ-9, FR-7, FR-27, FR-46. If a different UI surface is intended, name it explicitly.

### A-2. "the family member's clinic" vs "the clinic"
- **Locations:** §0 ("a family member's clinic"); §1 ("the family member's clinic"); §2.4 ("The family member's clinic has no nurse."); §10 ("The family member's clinic currently runs on paper..."); SM-1, SM-2, SM-3 all say "the clinic".
- **Issue:** Mild drift — not Glossary-critical, but inconsistent register. Either commit to "the clinic" once introduced, or to "the family member's clinic" throughout.
- **Suggested rewrite:** Introduce "the family member's clinic" once in §0/§1, then use "the clinic" consistently. Audit §10 and §2.4.

### A-3. "treatments performed" vs "Performed Treatments"
- **Locations:** UJ-3 ("marks treatments performed"); UJ-6 ("marks performed treatments"); FR-22 consequences ("creates a Performed Treatment").
- **Issue:** Glossary term is "Performed Treatment" (capitalized noun). UJ-3 and UJ-6 use it as a verb phrase. Borderline because the prose is narrative, but inconsistent capitalization within FR consequences is a real drift.
- **Suggested rewrite:** In FR text and consequences, capitalize **Performed Treatment(s)** consistently. In UJ narrative, "marks treatments as performed" is acceptable; the capitalized form should appear in FRs.

### A-4. "Outstanding Balance" capitalization
- **Locations:** UJ-1 ("partial payment due from prior visit"); UJ-3 ("balance owed"); FR-27 / FR-28 / Glossary use capitalized **Outstanding Balance**.
- **Issue:** UJ-1 says "partial payment due" where the Glossary term "Outstanding Balance" applies. UJ-3 says "balance owed" for the same concept.
- **Suggested rewrite:** Where the field refers to the Glossary's computed value, use **Outstanding Balance**. Otherwise the term is hidden behind paraphrases.

### A-5. "low-stock" / "Low-Stock" / "Low Stock"
- **Locations:** UJ-1 ("low-stock consumables"); UJ-8 title; FR-32 title "Low-Stock Alerts surface"; §11 IA item 4 "low-stock alerts"; Glossary entry "Low-Stock Alert".
- **Issue:** Three casings of the same term.
- **Suggested rewrite:** Standardize on **Low-Stock Alert** (Glossary form) for the noun; "low-stock" (lowercase hyphenated) acceptable as adjective ("low-stock items").

### A-6. "consumables" vs "Inventory Item"
- **Locations:** §4.7 title "Inventory (Consumables)"; UJ-8 ("low-stock consumables"); Glossary defines **Inventory Item**.
- **Issue:** "Consumables" is informal; "Inventory Item" is the Glossary term. Both are used.
- **Suggested rewrite:** Use "Inventory Item" in FRs and consequences; "consumables" acceptable in narrative/description prose if framed as a colloquial gloss.

### A-7. "sign-up" / "sign-in" hyphenation
- **Locations:** FR-1 ("sign-up"); FR-2 ("sign-in"); FR-2 consequences ("Sign-out"); §6.1 ("Sign-in"). Generally consistent but check FR-1 consequences: "After completing sign-up...".
- **Issue:** Mostly consistent. Minor: confirm no instance of "signup" or "signin" (one word).
- **Suggested rewrite:** None needed — keep hyphenated forms.

### A-8. "morning side panel" vs "side panel" vs "Today's Calendar side panel"
- **Locations:** UJ-1 ("A side panel surfaces..."); FR-32 consequences ("morning side panel (UJ-1)"); FR-14 consequences ("morning side panel").
- **Issue:** "Morning side panel" appears in two FRs but is not defined as a named surface. UJ-1 calls it "a side panel".
- **Suggested rewrite:** Either name the surface in §11 IA (e.g., "Today's Calendar Side Panel") and use that term in FR-14 and FR-32, or drop "morning" and use "the Today's Calendar side panel".

---

## B. Hedge Words & Weasel Phrases

### B-1. "fast and tolerant" — §4.2 Description
- **Excerpt:** "Search is fast and tolerant."
- **Issue:** "Fast" and "tolerant" are aspirational. FR-6 already specifies 300ms; "tolerant" is undefined.
- **Suggested rewrite:** Delete the sentence — FR-6 carries the testable spec.

### B-2. "predictably" — FR-48 consequences
- **Excerpt:** "Filters compose (combining filters narrows results predictably)."
- **Issue:** "Predictably" is weasel-shaped. The FR consequences below already enumerate the expected intersection behavior.
- **Suggested rewrite:** "Filters compose: combining filters returns the intersection of all active filters."

### B-3. "clear error" — FR-38 consequences
- **Excerpt:** "An Assistant attempting any of these operations is rejected at the domain layer with a clear error."
- **Issue:** "Clear error" is untestable.
- **Suggested rewrite:** "...is rejected at the domain layer with a `PermissionDenied` error naming the required role." Or drop "clear" — let the contract speak.

### B-4. "the happy path" — FR-36 consequences
- **Excerpt:** "A delta of zero is the happy path; non-zero deltas are flagged but not blocked."
- **Issue:** "Flagged" is undefined (how — color, badge, modal?).
- **Suggested rewrite:** "A delta of zero is the expected case; non-zero deltas display a visible delta indicator on the Day Closeout record but do not block confirmation."

### B-5. "graceful" — not found (good).
- **Issue:** Sweep for "graceful" turned up zero hits.

### B-6. "user-friendly" / "intuitive" / "seamless" — not found (good).

### B-7. "appropriate" / "reasonable" — not found in FRs/consequences (good).

### B-8. "prominently" — §4.3 Description and FR-5 consequences
- **Excerpt 1:** "Lab-work-awaiting flags surface prominently." (§4.3)
- **Excerpt 2:** "The field is shown prominently in the Patient File view." (FR-5)
- **Issue:** "Prominently" is subjective.
- **Suggested rewrite:** Either replace with a concrete placement spec ("rendered above the fold on the Patient File header") or drop the adverb. For FR-5 consequence, "The field renders in the Patient File header section above Visits." For §4.3 description, "Lab Work Flags appear in calendar rows and on the Today's Calendar side panel." (this also fixes a B-class issue.)

### B-9. "tolerant" / "fast" / "in seconds" — JTBD bullets §2.3
- **Excerpts:** "Find a returning patient's prior visits, diagnoses, and outstanding balance in seconds."; "Know — at a glance — which patients owe the clinic money."
- **Issue:** These live in JTBD, which is narrative — likely acceptable as user-language. But "in seconds" / "at a glance" recur in FRs (see B-10), where they are not testable.
- **Suggested rewrite:** Leave JTBD as-is (user voice). Flag for FRs in B-10.

### B-10. "at a glance" — §2.3, FR-32 consequences
- **Excerpt:** "and as a count badge on the morning side panel (UJ-1)" — acceptable. But JTBD says "Know — at a glance — which patients owe the clinic money."
- **Suggested rewrite:** JTBD is narrative; leave. If "at a glance" reappears in an FR consequence, replace with the concrete UI surface.

### B-11. "sensible default" — Open Question 4
- **Excerpt:** "Is 30 minutes a sensible default..."
- **Issue:** "Sensible" is acceptable in an open question prompt (it's a question, not a contract). Leave.

### B-12. "load-bearing" / "felt pain" — §1, §7
- **Excerpt:** "it relieves four felt pains"; "Counter-metrics are still load-bearing".
- **Issue:** Author voice — narrative rather than spec. Acceptable but stylistically heavy.
- **Suggested rewrite:** Optional: "it addresses four pain points"; "Counter-metrics still matter, because..."

### B-13. "non-trivial" — NFR-10
- **Excerpt:** "(4) optional UI / widget tests for non-trivial widgets."
- **Issue:** "Non-trivial" is undefined.
- **Suggested rewrite:** "(4) optional UI / widget tests for widgets containing branching logic, conditional rendering, or stateful behavior."

### B-14. "lean default" — §12 Risks table
- **Excerpt:** "Lean default in MVP (manual adjustment + threshold alerts)"
- **Issue:** "Lean default" is jargon-y; the parenthetical already says what's actually in MVP.
- **Suggested rewrite:** Drop "Lean default in MVP" — leave "Manual adjustment + threshold alerts; validate scope with clinic before building auto-decrement or batch tracking."

### B-15. "realistic" — §10
- **Excerpt:** "The MVP must support a realistic onboarding path"
- **Issue:** "Realistic" is undefined.
- **Suggested rewrite:** "The MVP must support an onboarding path consistent with the clinic's current paper + Excel + WhatsApp workflow."

---

## C. Passive Voice that Obscures the Actor

### C-1. FR-1 consequences
- **Excerpt:** "The signing-up User is assigned the Dentist role with `is_clinic_owner = true`."
- **Issue:** Passive — who assigns?
- **Suggested rewrite:** "Sign-up assigns the signing-up User the Dentist role with `is_clinic_owner = true`."

### C-2. FR-2 consequences
- **Excerpt:** "Sign-out clears the session and returns to the sign-in screen."
- **Issue:** Active — fine. (Listed for contrast.)

### C-3. FR-9 consequences
- **Excerpt:** "An Appointment is created in `scheduled` status."
- **Issue:** Acceptable — actor is the creating User from the FR body. Pattern is common in consequences. Leave.

### C-4. FR-12 consequences
- **Excerpt:** "A new Visit record is created, linked to the Appointment and Patient."
- **Issue:** Same pattern as C-3; acceptable.

### C-5. FR-13 consequences
- **Excerpt:** "The cancelled slot is visually freed in the calendar."
- **Issue:** Passive + "visually freed" is vague.
- **Suggested rewrite:** "The calendar removes the cancelled slot's visual block in the day and week views."

### C-6. FR-16 consequences
- **Excerpt:** "Each Treatment is timestamped and attributed to the recording User."
- **Issue:** Acceptable — system action; passive read is fine.

### C-7. FR-19 consequences
- **Excerpt:** "Unlock is rejected if any Payment exists on the Invoice — the Dentist must void the Invoice (FR-25) first."
- **Issue:** Acceptable; "rejected" by system is implicit.

### C-8. FR-26 consequences
- **Excerpt:** "Invoice Items become immutable as soon as the Invoice exits `draft`..."
- **Issue:** Acceptable.

### C-9. NFR-9
- **Excerpt:** "The local DB schema enforces these fields are not null."
- **Issue:** "These fields" — antecedent slightly remote; passive-ish but acceptable.

### C-10. FR-41 consequences
- **Excerpt:** "Push failures are retried with exponential backoff (cap at 10 min between retries [ASSUMPTION])."
- **Issue:** Who retries? The sync engine. Acceptable, but could be tightened.
- **Suggested rewrite:** "The sync engine retries push failures with exponential backoff (cap 10 min between retries)."

### C-11. NFR-2
- **Excerpt:** "Sync failures, network drops mid-sync, and conflicts must not corrupt local data."
- **Issue:** Acceptable.

---

## D. Tense and Mood Consistency (Imperative vs Indicative in FRs)

### D-1. FR body openings — mixed
- **Pattern observed:**
  - FR-1: "A new install with no local Clinic data prompts..." (indicative, system as subject)
  - FR-2: "A User signs in..." (indicative, user as subject)
  - FR-3: "A User with the Dentist role can add..." (modal "can")
  - FR-9: "Any User can create..." (modal "can")
  - FR-10: "The default landing surface ... shows..." (indicative)
  - FR-12: "The Assistant taps **Check In**..." (indicative, narrative)
  - FR-13: "Any User can cancel..." (modal)
  - FR-15: "Any User can transition..." (modal)
- **Issue:** Mix of "can" / present indicative / narrative. Mostly converges on "Any User can X" or "[Role] can X", which is fine. FR-12 is an outlier: "The Assistant taps **Check In** on a `scheduled` Appointment when the Patient arrives. This transitions..." — narrative tense.
- **Suggested rewrite:** Convert FR-12 to "The Assistant can check in a Patient by selecting **Check In** on a `scheduled` Appointment. The action transitions the Appointment to `checked_in` and creates a corresponding Visit in `checked_in` status." Same form as FR-13, FR-15.

### D-2. FR-10 — "The default landing surface (Today's Calendar) shows..."
- **Issue:** Indicative; surface is the subject. Acceptable but inconsistent with the user-as-subject FRs around it.
- **Suggested rewrite:** Optional: "Today's Calendar — the default landing surface — shows the current day's Appointments..."

### D-3. FR-32 — "A computed list of Inventory Items where `on_hand ≤ threshold` is shown..."
- **Issue:** Passive opening. Compare to FR-28 ("A dedicated screen lists...") which is active.
- **Suggested rewrite:** "A **Low Stock** view lists Inventory Items where `on_hand ≤ threshold`. A count badge on the Today's Calendar side panel surfaces the same list (UJ-1)."

### D-4. FR-35 — "At any time during the day, opening the **Day Closeout** screen shows..."
- **Issue:** Gerund subject ("opening...shows"); awkward.
- **Suggested rewrite:** "The **Day Closeout** screen shows, at any time during the day, the day's: number of completed Visits..."

---

## E. Untranslated Jargon

### E-1. "INPDP / Loi 2004-63" — §9.1
- **Excerpt:** "Under Tunisian law (**INPDP / Loi 2004-63**), health data is classified..."
- **Issue:** "INPDP" expanded nowhere; "Loi 2004-63" is French and untranslated.
- **Suggested rewrite:** First mention: "Under Tunisian law (INPDP — *Instance Nationale de Protection des Données à Caractère Personnel* — and Loi 2004-63, the personal data protection act)..."

### E-2. "PHI" — §9.1
- **Excerpt:** "The app handles **PHI** (Personal Health Information)"
- **Issue:** Already expanded inline. Good.

### E-3. "Drift" — §4.11, §9.1, §10
- **Issue:** "Drift" is a Flutter SQLite ORM. Not in Glossary, but the audience (Alaa + downstream agents) is technical. Acceptable; consider adding a one-liner to the Glossary or footnote on first use.
- **Suggested rewrite:** Add to §3 Glossary: "**Drift.** The local SQLite ORM used by the Flutter client; serves as the offline source of truth."

### E-4. "SQLCipher" — §9.1
- **Issue:** Technical term, audience-appropriate, no expansion needed.

### E-5. "Riverpod" / "GoRouter" / "Flutter scaffolding" — §10, NFR-11, FR-39
- **Issue:** Technical, audience-appropriate. Acceptable.

### E-6. "DICOM" — §4.8, §2.4
- **Excerpt:** "no DICOM viewer"
- **Issue:** Specialist (medical imaging) term. Probably worth a footnote for non-imaging readers.
- **Suggested rewrite:** First mention: "no DICOM viewer (the medical-imaging file standard for X-rays and CT scans)".

### E-7. "EHR" — §1
- **Excerpt:** "not a competitor to enterprise EHRs"
- **Issue:** EHR = Electronic Health Record; common in healthcare but not expanded.
- **Suggested rewrite:** First mention: "not a competitor to enterprise EHRs (Electronic Health Record systems)".

### E-8. "RBAC" — §6.1
- **Excerpt:** "Two-role RBAC (Dentist, Assistant)"
- **Issue:** Role-Based Access Control; common in dev contexts but unexpanded.
- **Suggested rewrite:** Either expand on first use or add to Glossary.

---

## F. Pronoun and Reference Ambiguity

### F-1. UJ-3 — "either: (a) ... ; (b) ..."
- **Excerpt:** "and either: (a) takes the full cash payment → invoice → `PAID`; (b) takes a partial cash payment..."
- **Issue:** Pronouns are clear, but the lowercase `PAID` in UJ-3 conflicts with §3 Glossary's `paid` (lowercase) status spelling.
- **Suggested rewrite:** Use `paid` / `partially_paid` in lowercase to match Glossary. (This is also a glossary-drift item — see A.)

### F-2. FR-3 — "the credentials"
- **Excerpt:** "The new User can sign in with the credentials and is constrained by their Role's permissions."
- **Issue:** "The credentials" — antecedent is the prior FR body's "send invite (or set initial password)". Not strictly ambiguous, but tightenable.
- **Suggested rewrite:** "The new User can sign in with the assigned credentials and is constrained by the assigned Role's permissions."

### F-3. UJ-4 — "the system prompts"
- **Excerpt:** "If `rescheduled`, the system prompts to create the replacement appointment immediately and links the two."
- **Issue:** "Links the two" — the two what? The new and the cancelled appointment. Clear from context but a downstream agent parsing this for tickets might miss it.
- **Suggested rewrite:** "...the system prompts the Assistant to create the replacement Appointment immediately and links the cancelled Appointment to the replacement via `rescheduled_to_appointment_id`."

### F-4. FR-22 consequences — "the same fields"
- **Excerpt:** "Marking a Planned Treatment done creates a Performed Treatment with the same fields (procedure, tooth, price, quantity)."
- **Issue:** Acceptable — parenthetical lists the fields.

### F-5. NFR-9 — "where applicable"
- **Excerpt:** "records `*_by_user_id` (creator + last editor where applicable)"
- **Issue:** "Where applicable" is weasel-shaped.
- **Suggested rewrite:** "records `created_by_user_id` and, for editable entities, `updated_by_user_id`".

### F-6. §1 — "this lands"
- **Excerpt:** "If that lands, the product earns the right..."
- **Issue:** "That" antecedent is the whole prior sentence (clinic adopting DocCentral). Acceptable in narrative.

### F-7. §7 SM-1 — "the four pain points"
- **Excerpt:** "uses DocCentral as their primary system for the four pain points"
- **Issue:** "The four pain points" refers back to §1. Not in scope here, but a reader landing on §7 won't know which four.
- **Suggested rewrite:** "...for the four pain points named in §1 (payments, calendar drift, inventory, history retrieval)..."

---

## G. Long Sentences (> 30 words)

### G-1. §0 — 154-word sentence/paragraph
- **Excerpt:** Entire §0 paragraph is one block running from "This PRD scopes the **Minimum Viable Product**..." to "...if needed)."
- **Issue:** It's actually three sentences, but the second sentence ("This PRD supersedes the existing planning artifacts...") is 38 words and the final sentence ("Downstream artifacts (epics, stories, tickets)...") is 16 — acceptable. The opening sentence is 64 words — too long.
- **Suggested rewrite:** Split the opening: "This PRD scopes the **Minimum Viable Product** of DocCentral: a desktop-first, offline-capable, French-primary clinic management application. The MVP targets a **single dental practice in Tunisia** — a solo dentist and a combined-role assistant. DocCentral is a learning project with a real first customer (a family member's clinic) and is built with deliberate architectural optionality for commercialization later."

### G-2. §1 — second paragraph opener
- **Excerpt:** "For the dentist and assistant it relieves four felt pains: payments slipping through the cracks (no view of who owes what), calendar drift (cancellations that never make it onto the schedule), inventory blind spots (running out of cotton or anesthetic at the wrong moment), and patient history that is hard to retrieve when a returning patient is in the chair."
- **Issue:** 56 words. The colon list is the right shape but the sentence as a whole reads as a single long breath.
- **Suggested rewrite:** Split at the colon: "For the dentist and assistant, DocCentral relieves four pain points. Payments slip through the cracks (no view of who owes what). Calendar drift happens when cancellations never make it onto the schedule. Inventory blind spots mean running out of cotton or anesthetic at the wrong moment. Patient history is hard to retrieve when a returning patient is in the chair."

### G-3. UJ-3 — final sentence
- **Excerpt:** "She reviews it with the patient, applies any discount/surcharge as line items, and either: (a) takes the full cash payment → invoice → `PAID`; (b) takes a partial cash payment → records the amount → invoice → `PARTIALLY_PAID`, balance owed visible on the patient profile and on a "Patients with Outstanding Balance" list."
- **Issue:** 52 words with two branches mid-sentence.
- **Suggested rewrite:** Split into two sentences. "She reviews the Invoice with the Patient and applies any discount/surcharge as line items. She then either (a) takes the full cash Payment, advancing the Invoice to `paid`; or (b) takes a partial cash Payment, advancing the Invoice to `partially_paid` with the Outstanding Balance visible on the Patient File and on the **Patients with Outstanding Balance** list."

### G-4. UJ-4 — "Edge case" sentence
- **Excerpt:** "**Edge case:** if the patient has an outstanding balance and is a repeat no-show, the patient profile flags the pattern visibly when the assistant is preparing future appointments."
- **Issue:** 30 words exactly. Borderline; "flags the pattern visibly" is also a B-class issue (hedge).
- **Suggested rewrite:** "**Edge case:** if the Patient has an Outstanding Balance and is a repeat no-show, the Patient File displays a repeat-no-show indicator when the Assistant prepares future Appointments."

### G-5. FR-19 consequences — third bullet
- **Excerpt:** "Unlock is rejected if any Payment exists on the Invoice — the Dentist must void the Invoice (FR-25) first."
- **Issue:** 21 words. Fine.

### G-6. NFR-9 — single sentence runs ~70 words
- **Excerpt:** "Every Invoice, Payment, Void, Day Closeout, Closeout Reopen, Visit transition, Performed Treatment entry/edit, Visit Unlock, Patient edit, and Appointment edit records `*_by_user_id` (creator + last editor where applicable) and a UTC timestamp."
- **Issue:** 32 words; the list is dense. Acceptable for a compliance NFR, but a list format would scan better.
- **Suggested rewrite:** Convert the comma-list to a bulleted list under the NFR description, or split into "These actions are audited: Invoice, Payment, Void, Day Closeout, Closeout Reopen, Visit transition, Performed Treatment entry/edit, Visit Unlock, Patient edit, Appointment edit. Each audit record captures `created_by_user_id` and (for editable entities) `updated_by_user_id`, plus a UTC timestamp."

### G-7. §13 Open Question 11
- **Excerpt:** "The architecture skill will need to author a per-entity sync matrix: which entities support which sync states, attachment-blob sync mechanics, queue ordering, and what specifically constitutes a "conflict" per entity."
- **Issue:** 32 words; still readable because of the colon list. Acceptable.

### G-8. §12 Risks table — "Multi-session Treatment Plans" row, Mitigation column
- **Excerpt:** "If validation rejects the full plan UX, the module reduces to FR-20 alone (a static list of "planned next steps" on the Patient File). FR-21 (Appointment linkage) and FR-22 (mark-performed) can be dropped without affecting Visit, Invoice, or Calendar flows; Patient File still surfaces the planned list."
- **Issue:** 47 words across two sentences within a table cell. Acceptable for a risks-table cell, but on the long side.
- **Suggested rewrite:** Leave; tables tolerate density.

---

## H. Repeated Phrases / Chants

### H-1. "Any User can..." — appears in 16+ FRs
- **Locations:** FR-4, FR-5, FR-9, FR-12 (variant), FR-13, FR-14, FR-15, FR-17, FR-18, FR-26, FR-29, FR-30, FR-31, FR-33, FR-34, FR-47, FR-48, FR-50.
- **Issue:** Heavy repetition. Becomes chant-like; downstream readers will skim past the actor. Worse, "Any User" is technically wrong in places where the action is functionally Assistant-driven (FR-12 check-in, FR-30 restock, FR-36 day closeout) even though both roles can do it.
- **Suggested rewrite:** Where the action is genuinely role-agnostic, keep "Any User can". Where the action has a primary actor in practice (even if not permission-restricted), name them: "The Assistant (or any User) can record a Restock Event...". Alternative: introduce a §4 preamble: "Unless otherwise noted, FRs in this section are permitted to both the Dentist and the Assistant. Role-restricted operations are explicitly named." Then FRs can drop "Any User can" and use imperative: "Create an Inventory Item with: name, category..."

### H-2. "The system..." — appears mostly in UJs, less in FRs
- **Locations:** UJ-3 ("The system auto-generates..."); UJ-4 ("the system prompts..."); UJ-4 ("the system requires..."); FR-13 body ("creates a Cancellation record"); FR-18 body ("the system auto-generates a `draft` Invoice").
- **Issue:** Mild chant. Acceptable in narrative.

### H-3. "**Consequences (testable):**" — every FR
- **Issue:** Every single FR uses this header. It's a template structure, not a chant — acceptable.

### H-4. "Realizes UJ-N" — feature descriptions
- **Locations:** §4.1 ("Realizes UJ-1, UJ-5 (gated by auth)."); §4.2 ("Realizes UJ-2, UJ-9."); §4.3, §4.4, §4.5, §4.6, §4.7 etc.
- **Issue:** Consistent structural marker; not a chant.

### H-5. "The User" / "the User" — capitalization
- **Issue:** Glossary defines **User** (capitalized) as a Clinic-scoped person with credentials. The PRD generally capitalizes correctly. Spot-check: FR-44 "The User can switch the UI language..." — fine. UJ narratives use "Assistant" and "Dentist" by name — fine.

### H-6. "free text" / "free-text"
- **Locations:** FR-9 ("reason (free text)"); FR-14 ("free-text note"); FR-16 ("procedure name (free text"); FR-20 ("procedure name (free text"); Glossary Lab Work Flag ("free-text note"); §2.4 ("free-text status flag").
- **Issue:** Inconsistent hyphenation. As a noun phrase ("entered as free text"), no hyphen; as a compound adjective before a noun ("a free-text note"), hyphenated. PRD mostly gets this right; verify §2.4 "free-text status flag" (adjective, correct) vs FR-14 "free-text note" (correct).
- **Suggested rewrite:** No change — usage is grammatically defensible. Optional: tighten to "free-text" as adjective everywhere.

### H-7. "for forward-compat" / "forward-compat" / "cheap optionality"
- **Locations:** §2.4 ("cheap optionality for the commercial branch"); Glossary Role entry ("forward-compat").
- **Issue:** Casual jargon. "Forward-compat" is informal for "forward compatibility".
- **Suggested rewrite:** Glossary: "defined in the role table for future compatibility, not exposed in MVP UX." §2.4: "the role is preserved in the role model for future commercial expansion, but no MVP UX is built for nurse-specific flows."

---

## I. Status-Value Casing (Glossary vs Body Inconsistency)

### I-1. Appointment statuses
- **Glossary:** `scheduled`, `checked_in`, `completed`, `no_show`, `cancelled`, `rescheduled` (all lowercase, snake_case).
- **PRD body:** Matches.
- **Issue:** None.

### I-2. Visit lifecycle
- **Glossary:** `checked_in → in_progress → completed` (lowercase, snake_case).
- **PRD body:** Matches.
- **Issue:** None.

### I-3. Invoice statuses
- **Glossary:** `draft`, `unpaid`, `partially_paid`, `paid`, `void`.
- **PRD body — drift:**
  - UJ-3: "invoice → `PAID`" and "invoice → `PARTIALLY_PAID`" — UPPERCASE.
  - Glossary itself: "legacy `BILLED` state from `usecases.md` is dropped" — uppercase referencing legacy, acceptable.
- **Issue:** UJ-3 uses uppercase `PAID` / `PARTIALLY_PAID` that conflicts with Glossary lowercase.
- **Suggested rewrite:** Change UJ-3 to lowercase: `paid`, `partially_paid`.

### I-4. Cancellation reasons
- **Glossary:** `patient_cancelled`, `no_show`, `clinic_cancelled`, `rescheduled`.
- **PRD body:** Matches consistently in FR-13 and UJ-4.
- **Issue:** None.

### I-5. Sync status
- **Glossary:** `pending`, `synced`, `conflict`.
- **PRD body — drift:**
  - FR-41: "sync_status = `pending`" — fine.
  - FR-41 consequences: "the affected records' sync_status becomes `synced`" — fine.
- **Issue:** None.

### I-6. Inventory category enum
- **Glossary §3:** does not list inventory categories.
- **FR-29:** lists `cleaning`, `medicament`, `supply`, `other`.
- **Assumption Index #8:** confirms `cleaning`, `medicament`, `supply`, `other`.
- **Issue:** Glossary entry for **Inventory Item** says "Records: name, category, unit..." but doesn't enumerate categories. Mild gap — the enum lives in FR-29 and the Assumption Index. Acceptable.

---

## J. Miscellaneous

### J-1. UJ-4 — "Phone rings"
- **Excerpt:** "Phone rings: \"I can't come tomorrow at 10.\""
- **Issue:** Scenic detail in a UJ. Stylistically fine; helps grounding.

### J-2. §1 — "WhatsApp's replacement"
- **Excerpt:** "The app is **paper-and-WhatsApp's replacement**"
- **Issue:** Possessive form is wrong. Should be "paper-and-WhatsApp replacement" (compound noun modifier) — the app IS the replacement FOR paper and WhatsApp, not OF them.
- **Suggested rewrite:** "The app **replaces paper and WhatsApp**, not enterprise EHRs."

### J-3. §2.1 — "She speaks French primarily, with Arabic as a secondary language for patient-facing interaction."
- **Issue:** Clear; no edit needed.

### J-4. §4.10 Description — "controls hidden for unauthorized roles"
- **Excerpt:** "reflected at the UI layer (controls hidden for unauthorized roles)"
- **Issue:** "Hidden" is acceptable. The FR-38 consequences elaborate.

### J-5. NFR-4 — "no further edits are possible"
- **Excerpt:** "Once an Invoice is `paid` or `void`, no further edits are possible."
- **Issue:** Passive but acceptable — describing system invariant.

### J-6. §13 Open Question 2
- **Excerpt:** "Does the clinic want a pre-defined catalog of dental procedures (with default unit prices) configurable from Settings, or do they prefer free-text entry per Visit?"
- **Issue:** 27 words; "they" pronoun refers to "the clinic" (singular collective). Use "it" or rephrase.
- **Suggested rewrite:** "Does the clinic want a pre-defined catalog of dental procedures (with default unit prices) configurable from Settings, or is free-text entry per Visit preferred?"

### J-7. FR-26 consequences — bullet "draft while no Payment..."
- **Excerpt:** "`draft` while no Payment has been recorded AND the Invoice has not been explicitly finalized (FR-50)."
- **Issue:** "Has not been explicitly finalized" — passive, but tightenable. The actor is the User (per FR-50).
- **Suggested rewrite:** "`draft` while no Payment has been recorded AND no User has explicitly finalized the Invoice (FR-50)."

### J-8. §0 — "where they conflict"
- **Excerpt:** "This PRD supersedes the existing planning artifacts in `docs/` and `todo.md` where they conflict"
- **Issue:** Clear pronoun; "they" = the planning artifacts. Acceptable.

### J-9. §1 — "WhatsApp's replacement, not a competitor"
- See J-2.

### J-10. §13 Open Question 8 — "push back into MVP?"
- **Excerpt:** "PDF invoice export — push back into MVP?"
- **Issue:** "Push back" is ambiguous: does it mean "promote (push) back into" or "resist (push back) on adding"?
- **Suggested rewrite:** "PDF invoice export — promote back into MVP?"

### J-11. §13 Open Question 9 — same as J-10.

---

## End of findings.
