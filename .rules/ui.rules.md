
# UI Rules

## Screens
- Organize screens by feature (appointments, staff, inventory, invoices)
- Shared widgets in lib/shared/widgets

## Layout
- Adaptive layout for web and mobile breakpoints
- Placeholder vs final screen distinction

## Atomic Design Principles
- Atoms → basic elements (buttons, labels, inputs)
- Molecules → combinations of atoms
- Organisms → groups of molecules forming a section
- Templates → page structure without content
- Pages → top-level views/screens

## ConsumerWidget Usage
- Only top widget of a view may extend ConsumerWidget
- All provider-related actions below the top widget must be passed as callbacks from the top widget

## User Confirmation
- Explain generated screen to user
- User must approve layout and component placement

## Form Handling

- All forms must:
  - Have validation
  - Handle loading and error states
  - Use controllers or form state management consistently