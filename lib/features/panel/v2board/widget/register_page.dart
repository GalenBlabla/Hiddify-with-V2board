import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/core/localization/translations.dart';
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
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _sendVerificationCode() async {
    final t = ref.watch(translationsProvider); 
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackbar(context, t.register.emailEmptyError); 
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
            context, "${t.register.codeSentSuccess} $email"); 
      } else {
        _showSnackbar(context, response["message"]);
      }
    } catch (e) {
      _showSnackbar(context, "${t.register.errorOccurred} $e");
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
    final t = ref.watch(translationsProvider); 
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
        _showSnackbar(context, t.register.registrationSuccess); 
        context.go('/login'); 
      } else {
        _showSnackbar(context, result["message"]);
      }
    } catch (e) {
      _showSnackbar(context, "${t.register.errorOccurred} $e");
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
        title: Text(t.register.pageTitle),
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
                decoration: InputDecoration(
                  labelText: t.register.email,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.register.emailEmptyError; 
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: t.register.password, 
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
                    return t.register.passwordEmptyError; 
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _inviteCodeController,
                decoration: InputDecoration(
                  labelText: t.register.inviteCode, 
                ),
              ),
              TextFormField(
                controller: _emailCodeController,
                decoration: InputDecoration(
                  labelText: t.register.verificationCode, 
                  suffixIcon: _isCountingDown
                      ? Text('$_countdownTime s')
                      : TextButton(
                          onPressed: _sendVerificationCode,
                          child: Text(t.register.sendCode), 
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return t.register.verificationCodeEmptyError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _register(context),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(t.register.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
