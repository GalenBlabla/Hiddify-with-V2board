import 'dart:convert';

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
  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
// 划转佣金的方法
  Future<void> _transferCommission(
      BuildContext context, WidgetRef ref, int transferAmount) async {
    final t = ref.read(translationsProvider);
    final token = await getToken();
    if (token == null) {
      _showSnackbar(context, t.userInfo.noAccessToken);
      return;
    }

    try {
      final success =
          await AuthService().transferCommission(token, transferAmount);
      if (success) {
        _showSnackbar(context, t.transferDialog.transferSuccess); // 提示划转成功
        ref.refresh(userInfoProvider); // 刷新用户信息
      } else {
        _showSnackbar(context, t.transferDialog.transferError); // 提示划转失败
      }
    } catch (e) {
      _showSnackbar(context, "${t.transferDialog.transferError}: $e");
    }
  }
void _showWithdrawDialog(
      BuildContext context, WidgetRef ref, double commissionBalance) {
    final t = ref.watch(translationsProvider); // 获取本地化对象
    final _amountController = TextEditingController(); // 用于接收输入的金额

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.transferDialog.withdrawTitle), // 弹窗标题
          content: Column(
            mainAxisSize: MainAxisSize.min, // 设置列宽度最小化
            children: [
              Text(t.transferDialog.withdrawHint), // 提示信息
              const SizedBox(height: 16), // 间隔
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${t.transferDialog.currentBalance}:'),
                  Text(
                    '${(commissionBalance / 100).toStringAsFixed(2)} ${t.userInfo.currency}', // 当前推广佣金余额
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16), // 间隔
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.transferDialog.withdrawAmount, // 输入金额标签
                  border: const OutlineInputBorder(), // 边框
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭弹窗
              },
              child: Text(t.ensure.cancel), // 取消按钮文本
            ),
            TextButton(
              onPressed: () async {
                final inputAmount = int.tryParse(_amountController.text);
                if (inputAmount != null && inputAmount > 0) {
                  final transferAmount = inputAmount * 100; // 将输入金额转换为表单所需倍数
                  final token = await getToken();
                  // 发送划转请求
                  final success = await AuthService().transferCommission(token!,
                    json.encode({
                      "transfer_amount": transferAmount,
                    }) as int,
                  );
                  if (success) {
                    _showSnackbar(
                        context, t.transferDialog.transferSuccess); // 显示成功消息
                    ref.refresh(userInfoProvider); // 刷新用户信息
                  } else {
                    _showSnackbar(
                        context, t.transferDialog.transferError); // 显示失败消息
                  }
                } else {
                  _showSnackbar(
                      context, t.transferDialog.withdrawError); // 无效输入提示
                }

                Navigator.of(context).pop(); // 关闭弹窗
              },
              child: Text(t.ensure.confirm), // 确认按钮文本
            ),
          ],
        );
      },
    );
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
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户信息卡片
                  _buildUserInfoCard(userInfo, t),

                  const SizedBox(height: 16), // 分隔

                  // 账户余额信息卡片
                  _buildAccountBalanceCard(userInfo, t, context, ref),

                  const SizedBox(height: 16), // 分隔

                  // 邀请码列表卡片
                  _buildInviteCodeSection(context, ref, t),

                  const SizedBox(height: 16), // 分隔

                  // 重置订阅按钮
                  _buildResetSubscriptionButton(context, ref, t),
                ],
              ),
            );
          } else {
            return Center(child: Text(t.userInfo.noData));
          }
        },
      ),
    );
  }

// 构建分区标题
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

