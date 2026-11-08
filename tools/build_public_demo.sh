#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# Deliberately accepts no dart-defines or production configuration.
flutter build web --release --no-pub --no-web-resources-cdn \
  --target=lib/demo.dart --base-href=/flutter-korea-booth/
cp web/demo_bootstrap.js build/web/booth_bootstrap.js
rm -f build/web/booth_session.mjs
mkdir -p build/web/licenses
cp LICENSE build/web/licenses/MIT.txt
cp assets/fonts/OFL.txt build/web/licenses/OFL.txt
cp THIRD_PARTY_NOTICES.md build/web/licenses/THIRD_PARTY_NOTICES.txt
cp web/demo_licenses.html build/web/licenses.html
python3 - <<'PYTHON'
from pathlib import Path
page = Path('build/web/index.html')
text = page.read_text().replace('</body>', '<a href="licenses.html" style="position:fixed;top:29px;left:80px;z-index:5;font:12px system-ui,sans-serif;color:#45648b">Licenses</a></body>')
page.write_text(text)
PYTHON
cp build/web/index.html build/web/404.html
touch build/web/.nojekyll
