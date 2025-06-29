# DocCentral

DocCentral is a cross-platform doctor management application designed to help doctors and their assistants efficiently manage appointments, patients, and inventory. Built with Flutter and Firebase, DocCentral aims to streamline daily medical practice operations with a user-friendly interface and secure data handling.

---

## Features

- **User Authentication:** Secure login for doctors and their assistants
- **Patient Management:** Add, edit, and view patient profiles and medical history
- **Appointment Scheduling:** Create, edit, and view appointments with calendar integration
- **Inventory Management:** Track medical supplies and equipment with alerts for low stock
- **Role-Based Access:** Different access levels for doctors and assistants
- **Cross-Platform:** Works on web, mobile (iOS and Android), and desktop

---

## Technology Stack

- **Frontend:** Flutter (Web, iOS, Android, Desktop)
- **Backend:** Firebase (Authentication, Firestore Database, Cloud Functions)

---

## Getting Started

### Prerequisites

- Flutter SDK installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Firebase project set up with Firestore and Authentication enabled
- An editor such as Visual Studio Code or Android Studio

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/doccentral.git
   cd doccentral
   ```
2. Install FVM
   ```bash
   dart pub global activate fvm
   ```
3. Install Flutter dependencies:
   ```bash
   fvm flutter pub get
   ```
4. Configure Firebase:
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Follow the Firebase Flutter setup guide for your platforms([Firebase + Flutter](https://firebase.flutter.dev/docs/overview/))
5. Download and add the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files to your project as per the Firebase setup instructions.

6. Run the application:
   ```bash
   fvm flutter run
   ```

---

## Folder Structure

```bash
doccentral/
├── android/                # Android-specific files
├── ios/                    # iOS-specific files
├── lib/                    # Main application code
│   ├── models/             # Data models
│   ├── screens/            # UI screens
│   ├── services/           # Services for Firebase and other APIs
│   ├── widgets/            # Reusable widgets
|-- firebase/              # Firebase configuration files
```

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

For any questions or feedback, please contact the project maintainer at [alaa.abdelbaki@outlook.com](mailto:alaa.abdelbaki@outlook.com).
