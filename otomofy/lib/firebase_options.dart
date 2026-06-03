import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB5q4xnPhFuorrq_NqKepnSQLJMpZV8r5c',
    appId: '1:660847171607:web:023cb8edc5ebff4bc36452',
    messagingSenderId: '660847171607',
    projectId: 'otomotify',
    authDomain: 'otomotify.firebaseapp.com',
    storageBucket: 'otomotify.firebasestorage.app',
    measurementId: 'G-KJY6XLSRHH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9pyaKfyQ8J9P3MddgwWaFkE7FO49AquU',
    appId: '1:660847171607:android:6a6c5431d78b8c0dc36452',
    messagingSenderId: '660847171607',
    projectId: 'otomotify',
    storageBucket: 'otomotify.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDod3S7zSIS2MEs1IU7BU62zG5KMZ2tyCg',
    appId: '1:660847171607:ios:d8f1191a8ce77c5dc36452',
    messagingSenderId: '660847171607',
    projectId: 'otomotify',
    storageBucket: 'otomotify.firebasestorage.app',
    iosBundleId: 'com.example.otomofy',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDod3S7zSIS2MEs1IU7BU62zG5KMZ2tyCg',
    appId: '1:660847171607:ios:d8f1191a8ce77c5dc36452',
    messagingSenderId: '660847171607',
    projectId: 'otomotify',
    storageBucket: 'otomotify.firebasestorage.app',
    iosBundleId: 'com.example.otomofy',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB5q4xnPhFuorrq_NqKepnSQLJMpZV8r5c',
    appId: '1:660847171607:web:8207fa5aed72b53bc36452',
    messagingSenderId: '660847171607',
    projectId: 'otomotify',
    authDomain: 'otomotify.firebaseapp.com',
    storageBucket: 'otomotify.firebasestorage.app',
    measurementId: 'G-Y83QLG1CB5',
  );
}
