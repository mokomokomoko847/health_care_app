import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/auth_input_validator.dart';
import '../services/auth_service.dart';

/// コードなしではメール送信、コードありではリンク検証後の再設定を担当する。
class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({
    super.key,
    required this.auth,
    this.code,
    this.initialEmail = '',
  });
  final AuthService auth;
  final String? code;
  final String initialEmail;

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _password = TextEditingController();
  bool _busy = false;
  bool _validCode = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) _verifyCode();
  }

  Future<void> _verifyCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final email = await widget.auth.verifyPasswordResetCode(widget.code!);
      if (mounted) {
        setState(() {
          _email.text = email;
          _validCode = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.code == null) {
        await widget.auth.sendPasswordResetEmail(_email.text.trim());
      } else {
        if (!_validCode) return;
        await widget.auth.confirmPasswordReset(widget.code!, _password.text);
        _password.clear();
      }
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('パスワードの再設定'),
      leading: BackButton(onPressed: _busy ? null : () => context.go('/login')),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_done) ...[
                  Text(
                    widget.code == null
                        ? '登録済みのメールアドレスの場合、再設定メールが届きます。メール内のリンクを開いてください。'
                        : 'パスワードを再設定しました。新しいパスワードでログインしてください。',
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('ログイン画面へ戻る'),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _email,
                    enabled: !_busy && widget.code == null,
                    decoration: const InputDecoration(labelText: 'メールアドレス'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    validator: AuthInputValidator.validateEmail,
                  ),
                  if (widget.code != null && _validCode) ...[
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _password,
                      enabled: !_busy,
                      decoration: const InputDecoration(labelText: '新しいパスワード'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      autocorrect: false,
                      enableSuggestions: false,
                      validator: (value) => AuthInputValidator.validatePassword(
                        value,
                        isRegistering: true,
                      ),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const Text('8文字以上・英字と数字をそれぞれ1文字以上。'),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_busy) const Center(child: CircularProgressIndicator()),
                  if (widget.code == null || _validCode)
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        widget.code == null ? '再設定メールを送信' : 'パスワードを再設定',
                      ),
                    )
                  else if (!_busy)
                    TextButton(
                      onPressed: _verifyCode,
                      child: const Text('リンクを再確認'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// カスタムメールリンクでメール確認を完了する画面。
class EmailActionPage extends StatefulWidget {
  const EmailActionPage({super.key, required this.auth, required this.code});
  final AuthService auth;
  final String code;

  @override
  State<EmailActionPage> createState() => _EmailActionPageState();
}

class _EmailActionPageState extends State<EmailActionPage> {
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apply();
  }

  Future<void> _apply() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.applyEmailVerificationCode(widget.code);
    } catch (error) {
      if (mounted) setState(() => _error = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('メールアドレスの確認')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              const CircularProgressIndicator()
            else ...[
              Text(_error ?? 'メールアドレスを確認しました。'),
              if (_error != null)
                TextButton(onPressed: _apply, child: const Text('再試行')),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('アプリへ戻る'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
