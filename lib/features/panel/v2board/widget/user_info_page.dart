import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart'; // 用于复制到剪贴板
import 'package:hiddify/features/panel/v2board/common/logout_dialog.dart';
import 'package:hiddify/features/panel/v2board/models/user_info_model.dart';
import 'package:hiddify/features/panel/v2board/models/invite_code_model.dart'; // 引入 InviteCode 模型
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/panel/v2board/service/future_provider.dart';
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

  // 获取邀请码列表的方法
  Future<List<InviteCode>> _fetchInviteCodes(String accessToken) async {
    return await AuthService().fetchInviteCodes(accessToken);
  }
  // 生成邀请码的方法
  Future<void> _generateInviteCode(BuildContext context, WidgetRef ref) async {
    final t = ref.watch(translationsProvider);
    final accessToken = await getToken();
    if (accessToken == null) {
      _showSnackbar(context, t.userInfo.noAccessToken);
      return;
    }

    try {
      final success = await AuthService().generateInviteCode(accessToken);
      if (success) {
        _showSnackbar(context, t.inviteCode.generateInviteCode);
        // 生成邀请码成功后刷新邀请码列表
        ref.refresh(inviteCodesProvider); // 使用 inviteCodesProvider 进行刷新
      } else {
        _showSnackbar(context, t.inviteCode.inviteCodeGenerateError);
      }
    } catch (e) {
      _showSnackbar(context, "${t.inviteCode.inviteCodeGenerateError}: $e");
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
                child:
                    Text('${t.userInfo.fetchUserInfoError} ${snapshot.error}'));
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
                  title: Text(
                      '${t.userInfo.balance} (${t.userInfo.onlyForConsumption})'),
                  subtitle: Text('${userInfo.balance} ${t.userInfo.currency}'),
                ),
                ListTile(
                  title: Text(t.userInfo.commissionBalance),
                  subtitle: Text(
                      '${userInfo.commissionBalance} ${t.userInfo.currency}'),
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
                ListTile(
                  title: Text(t.userInfo.accountStatus),
                  subtitle: Text(
                      userInfo.banned ? t.userInfo.banned : t.userInfo.active),
                ),
                const Divider(), // 分隔符
                // 邀请码列表标题
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t.inviteCode.inviteCodeListTitle, // 邀请码列表标题
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // 调用生成邀请码的逻辑
                          _generateInviteCode(context, ref);
                        },
                        icon: const Icon(FluentIcons.add_24_filled), // 图标
                        label: Text(t.inviteCode.generateInviteCode), // 本地化按钮文本
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                // 显示邀请码列表
                FutureBuilder<List<InviteCode>>(
                  future: getToken().then((token) {
                    if (token == null) {
                      _showSnackbar(context, t.userInfo.noAccessToken);
                      return [];
                    }
                    return _fetchInviteCodes(token);
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                          child: Text(
                              '${t.inviteCode.fetchInviteCodesError} ${snapshot.error}'));
                    } else if (snapshot.hasData && snapshot.data != null) {
                      final inviteCodes = snapshot.data!;
                      if (inviteCodes.isEmpty) {
                        return Center(child: Text(t.inviteCode.noInviteCodes));
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: inviteCodes.length,
                        itemBuilder: (context, index) {
                          final inviteCode = inviteCodes[index];
                          final fullInviteLink =
                              AuthService.getInviteLink(inviteCode.code);
                          return ListTile(
                            title: Text(inviteCode.code),
                            trailing: IconButton(
                              icon: const Icon(FluentIcons.copy_24_regular),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(
                                    text: fullInviteLink)); // 复制完整链接到剪贴板
                                _showSnackbar(context,
                                    '${t.inviteCode.copiedInviteCode} $fullInviteLink'); // 提示已复制链接
                              },
                              tooltip: t.inviteCode.copyToClipboard,
                            ),
                          );
                        },
                      );
                    } else {
                      return Center(child: Text(t.inviteCode.noInviteCodes));
                    }
                  },
                ),
              
                const Divider(), // 分隔符
                // 重置订阅按钮
                ElevatedButton.icon(
                  onPressed: () => _resetSubscription(context, ref),
                  icon: const Icon(FluentIcons.arrow_clockwise_24_filled),
                  label: Text(t.userInfo.resetSubscription),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    backgroundColor: Colors.blue,
                  ),
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
