import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/v2board/models/user_info_model.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoCard extends ConsumerWidget {
  const UserInfoCard({super.key});

  Future<UserInfo?> _fetchUserInfo(String accessToken) async {
    return await AuthService().fetchUserInfo(accessToken);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return FutureBuilder<UserInfo?>(
      future: getToken().then((token) {
        if (token == null) {
          return null;
        }
        return _fetchUserInfo(token);
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final userInfo = snapshot.data!;
          return _buildUserInfoCard(userInfo, t);
        } else {
          return const SizedBox(); // 其他情况下返回一个空的占位
        }
      },
    );
  }

  // 构建用户信息卡片
  Widget _buildUserInfoCard(UserInfo userInfo, Translations t) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(userInfo.avatarUrl),
        ),
        title: Text(userInfo.email), // 用户邮箱
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${t.userInfo.plan}: ${userInfo.planId}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                '${t.userInfo.accountStatus}: ${userInfo.banned ? t.userInfo.banned : t.userInfo.active}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
