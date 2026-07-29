import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    appId: '1:123456789:web:aaaaaaaaaaaaaaaaaaaaaa',
    messagingSenderId: '123456789',
    projectId: 'YOUR_FIREBASE_PROJECT_ID',
    authDomain: 'YOUR_PROJECT.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT.appspot.com',
    measurementId: 'G-XXXXXXXXXX',
  );
}
