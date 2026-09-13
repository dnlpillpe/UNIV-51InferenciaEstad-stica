# iOS

El proyecto Xcode lo genera `flutter create --platforms=android,ios .`.
Después, `bash tool/postcreate.sh` fija el nombre visible «Inferencia Estadística»
y la orientación vertical en `Runner/Info.plist`, y
`dart run flutter_launcher_icons` instala el icono.

La compilación para iOS requiere macOS con Xcode y una cuenta de Apple
Developer para firmar; ver `docs/05_Despliegue_y_CI_CD.md`.
