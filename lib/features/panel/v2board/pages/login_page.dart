import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/panel/v2board/service/subscription_service.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../service/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final email = _usernameController.text;
    final password = _passwordController.text;

    try {
      // 使用 AuthService 进行登录请求
      final result = await AuthService().login(email, password);

      // 初始化要查找的字段
      String? authData;
      String? token;

      // 递归遍历 JSON 结构
      void _findAuthData(Map<String, dynamic> json) {
        json.forEach((key, value) {
          if (key == 'auth_data' && value is String) {
            authData = value;
          }
          if (key == 'token' && value is String) {
            token = value;
          }
          if (value is Map<String, dynamic>) {
            _findAuthData(value); // 如果值是一个 Map，则递归调用
          }
        });
      }

      // 开始遍历查找
      _findAuthData(result);

      if (authData != null && token != null) {
        print("Login successful");
        print("Access Token: $authData");

        // 存储令牌
        await storeToken(authData!);
        // 调用重置订阅的逻辑
        await SubscriptionService.updateSubscription(context, ref);
        // 更新 authProvider 状态为已登录
        ref.read(authProvider.notifier).state = true;

        if (mounted) {
          context.go('/');
        }
      } else {
        // 如果 authData 或 token 为空，则显示错误信息
        _showErrorSnackbar(
            context, "Login failed. Invalid authentication data.");
      }
    } catch (e) {
      _showErrorSnackbar(context, "An error occurred during login.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (!mounted) return; // 确保当前 widget 还挂载在树中

    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider); // 获取翻译实例

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 600
                      ? 500
                      : constraints.maxWidth * 0.9,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: t.login.welcome,
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 32 : 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            TextSpan(
                              text: ' ', // 添加一个空格来分隔两段文字
                            ),
                            TextSpan(
                              text: t.general.appTitle,
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 32 : 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center, // 设置文本居中
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: t.login.username,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t.login.username;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: t.login.password,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return t.login.password;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        SizedBox(
                          width: constraints.maxWidth > 600
                              ? 150
                              : constraints.maxWidth * 0.5,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _login(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              t.login.loginButton,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.go('/forget-password');
                            },
                            child: Text(
                              t.login.forgotPassword,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            child: Text(
                              t.login.register,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
