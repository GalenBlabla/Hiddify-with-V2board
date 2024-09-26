import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/panel/v2board/models/invite_code_model.dart';

// 创建一个 FutureProvider 来管理邀请码列表
final inviteCodesProvider = FutureProvider<List<InviteCode>>((ref) async {
  final accessToken = await getToken(); // 从存储中获取 accessToken
  if (accessToken == null) {
    throw Exception('No access token found.');
  }
  return AuthService().fetchInviteCodes(accessToken);
});
