# DocCentral Project Todo List

## 1. Planning & Design

- [x] Finalize app features and scope for MVP
- [x] Design relational data model (entities, relationships, enums)
- [x] Create UML class diagrams (with abstractions and enums)
- [x] Define main use cases and user roles (Doctor, Assistant)
- [x] Choose app name and branding elements

## 2. Project Setup

- [x] Initialize Flutter project with recommended folder structure
- [x] Setup Firebase project (prod, staging, emulator)
- [x] Add essential dependencies (`flutter_riverpod`, `go_router`, `firebase_core`, etc.)
- [x] Configure Firebase Emulator Suite for local development

## 3. Data Layer

- [ ] Implement Firestore data models and JSON serialization
- [ ] Create repository classes abstracting Firebase SDK calls
- [ ] Write seed scripts to populate emulator with test data

## 4. Domain Layer

- [ ] Define domain entities (Patient, Appointment, Invoice, Payment, etc.)
- [ ] Implement use cases (e.g., ScheduleAppointment, AddPatient, CreateInvoice)

## 5. Presentation Layer

- [ ] Design and implement UI screens (Login, Dashboard, Patients, Appointments, Inventory, Billing)
- [ ] Integrate Riverpod providers for state management
- [ ] Setup routing with GoRouter

## 6. Authentication & Security

- [ ] Implement Firebase Authentication for Doctors and Assistants
- [ ] Setup Firestore security rules based on user roles
- [ ] Test authentication flows and role-based access

## 7. Features Implementation

- [ ] CRUD operations for Patients, Appointments, Inventory, Invoices, Payments
- [ ] Link appointments to invoices and payments
- [ ] Implement reminders and notifications (Firebase Messaging) — future
- [ ] Add analytics dashboards — future
- [ ] Plan AI integration — future

## 8. Testing

- [ ] Write unit tests for domain and data layers
- [ ] Write widget tests for UI components
- [ ] Setup integration tests using Firebase Emulator Suite
- [ ] Perform manual testing on web, mobile, and desktop

## 9. Performance & Optimization

- [ ] Optimize Firestore queries and indexing
- [ ] Implement offline support and data synchronization
- [ ] Optimize app startup and screen transitions

## 10. Deployment

- [ ] Prepare production Firebase project
- [ ] Configure CI/CD pipelines (optional)
- [ ] Publish Flutter app on Web, Play Store, App Store (as applicable)

## 11. Documentation & Maintenance

- [ ] Write README and developer documentation
- [ ] Document API and data model specifications
- [ ] Setup error monitoring and analytics tools
- [ ] Plan for app updates and new features
