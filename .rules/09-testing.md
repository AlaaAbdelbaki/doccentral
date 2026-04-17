# 🧪 Testing Rule – DocCentral

## 📌 Core Rule

For EVERY module created in the system, the following tests MUST be implemented:

---

# 1. Unit Tests (MANDATORY)

Each module must include unit tests covering:

- Business logic
- Validation rules
- State transitions
- Data transformations (DTO ↔ Entity)
- Repository methods (mocked dependencies)

## Example scope:
- Patient creation validation
- Invoice total calculation
- Visit state transitions
- Appointment scheduling rules

---

# 2. Integration Tests (MANDATORY)

Each module must include integration tests covering:

- Riverpod providers interaction
- Drift database operations
- Repository → DB → Sync layer flow (if applicable)
- Multi-step workflows

## Example scope:
- Create patient → persists in Drift → visible in stream
- Create visit → generate invoice → stored correctly
- Update appointment → reflected in UI state

---

# 3. Sync-Aware Tests (CRITICAL FOR THIS PROJECT)

For modules that interact with sync system:

- Verify local Drift write
- Verify sync queue marking (pending → synced)
- Verify Supabase mapping correctness (mocked)

---

# 4. UI Tests (OPTIONAL BUT RECOMMENDED)

For each feature module:

- Basic widget rendering
- Form validation behavior
- Role-based UI visibility

---

# ⚠️ STRICT RULES

- No module is considered complete without unit tests
- No module is merged without integration tests
- Sync-related modules MUST include sync tests
- Tests must follow Arrange → Act → Assert pattern

---

# 🧠 AI DEVELOPMENT RULE

When generating any module using AI:

👉 ALWAYS generate:
- implementation code
- unit tests
- integration tests

in the same output

---

# 🚀 GOAL

Ensure:
- deterministic financial logic
- safe offline behavior
- reliable sync across devices
- regression-safe development