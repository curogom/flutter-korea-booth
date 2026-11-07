# Demo Booth Quiz

[English](README.md) | [한국어](README.ko.md)

A bilingual Korean/English Flutter web quiz. The default build uses 17 original arithmetic demo questions and makes no Firebase or Analytics connection. It asks four questions per round, preserves stable answer IDs across languages, supports touch layouts, and shows no real prize entitlement.

## Run locally

Requires Flutter with Dart 3.13.7 or compatible and its cached/available dependencies.

```sh
flutter pub get
flutter run -d chrome
```

For a static build with local renderer resources:

```sh
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8767 --bind 127.0.0.1 --directory build/web
```

Open http://127.0.0.1:8767. Installing dependencies requires network access when they are not cached. The static sample build bundles its question bank, Korean font and web renderer; it is not a service-worker offline-installable PWA. Opening a static page still requires the local server.

## Scope of this copy

- Original event questions were removed, including question-specific test assertions. The new bank was independently authored for this demonstration.
- Event imagery, logos, participant records, exports, logs, generated builds, operational documents, production configuration and release utilities are omitted.
- Web is the supplied build target. Android/iOS/macOS scaffolding, signing files and native branding are intentionally absent. Native storage code remains as an example, but native builds were not prepared or tested.
- The app entry point does not wire participant run recording, synchronization, analytics or operator reporting. Those reusable modules and unit tests remain for reference. Re-enabling them requires an explicit privacy/retention and least-privilege design; do not recreate a shared signed-in administrator kiosk.
- No repository, deployment, upload or live service change is included in this folder preparation.

## Optional Firebase question management

Default sample mode needs no Firebase account or SDK download. Optional web Firebase mode downloads SDK 13.1.0 from Google’s official gstatic CDN and therefore needs network access even when using local emulators. For local emulators:

```sh
firebase emulators:start --project demo-quiz --only firestore,auth
# In another terminal, install tool dependencies first:
npm --prefix tools ci
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node tools/firebase_admin.mjs bootstrap-emulator demo-quiz
flutter run -d chrome --dart-define-from-file=config/emulator.json
```

The emulator-only host account is host@example.test / LocalDemoOnly123!. Never use this demo password with a real service. The helper refuses real project IDs or non-loopback endpoints. Firebase CLI and Java 21+ are separate prerequisites.

For your own project, copy config/firebase.example.json to ignored config/firebase.json and provide your own public web configuration. No production project is preselected and no hosting deploy configuration is provided. Configure Firebase Auth, server-enforced quizAdmin claims and Firestore rules through your own controlled setup. Do not put service-account keys, refresh tokens or operator passwords in client defines. Web client API keys are public configuration, not administrator credentials.

Each admin route entry clears inherited authentication before showing the sign-in form. Leaving clears authentication before returning to the quiz; failures block navigation until retried. Web Auth uses in-memory persistence and Firestore persistent caching is disabled. Staff must still protect an actively unlocked admin screen. Local authentication cleanup is not server-side token revocation.

## Verification

```sh
flutter analyze
flutter test
npm --prefix tools run test:session
npm --prefix tools run test:emulators
```

The rules suite uses demo-quiz-tests and isolated loopback ports 8085/9095. Test setup refuses real projects and preview ports. Never point tests at real Firebase.

Optional Firebase browser/CDN integration has not been tested; passing emulator tests does not validate that integration.

See docs/VALIDATION.md for the recorded checks and limitations and SECURITY.md for the security boundary. This is a reviewed demonstration source copy, not a production security certification.

## License

The original application code in this copy is licensed under the MIT License; see LICENSE and LICENSE_DECISION.md. Copyright (c) 2026 curogom. Third-party code, dependencies and fonts retain their own licenses and copyright notices; see THIRD_PARTY_NOTICES.md. The MIT License does not cover the excluded original event questions, imagery or branding. License selection does not publish or deploy this copy.
