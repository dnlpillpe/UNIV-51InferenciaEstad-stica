#!/usr/bin/env bash
# Ajustes tras `flutter create`: nombre visible en iOS y orientación vertical.
set -euo pipefail
cd "$(dirname "$0")/.."
PLIST="ios/Runner/Info.plist"
if [ -f "$PLIST" ]; then
  python3 - "$PLIST" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
s = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)", r"\1Inferencia Estadística\2", s)
s = re.sub(r"(<key>CFBundleName</key>\s*<string>)[^<]*(</string>)", r"\1Inferencia\2", s)
# Solo vertical en iPhone.
s = re.sub(r"(<key>UISupportedInterfaceOrientations</key>\s*<array>).*?(</array>)",
           r"\1\n\t\t<string>UIInterfaceOrientationPortrait</string>\n\t\2", s, count=1, flags=re.S)
open(p, "w", encoding="utf-8").write(s)
print("Info.plist ajustado")
PY
fi
# Elimina el test de ejemplo que genera `flutter create` (no aplica a esta app).
if [ -f test/widget_test.dart ] && grep -q "Counter increments smoke test" test/widget_test.dart; then
  rm test/widget_test.dart
  echo "test/widget_test.dart de plantilla eliminado"
fi
