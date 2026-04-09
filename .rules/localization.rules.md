# Localization Rules

## Supported Languages
- The app must support: French (fr), English (en), and Arabic (ar)
- The fallback logic:
  1. Use the device/system language if supported
  2. If system language is unsupported, fallback to English (en)

## Externalization
- All user-facing text in the UI must use Flutter localization (`intl` / `flutter_localizations`)  
- Never hardcode UI strings in widgets, services, or screens  
- Dynamic values must use placeholders in localization files (e.g., "Hello {name}")

## Naming
- Localization keys must be descriptive and consistent
- Keys must correspond to `.arb` files or localization resources

## Testing
- All UI strings must be referenced correctly from localization files
- Ensure dynamic parameters render correctly
- Verify that switching between supported languages renders the correct text
- Agent must check that no hardcoded strings remain in the codebase