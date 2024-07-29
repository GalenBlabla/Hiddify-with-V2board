import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = StateProvider<bool>((ref) {
  // 初始为未登录状态
  return false;
});
