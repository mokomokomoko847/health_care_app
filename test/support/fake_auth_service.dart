import 'dart:async';

import 'package:health_care_app/services/auth_service.dart';

class FakeAuthService extends AuthService {
  FakeAuthService({
    this.isSignedIn = false,
    this.isEmailVerified = false,
    this.isReady = true,
  });
  @override
  bool isReady;
  @override
  bool isSignedIn;
  @override
  bool isEmailVerified;
  @override
  String? get userId => isSignedIn ? accountId : null;
  String accountId = 'test-user';
  @override
  String? email = 'sample@example.com';
  @override
  String? verificationError;
  @override
  String? initializationError;
  Object? failure;
  Completer<void>? pending;
  int signInCalls = 0;
  int registerCalls = 0;
  int resetCalls = 0;
  int resendCalls = 0;
  bool verifiedOnReload = false;
  String? submittedEmail;
  String? submittedPassword;

  Future<void> _complete() async {
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls++;
    submittedEmail = email;
    submittedPassword = password;
    await _complete();
    isSignedIn = true;
    isEmailVerified = true;
    notifyListeners();
  }

  @override
  Future<void> register(String email, String password) async {
    registerCalls++;
    await _complete();
    isSignedIn = true;
    isEmailVerified = false;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    await _complete();
    isSignedIn = false;
    isEmailVerified = false;
    notifyListeners();
  }

  @override
  Future<void> reloadUser() async {
    await _complete();
    isEmailVerified = verifiedOnReload;
    notifyListeners();
  }

  @override
  Future<void> sendVerificationEmail() async {
    resendCalls++;
    await _complete();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    resetCalls++;
    await _complete();
  }

  @override
  Future<String> verifyPasswordResetCode(String code) async {
    await _complete();
    return email!;
  }

  @override
  Future<void> confirmPasswordReset(String code, String password) async {
    submittedPassword = password;
    await _complete();
  }

  @override
  Future<void> applyEmailVerificationCode(String code) async {
    await _complete();
  }
}
