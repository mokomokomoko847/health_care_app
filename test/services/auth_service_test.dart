import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/services/auth_service.dart';

class TestUser extends Fake implements User {
  bool verified = false;
  Object? sendFailure;
  Object? tokenFailure;
  int sendCalls = 0;
  int refreshCalls = 0;
  @override
  bool get emailVerified => verified;
  @override
  String get email => 'sample@example.com';
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    sendCalls++;
    if (sendFailure != null) throw sendFailure!;
  }

  @override
  Future<void> reload() async {
    verified = true;
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (forceRefresh) refreshCalls++;
    if (tokenFailure != null) throw tokenFailure!;
    return 'test-token';
  }
}

class TestCredential extends Fake implements UserCredential {}

class TestFirebaseAuth extends Fake implements FirebaseAuth {
  final events = StreamController<User?>.broadcast();
  TestUser? user;
  String? language;
  int createCalls = 0;
  Object? signOutFailure;
  final nextUser = TestUser();
  @override
  User? get currentUser => user;
  @override
  Stream<User?> userChanges() => events.stream;
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    createCalls++;
    user = nextUser;
    events.add(user);
    return TestCredential();
  }

  @override
  Future<void> setLanguageCode(String? code) async {
    language = code;
  }

  @override
  Future<void> signOut() async {
    if (signOutFailure != null) throw signOutFailure!;
    user = null;
    events.add(null);
  }
}

void main() {
  late TestFirebaseAuth sdk;
  late FirebaseAuthService service;
  setUp(() {
    sdk = TestFirebaseAuth();
    service = FirebaseAuthService(auth: sdk);
  });
  tearDown(() async {
    service.dispose();
    await sdk.events.close();
  });

  test('初回の認証イベントまで復元待ちとする', () async {
    expect(service.isReady, isFalse);
    sdk.events.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(service.isReady, isTrue);
    expect(service.isSignedIn, isFalse);
  });

  test('登録後に日本語の確認メールを送り、未確認セッションを保持する', () async {
    await service.register(' sample@example.com ', 'abc12345');
    expect(sdk.createCalls, 1);
    expect(sdk.nextUser.sendCalls, 1);
    expect(sdk.language, 'ja');
    expect(service.isSignedIn, isTrue);
    expect(service.isEmailVerified, isFalse);
  });

  test('初回メール送信失敗後もアカウントを保持し、再作成せず再送できる', () async {
    sdk.nextUser.sendFailure = FirebaseAuthException(
      code: 'network-request-failed',
    );
    await service.register('sample@example.com', 'abc12345');
    expect(service.isSignedIn, isTrue);
    expect(service.verificationError, contains('通信できませんでした'));
    sdk.nextUser.sendFailure = null;
    await service.sendVerificationEmail();
    expect(sdk.createCalls, 1);
    expect(sdk.nextUser.sendCalls, 2);
    expect(service.verificationError, isNull);
  });

  test('メール確認状態の再取得後にトークンも更新する', () async {
    await service.register('sample@example.com', 'abc12345');
    await service.reloadUser();
    expect(service.isEmailVerified, isTrue);
    expect(sdk.nextUser.refreshCalls, 1);
  });

  test('トークン更新に失敗した場合は確認済み画面を解放しない', () async {
    await service.register('sample@example.com', 'abc12345');
    sdk.nextUser.tokenFailure = FirebaseAuthException(
      code: 'network-request-failed',
    );
    await expectLater(
      service.reloadUser(),
      throwsA(isA<FirebaseAuthException>()),
    );
    expect(service.isEmailVerified, isFalse);
  });

  test('ログアウト失敗を呼び出し元へ返し、セッションを成功扱いで消さない', () async {
    await service.register('sample@example.com', 'abc12345');
    sdk.signOutFailure = FirebaseAuthException(code: 'network-request-failed');
    await expectLater(service.signOut(), throwsA(isA<FirebaseAuthException>()));
    expect(service.isSignedIn, isTrue);
  });

  test('未対応の例外でも内部メッセージを画面へ返さない', () {
    expect(
      authErrorMessage(Exception('private detail')),
      '処理に失敗しました。もう一度お試しください。',
    );
    expect(
      authErrorMessage(
        FirebaseAuthException(code: 'unknown', message: 'private detail'),
      ),
      '処理に失敗しました。もう一度お試しください。',
    );
  });
}
