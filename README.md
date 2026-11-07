# CampusCare

**Report campus issues in seconds and follow them until they are fixed.**

CampusCare is a Flutter mobile app for the African Leadership University (ALU) community. Students report problems around campus, such as a broken tap, a power cut or a safety hazard, with a description, location and photo. Staff review the reports, update their status and leave notes, and every change appears live in the reporter's timeline.

---

## Table of contents

- [Features](#features)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Using the app](#using-the-app)
- [Project structure](#project-structure)
- [Data model](#data-model)
- [Security](#security)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Known limitations](#known-limitations)
- [Author](#author)

---

## Features

### For students
- **Sign up with an ALU email** (`@alustudent.com` or `@alueducation.com`), with email verification and password reset.
- **Report an incident** with a title, category, campus location, exact spot, description and an optional photo from the camera or gallery.
- **Track progress** live as a report moves from **Submitted** to **In Progress** to **Resolved**, with a timeline showing who made each change, when, and any note they left.
- **Browse campus reports**, with search and a status filter, or see only **My Reports**.
- **Manage your profile:** photo, name, sign out.

### For staff
- **Staff dashboard** with counts per status and filters by status and category.
- **Update status** with an optional note. Only valid next steps are offered, and a resolved report can be re-opened.
- **Full audit trail:** every status change is recorded permanently.

### Across the app
- **Real-time updates:** all lists and details refresh automatically, with no pull-to-refresh needed.
- **Friendly errors** and clear loading and empty states.
- **Input checked twice:** validated on the device, and again on the server by Firebase Security Rules.

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.47 (Dart 3.13), Material 3 |
| Authentication | Firebase Authentication (email and password) |
| Database | Cloud Firestore |
| File storage | Cloud Storage for Firebase |
| State management | Riverpod 3 |
| Navigation | go_router |
| Photos | image_picker |
| Testing | flutter_test, fake_cloud_firestore, firebase_auth_mocks, mocktail |

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) **3.47 or newer**: check with `flutter --version`.
- **Android Studio** with an Android emulator, or a physical Android device with USB debugging on.
  - iOS builds need macOS with a full Xcode installation and CocoaPods.
- [Firebase CLI](https://firebase.google.com/docs/cli), only needed to deploy security rules: `npm install -g firebase-tools`.

### 1. Clone and install

```bash
git clone <repository-url>
cd campus_incident
flutter pub get
```

### 2. Firebase

The repository already contains the Firebase configuration for the project **`student-life-1`** (`lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`). These files identify the project. They are not secrets, because access is controlled by the Security Rules.

To **use the existing project**, skip to step 3.

To **use your own Firebase project** instead:

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Enable:
   - **Authentication → Sign-in method → Email/Password**
   - **Firestore Database**
   - **Storage**. This may require the Blaze (pay-as-you-go) plan.
3. Connect the app:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-project-id>
   ```
4. Deploy the security rules and indexes:
   ```bash
   firebase login
   firebase deploy --only firestore,storage --project <your-project-id>
   ```

### 3. Run

Start an emulator (or connect a device), then:

```bash
flutter run
```

---

## Using the app

### Student walkthrough

1. **Create an account** with your ALU email, then open the link in the verification email. Check spam if it doesn't arrive.
2. The app opens **Home** automatically once your email is verified.
3. Tap **Report an incident** (on Home, or the purple **+** in the bottom bar), fill in the form and tap **Submit report**.
4. Follow the report on its details screen, under **Reports**, or in **Profile → My reports**.

### Getting staff access

Every new account is created as a **student**. An administrator grants staff rights:

1. The person registers and verifies their account in the app.
2. In the Firebase console, open **Firestore Database → `users`** and find their document. Its ID is their user ID; check the `email` field.
3. Change the `role` field from `student` to `staff` and save.

The change takes effect immediately. A **Staff dashboard** card then appears on Home and under Profile.

### Staff walkthrough

1. Open **Staff dashboard**. It starts on reports waiting for review (**Submitted**).
2. Tap a report, then **Update status**.
3. Choose the new status, optionally add a note for the reporter, and tap **Save**.

---

## Project structure

```
lib/
├── main.dart                 # Initialises Firebase and Riverpod
├── app.dart                  # MaterialApp: theme and router
├── core/
│   ├── constants/            # ALU email domains, input limits
│   ├── errors/               # AppException: friendly error messages
│   ├── theme/                # Colours, spacing, Material theme
│   ├── utils/                # Validators, date formatting, photo picker
│   └── widgets/              # Reusable UI: cards, buttons, chips, states
├── models/                   # Incident, AppUser, StatusChange and enums
├── data/
│   ├── auth_repository.dart      # Sign up, sign in, verification, reset
│   ├── user_repository.dart      # User profiles
│   ├── incident_repository.dart  # Create, list and update incidents
│   ├── storage_repository.dart   # Photo uploads
│   └── providers.dart            # Riverpod providers connecting data to the UI
├── routing/
│   ├── app_router.dart       # Routes and sign-in redirect
│   ├── auth_redirect.dart    # Rules for who may open which screen
│   └── app_shell.dart        # Bottom navigation bar
└── features/                 # Screens, one folder per area
    ├── auth/                 # Welcome, login, register, reset, verify
    ├── home/
    ├── reports/              # Campus reports, my reports
    ├── report/               # New report form
    ├── incident/             # Report details and timeline
    ├── profile/
    └── staff/                # Dashboard and status update sheet

test/
├── unit/                     # Validators, models, errors, navigation rules
├── data/                     # Repositories with fake Firebase
└── widget/                   # Full app flows with fake Firebase

firestore.rules               # Database security rules
firestore.indexes.json        # Indexes for the incident queries
storage.rules                 # Photo upload rules
```

**How the pieces fit:** a screen reads data through a Riverpod provider. The provider calls a repository, and the repository talks to Firebase. Screens never use Firebase directly, which keeps them simple and lets the tests swap in fake Firebase.

**Navigation:** the router watches the sign-in state. Signed-out users only see the welcome and login screens, unverified users only see the verify-email screen, and only staff can open the staff dashboard.

---

## Data model

**Firestore**

| Collection | Fields |
|---|---|
| `users/{uid}` | `fullName`, `email`, `role` (`student` or `staff`), `photoUrl`, `createdAt`, `updatedAt` |
| `incidents/{id}` | `title`, `description`, `category`, `location`, `locationDetails`, `photoUrl`, `reporterId`, `reporterName`, `status`, `createdAt`, `updatedAt`, `inProgressAt`, `resolvedAt` |
| `incidents/{id}/statusHistory/{id}` | `fromStatus`, `toStatus`, `changedBy`, `changedByName`, `note`, `changedAt` |

**Storage**

| Path | Contents |
|---|---|
| `incident_photos/{uid}/{incidentId}.jpg` | Photo attached to a report |
| `profile_photos/{uid}/avatar.jpg` | Profile picture |

---

## Security

Firebase Security Rules ([`firestore.rules`](firestore.rules), [`storage.rules`](storage.rules)) enforce access on the server, independently of the app:

- **ALU only:** only verified ALU email accounts can read or create reports.
- **No self-promotion:** every new account is a student, and users cannot change their own role or email.
- **Valid data:** fields are checked for type and length, and new reports must start as *Submitted* and belong to the person creating them.
- **Staff-only updates:** only staff can change a report's status, and only along allowed transitions.
- **Permanent records:** status history can only be added to, never edited or deleted, and reports cannot be deleted.
- **Safe uploads:** photos must be images under 5 MB, uploaded to the uploader's own folder.
- **Privacy:** other students can see a report but not who submitted it.

---

## Testing

Run all tests:

```bash
flutter test
```

| Folder | What is tested |
|---|---|
| `test/unit/` | Form validators, model conversion, status transitions, error messages, navigation rules |
| `test/data/` | Registration, report creation with photo, status updates and permission checks, against fake Firebase |
| `test/widget/` | The real app on fake Firebase: welcome and login, form validation, the email-verification gate, student vs staff home, submitting a report end-to-end |

Check code quality:

```bash
flutter analyze
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Verification email doesn't arrive | Check the spam folder, then tap **Resend email**. It can be resent every 30 seconds. |
| "You don't have permission to do that" | The Security Rules may not be deployed. Run `firebase deploy --only firestore,storage`. Also confirm the email is verified. |
| Photo upload fails | Firebase Storage must be set up in the console (**Storage → Get started**) and `storage.rules` deployed. |
| A list shows an error just after deploying | Firestore indexes take a few minutes to build after `firebase deploy`. Wait, then tap **Try again**. |
| Staff dashboard doesn't appear | The user's `role` must be exactly `staff`, in lowercase, in their `users` document. |
| `flutterfire: command not found` | Add the Dart global tools to your PATH: `export PATH="$PATH:$HOME/.pub-cache/bin"`. |

---

## Known limitations

- **Search** filters the reports already loaded on the device, because Firestore has no built-in full-text search.
- **No push notifications:** status changes appear live while the app is open.
- **Manual staff roles:** staff are assigned by hand in the Firebase console. There is no admin screen.
- **Android first:** Android is the main target. iOS is configured but has not been built or tested.

---

## Author

**David-Mug**, African Leadership University, Individual Assignment 2.
