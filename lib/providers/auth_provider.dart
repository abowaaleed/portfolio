import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _loading = true;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  bool get isAdmin {
    return _user != null && _user!.email == 'abo.waaleed@gmail.com';
  }

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      _loading = false;
      notifyListeners();
    });
  }

  Future<String?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      _user = result.user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'فشل تسجيل الدخول';
    } catch (e) {
      return 'حدث خطأ: $e';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
