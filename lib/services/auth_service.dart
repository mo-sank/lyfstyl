import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  User? _currentUser;

  // Get current user
  User? get currentUser => _currentUser ?? _auth.currentUser;

  // Loading state getter
  bool get isLoading => _isLoading;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthService() {
    _currentUser = _auth.currentUser;
    print('DEBUG AUTH_SERVICE: Initial user: ${_currentUser?.email ?? "null"}');
    
    // Listen to Firebase auth changes
    _auth.authStateChanges().listen((User? user) {
      print('DEBUG AUTH_SERVICE: Firebase auth state changed to: ${user?.email ?? "null"}');
      _currentUser = user;
      notifyListeners(); // This will trigger UI rebuilds
    });
  }

  // Set loading state and notify listeners
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return null;
    
    _setLoading(true);
    try {
      print('DEBUG SIGNUP: Starting signup for $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('DEBUG SIGNUP: User created successfully');
      
      // Send email verification
      await result.user?.sendEmailVerification();
      print('DEBUG SIGNUP: Verification email sent');
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('DEBUG SIGNUP: FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (_isLoading) {
      print('DEBUG LOGIN: Already loading, ignoring request');
      return null;
    }
    
    _setLoading(true);
    try {
      print('DEBUG LOGIN: Attempting login for $email');
      print('DEBUG LOGIN: Current user before login: ${_auth.currentUser?.email ?? "null"}');
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('DEBUG LOGIN: Login successful for ${result.user?.email}');
      print('DEBUG LOGIN: Email verified before reload: ${result.user?.emailVerified}');
      
      // Force a fresh token and reload user data
      await result.user?.reload();
      
      User? refreshedUser = _auth.currentUser;
      
      print('DEBUG LOGIN: Email verified after reload: ${refreshedUser?.emailVerified}');
      print('DEBUG LOGIN: Current user after reload: ${refreshedUser?.email}');

      // Check if email is verified with refreshed data
      if (refreshedUser != null && !refreshedUser.emailVerified) {
        print('DEBUG LOGIN: Email not verified, signing out...');
        await _auth.signOut();
        print('DEBUG LOGIN: Signed out due to unverified email');
        throw 'Please verify your email before signing in. Check your inbox for a verification link.';
      }
      
      print('DEBUG LOGIN: Login completed successfully!');
      
      // Update our cached user and force notification
      _currentUser = refreshedUser;
      print('DEBUG AUTH_SERVICE: Manually updating current user and notifying');
      notifyListeners();
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('DEBUG LOGIN: FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('DEBUG LOGIN: Other exception: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    if (_isLoading) return;
    
    _setLoading(true);
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.sendEmailVerification();
        print('DEBUG: Email verification sent');
      } else {
        print('DEBUG: No current user to send verification to');
      }
    } on FirebaseAuthException catch (e) {
      print('DEBUG: Error sending verification: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } finally {
      _setLoading(false);
    }
  }

  // Check if email is verified
  bool get isEmailVerified => _currentUser?.emailVerified ?? _auth.currentUser?.emailVerified ?? false;

  // Sign out
  Future<void> signOut() async {
    if (_isLoading) return;
    
    _setLoading(true);
    try {
      print('DEBUG LOGOUT: Signing out current user: ${_auth.currentUser?.email ?? "null"}');
      await _auth.signOut();
      print('DEBUG LOGOUT: Sign out completed');
      
      // Update our cached user and notify
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('DEBUG LOGOUT: Error during sign out: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      case 'invalid-credential':
        return 'The credentials provided are invalid or expired.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}