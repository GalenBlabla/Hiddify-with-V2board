import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/v2board/service/auth_service.dart';
import 'package:hiddify/core/localization/translations.dart'; // 导入本地化支持

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _emailCodeController = TextEditingController();
  bool _isLoading = false;
  bool _isCountingDown = false;
  int _countdownTime = 60; // 倒计时时间（秒）
  bool _obscurePassword = true; // 控制密码框的可见性

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _inviteCodeController.dispose();
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
    final t = ref.watch(translationsProvider); // 获取本地化对象
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar(context, t.register.emailEmptyError); // 使用本地化错误信息
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdownTime = 60;
    });

    try {
      final response = await AuthService().sendVerificationCode(email);

      if (response["status"] == "success") {
        _showSnackbar(
            context, "${t.register.codeSentSuccess} $email"); // 使用本地化信息
      } else {
        _showSnackbar(context, response["message"]);
      }
    } catch (e) {
      _showSnackbar(context, "${t.register.errorOccurred} $e"); // 使用本地化错误信息
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

  Future<void> _register(BuildContext context) async {
    final t = ref.watch(translationsProvider); // 获取本地化对象
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final inviteCode = _inviteCodeController.text.trim();
    final emailCode = _emailCodeController.text.trim();

    try {
      final result =
          await AuthService().register(email, password, inviteCode, emailCode);

      if (result["status"] == "success") {
        _showSnackbar(context, t.register.registrationSuccess); // 使用本地化信息
        context.go('/login'); // 假设登录页面的路由为 /login
      } else {
        _showSnackbar(context, result["message"]);
      }
    } catch (e) {
      _showSnackbar(context, "${t.register.errorOccurred} $e"); // 使用本地化错误信息
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider); // 获取本地化对象
    return Scaffold(
      appBar: AppBar(
        title: Text(t.register.pageTitle), // 使用本地化的页面标题
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
                  labelText: t.register.email, // 使用本地化标签
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.register.emailEmptyError; // 使用本地化错误信息
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: t.register.password, // 使用本地化标签
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.register.passwordEmptyError; // 使用本地化错误信息
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _inviteCodeController,
                decoration: InputDecoration(
                  labelText: t.register.inviteCode, // 使用本地化标签
                ),
              ),
              TextFormField(
                controller: _emailCodeController,
                decoration: InputDecoration(
                  labelText: t.register.verificationCode, // 使用本地化标签
                  suffixIcon: _isCountingDown
                      ? Text('$_countdownTime s')
                      : TextButton(
                          onPressed: _sendVerificationCode,
                          child: Text(t.register.sendCode), // 使用本地化文本
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.register.verificationCodeEmptyError; // 使用本地化错误信息
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _register(context),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(t.register.register), // 使用本地化文本
              ),
            ],
          ),
        ),
      ),
    );
  }
}
