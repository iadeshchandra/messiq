import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not supported yet.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMZp_eliy5PkNhAIVteByb8_e0sPB9d_E',
    appId: '1:888220196145:android:9c0317f226ce85671ee410',
    messagingSenderId: '888220196145',
    projectId: 'messiq-4b00c',
    storageBucket: 'messiq-4b00c.firebasestorage.app',
  );
}
