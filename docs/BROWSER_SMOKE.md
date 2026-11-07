# Default sample browser smoke test

Final release build tested on 2026-11-07 in an isolated local Chrome profile. A localhost-only test server was used, with all non-loopback page requests intercepted and denied before navigation.

Final observed result:
- 15 page requests, all to the local server; zero attempted external page requests.
- Zero JavaScript exceptions.
- Korean home and start-button glyphs visually rendered correctly.
- Korean to English language switch, four answer/confirmation steps, score result, next-player reset and return to Korean passed.
- Generic DEMO QUIZ labels displayed; no event slogans or brand imagery.

Earlier smoke runs exposed remote fallback Korean font requests and missing button glyphs. These were fixed with a verified OFL Korean font, explicit button font selection, and same-origin renderer/fallback configuration. The final results above were measured after those fixes.

Limits: this is the default local sample path, not a Firebase-connected browser test, production deployment test, comprehensive cross-browser audit or a claim about all future inputs/glyphs. Staff-only Firebase login/SDK integration remains unverified in a browser. All test-owned browser/server processes and temporary profiles were cleaned up. Screenshots and raw logs are not included in this source export.
