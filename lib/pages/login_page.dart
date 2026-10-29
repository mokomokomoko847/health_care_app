import 'package:flutter/material.dart';

import '../models/auth_input_validator.dart';

/// 添付デザインをFlutterで再現した認証フォーム。Firebase接続は別途行う。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _primary = Color(0xFF0037B0);
  static const _primaryContainer = Color(0xFF1D4ED8);
  static const _surfaceContainer = Color(0xFFE9EDFF);
  static const _onSurface = Color(0xFF141B2B);
  static const _onSurfaceVariant = Color(0xFF434655);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(bool isRegistering) {
    if (_isRegistering == isRegistering) return;
    FocusScope.of(context).unfocus();
    final email = _emailController.text;
    _formKey.currentState?.reset();
    _emailController.text = email;
    setState(() {
      _isRegistering = isRegistering;
      // メールアドレスは保持し、モード切り替え時にはパスワードを消す。
      _passwordController.clear();
      _obscurePassword = true;
    });
  }

  void _submit() {
    if (!_isRegistering) {
      // 画面遷移の確認を優先し、仮ログインでは入力・認証を要求しない。
      FocusScope.of(context).unfocus();
      widget.onLogin();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _showNotConnectedMessage(
      _isRegistering ? '新規登録' : 'ログイン',
      'Firebase認証が未接続のため、まだ${_isRegistering ? '登録' : 'ログイン'}できません。',
    );
  }

  Future<void> _showNotConnectedMessage(String title, String message) {
    // 登録・再設定はFirebase接続まで未実装であることを案内する。
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 既存の記録入力画面のテーマを変えず、認証画面だけに配色を適用する。
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryContainer,
          primary: _primary,
          surface: Colors.white,
          onSurface: _onSurface,
        ),
        textTheme: theme.textTheme.apply(
          bodyColor: _onSurface,
          displayColor: _onSurface,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTabs(),
                    const SizedBox(height: 32),
                    _buildForm(),
                    const SizedBox(height: 32),
                    _buildInformationCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.favorite, color: _primary, size: 32),
        ),
        const SizedBox(height: 16),
        const Text.rich(
          TextSpan(
            text: '楽ちん報告アプリ',
            children: [
              TextSpan(
                text: ' （仮）',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFF585F67),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            height: 1.33,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '日々の記録を、診察で伝えやすく。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, height: 1.5, color: _onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('ログイン', isRegistering: false),
          _buildTab('新規登録', isRegistering: true),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {required bool isRegistering}) {
    final selected = _isRegistering == isRegistering;
    return Expanded(
      child: Semantics(
        selected: selected,
        child: TextButton(
          key: ValueKey(isRegistering ? 'registerTab' : 'loginTab'),
          onPressed: () => _switchMode(isRegistering),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 44),
            backgroundColor: selected ? _primaryContainer : Colors.transparent,
            foregroundColor: selected ? Colors.white : _onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFieldLabel('メールアドレス'),
            const SizedBox(height: 8),
            Semantics(
              label: 'メールアドレス',
              child: TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('sample@example.com'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                validator: AuthInputValidator.validateEmail,
              ),
            ),
            const SizedBox(height: 24),
            _buildFieldLabel('パスワード'),
            const SizedBox(height: 8),
            Semantics(
              label: 'パスワード',
              child: TextFormField(
                controller: _passwordController,
                decoration: _inputDecoration('••••••••').copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'パスワードを表示' : 'パスワードを隠す',
                    onPressed: () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF585F67),
                      size: 20,
                    ),
                  ),
                ),
                obscureText: _obscurePassword,
                autofillHints: [
                  _isRegistering
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => AuthInputValidator.validatePassword(
                  value,
                  isRegistering: _isRegistering,
                ),
              ),
            ),
            if (_isRegistering) ...[
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: _onSurfaceVariant),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '8文字以上・英字と数字をそれぞれ1文字以上。記号も使えます。',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.43,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              key: const ValueKey('authSubmit'),
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryContainer,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(_isRegistering ? '新規登録' : 'ログイン'),
            ),
            const SizedBox(height: 16),
            if (_isRegistering)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '登録ボタンを押すと確認メールが届きます。\nメール内のリンクをタップして登録を完了してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: _onSurfaceVariant,
                  ),
                ),
              )
            else
              Center(
                child: TextButton(
                  onPressed: () => _showNotConnectedMessage(
                    'パスワードの再設定',
                    'Firebase認証が未接続のため、まだ再設定メールを送信できません。',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    minimumSize: const Size(48, 56),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('パスワードを忘れた方'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE1E8FD),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '必須',
            style: TextStyle(fontSize: 14, color: _primary),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: _surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorMaxLines: 3,
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: _primary, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '診察時の情報共有をスムーズに',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'ご自身で測った日々の数値をまとめて医師へ見せることができます。不要な通知や広告はありません。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.43,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
