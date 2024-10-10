import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ForgetPasswordPage extends ConsumerStatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  _ForgetPasswordPageState createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends ConsumerState<ForgetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isCountingDown = false;
  int _countdownTime = 60; // 倒计时时间（秒）
  bool _obscurePassword = true; // 控制密码框的可见性

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    final email = _emailController.text.trim();

    setState(() {
      _isCountingDown = true;
      _countdownTime = 60;
    });

    await AuthService().sendVerificationCode(email);

    // 倒计时逻辑
    while (_countdownTime > 0) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _countdownTime--;
      });
    }

    setState(() {
      _isCountingDown = false;
    });
  }

  Future<void> _resetPassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final emailCode = _emailCodeController.text.trim();

    try {
      await AuthService().resetPassword(email, password, emailCode);
      context.go('/login');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.forgetPassword.pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/login');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: t.forgetPassword.email),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.forgetPassword.emailEmptyError;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: t.forgetPassword.newPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.forgetPassword.passwordEmptyError;
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailCodeController,
                decoration: InputDecoration(
                  labelText: t.forgetPassword.verificationCode,
                  suffixIcon: _isCountingDown
                      ? Text('$_countdownTime s')
                      : TextButton(
                          onPressed: _sendVerificationCode,
                          child: Text(t.forgetPassword.sendCode),
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.forgetPassword.verificationCodeEmptyError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _resetPassword(context),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(t.forgetPassword.resetPassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
