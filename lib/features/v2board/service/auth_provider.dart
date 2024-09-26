import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/v2board/storage/token_storage.dart';

final authProvider = StateProvider<bool>((ref) {
  // 初始为未登录状态
  return false;
});
// 定义一个登出函数
Future<void> logout(BuildContext context, WidgetRef ref) async {
  // 清除存储的 token
  await deleteToken();
  // 更新 authProvider 状态为未登录
  ref.read(authProvider.notifier).state = false;
  // 跳转到登录页面
  context.go('/login');
}