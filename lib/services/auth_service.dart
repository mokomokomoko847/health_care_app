import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// 画面はこの窓口を通して認証する。テストではFirebase通信を差し替える。
abstract class AuthService extends ChangeNotifier {
  bool get isReady;
  bool get isSignedIn;
  bool get isEmailVerified;
  String? get email;
  String? get verificationError;
  String? get initializationError;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> sendVerificationEmail();
  Future<void> reloadUser();
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<String> verifyPasswordResetCode(String code);
  Future<void> confirmPasswordReset(String code, String password);
  Future<void> applyEmailVerificationCode(String code);
}

class FirebaseAuthService extends AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance {
    // 初回イベントを待ち、保存済みセッションの復元前に画面を決めない。
    _subscription = _auth.userChanges().listen(
      (_) {
        _isReady = true;
        _initializationError = null;
        if (!_checkingVerification) {
          _emailVerified = _auth.currentUser?.emailVerified ?? false;
          if (!_registering) notifyListeners();
        }
      },
      onError: (Object error) {
        _initializationError = authErrorMessage(error);
        notifyListeners();
      },
    );
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _subscription;
  bool _isReady = false;
  bool _registering = false;
  bool _checkingVerification = false;
  bool _emailVerified = false;
  String? _verificationError;
  String? _initializationError;

  @override
  bool get isReady => _isReady;
  @override
  bool get isSignedIn => _auth.currentUser != null;
  @override
  bool get isEmailVerified => _emailVerified;
  @override
  String? get email => _auth.currentUser?.email;
  @override
  String? get verificationError => _verificationError;
  @override
  String? get initializationError => _initializationError;

  @override
  Future<void> signIn(String email, String password) async {
    _verificationError = null;
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register(String email, String password) async {
    _registering = true;
    _verificationError = null;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      try {
        await sendVerificationEmail();
      } catch (error) {
        // 作成済みアカウントは保持し、確認待ち画面で再送できるようにする。
        _verificationError = authErrorMessage(error);
      }
    } finally {
      _registering = false;
      notifyListeners();
    }
  }

  @override
  Future<void> sendVerificationEmail() async {
    await _auth.setLanguageCode('ja');
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-token-expired');
    await user.sendEmailVerification();
    _verificationError = null;
  }

  @override
  Future<void> reloadUser() async {
    _checkingVerification = true;
    try {
      await _auth.currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      if (verified) await _auth.currentUser?.getIdToken(true);
      // 再取得とトークン更新の両方に成功してから、ルーターへ確認済みを通知する。
      _emailVerified = verified;
      notifyListeners();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'user-disabled' ||
          error.code == 'user-not-found' ||
          error.code == 'user-token-expired') {
        await signOut();
      }
      rethrow;
    } finally {
      _checkingVerification = false;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    _emailVerified = false;
    _verificationError = null;
    notifyListeners();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.setLanguageCode('ja');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<String> verifyPasswordResetCode(String code) =>
      _auth.verifyPasswordResetCode(code);

  @override
  Future<void> confirmPasswordReset(String code, String password) =>
      _auth.confirmPasswordReset(code: code, newPassword: password);

  @override
  Future<void> applyEmailVerificationCode(String code) async {
    // 再設定コードなどをメール確認コードとして受け入れない。
    final info = await _auth.checkActionCode(code);
    if (info.operation != ActionCodeInfoOperation.verifyEmail) {
      throw FirebaseAuthException(code: 'invalid-action-code');
    }
    await _auth.applyActionCode(code);
    await reloadUser();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// SDKの内部メッセージや認証情報を、そのまま画面・ログへ出さない。
String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return '処理に失敗しました。もう一度お試しください。';
  }
  return switch (error.code) {
    'invalid-email' => 'メールアドレスの形式を確認してください。',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-login-credentials' => 'メールアドレスまたはパスワードが正しくありません。',
    'email-already-in-use' => 'このメールアドレスは登録済みです。ログインしてください。',
    'weak-password' ||
    'password-does-not-meet-requirements' => 'パスワードが登録条件を満たしていません。',
    'network-request-failed' => '通信できませんでした。接続を確認して、もう一度お試しください。',
    'too-many-requests' => '試行回数が多すぎます。しばらく待ってからお試しください。',
    'user-disabled' => 'このアカウントは無効になっています。',
    'user-token-expired' ||
    'invalid-user-token' ||
    'requires-recent-login' => 'もう一度ログインしてください。',
    'expired-action-code' ||
    'invalid-action-code' => 'リンクが無効か、有効期限が切れています。メールを再送してください。',
    'operation-not-allowed' => '現在この認証方法を利用できません。管理者に確認してください。',
    _ => '処理に失敗しました。もう一度お試しください。',
  };
}
