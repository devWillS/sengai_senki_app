import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web Firebase configuration has not been provided.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase options have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD34uDVvsoSvqBp6T-ed_xQRhpCg7MBUSM',
    appId: '1:602208895421:android:4f2989bfeb51eb0a4552d4',
    messagingSenderId: '602208895421',
    projectId: 'sengi-pocket',
    storageBucket: 'sengi-pocket.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDimTW_sQPr-xI6rhQImgpmsNBLrYJlxFg',
    appId: '1:602208895421:ios:f363f8d36ed76db24552d4',
    messagingSenderId: '602208895421',
    projectId: 'sengi-pocket',
    storageBucket: 'sengi-pocket.firebasestorage.app',
    iosBundleId: 'jp.devwill.sengiPocket',
  );
}
