import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthResult {
  final String idToken;
  final String email;
  final String displayName;
  final String? photoUrl;

  const GoogleAuthResult({
    required this.idToken,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });
}

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Attempts native/web Google Sign-In.
  /// Returns null if the user cancels or if native Google Sign-In is unavailable.
  static Future<GoogleAuthResult?> signIn(BuildContext context) async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        debugPrint('GoogleSignIn returned empty idToken.');
        return null;
      }
      return GoogleAuthResult(
        idToken: token,
        email: account.email,
        displayName: account.displayName ?? account.email.split('@').first,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      debugPrint('GoogleSignIn native failed: $e');
      return null;
    }
  }
}
