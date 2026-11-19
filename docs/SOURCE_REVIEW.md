# Independent source review — 2026-11-18

## Architecture and evidence

The local workspace has no Git metadata. It is newer than the GitHub main snapshot dated 2026-07-16 (commit `309226549906cd523a8c5b9472a558f1a71cb10e`). Original files were read, not replaced. Graphify queries narrowed the source audit; actual source then confirmed the features below. Prior Claude progress reports were read for context but were not accepted as test evidence for this package.

Flutter: `lib/main.dart`, `app.dart` and `app_services.dart` wire the app to feature repositories/controllers/pages under `lib/features`. Teacher roles come from backend profiles. `core/app_config.dart` validates public client config and rejects privileged keys. The Android scaffold pins its Gradle/Kotlin/AGP configuration and requires external release signing.

React: `src/router.tsx` lazily loads pages and applies session/role routing; AuthProvider and Supabase APIs back the workflow. TanStack Query manages server state; Zod validates RPC responses. Vite, TypeScript, ESLint, Vitest and Playwright mock infrastructure are present with pinned dependencies.

Backend: the 16 active migrations progress from guarded V0 foundation and private helpers through courses, submissions, grading, lessons, attendance, dashboards, activities/progress/tasks, avatars, QR attendance, staff attendance and live demo/presenter lifecycle. RPC-only mutations, scoped SELECT/RLS and private Storage authorization are central contracts. Legacy migrations are superseded history, not prerequisites for a fresh installation.

## Requested feature verification

| Feature | Actual source inspected | Independent evidence / limit |
|---|---|---|
| Unified Demo | web/pages/demo + lib/api/demo, Flutter features/demo, V15/V15b/V16 migrations and router | Student claim/activation, Presenter Start/token/overview/pause/end APIs and pages exist; demo unit tests included in passing suites. No live event run. |
| Profile/avatar | web/pages/profile + AvatarEditor/API avatar, Flutter features/profile, V11/V12 | Name/language/theme/photo UI, image validation and ownership/order protections exist; relevant tests included. No real Storage roundtrip. |
| Student Attendance | web/pages/attendance + lib/api/att2, Flutter features/attendance, V6/V13 | Session/grid/history and QR/manual-code entry exist; relevant tests included. Physical scan not tested. |
| Staff Attendance | web/pages/staff + lib/api/att2, Flutter features/staff, V14 | Explicit staff context, clock in/out, reports, requests and supervisor decisions exist; relevant tests included. No real supervisor workflow run. |

All four are implemented in source, not declared fully accepted on a new hosted installation. Teacher/student learning workflows and English/Thai/Malaysian Malay resources are present in both clients. The package does not promise offline support, production certification or a store release.

## Verification from staging

- PASS: Web `npm ci --offline --ignore-scripts` (283 packages), manifest/lock dependency equality, `npm run typecheck`, `npm run lint`, `npm test` (83 tests in 12 files), `npm run build` (488 modules).
- PASS: Flutter `flutter pub get --offline`, final `flutter analyze --no-pub`, full test suite 620 passed / 2 skipped. The skipped private live avatar fixture was subsequently excluded; the remaining optional capture skip remains.
- Flutter first test run failed at three SDK-font setup hooks because they assumed `../.tools/flutter`. Staging-only `test/sdk_fonts.dart` resolves SDK fonts from FLUTTER_ROOT or test-runner ancestors; the three callers were updated. Full rerun passed. No runtime application source was changed.
- PASS: final Chromium mock Web browser run, 51 passed / 0 failed in 3.2 minutes (exit 0), covering three languages, narrow screens, keyboard and accessibility checks. Initial run found ambiguous Profile heading selectors (Profile vs Profile photo, including translations); staged test uses exact headings. Initial sandbox run was interrupted during completion; final full run completed outside sandbox against localhost mock services only. Firefox/WebKit were not rerun.
- PASS static: Android config consistency (JDK17, AGP9.0.1, Kotlin2.3.20, Gradle9.1.0), manifests and release signing guard. Android debug/release compile and emulator/physical-device workflows NOT TESTED in this packaging run.
- PASS static: 16 unique migration timestamps in order, paired dollar delimiters, exact migration bytes retained. This is not a SQL grammar/parser check. Full syntax/execution/PLpgSQL validation and schema replay are BLOCKED by absent Docker engine. No database was changed.

Commands to reproduce from `web/`:

```powershell
npm.cmd ci
npm.cmd run typecheck
npm.cmd run lint
npm.cmd test
npm.cmd run build
node scripts/build-mock.mjs
npm.cmd run e2e:i18n
```

Mock tests bind localhost ports 54399/4174 and do not need real credentials. They write temporary screenshots and test-results; do not commit those artifacts. `npm run e2e` deliberately explains that private real-backend fixtures are excluded and exits nonzero. Hosted acceptance needs a separate isolated, authorized fixture setup.

Commands from `mobile/`:

```powershell
flutter pub get
flutter analyze
flutter test
```

## Packaging decisions and limitations

Option B preserves complete current application source and essential build/configuration files. Replaced public README and added setup/security guidance. Disabled missing private seed, supplied public examples, made test-only portability fixes and replaced the private Web E2E command with an explicit explanation. No new dependency, deployment automation or license was introduced.

No original source was modified; Graphify was not rebuilt in the original workspace. Agent reports, private operators, logs, screenshots, live-fixture tests, legacy trees, linking metadata, caches and built binaries are omitted. The standard Gradle wrapper JAR and generated localization Dart are necessary exceptions to excluding generated/build artifacts.

Public source readiness does not establish backend reproduction or release signing readiness. Review the destructive historical baseline, stock Supabase extension requirements, teacher/staff/demo provisioning and missing license before publication. External acceptance/security/comparison/manifest reports accompany the ZIP for Owner review and are not bundled as application runtime files.
