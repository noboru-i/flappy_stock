import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'analytics_service.dart';

class AuthService {
  AuthService._() {
    _auth.authStateChanges().listen((user) async {
      if (user != null && !_isAllowedEmail(user.email)) {
        await signOut();
      }
    });
  }
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  static const _allowedDomain = 'monstar-lab.com';

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithGoogle() async {
    UserCredential credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      credential = await _auth.signInWithPopup(provider);
    } else {
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {
        await GoogleSignIn.instance.signOut();
      }
      final googleUser = await GoogleSignIn.instance.authenticate();
      final auth = googleUser.authentication;
      final oauthCredential = GoogleAuthProvider.credential(
        idToken: auth.idToken,
      );
      credential = await _auth.signInWithCredential(oauthCredential);
    }

    if (!_isAllowedEmail(credential.user?.email)) {
      await signOut();
      throw FirebaseAuthException(
        code: 'unauthorized-domain',
        message: 'Please sign in with a @$_allowedDomain account.',
      );
    }

    await AnalyticsService.instance.logLogin('google');
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
  }

  bool _isAllowedEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return email.toLowerCase().endsWith('@$_allowedDomain');
  }
}
