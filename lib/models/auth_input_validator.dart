/// ログインと新規登録で共通の入力ルールを管理する。
class AuthInputValidator {
  const AuthInputValidator._();

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'メールアドレスの形式を確認してください';
    }
    return null;
  }

  static String? validatePassword(
    String? value, {
    required bool isRegistering,
  }) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'パスワードを入力してください';
    }
    // ログイン時は既存の認証情報をそのまま扱い、登録条件は適用しない。
    if (isRegistering &&
        (password.length < 8 ||
            !RegExp(r'[a-zA-Z]').hasMatch(password) ||
            !RegExp(r'[0-9]').hasMatch(password))) {
      return '8文字以上で、英字と数字をそれぞれ含めてください';
    }
    return null;
  }
}
