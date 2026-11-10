import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, required this.auth});
  final AuthService auth;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _message = widget.auth.verificationError;
  }

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (mounted && success != null) setState(() => _message = success);
    } catch (error) {
      if (mounted) setState(() => _message = authErrorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    await widget.auth.reloadUser();
    if (!widget.auth.isEmailVerified && mounted) {
      setState(() => _message = 'メールアドレスの確認が完了していません。');
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    // 戻る操作でも認証を解除し、別のアカウントでログインできるようにする。
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _run(widget.auth.signOut);
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('メールアドレスの確認'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 56),
                const SizedBox(height: 24),
                Text('${widget.auth.email ?? ''}\nに届いた確認メール内のリンクを開いてください。'),
                const SizedBox(height: 16),
                const Text('確認メールが届かない場合は迷惑メールをご確認のうえ、再送してください。'),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_message!, semanticsLabel: _message),
                  ),
                if (_busy) const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : () => _run(_check),
                  child: const Text('確認が完了しました'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          widget.auth.sendVerificationEmail,
                          success: '確認メールを再送しました。',
                        ),
                  child: const Text('確認メールを再送する'),
                ),
                TextButton(
                  onPressed: _busy ? null : () => _run(widget.auth.signOut),
                  child: const Text('ログイン画面へ戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
