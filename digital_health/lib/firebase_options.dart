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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDa5cHF7He0XjWk0hgESX6YbaocgmD-fbk',
    appId: '1:1069489323213:android:4c9e9b025348464d10bd84',
    messagingSenderId: '1069489323213',
    projectId: 'ems-app-710ec',
    storageBucket: 'ems-app-710ec.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDa5cHF7He0XjWk0hgESX6YbaocgmD-fbk',
    appId: '1:1069489323213:android:4c9e9b025348464d10bd84',
    messagingSenderId: '1069489323213',
    projectId: 'ems-app-710ec',
    storageBucket: 'ems-app-710ec.appspot.com',
    iosBundleId: 'com.example.healthApp',
  );
}
