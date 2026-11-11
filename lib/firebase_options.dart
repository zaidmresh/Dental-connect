import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBumfwgn7sJZu2bCIZ87cUlH14SKy0oUqc',
    appId: '1:471890487399:web:c8897c961fd4e2969c8cc2',
    messagingSenderId: '471890487399',
    projectId: 'zaidmresh-983cc',
    authDomain: 'zaidmresh-983cc.firebaseapp.com',
    storageBucket: 'zaidmresh-983cc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBumfwgn7sJZu2bCIZ87cUlH14SKy0oUqc',
    appId: '1:471890487399:android:13f9f2e3b6c892cb9c8cc2',
    messagingSenderId: '471890487399',
    projectId: 'zaidmresh-983cc',
    storageBucket: 'zaidmresh-983cc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBumfwgn7sJZu2bCIZ87cUlH14SKy0oUqc',
    appId: '1:471890487399:ios:63d8572bc3fca2dd9c8cc2',
    messagingSenderId: '471890487399',
    projectId: 'zaidmresh-983cc',
    storageBucket: 'zaidmresh-983cc.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBumfwgn7sJZu2bCIZ87cUlH14SKy0oUqc',
    appId: '1:471890487399:web:542d6f3eec8d57759c8cc2',
    messagingSenderId: '471890487399',
    projectId: 'zaidmresh-983cc',
    authDomain: 'zaidmresh-983cc.firebaseapp.com',
    storageBucket: 'zaidmresh-983cc.firebasestorage.app',
  );
}
