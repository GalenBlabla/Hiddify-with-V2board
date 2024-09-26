import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hiddify/features/panel/v2board/common/logout_dialog.dart';
import 'package:hiddify/features/panel/v2board/models/user_info_model.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart'; // 引入路由库以便进行页面跳转

import 'package:hiddify/core/localization/translations.dart'; // 本地化支持
import 'package:hiddify/features/panel/v2board/service/auth_provider.dart'; // 引入 authProvider 和 logout 函数

class UserInfoPage extends ConsumerWidget {
  const UserInfoPage({super.key});

  // 获取用户信息的方法
  Future<UserInfo?> _fetchUserInfo(String accessToken) async {
    return await AuthService().fetchUserInfo(accessToken);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider); 

    return Scaffold(
      appBar: AppBar(
        title: Text(t.userInfo.pageTitle), 
        leading: IconButton(
          icon: const Icon(FluentIcons.navigation_24_filled),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.sign_out_24_filled),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const LogoutDialog(),
              );
            },
            tooltip: t.logout.buttonText, 
          ),
        ],
      ),
      body: FutureBuilder<UserInfo?>(
        future: getToken().then((token) {
          if (token == null) {
            _showSnackbar(context, t.userInfo.noAccessToken);
            return null;
          }
          return _fetchUserInfo(token);
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
                    '${t.userInfo.fetchUserInfoError} ${snapshot.error}')); 
          } else if (snapshot.hasData && snapshot.data != null) {
            final userInfo = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(userInfo.avatarUrl),
                  ),
                  title: Text(userInfo.email),
                  subtitle: Text('UUID: ${userInfo.uuid}'),
                ),
                const Divider(),
                ListTile(
                  title: Text(t.userInfo.balance), 
                  subtitle: Text(
                      '${userInfo.balance} ${t.userInfo.currency}'),
                ),
                ListTile(
                  title: Text(t.userInfo.transferEnable), 
                  subtitle: Text(
                      '${(userInfo.transferEnable / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB'),
                ),
                ListTile(
                  title: Text(t.userInfo.plan), 
                  subtitle: Text(userInfo.planId.toString()),
                ),
                if (userInfo.expiredAt != null)
                  ListTile(
                    title: Text(t.userInfo.expiredAt), 
                    subtitle: Text(DateTime.fromMillisecondsSinceEpoch(
                            userInfo.expiredAt! * 1000)
                        .toLocal()
                        .toString()),
                  ),
                ListTile(
                  title: Text(t.userInfo.lastLogin), 
                  subtitle: Text(DateTime.fromMillisecondsSinceEpoch(
                          userInfo.lastLoginAt * 1000)
                      .toLocal()
                      .toString()),
                ),
              ],
            );
          } else {
            return Center(child: Text(t.userInfo.noData));
          }
        },
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
