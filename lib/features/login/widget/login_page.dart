import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart';
import 'package:hiddify/storage/token_storage.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_notifier.dart';

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
      // 清理之前的订阅信息
      await _clearSubscriptionData();
      final url =
          Uri.parse("https://tomato.galen.life/api/v1/passport/auth/login");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "success") {
          final authData = data["data"]["auth_data"];
          print("Login successful");
          print("Access Token: $authData");

          // 存储令牌
          await storeToken(authData);
          // 添加订阅信息并更新活动配置文件
          await _addSubscription(authData);

          // 更新 authProvider 状态为已登录
          ref.read(authProvider.notifier).state = true;

          // 打印日志，确认执行到这里
          print("Navigation to HomePage");

          // 跳转到首页
          if (mounted) {
            print("Trying to navigate to HomePage");
            context.go('/');
            print("Navigated to HomePage");
          }
        } else {
          _showErrorSnackbar(context, data["message"]);
        }
      } else {
        _showErrorSnackbar(
            context, "An error occurred: ${response.statusCode}");
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
      // 获取订阅链接
      final subscriptionLink = await _getSubscriptionLink(accessToken);
      if (subscriptionLink == null) return;

      print("Adding subscription link: $subscriptionLink");

      // 调用 AddProfile 提供者来添加订阅链接
      await ref.read(addProfileProvider.notifier).add(subscriptionLink);

      // 获取新添加的配置文件并设置为活动配置文件
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

  Future<String?> _getSubscriptionLink(String accessToken) async {
    final url = Uri.parse("https://tomato.galen.life/api/v1/user/getSubscribe");
    final response = await http.get(
      url,
      headers: {'Authorization': accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        print("Subscription link retrieved successfully");
        return data["data"]["subscribe_url"];
      } else {
        print("Failed to retrieve subscription link: ${data["message"]}");
        return null;
      }
    } else {
      print("Failed to retrieve subscription link: ${response.statusCode}");
      return null;
    }
  }

  Future<void> _clearSubscriptionData() async {
    // 获取 ProfileRepository 的实例
    final profileRepository = ref.read(profileRepositoryProvider).requireValue;

    // 获取所有订阅信息
    final profilesResult = await profileRepository.watchAll().first;

    // 遍历所有订阅并删除
    profilesResult.fold(
      (failure) {
        // 处理获取订阅失败的情况
        print('Error retrieving profiles: $failure');
      },
      (profiles) async {
        for (final profile in profiles) {
          await profileRepository.deleteById(profile.id).run();
        }
      },
    );

    // 清空活动配置文件
    ref.read(activeProfileProvider.notifier).update((state) => null);
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
                      Text(
                        'Welcome to Hiddify VPN',
                        style: TextStyle(
                          fontSize: constraints.maxWidth > 600 ? 32 : 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center, // 文字居中
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        SizedBox(
                          width: constraints.maxWidth > 600 ? 150 : constraints.maxWidth * 0.5, // 缩减 Login 按钮宽度
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
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Forgot Password? 和 Register 按钮水平对齐在一行
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              context.go('/forget-password');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/register'); // 跳转到注册页面
                            },
                            child: Text(
                              'Register',
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