// 构建用户信息卡片
  Widget _buildUserInfoCard(UserInfo userInfo, Translations t) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8), // 卡片间距
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(userInfo.avatarUrl),
        ),
        title: Text(userInfo.email), // 用户邮箱
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 水平排列并两端对齐
          children: [
            if (userInfo.planId != null) // 如果套餐ID不为空
              Expanded(
                child: Text(
                  '${t.userInfo.plan}: ${userInfo.planId}', // 套餐信息
                  style: const TextStyle(fontSize: 12), // 字体缩小
                ),
              ),
            Expanded(
              child: Text(
                '${t.userInfo.accountStatus}: ${userInfo.banned ? t.userInfo.banned : t.userInfo.active}', // 账户状态
                style: const TextStyle(fontSize: 12), // 字体缩小
                textAlign: TextAlign.end, // 文本右对齐
              ),
            ),
          ],
        ),
      ),
    );
  }

// 构建账户余额信息卡片
  Widget _buildAccountBalanceCard(
      UserInfo userInfo, Translations t, BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8), // 卡片间距
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4, // 阴影效果
      child: Column(
        children: [
          ListTile(
            leading: const Icon(FluentIcons.wallet_24_filled), // 图标
            title: Text(
                '${t.userInfo.balance} (${t.userInfo.onlyForConsumption})'),
            subtitle: Text(
                '${(userInfo.balance / 100).toStringAsFixed(2)} ${t.userInfo.currency}'), // 余额除以100并保留两位小数
          ),
          Divider(height: 1), // 分隔线
          ListTile(
            leading: const Icon(FluentIcons.gift_card_money_24_filled), // 图标
            title: Text(t.userInfo.commissionBalance),
            subtitle: Text(
                '${(userInfo.commissionBalance / 100).toStringAsFixed(2)} ${t.userInfo.currency}'), // 佣金余额除以100并保留两位小数
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      _showTransferDialog(context, ref, userInfo), // 弹出划转弹窗
                  child: Text(t.transferDialog.transfer), // 本地化“划转”按钮
                ),
                const SizedBox(width: 8), // 按钮间距
                ElevatedButton(
                  onPressed: () =>
                      _showWithdrawDialog(context, ref, userInfo.commissionBalance), // 弹出提现弹窗（实现类似）
                  child: Text(t.transferDialog.withdraw), // 本地化“提现”按钮
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
// 显示划转对话框的方法
  void _showTransferDialog(
      BuildContext context, WidgetRef ref, UserInfo userInfo) {
    final t = ref.read(translationsProvider); // 获取本地化对象
    final _amountController = TextEditingController(); // 控制用户输入的划转金额

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.transferDialog.transferTitle), // 标题“推广佣金划转至余额”
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.transferDialog.transferHint), // 提示“划转后的余额仅用于消费使用”
              const SizedBox(height: 8),
              Text(
                  '${t.transferDialog.currentBalance}: ${(userInfo.commissionBalance / 100).toStringAsFixed(2)} ${t.userInfo.currency}'), // 显示当前佣金余额
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: t.transferDialog.transferAmount), // 标签“划转金额”
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // 取消按钮关闭对话框
              child: Text(t.ensure.cancel), // 本地化“取消”按钮
            ),
            ElevatedButton(
              onPressed: () async {
                final inputAmount = int.tryParse(_amountController.text) ?? 0;
                if (inputAmount > 0) {
                  await _transferCommission(
                      context, ref, inputAmount * 100); // 调用划转请求，并将用户输入的金额乘以100
                }
                Navigator.of(context).pop(); // 划转后关闭对话框
              },
              child: Text(t.ensure.confirm), // 本地化“确认”按钮
            ),
          ],
        );
      },
    );
  }

// 构建邀请码列表部分
  Widget _buildInviteCodeSection(
      BuildContext context, WidgetRef ref, Translations t) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8), // 卡片间距
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4, // 阴影效果
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.inviteCode.inviteCodeListTitle,
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
            const Divider(), // 分隔符
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
          ],
        ),
      ),
    );
  }

// 构建重置订阅按钮
  Widget _buildResetSubscriptionButton(
      BuildContext context, WidgetRef ref, Translations t) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _resetSubscription(context, ref),
        icon: const Icon(FluentIcons.arrow_clockwise_24_filled),
        label: Text(t.userInfo.resetSubscription),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }

}
