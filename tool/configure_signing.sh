#!/usr/bin/env bash
# Configura la firma de release de Android a partir de secretos de GitHub.
# Variables: KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD.
# Sin estos secretos, `flutter build apk --release` firma con la clave de
# depuración: el APK se instala para pruebas, pero no se puede publicar.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "$KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks
cat > android/key.properties <<PROPS
storePassword=$KEYSTORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=upload-keystore.jks
PROPS

GRADLE_KTS="android/app/build.gradle.kts"
GRADLE="android/app/build.gradle"
if [ -f "$GRADLE_KTS" ]; then
  python3 - "$GRADLE_KTS" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
if "keystoreProperties" not in s:
    header = ('import java.util.Properties\nimport java.io.FileInputStream\n\n'
              'val keystoreProperties = Properties()\n'
              'val keystorePropertiesFile = rootProject.file("key.properties")\n'
              'if (keystorePropertiesFile.exists()) {\n'
              '    keystoreProperties.load(FileInputStream(keystorePropertiesFile))\n}\n\n')
    s = header + s
    s = s.replace("    buildTypes {", (
        "    signingConfigs {\n"
        "        create(\"release\") {\n"
        "            keyAlias = keystoreProperties[\"keyAlias\"] as String\n"
        "            keyPassword = keystoreProperties[\"keyPassword\"] as String\n"
        "            storeFile = file(keystoreProperties[\"storeFile\"] as String)\n"
        "            storePassword = keystoreProperties[\"storePassword\"] as String\n"
        "        }\n"
        "    }\n\n"
        "    buildTypes {"), 1)
    s = s.replace('signingConfig = signingConfigs.getByName("debug")',
                  'signingConfig = signingConfigs.getByName("release")')
    open(p, "w").write(s)
print("Firma de release configurada (Kotlin DSL)")
PY
elif [ -f "$GRADLE" ]; then
  python3 - "$GRADLE" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
if "keystoreProperties" not in s:
    header = ("def keystoreProperties = new Properties()\n"
              "def keystorePropertiesFile = rootProject.file('key.properties')\n"
              "if (keystorePropertiesFile.exists()) {\n"
              "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n}\n\n")
    s = s.replace("android {", header + "android {", 1)
    s = s.replace("    buildTypes {", (
        "    signingConfigs {\n"
        "        release {\n"
        "            keyAlias keystoreProperties['keyAlias']\n"
        "            keyPassword keystoreProperties['keyPassword']\n"
        "            storeFile file(keystoreProperties['storeFile'])\n"
        "            storePassword keystoreProperties['storePassword']\n"
        "        }\n"
        "    }\n\n"
        "    buildTypes {"), 1)
    s = s.replace("signingConfig signingConfigs.debug", "signingConfig signingConfigs.release")
    open(p, "w").write(s)
print("Firma de release configurada (Groovy)")
PY
fi
