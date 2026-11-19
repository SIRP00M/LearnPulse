# LearnPulse

LearnPulse is a learning management beta with a Flutter Android application, a React web application, and a shared Supabase backend. This distribution contains reviewed source, not a hosted service or an installable release.

## Features and status

Teacher and Student workflows include courses and lessons, assignments and grading, student progress and attendance, profiles and avatars. Staff Attendance supports clock-in/out and supervisor review for explicitly enrolled staff. The Unified Demo Experience includes Student join and Presenter session controls. Both clients provide English, Thai, and Malaysian Malay.

These features are present in the source. Demo seats, presenter accounts, teacher invitations and staff membership require secure server-side provisioning; private operators and the existing classroom dataset are deliberately excluded. A fresh schema alone does not create a presentation event. Physical camera acceptance, hosted authorization and a fresh database replay are not certified by this source package. See [verification](docs/SOURCE_REVIEW.md).

## Stack and structure

- `mobile/`: Flutter/Dart application, Android Gradle project, ARB translations and tests. Flutter's Web runner is also retained; React is the primary Web client.
- `web/`: React 19, TypeScript, Vite, TanStack Query/Router/Table, Vitest and local mock Playwright tests.
- `supabase/migrations/`: ordered PostgreSQL schema, RPCs, RLS and Storage policies through V16.
- `supabase/tests/`: selected SQL authorization matrices; read their fixture prerequisites before use.
- `docs/`: setup, security limitations and source review.

Lockfiles are included. Build outputs, private accounts, screenshots and cloud linking metadata are excluded. There is no automated deployment workflow in this package.

## Requirements

Validated toolchain: Flutter 3.44.6, Dart 3.12.2, Node 26.13.0. `pubspec.yaml` requires Dart ^3.12.2. Use a compatible current Node version satisfying the locked dependencies' engines. Android requires JDK 17 and the Android SDK selected by Flutter. Gradle 9.1.0, AGP 9.0.1 and Kotlin 2.3.20 are pinned in the Android project. Local Supabase needs Docker Desktop and CLI 2.81.3 (pin the CLI; this config has not been migrated to CLI v3).

## Configure a fresh backend

Read [backend setup](docs/BACKEND_SETUP.md) before executing migrations. The V0 migration contains a guarded `DROP SCHEMA public CASCADE`; use a NEW disposable local environment, never blindly apply it to an existing project.

From the repository root, after reviewing the config and ensuring the local project name and ports do not collide with another stack:

```powershell
npx.cmd --yes supabase@2.81.3 start
npx.cmd --yes supabase@2.81.3 db reset --local
```

The second command destroys and recreates the selected LOCAL database. Use it only in an isolated disposable stack. This command was not executed during packaging. The config disables seed because private demo data is not distributed. No linked remote commands are needed for local setup.

## Web development

```powershell
Set-Location web
npm.cmd ci
Copy-Item .env.example .env.local
# Edit .env.local with YOUR backend URL and public publishable/anon key.
npm.cmd run dev
```

`VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY` and `VITE_APP_ENV` are public build-time client configuration. Never use a privileged key. Local backend URL is normally `http://127.0.0.1:54321`. Supabase Auth redirect URLs must match your own development origins.

## Flutter development

```powershell
Set-Location mobile
flutter pub get
Copy-Item defines.example.json defines.local.json
# Edit defines.local.json with your own public client configuration.
flutter run --dart-define-from-file=defines.local.json
```

For an Android emulator use `http://10.0.2.2:54321` for a backend on the host. Flutter generates `android/local.properties` with your SDK paths; do not commit it. The Auth callback is `learnpulse://auth-callback`; add it to your own backend redirect allow-list.

```powershell
flutter build apk --debug --dart-define-from-file=defines.local.json
```

Signed release builds need an Owner-controlled keystore and `android/app/key.properties`; see [mobile signing](mobile/README.md). No keystore is provided and a debug key must not be used for a distributed release.

## Testing

```powershell
# From web/
npm.cmd run typecheck
npm.cmd run lint
npm.cmd test
npm.cmd run build
# Optional local-only browser tests (browser download required):
npx.cmd playwright install chromium
node scripts/build-mock.mjs
npm.cmd run e2e:i18n
# From mobile/
flutter analyze
flutter test
```

The `e2e` package script explains the excluded private integration fixtures; only `e2e:i18n` is distributed as a portable browser suite. Golden capture modes depend on developer fonts/screenshots and are not part of normal verification. SQL matrices require their documented isolated fixture and transaction setup; do not run them on a presentation project.

## Limitations and license

This is a beta source checkpoint. No production certification, offline capability, Play Store publication or commercial availability is claimed. Hosted signup policy, mail delivery, rate limits, teacher invitations, staff supervisors and demo provisioning require administrator setup and acceptance testing. There is no approved project license in this distribution; the Owner must choose terms before granting reuse rights. Dependency licenses continue to apply. See [publication notes](docs/PUBLICATION_NOTES.md).
