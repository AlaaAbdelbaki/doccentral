# DocCentral Gaps

This file lists the main gaps found by comparing `todo.md`, `.rules/`, and `docs/`.

## High-Priority Gaps

1. Workflow states are inconsistent.
   - `todo.md` uses visit lifecycle `CHECKED_IN → COMPLETED → BILLED`.
   - `.rules/06-workflow.md` and `docs/usecases.md` include `IN_PROGRESS`.
   - Invoice statuses also differ between `todo.md` and `docs/usecases.md`.
   - Impact: developers may implement different state machines.

2. Appointment-to-visit creation is ambiguous.
   - `.rules/06-workflow.md` says a visit must be created from an appointment.
   - `docs/usecases.md` says appointment may result in a visit manually or automatically.
   - Impact: the core clinical flow is not fully defined.

3. Testing requirements are not represented in the roadmap.
   - `.rules/09-testing.md` requires unit, integration, sync-aware, and optional UI tests for every module.
   - `todo.md` has no explicit test tickets.
   - Impact: implementation can be marked complete without validation coverage.

4. RBAC is underspecified.
   - `.rules/07-permissions.md` requires action-based permissions enforced at router, Riverpod, and domain levels.
   - `todo.md` only mentions role model, permission checking, and route guards.
   - Impact: authorization logic may end up only partially enforced.

5. The roadmap does not fully reflect the database model.
   - `docs/database.md` defines clinics, users, roles, and join tables.
   - `todo.md` only covers generic architecture plus patient/appointment/visit/invoice tables.
   - Impact: identity and clinic persistence may be missed or delayed.

6. Sync behavior needs more operational detail.
   - `docs/usecases.md` says Drift is authoritative, all entities are sync-tracked, and conflict resolution is last-write-wins.
   - `todo.md` only lists generic sync fields and push/pull engine tasks.
   - Impact: sync queue states, conflict scope, and per-entity behavior remain unclear.

7. Financial rules are not fully pinned down.
   - `docs/usecases.md` includes `UNPAID` and `PARTIALLY_PAID` invoice states.
   - `todo.md` only tracks `DRAFT → PAID → VOID`.
   - Impact: payment tracking may diverge from the intended business model.

8. Localization requirements are too shallow in the roadmap.
   - `.rules/08-l10n.md` requires no hardcoded strings and Arabic RTL support.
   - `todo.md` only mentions EN / FR / AR translations.
   - Impact: translation storage and RTL behavior may be left vague.

9. UI architecture constraints are not explicitly planned.
   - `.rules/05-ui.md` requires page-only Riverpod access, dumb child widgets, and responsive LayoutBuilder-based layouts.
   - `todo.md` only lists a design system and module screens.
   - Impact: presentation structure may drift from the intended architecture.

10. Auditability and clinic administration are not explicit roadmap items.
   - `docs/usecases.md` includes clinic profile management, staff administration, and auditability.
   - `todo.md` does not turn these into tickets.
   - Impact: some user-facing and compliance-related work may be omitted.

## Suggested Follow-Up Improvements

- Define one canonical state model for appointment, visit, treatment, and invoice lifecycles.
- Add explicit test tickets per module, including sync-aware tests where applicable.
- Add a permission matrix and domain-level authorization ticket.
- Add clinic, user, and role persistence tickets.
- Add sync metadata and conflict-resolution acceptance criteria.
- Add localization tickets for RTL support and no-hardcoded-string enforcement.
- Add clinic administration and audit trail tickets if they are in MVP scope.
- Add acceptance criteria to each roadmap item so completion is unambiguous.
