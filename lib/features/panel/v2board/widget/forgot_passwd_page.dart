import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/core/localization/translations.dart'; // 导入本地化支持

class ForgetPasswordPage extends ConsumerStatefulWidget {
  const ForgetPasswordPage({Key? key}) : super(key: key);

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

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3), // 自动消失时间
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _sendVerificationCode() async {
    final t = ref.watch(translationsProvider); // 获取翻译实例
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar(context, t.forgetPassword.emailEmptyError);
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdownTime = 60;
    });

    try {
      final result = await AuthService().sendVerificationCode(email);

      if (result["status"] == "success") {
        _showSnackbar(context, "${t.forgetPassword.codeSentSuccess} $email");
      } else {
        _showSnackbar(context, result["message"]);
      }
    } catch (e) {
      _showSnackbar(context, "${t.forgetPassword.errorOccurred} $e");
    }

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
    final t = ref.watch(translationsProvider); // 获取翻译实例
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
      final result =
          await AuthService().resetPassword(email, password, emailCode);

      if (result["status"] == "success") {
        _showSnackbar(context, t.forgetPassword.resetSuccess);
        context.go('/login');
      } else {
        _showSnackbar(
            context, result["message"] ?? t.forgetPassword.passwordResetError);
      }
    } catch (e) {
      _showSnackbar(context, "${t.forgetPassword.errorOccurred} $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider); // 获取翻译实例

    return Scaffold(
      appBar: AppBar(
        title: Text(t.forgetPassword.pageTitle), // 使用本地化的页面标题
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/login'); // 返回登录页面
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
                decoration: InputDecoration(
                    labelText: t.forgetPassword.email), // 使用本地化标签
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.forgetPassword.emailEmptyError; // 使用本地化错误信息
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: t.forgetPassword.newPassword, // 使用本地化标签
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
                    return t.forgetPassword.passwordEmptyError; // 使用本地化错误信息
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _emailCodeController,
                decoration: InputDecoration(
                  labelText: t.forgetPassword.verificationCode, // 使用本地化标签
                  suffixIcon: _isCountingDown
                      ? Text('$_countdownTime s')
                      : TextButton(
                          onPressed: _sendVerificationCode,
                          child: Text(t.forgetPassword.sendCode), // 使用本地化文本
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t
                        .forgetPassword.verificationCodeEmptyError; // 使用本地化错误信息
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _resetPassword(context),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(t.forgetPassword.resetPassword), // 使用本地化文本
              ),
            ],
          ),
        ),
      ),
    );
  }
}
