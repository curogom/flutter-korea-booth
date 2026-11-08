# Validation record

Verified on 2026-11-07 using local cached dependencies and synthetic test data.

## Passed

- flutter pub get --offline.
- npm ci --offline --ignore-scripts --no-audit --no-fund: 239 locked packages installed for testing only.
- Final flutter analyze --no-pub: no issues.
- Final flutter test --no-pub: 125 tests passed. Includes all demo questions in Korean/English, tablet layouts, scoring, controller/storage behavior, administrator entry/exit cleanup and delayed sign-in coordination.
- Local Auth/Firestore/session suite: 52 tests passed using demo-quiz-tests and guarded loopback ports. One initial seed-helper credential-type failure was corrected before the passing run.
- flutter build web --release --no-pub --no-web-resources-cdn: successful JavaScript release build and Wasm dry-run check.
- JavaScript syntax checks for bootstrap and emulator helper.
- Source export search found no operating-project identifiers, machine paths or credential-pattern matches. Original event prompts/explanations/long options were separately compared with exported text and found absent.
- Original source before/after hashes matched; no original app files were modified.

## Limits

- Optional Firebase web initialization loads pinned official SDK 13.1.0 from the Google CDN. This browser path was not tested against external SDK endpoints or live Firebase. Passing emulator rule tests does not validate that browser integration.
- Actual deployed rules, Auth/IAM, domain restrictions, production configuration, hosting headers, data retention and Analytics settings were not inspected or modified.
- The initial offline validation did not query dependency advisories; npm installation used --no-audit and offline cache. The later online check is recorded below. Deprecation notices exist for node-domexception and some OpenTelemetry packages; they are not proof of an exploitable vulnerability.
- Native targets were omitted and not built. Vendor/dependency implementations and all historical files were not exhaustively audited.
- The original validation preceded the owner's application-license selection. The owner selected MIT on 2026-11-07; see LICENSE and LICENSE_DECISION.md. Code ownership was not independently verified.
- Generated builds, package caches and test logs are excluded from this final source folder. Re-run dependency setup before testing.

Default-sample browser observations, if completed, are recorded in BROWSER_SMOKE.md. Absence of that file means no browser-level network or interaction claim is made.

## Later license-only update: 2026-11-07

Added the owner's selected MIT License and updated licensing guidance only. Application code, dependencies, font binaries and third-party license texts were unchanged. The checks above remain the original validation record; no build, test suite, browser check, security scan or current CVE/advisory lookup was rerun for this documentation-only update.

## Later online dependency advisory check: 2026-11-07

