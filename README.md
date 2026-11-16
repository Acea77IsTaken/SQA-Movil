# StockFácil móvil

Base Flutter para desarrollar el inventario local de Android. Esta rama incluye la identidad visual y la navegación entre Productos, Stock bajo e Historial. Las funciones de inventario se incorporan en las ramas siguientes.

## Preparar el entorno

Usa Flutter 3.44.5 estable y Dart 3.12.2, versiones empleadas para esta entrega, y un SDK de Android con un dispositivo o emulador. Ejecuta los comandos desde la raíz de este repositorio:

```powershell
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run
```

Selecciona el dispositivo Android cuando Flutter lo solicite. Para compilar un APK de desarrollo:

```powershell
flutter build apk --debug
```

El APK se genera en `build/app/outputs/flutter-apk/app-debug.apk`. Comprueba que la app muestre StockFácil y permita recorrer las tres secciones sin cerrarse. El análisis y las pruebas de widgets no sustituyen esta comprobación en Android.

## Datos y acceso

La primera versión usa datos propios del teléfono y funciona sin Internet. No comparte el archivo SQLite ni las cuentas del proyecto Laravel. Las ramas siguientes implementan SQLite y una cuenta local creada en el primer uso; no se incluyen credenciales predeterminadas.

La conexión con el inventario web y su API están fuera de este alcance. El aviso de fallos de red del issue #9 queda pendiente hasta que exista una operación que necesite red.

## Git y siguiente paso

Este repositorio corresponde a [Acea77IsTaken/SQA-Movil](https://github.com/Acea77IsTaken/SQA-Movil). El proyecto Laravel se conserva en `../web/`, con su propio Git. No incluyas datos locales, claves de firma ni archivos generados en los commits.

Consulta el [issue #1](https://github.com/Acea77IsTaken/SQA-Movil/issues/1) para los criterios de esta base. Después continúa con el acceso local y el catálogo.
