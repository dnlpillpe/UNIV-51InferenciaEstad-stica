# Despliegue y CI/CD

## Subir el proyecto a GitHub

```bash
cd inferencia_estadistica
git init && git add . && git commit -m "Inferencia Estadística 1.0.0 (MVP)"
git branch -M main
git remote add origin https://github.com/<usuario>/inferencia-estadistica.git
git push -u origin main
```

Al primer push, `ci.yml` valida contenido y código, y `build-apk.yml` genera el APK.

## Qué se versiona y qué se genera

El repositorio **no incluye** el proyecto nativo completo: solo
`android/app/src/main/AndroidManifest.xml` (nombre visible, icono y orientación). El resto lo
crea `flutter create`, que **no sobrescribe** archivos existentes. Ventajas: menos ruido en el
repositorio y actualizaciones de plantilla automáticas al cambiar de versión de Flutter.

```bash
flutter create --platforms=android,ios --project-name inferencia_estadistica --org com.inferenciaestadistica .
bash tool/postcreate.sh      # nombre visible en iOS, orientación, limpia el test de plantilla
flutter pub get
dart run flutter_launcher_icons
```

`tool/postcreate.sh` también elimina el `test/widget_test.dart` de la plantilla, que de otro
modo haría fallar `flutter analyze` al referirse a un `MyApp` inexistente.

## Workflows

### `ci.yml` — calidad (estricto)

1. **Contenido (Python, sin Flutter):** `tool/validate_content.py` verifica ids únicos,
   referencias, distractores con retroalimentación, confusiones usadas y **50 cifras**
   recalculadas con `tool/inference_core.py`.
2. **Verificación estática:** `tool/static_check.py` revisa delimitadores, imports y
   dependencias de los 88 archivos Dart.
3. **Flutter:** `flutter analyze --no-fatal-infos` y `flutter test`.

Un fallo aquí bloquea el merge.

### `build-apk.yml` — artefactos

Compila el APK universal y los de cada arquitectura, los sube como artefacto (30 días) y, si el
push es de una etiqueta `v*`, publica un release de GitHub con los archivos. Las pruebas se
ejecutan en modo informativo: un test roto no debe impedir obtener un APK para pruebas de campo
(el estado estricto vive en `ci.yml`).

```bash
git tag v1.0.0 && git push origin v1.0.0   # dispara el release
```

### `build-ios.yml` — verificación manual

`flutter build ios --release --no-codesign` en macOS. No produce un IPA instalable.

## Firma del APK

Sin secretos configurados, el APK de release se firma con la **clave de depuración**:
instalable en cualquier dispositivo con «orígenes desconocidos» habilitado, no publicable en
Google Play.

Para firma real:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
base64 -w0 upload-keystore.jks   # el resultado va al secreto KEYSTORE_BASE64
```

Secretos del repositorio: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
Con ellos presentes, `tool/configure_signing.sh` inyecta la configuración de firma en el
`build.gradle` (Kotlin o Groovy) generado. **Nunca** subir el `.jks` ni `key.properties` al
repositorio: ambos están en `.gitignore`.

## Instalar el APK para pruebas de campo

1. Descargar el artefacto del workflow (pestaña Actions) o el release.
2. Usar `inferencia-estadistica-v1.0.0.apk` (universal) o el de la arquitectura del dispositivo
   (`arm64-v8a` en la mayoría de los teléfonos actuales).
3. Habilitar la instalación de orígenes desconocidos y abrir el archivo.

## Publicación en Google Play (resumen)

1. Cambiar `version:` en `pubspec.yaml` (`1.0.1+2`: nombre + código de compilación).
2. `flutter build appbundle --release` con la firma real configurada.
3. Subir el `.aab` a la consola de Play, completar ficha, clasificación de contenido y política
   de privacidad. La app no recoge datos personales ni usa red: el formulario de seguridad de
   datos se declara sin recolección.
4. Para iOS: `flutter build ipa` en macOS con cuenta de Apple Developer y perfil de distribución.

## Requisitos de compilación

| Herramienta | Versión |
|---|---|
| Flutter | canal `stable` (3.24 o superior) |
| Dart | 3.5+ |
| JDK | 17 (para Android Gradle Plugin 8.x) |
| Android SDK | compileSdk de la plantilla de Flutter; minSdk 21 |
