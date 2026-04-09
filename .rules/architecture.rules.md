# Architecture Rules

## Module Generation Order
1. Models → Repositories → Services → Providers → Screens → Tests

## Folder Structure
- lib/models
- lib/repositories
- lib/services
- lib/providers
- lib/screens/[feature]
- lib/shared/widgets
- lib/shared/utils

## Layered Architecture Rules
- Each layer can only call the layer directly beneath it:
  - Providers → Services → Repositories → DataSources
- Services **must not call providers**
- Providers **must not call repositories or datasources directly**
- Repositories **must not call services or providers**
- DataSources **have no knowledge of higher layers**

## Repository Rules
- A repository can **only be called by a service**
- A repository can **only depend on a single datasource** (Local, Firebase, or REST)
- Must remain thin: only handle basic CRUD for its datasource
- Must not orchestrate multiple datasources or call higher layers

## Service Rules
- A service can call **multiple services**
- A service can have **at most one repository dependency**
- A service is responsible for **persisting data to both local and remote databases simultaneously**
- Services orchestrate multi-datasource operations
- Services inject datasources as needed:
  - LocalDataSource
  - FirebaseDataSource
  - RestDataSource

## Provider Rules
- A provider can call **multiple services**
- Providers **must not call repositories or datasources directly**
- Providers are UI-facing and expose state/actions

## RBAC Enforcement
- Services and UI must include role-based access
- Multi-role users supported

## Offline-First Rules
- Implement local Drift database first
- Abstract remote Firebase datasource for future replacement
- Conflict resolution: last-write-wins for MVP

## Dependency Management
- All dependencies must be added through the Flutter CLI:
  ```bash
  flutter pub add <package_name>
  ```
- Do not hardcode versions in pubspec.yaml
- Allow Flutter daemon to fetch latest compatible version
- Constants and Shared Resources
- All string variables such as routes, route names, SharedPreferences keys must be stored in static abstract classes
- Hardcoded text must never appear outside these classes (except temporary placeholders during development)

Example:
```dart
abstract class Routes {
  static const home = '/home';
  static const appointments = '/appointments';
}

abstract class PrefKeys {
  static const userRole = 'user_role';
  static const authToken = 'auth_token';
}
```
## Code Review Checklist
- Remove unused imports
- Services and repositories follow hierarchy
- Providers correctly injected
- Constants referenced correctly, no duplication

## Error Handling Rules

- All service and repository methods must return a Result type (success/failure)
- Do not throw unhandled exceptions across layers
- Errors must be mapped to domain-level failures
- Providers must handle errors and expose user-friendly states

## Data Model Separation

- Use separate models:
  - DTOs (for data sources)
  - Domain Models (for app logic)
- Repositories must map DTOs ↔ Domain Models
- Services must only work with domain models

## Sync Rules

- All write operations must:
  1. Persist locally first
  2. Queue remote sync operation
- Sync must be triggered:
  - On connectivity restoration
  - On app startup
- Use last-write-wins for conflicts in MVP
- Sync logic must be abstracted for future improvement
  
## ID Management

- IDs must be generated locally (UUID)
- Same ID must be used for both local and remote persistence
- No reliance on remote-generated IDs
