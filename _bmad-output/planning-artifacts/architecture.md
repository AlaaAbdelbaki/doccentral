---
stepsCompleted: [1, 2]
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-DocCentral-2026-05-21/prd.md
  - docs/system_spec.md
  - docs/usecases.md
  - docs/database.md
workflowType: 'architecture'
project_name: 'DocCentral'
user_name: 'Alaa'
date: '2026-05-23'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

49 FRs across 12 domains: Auth & Clinic Bootstrap (FR-1–3), Patient Management (FR-4–8, FR-46), Calendar & Appointments (FR-9–14, FR-47–48), Visit Workflow (FR-15–19), Treatment Planning (FR-20–22), Invoicing & Payments (FR-23–28, FR-49), Inventory (FR-29–32), Attachments (FR-33–34), Day Closeout (FR-35–37), Roles & Permissions (FR-38–39), Offline-First & Sync (FR-40–43), Localization & RTL (FR-44–45).

**Non-Functional Requirements:**

- NFR-1: Full offline operation — all FRs work without internet; only initial device sign-in requires connectivity
- NFR-2: Sync resilience — sync failures and conflicts must not corrupt local data; Drift is authoritative
- NFR-3: Financial determinism — Invoice totals always computed from Items + adjustments + Payments, never manually set
- NFR-4: Immutability of paid records — once an Invoice has any Payment, Invoice Items lock; paid/void Invoices allow no further edits
- NFR-5: No hardcoded UI strings — all text from translation files
- NFR-6: RTL correctness — Arabic locale flips all screens to RTL
- NFR-7: Desktop performance baseline — cold launch < 4s; Today's Calendar < 2s post-sign-in; screen navigation < 500ms
- NFR-8: Supabase in EU region (Frankfurt or Ireland)
- NFR-9: Audit attribution on all financial + clinical writes — actor + UTC timestamp, enforced non-null in schema
- NFR-10: Per-module test discipline — unit, integration, sync-aware tests per module
- NFR-11: LayoutBuilder-based responsive layouts; only top-level pages consume Riverpod

**Scale & Complexity:**

- Primary domain: Flutter desktop, offline-first with Supabase sync layer
- Complexity level: High — offline-first sync + financial determinism + three-layer RBAC + RTL + audit trail all simultaneously
- Estimated architectural components: 18–22 (auth, clinic, patient, appointment, visit, treatment plan, invoice, payment, inventory, attachment, day closeout, RBAC, sync engine, audit log, localization, navigation, design system, error handling)

### Technical Constraints & Dependencies

- **Flutter desktop** (Windows/macOS/Linux) — mobile, web, tablet explicitly out of scope
- **Drift** — local SQLite ORM, source of truth for all runtime operations
- **Supabase** — sync/replication target only; not a runtime dependency for any feature except initial device sign-in
- **Riverpod** — state management; only top-level pages may use Riverpod widgets
- **GoRouter** — navigation; router-layer permission enforcement required
- **SQLCipher or equivalent** — encryption at rest (assumption, pending performance validation on clinic hardware)
- **Single Clinic per deployment** — schema is multi-tenant for forward-compat, but MVP product is single-tenant
- **Cash-only payments** — `method` field exists for v2 extensibility but only `cash` is used in MVP

### Cross-Cutting Concerns Identified

1. **Sync metadata** — every entity carries `sync_status`, `updated_at`, `created_at`, `deleted_at` (non-null); sync engine touches all modules
2. **Three-layer RBAC** — router guard, Riverpod provider visibility, domain operation rejection; same permission predicate at all three layers; no drift between layers
3. **Audit attribution** — all financial and clinical writes record `actor_id` + UTC timestamp; enforced at schema level
4. **Financial locking / immutability** — Invoice Items lock on first Payment; Invoice total is always derived; void is terminal
5. **Soft-delete pattern** — `deleted_at` set on logical deletion; no physical record removal; financial integrity preserved
6. **Localization / RTL** — no hardcoded strings; locale-aware date/time/currency; Arabic flips entire layout tree to RTL
7. **Performance on clinic hardware** — cold launch, calendar render, and navigation targets must be validated on actual devices
