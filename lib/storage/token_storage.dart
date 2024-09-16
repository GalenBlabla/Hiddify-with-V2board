// lib/storage/token_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // 添加这个导入
import 'dart:convert'; // 添加这个导入

Future<void> storeToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
}

Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('auth_token');
}

Future<void> deleteToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}

// 验证token的方法定义
Future<bool> validateToken(String token) async {
  final url = Uri.parse("https://tomato.galen.life/api/v1/user/getSubscribe");
  final response = await http.get(
    url,
    headers: {'Authorization': token},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    print(data);
    return data["status"] == "success";
  } else if (response.statusCode == 401) {
    // 处理 token 过期的情况
    return false;
  } else {
    // 处理其他可能的错误
    return false;
  }
}
