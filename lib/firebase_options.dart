// File generated from Firebase console configs for project bhagvad-geeta-2a708.
// Re-generate with: flutterfire configure

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const bool isConfigured = true;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCNkA5_8ahziFGpMd_mZFp9DuYoJRMBCLk',
    appId: '1:743728143829:android:266d5f196536be89',
    messagingSenderId: '743728143829',
    projectId: 'bhagvad-geeta-2a708',
    databaseURL: 'https://bhagvad-geeta-2a708.firebaseio.com',
    storageBucket: 'bhagvad-geeta-2a708.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBSPgdrewKOG_KJ2iWC92IeS7v9A8CUu5E',
    appId: '1:743728143829:ios:c2fc2f313e137f94feb15c',
    messagingSenderId: '743728143829',
    projectId: 'bhagvad-geeta-2a708',
    databaseURL: 'https://bhagvad-geeta-2a708.firebaseio.com',
    storageBucket: 'bhagvad-geeta-2a708.firebasestorage.app',
    iosBundleId: 'org.komal.bhagvadgeeta',
  );
}
