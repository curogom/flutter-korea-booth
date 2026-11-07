# Security scope and release precautions

## Safe default

The runnable default is a local sample quiz. No Firebase configuration, participant records or analytics are enabled. Do not use browser-visible answers or scores as an anti-cheating or valuable-prize verification mechanism.

## Optional Firebase mode

Published questions, explanations and correct answer IDs are intentionally public. Firestore rules require quizAdmin for drafts, question writes, participation records and reporting configuration, and default-deny unmatched collections. The client is not an authorization boundary. Deploying rules is a separate owner-controlled action; no live rules were verified by this preparation.

Admin entry clears inherited credentials, and admin exit waits for sign-out before returning. Failed cleanup is fail-closed. Auth persistence is memory-only, Firestore persistence is disabled, password text is cleared after sign-in, and late sign-in completion after page disposal signs out. Protect an actively unlocked administrator screen and avoid administrator credentials on unattended kiosks. Sign-out does not revoke previously issued tokens server-side. Prefer a separate protected admin device/origin for production.

The runnable entry point deliberately does not connect RunLedger, remote run synchronization, Analytics or reporting views. Their modules are retained for educational/reference use and covered by existing unit tests. Re-enabling them requires least-privilege separation, input integrity, data minimization, retention/deletion controls and user-facing privacy information.

## Publication checklist

- Keep LICENSE with the original application code under the owner's selected MIT License. Confirm that any code being distributed is yours to license, and preserve separate third-party licenses and copyright notices; see LICENSE_DECISION.md and THIRD_PARTY_NOTICES.md.
- Keep local Firebase configuration, credentials, service accounts, exports, backups and generated files out of source control. .gitignore is preventive convenience, not a secret scanner.
- Run the tests and dependency vulnerability checks in the intended release environment. Lockfiles pin versions, not security guarantees.
- Review current dependency advisories and license requirements before each release. The initial review was offline; a later online check on 2026-11-07 returned no matching advisories for the locked Pub/npm packages and checked optional Firebase SDK identities. See [the dated scope and limits](docs/VALIDATION.md#later-online-dependency-advisory-check-2026-11-07). This does not guarantee absence of vulnerabilities.
- Before production, independently verify deployed rules, Auth/IAM, allowed domains, HTTPS/security headers, data retention and actual browser behavior.
- Public reports should not contain credentials or private participant data. No external reporting contact has been invented for this project.
