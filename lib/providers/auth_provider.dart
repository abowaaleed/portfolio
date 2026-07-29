import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;
  bool _initialized = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;
  bool get initialized => _initialized;

  bool get isAdmin {
    return _user != null && _user!.email == 'abo.waaleed@gmail.com';
  }

  AuthProvider() {
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        _user = user;
        _loading = false;
        _initialized = true;
        notifyListeners();
      });
    } catch (e) {
      _loading = false;
      _initialized = false;
      debugPrint('Auth init failed: $e');
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final result = await FirebaseAuth.instance.signInWithPopup(provider);
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
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    _user = null;
    notifyListeners();
  }
}
