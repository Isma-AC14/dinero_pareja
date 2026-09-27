# Dinero de los dos — V2

V2 preparada para Android + iPhone con Firebase.

## Incluye
- Cuenta con correo y contraseña.
- Crear una cuenta de pareja.
- Código de 6 caracteres para que la segunda persona se una.
- Máximo 2 miembros por pareja.
- Saldo inicial compartido.
- Ingresos y gastos compartidos.
- Historial en la nube.
- Sincronización automática en los dos móviles mediante Firestore.
- Cada movimiento guarda qué usuario lo creó.

## Importante
Este ZIP es el proyecto fuente. Todavía no contiene las claves/configuración de Firebase de vuestra cuenta. Eso es intencionado: las claves y el proyecto de Firebase deben pertenecer a vosotros.

## Configuración una sola vez
1. Crear un proyecto en Firebase Console.
2. Activar Authentication > Sign-in method > Email/Password.
3. Crear Firestore Database.
4. Instalar Flutter y FlutterFire CLI.
5. En esta carpeta ejecutar:

   flutter pub get
   dart pub global activate flutterfire_cli
   flutterfire configure

6. Seleccionar Android e iOS cuando lo pregunte. Esto sustituirá `lib/firebase_options.dart` por la configuración real.
7. Publicar las reglas de `firestore/firestore.rules` en Firestore.
8. Ejecutar `flutter run` para probar.

## Android
flutter build apk --release

## iPhone
Para compilar/publicar iOS hace falta un Mac con Xcode.

## Estructura
- `lib/main.dart`: interfaz y navegación principal.
- `lib/models/movimiento.dart`: modelo de movimientos.
- `lib/services/firebase_service.dart`: autenticación, pareja y sincronización.
- `lib/firebase_options.dart`: marcador hasta ejecutar `flutterfire configure`.
- `firestore/firestore.rules`: reglas de seguridad.
