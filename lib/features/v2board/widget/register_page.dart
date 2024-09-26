import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hiddify/features/v2board/service/auth_service.dart'; // 导入 AuthService

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
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar(context, "Please enter your email");
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdownTime = 60;
    });

    try {
      final response = await AuthService().sendVerificationCode(email);

      if (response["status"] == "success") {
        _showSnackbar(context, "Verification code sent to $email");
      } else {
        _showSnackbar(context, response["message"]);
      }
    } catch (e) {
      _showSnackbar(context, "An error occurred: $e");
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
        _showSnackbar(context, "Registration successful");
        context.go('/login'); // 假设登录页面的路由为 /login
      } else {
        _showSnackbar(context, result["message"]);
      }
    } catch (e) {
      _showSnackbar(context, "An error occurred: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
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
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
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
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _inviteCodeController,
                decoration:
                    InputDecoration(labelText: 'Invite Code (optional)'),
              ),
              TextFormField(
                controller: _emailCodeController,
                decoration: InputDecoration(
                  labelText: 'Verification Code',
                  suffixIcon: _isCountingDown
                      ? Text('$_countdownTime s')
                      : TextButton(
                          onPressed: _sendVerificationCode,
                          child: const Text('Send Code'),
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the verification code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _register(context),
                child:
                    _isLoading ? CircularProgressIndicator() : Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
