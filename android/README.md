# Android

Solo se versiona `app/src/main/AndroidManifest.xml` (nombre visible, icono y
orientación vertical). El resto del proyecto nativo lo genera
`flutter create --platforms=android,ios .`, que **no sobrescribe** archivos
existentes. El workflow de CI ejecuta ese paso antes de compilar.

Para trabajar localmente:

```bash
flutter create --platforms=android,ios --project-name inferencia_estadistica --org com.inferenciaestadistica .
bash tool/postcreate.sh
dart run flutter_launcher_icons
flutter run
```
