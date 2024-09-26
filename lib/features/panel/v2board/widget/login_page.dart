import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart'; 
import '../service/auth_provider.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';

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

      if (result["status"] == "success") {
        final authData = result["data"]["auth_data"];
        print("Login successful");
        print("Access Token: $authData");

        // 存储令牌
        await storeToken(authData);
        // 添加订阅信息并更新活动配置文件
        await _addSubscription(authData);

        // 更新 authProvider 状态为已登录
        ref.read(authProvider.notifier).state = true;

        if (mounted) {
          context.go('/');
        }
      } else {
        _showErrorSnackbar(context, result["message"]);
      }
    } catch (e) {
      print(e);
      _showErrorSnackbar(context, "An error occurred during login.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addSubscription(String accessToken) async {
    try {
      final subscriptionLink =
          await AuthService().getSubscriptionLink(accessToken);
      if (subscriptionLink == null) return;

      print("Adding subscription link: $subscriptionLink");

      await ref.read(addProfileProvider.notifier).add(subscriptionLink);

      final profileRepository =
          await ref.read(profileRepositoryProvider.future);
      final profilesResult = await profileRepository.watchAll().first;
      final profiles = profilesResult.getOrElse((_) => []);
      final newProfile = profiles.firstWhere(
        (profile) =>
            profile is RemoteProfileEntity && profile.url == subscriptionLink,
        orElse: () {
          if (profiles.isNotEmpty) {
            return profiles[0];
          } else {
            throw Exception("No profiles available");
          }
        },
      );

      ref.read(activeProfileProvider.notifier).update((_) => newProfile);
    } catch (e) {
      print(e);
      _showErrorSnackbar(
          context, "An error occurred while adding the subscription.");
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
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