Checked at 14:17–14:18 UTC using [OSV](https://osv.dev/) and [npm audit](https://docs.npmjs.com/cli/v11/commands/npm-audit). All 77 hosted Pub packages (12 direct runtime, 1 direct development, 64 transitive) and all 239 npm tool-package entries (220 distinct name/version pairs) were checked at their locked versions. OSV returned no matching advisories; npm audit reported zero vulnerabilities at every severity. The npm graph is administration/test tooling, not the Flutter browser bundle. No dependency installs, lifecycle hooks, upgrades or lockfile changes were performed for this check.

Optional Firebase 13.1.0 and its registry-mapped @firebase/app 0.16.4, @firebase/auth 1.13.8, @firebase/firestore 4.19.0 and @firebase/analytics 0.10.25 also returned no OSV matches. [GHSA-3wf4-68gx-mph8 / CVE-2024-11023](https://github.com/advisories/GHSA-3wf4-68gx-mph8) is Moderate and fixed in Firebase 10.9.0; neither optional 13.1.0 nor test dependency 13.2.0 is affected.

Installed validation SDK Flutter 3.47.9 / Dart 3.13.7 was checked against all eight published [Dart SDK advisories](https://github.com/dart-lang/sdk/security/advisories); none applies to these versions. In particular, [GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp) is High and fixed in Flutter 3.47.8 / Dart 3.13.7, and [GHSA-q739-79rh-vmvp / CVE-2026-27704](https://github.com/dart-lang/sdk/security/advisories/GHSA-q739-79rh-vmvp) is Low and fixed in Flutter 3.41.0 / Dart 3.11.0. The [Flutter repository](https://github.com/flutter/flutter/security/advisories) listed no separate published advisories.

No affected locked version or dependency-advisory release blocker was identified. Zero matches is not a vulnerability-free guarantee. The five SDK lock entries marked 0.0.0 were assessed at SDK level, not as hosted Pub releases. Engine/native/browser internals, emulator binaries and global tooling were not comprehensively inventoried. CDN artifacts and embedded dependencies were not recursively audited or executed; optional Firebase browser integration and live operation remain unverified. No functional tests or builds were rerun for this advisory check. DEPENDENCIES.json retains the initial offline-review status; this dated follow-up records the newer online result.

## Public static demo: 2026-11-08

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: all 126 tests passed, including public admin/sign-in/report route denial.
- `node --test tools/booth_session.test.mjs`: all 4 tests passed. Firestore/Auth emulator rules were unchanged and their full suite was not rerun for this static-only release.
- `sh tools/build_public_demo.sh`: JavaScript release and Wasm dry run succeeded; uses the dedicated sample-only entrypoint and local renderer/font files under `/flutter-korea-booth/`.
- Local isolated Chromium checks at 1280×900 and 390×844 passed: Korean/English switch, four answers, result, reset, refresh, Back/Forward, hash admin/report routes and direct-path 404 fallback. Actual desktop/mobile pixels were reviewed.
- Each viewport run observed 37 same-origin GET requests, zero attempted external requests and zero JavaScript exceptions. Fresh-context localStorage, sessionStorage, IndexedDB, cookies and service workers remained empty. No app storage was cleared. Provider HTTP logs and browser asset caches are outside this app-state observation.
- The deployment contains the MIT license, Noto Sans KR copyright/OFL text and generated Flutter dependency `assets/NOTICES`, linked from `licenses.html`.
- The optional Firebase loader is replaced with a static-only bootstrap in this build. No operational configuration, identifiers or credentials are used. Original operational rules, Auth, data and hosting are untouched.
- Local validation is not itself proof of live publication. Check the repository's GitHub Pages deployment status and anonymous live URL for a particular deployed revision.

### Verified public deployment

Public URL: https://curogom.github.io/flutter-korea-booth/

Application source: `c3114e7d47d91f935aa683282eb163b16b8416da`.
Static artifact: `8a2997a5a1aa8c7a4c5750b2f7fc33623a2ca2e4` on `gh-pages`.
Both commits have GitHub-verified signatures. GitHub Pages [build and deployment 42443315949](https://github.com/curogom/flutter-korea-booth/actions/runs/42443315949) completed successfully. Pages reports public access, enforced HTTPS, the `gh-pages` root as its source and no custom domain. GitHub Pages is available for public repositories on GitHub Free; no paid resources or new credentials were created.

Anonymous live Chromium checks at 1280×900 and 390×844 repeated the local bilingual/four-question/result/reset, refresh, history and admin-route checks successfully. Each run observed 37 same-origin GET requests, no external request attempts and no JavaScript exceptions. The only HTTP error was the expected direct `/admin` 404, which displayed the safe static fallback; no admin login or report was available. Persistent app storage, cookies and service-worker registrations remained empty. Desktop/mobile live screenshots were visually reviewed.

SHA-256 comparisons matched 12 live files to the signed artifact: index, 404 fallback, main JavaScript, both bootstraps, sample question bank, Korean font, active CanvasKit Wasm, dependency notices, OFL, MIT and source metadata. The public license page and all three license/notice downloads returned HTTP 200. This documents the observed deployed revision, not a guarantee about future edits, provider logs or all browsers.
