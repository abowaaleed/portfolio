import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDQy3w4a8luM2g5vFVQ6ggoe3a1nmp2PGs',
    appId: '1:150947006478:web:01b49dda172eb10946d45f',
    messagingSenderId: '150947006478',
    projectId: 'saleh-portfolio-ef926',
    authDomain: 'saleh-portfolio-ef926.firebaseapp.com',
    storageBucket: 'saleh-portfolio-ef926.firebasestorage.app',
    measurementId: 'G-S59ML9TRTM',
  );
}
