# Validation Interview — DocCentral MVP

A ready-made question sheet for sitting down with the dentist and the assistant at the family member's clinic. Each section refers back to PRD sections so you can update the PRD live (or right after) with the interview's outcome.

**Goal of the interview:** resolve every `[NEEDS VALIDATION WITH CLINIC]` tag in the PRD and answer §12 Open Questions before any beads tickets are cut. ~30 minutes is plenty if you keep it conversational.

---

## For the Assistant

1. Walk me through a typical morning from the moment you arrive — what do you do first, second, third? *(PRD §2.4 UJ-1)*
2. When a patient walks in, what do you actually need to know about them in the next 60 seconds? *(UJ-2, FR-7 Patient File contents)*
3. After a visit ends, what do you write down, where, and how long does it take you? *(UJ-3, FR-16, FR-17 — autosave on blur vs. explicit save?)*
4. Last time someone called to cancel — what happened? Did it get on the calendar correctly? Why or why not? *(UJ-4, FR-13)*
5. When a patient pays partial, what do you do today? How often does this happen? *(UJ-3, FR-26 — confirm partial payment is the right primary case)*
6. What runs out at the worst possible moment? What did you wish you'd ordered last week? *(UJ-8, §4.7 — confirm consumables scope)*
7. Would you want the system to auto-decrement stock when you mark a treatment performed, or do you prefer to count manually? *(FR-31, Open Q in §4.7)*
8. End of day — do you count the cash today? How do you know if it's right? *(UJ-10, FR-35–FR-36)*
9. If a closed day needs reopening (e.g., a missed payment), how often does that happen? Same-day or sometimes days later? *(Open Q10)*

## For the Dentist

1. When you walk into the clinic, what do you want to see on the screen first? *(UJ-5)*
2. After you finish a procedure, what do you need to write down — and would you do it yourself or have the assistant do it? *(UJ-6, FR-17)*
3. Do you do multi-session treatment plans? If so, how do you keep track today? Would the §4.5 surface help or just add clicks? *(UJ-7, §4.5)*
4. Do you ever want to look at "who owes the clinic money"? *(UJ-9, FR-28)*
5. Do you want to hand patients a printed invoice? *(Open Q8 — PDF invoice export)*
6. Is there anything the assistant does that you wish were faster, or that you wish you could see without asking her?
7. When you record a treatment, would you rather pick from a list of common procedures (with default prices) or type free text? *(Open Q2 — procedure catalog)*
8. Do you ever intentionally double-book a slot (e.g., a quick consult alongside a longer procedure)? *(Open Q7 — overlap policy)*
9. Discounts — when you give one, is it a percentage, a fixed amount, or a "family rate"? *(Open Q6)*

## For both

1. How many devices do you actually have / want to use DocCentral on? *(Open Q3 — multi-device need; PRD assumes two desktops)*
2. What's the desktop you'll be running this on? Brand, age, rough specs? *(NFR-7 hardware baseline)*
3. What language do you mostly want to see on screen — French, Arabic, or does it depend? *(§4.12)*
4. Would you want appointment reminders sent to patients (SMS, WhatsApp)? *(Open Q9)*

---

## After the interview — what to do with the answers

1. **Open the PRD `.decision-log.md`** and add an entry per major answer ("UJ-1 validated as: …" / "UJ-1 corrected to: …").
2. **Update or delete `[NEEDS VALIDATION WITH CLINIC]` tags** in the PRD where the answer is now known.
3. **Resolve Open Questions §12** where possible. Anything still open after the interview becomes a downstream decision for the architecture or UX skill.
4. **Re-check the Assumptions** scattered throughout the PRD. Anything confirmed → drop the `[ASSUMPTION]` tag. Anything contradicted → revise the FR.
5. **Update the PRD `updated` frontmatter date** and bump `status` if substantial revisions are needed.
6. **Then proceed to the next downstream skill**: `bmad-create-ux-design`, `bmad-create-architecture`, or `bmad-create-epics-and-stories` (with the beads handoff per CLAUDE.md).
