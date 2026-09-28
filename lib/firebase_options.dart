// Este archivo es un marcador hasta ejecutar `flutterfire configure`.
// Ese comando genera automáticamente la configuración real para Android/iPhone.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return android;
    case TargetPlatform.iOS:
      return ios;
    default:
      return android;
  }
}

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDztPFNY2BmDhq3jYH41sq_y1Qq-UdojFU',
    appId: '1:513011070074:ios:5f81cc15437c075376f7c3',
    messagingSenderId: '513011070074',
    projectId: 'cuenta-comun-43e53',
    storageBucket: 'cuenta-comun-43e53.firebasestorage.app',
    iosBundleId: 'com.example.dineroPareja',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDGbk2aQv6DPZRXQBRFSXVpOoM5Lxa57Mc',
    appId: '1:513011070074:android:79eb0b305b76b00d76f7c3',
    messagingSenderId: '513011070074',
    projectId: 'cuenta-comun-43e53',
    storageBucket: 'cuenta-comun-43e53.firebasestorage.app',
  );
}
