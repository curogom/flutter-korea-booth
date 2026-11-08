# Third-party notices

No event logos, mascot images, event question bank or original application icons are redistributed in this source copy. The compiled public demo includes the Flutter web renderer and generated dependency notices, and keeps its font license and application MIT license accessible from the Licenses link. Generic UI icons come from Flutter's Material icons dependency.

Dart/Flutter dependencies are resolved from pubspec.lock and tool dependencies from tools/package-lock.json. Dependency implementation trees and package caches are not shipped. docs/DEPENDENCIES.json records resolved versions and available Node package license metadata. Metadata is not a substitute for license texts or legal review. Flutter generates dependency license notices when building an application.

Optional Firebase web mode loads Firebase JavaScript SDK 13.1.0 from https://www.gstatic.com/firebasejs/13.1.0/ using official SDK module names. The pinned version matches the locked firebase_core_web 4.1.0 SDK declaration. That path requires network access; it is not invoked in default sample mode. Review the SDK and other dependency licenses before distributing a compiled application.

Legacy locally modified SDK files were omitted because their provenance manifest did not authenticate the redistributed bytes. No upstream source was downloaded or contacted during preparation. The original application code is licensed under the MIT License in LICENSE; see LICENSE_DECISION.md. Third-party code, dependencies and fonts retain their separate licenses and copyright notices.

## Bundled Korean font

assets/fonts/NotoSansKR.ttf is included unmodified with assets/fonts/OFL.txt. The binary name table identifies Noto Sans KR Thin, copyright 2014–2021 Adobe with Reserved Font Name Source, and SIL Open Font License 1.1. That metadata matches the accompanying license. It is bundled to avoid Flutter downloading fallback Korean glyph fonts. Do not relicense the font under the application's MIT License or remove its notice.
