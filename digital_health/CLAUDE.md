 # CLAUDE.md

 This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

 ## Project

 Patient Insights — a Flutter mobile app that helps patients understand their clinical records from 1177.se in plain la
     nguage. Core features: health profile management, AI-assisted Q&A, voice-captured consultation recording with AI summa
     rization, and pre-visit preparation.

 ## Commands

 ```bash
 flutter pub get          # Install dependencies
 flutter run              # Run on connected device/emulator (debug)
 flutter run --release    # Run release build
 flutter analyze          # Lint (uses flutter_lints)
 flutter test             # Run tests (currently only a placeholder test)
 flutter build apk        # Android release
flutter build ios        # iOS release
 ```

 ## Architecture

 **State management:** GetX (`get` 4.6.6). Two global controllers are registered at startup in `main.dart`:
 - `AuthController` — Firebase Auth (email/password + Google Sign-In) and demo/skip-auth mode
- `HealthController` — all Firestore reads/writes for patient profile, consultations, and symptoms

Controllers are injected once via `Get.put()` and accessed anywhere with `Get.find<T>()` or `controller.obs` reactive
     bindings.

**Navigation:** GetX named routes for main screens (`/login`, `/`, `/profile`, `/edit-profile`, `/history`). Supplemen
     tary screens (AI chat, prepare visit, record consultation) use `Get.to()` without named routes.

**AI integration:** `lib/services/ai_service.dart` calls OpenRouter's API (Nemotron 120B model) for two operations: `a
     skAi()` (conversational Q&A with patient context injected) and `summarizeConsultation()` (transcript → structured SOAP
     -style summary). The API key is currently hardcoded in this file.

**Speech-to-text:** `RecordConsultationScreen` uses `speech_to_text` with continuous 30 s windows and auto-restart. Ac
     cumulated transcript is sent to `AiService.summarizeConsultation()`, then saved to Firestore under `users/{uid}/consul
     tations/{docId}`.

**Firestore schema:**
```
users/{uid}
 name, email, dob, bloodType, height, weight,
  conditions[], medications[], vitals{},
  emergencyContact{}
  └─ consultations/{docId}
       doctorName, date, timestamp,
        transcript, summary,
        symptoms[], questions[]
 ```

 **Firebase config:** `lib/firebase_options.dart` (generated; do not hand-edit). Project ID: `ems-app-710ec`. Google Si
     gn-In server client ID is hardcoded in `auth_controller.dart`.
 **Firebase config:** `lib/firebase_options.dart` (generated; do not hand-edit). Project ID: `ems-app-710ec`. Google Si
     gn-In server client ID is hardcoded in `auth_controller.dart`.

 ## Key Files

 | File | Role |
|------|------|
 | `lib/main.dart` | App entry: Firebase init, GetX DI, route table |
 | `lib/controllers/auth_controller.dart` | Auth state, sign-in/out flows |
 | `lib/controllers/health_controller.dart` | Patient CRUD, consultations, symptoms |
 | `lib/models/patient_model.dart` | `PatientModel` entity with BMI calculation |
 | `lib/services/ai_service.dart` | OpenRouter API calls (hardcoded key — do not commit new keys) |
 | `lib/screens/main_screen.dart` | Bottom-nav host (4 tabs) |
 | `lib/screens/home_screen.dart` | Dashboard: profile completeness, quick actions |
 | `lib/screens/record_consultation_screen.dart` | Voice capture + AI summarize → Firestore |
 | `lib/screens/ai_chat_screen.dart` | Chat UI with TTS playback |

 ## Known Issues


- `lib/screens/nutrition_screen.dart` appears to be an unused duplicate of `ai_chat_screen.dart`.
  - No logging framework — `print()` is used throughout