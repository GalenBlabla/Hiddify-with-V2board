import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hiddify/features/panel/v2board/common/logout_dialog.dart';
import 'package:hiddify/features/panel/v2board/models/user_info_model.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/features/profile/overview/profiles_overview_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import 'package:hiddify/core/localization/translations.dart'; 
import 'package:hiddify/features/panel/v2board/service/auth_provider.dart'; 


class UserInfoPage extends ConsumerWidget {
  const UserInfoPage({super.key});

  // 获取用户信息的方法
  Future<UserInfo?> _fetchUserInfo(String accessToken) async {
    return await AuthService().fetchUserInfo(accessToken);
  }

  // 重置订阅链接的方法
  Future<void> _resetSubscription(BuildContext context, WidgetRef ref) async {
    final t = ref.watch(translationsProvider); 
    final accessToken = await getToken();
    if (accessToken == null) {
      _showSnackbar(context, t.userInfo.noAccessToken);
      return;
    }

    try {
      // 获取新的订阅链接
      final newSubscriptionLink =
          await AuthService().resetSubscriptionLink(accessToken);
      if (newSubscriptionLink != null) {
        // 删除旧的订阅配置
        final profileRepository =
            await ref.read(profileRepositoryProvider.future);
        final profilesResult = await profileRepository.watchAll().first;
        final profiles = profilesResult.getOrElse((_) => []);
        for (final profile in profiles) {
          if (profile is RemoteProfileEntity) {
            await ref
                .read(profilesOverviewNotifierProvider.notifier)
                .deleteProfile(profile);
          }
        }

        // 添加新的订阅链接
        await ref.read(addProfileProvider.notifier).add(newSubscriptionLink);

        // 获取新添加的配置文件并设置为活动配置文件
        final newProfilesResult = await profileRepository.watchAll().first;
        final newProfiles = newProfilesResult.getOrElse((_) => []);
        final newProfile = newProfiles.firstWhere(
          (profile) =>
              profile is RemoteProfileEntity &&
              profile.url == newSubscriptionLink,
          orElse: () {
            if (newProfiles.isNotEmpty) {
              return newProfiles[0];
            } else {
              throw Exception("No profiles available");
            }
          },
        );

        // 更新活跃配置文件状态
        ref.read(activeProfileProvider.notifier).update((_) => newProfile);

        // 显示成功提示
        _showSnackbar(context, t.userInfo.subscriptionResetSuccess);
      }
    } catch (e) {
      _showSnackbar(context, "${t.userInfo.subscriptionResetError} $e");
    }
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
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const LogoutDialog(), 
            ),
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
                  title: Text(t.userInfo.lastLogin), // 本地化最后登录标签
                  subtitle: Text(DateTime.fromMillisecondsSinceEpoch(
                          userInfo.lastLoginAt * 1000)
                      .toLocal()
                      .toString()),
                ),
                const Divider(), // 分隔符
                // 重置订阅按钮
                ElevatedButton.icon(
                  onPressed: () => _resetSubscription(context, ref), 
                  icon: const Icon(
                      FluentIcons.arrow_clockwise_24_filled), 
                  label: Text(t.userInfo.resetSubscription), //
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text(t.userInfo.noData)); // 显示无数据的提示
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
