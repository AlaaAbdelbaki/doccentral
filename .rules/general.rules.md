# General Agent Rules

## Workflow
1. Understand → Plan → Challenge → Confirm → Implement → Explain → Test → Commit → Reflect

## Small-Step Implementation
- Implement minimal piece at a time (service, provider, screen)
- Generate tests immediately

## User Confirmation Required
- Architecture changes
- Folder structure & provider setup
- Naming conventions
- Test coverage
- Compatibility with connected modules

## Code Review
- Agent performs self-review before showing code:
  - Remove unused imports
  - Check RBAC and offline-first compliance
  - Validate provider injection and connections
  - Validate constants and shared resource usage
  - Validate repository/service/data source hierarchy

## Git
- Commit each completed module with clear message and description

## Test Failures
- Pause if tests fail repeatedly
- Ask user for success conditions
- Iterate fixes before proceeding

## Learning Hooks
- Explain rationale for code patterns, test choices, and design decisions

## Definition of Done

A module is complete only if:
- Code is implemented
- Tests are written and passing
- RBAC rules applied
- Localization applied
- No hardcoded strings
- User has explicitly validated functionality
- Code is committed to Git

## Naming Conventions

- Use consistent naming:
  - Models: Appointment
  - DTOs: AppointmentDto
  - Services: AppointmentService
  - Repositories: AppointmentRepository
  - Providers: appointmentProvider

## Rule Priority

If rules conflict, priority is:
1. Architecture Rules
2. State Rules
3. UI Rules
4. Localization Rules
5. General Rules