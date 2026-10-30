// File generated for Firebase project: foodgo-59da7
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
/// Configured for Firebase project: foodgo-59da7
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyFoodGoWebApiKey59da7',
    appId: '1:1049282001:web:foodgo59da7web',
    messagingSenderId: '1049282001',
    projectId: 'foodgo-59da7',
    authDomain: 'foodgo-59da7.firebaseapp.com',
    storageBucket: 'foodgo-59da7.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyFoodGoAndroidApiKey59da7',
    appId: '1:1049282001:android:com_example_foodgo_flutter',
    messagingSenderId: '1049282001',
    projectId: 'foodgo-59da7',
    storageBucket: 'foodgo-59da7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyFoodGoIosApiKey59da7',
    appId: '1:1049282001:ios:foodgo59da7ios',
    messagingSenderId: '1049282001',
    projectId: 'foodgo-59da7',
    storageBucket: 'foodgo-59da7.appspot.com',
    iosBundleId: 'com.example.foodgoFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyFoodGoIosApiKey59da7',
    appId: '1:1049282001:ios:foodgo59da7ios',
    messagingSenderId: '1049282001',
    projectId: 'foodgo-59da7',
    storageBucket: 'foodgo-59da7.appspot.com',
    iosBundleId: 'com.example.foodgoFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyFoodGoWebApiKey59da7',
    appId: '1:1049282001:web:foodgo59da7web',
    messagingSenderId: '1049282001',
    projectId: 'foodgo-59da7',
    authDomain: 'foodgo-59da7.firebaseapp.com',
    storageBucket: 'foodgo-59da7.appspot.com',
  );
}
