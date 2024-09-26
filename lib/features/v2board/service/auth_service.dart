// 文件路径: lib/features/login/service/auth_service.dart
import 'package:hiddify/features/v2board/models/plan_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class AuthService {
  static const _baseUrl = "https://tomato.galen.life";

  // 统一的 POST 请求方法
  Future<Map<String, dynamic>> _postRequest(
      String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers}) async {
    final url = Uri.parse("$_baseUrl$endpoint");
    final response = await http.post(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Request to $endpoint failed: ${response.statusCode}");
    }
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> _getRequest(String endpoint,
      {Map<String, String>? headers}) async {
    final url = Uri.parse("$_baseUrl$endpoint");
    final response = await http.get(
      url,
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Request to $endpoint failed: ${response.statusCode}");
    }
  }

  // 登录请求
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _postRequest(
      "/api/v1/passport/auth/login",
      {"email": email, "password": password},
    );
  }

  // 注册请求
  Future<Map<String, dynamic>> register(String email, String password,
      String inviteCode, String emailCode) async {
    return await _postRequest(
      "/api/v1/passport/auth/register",
      {
        "email": email,
        "password": password,
        "invite_code": inviteCode,
        "email_code": emailCode,
      },
    );
  }

  // 发送验证码请求
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    final url = Uri.parse("$_baseUrl/api/v1/passport/comm/sendEmailVerify");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'email': email},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          "Failed to send verification code: ${response.statusCode}");
    }
  }

  // 重置密码请求
  Future<Map<String, dynamic>> resetPassword(
      String email, String password, String emailCode) async {
    return await _postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }

  // 获取订阅链接请求
  Future<String?> getSubscriptionLink(String accessToken) async {
    final url = Uri.parse("$_baseUrl/api/v1/user/getSubscribe");
    final response = await http.get(
      url,
      headers: {'Authorization': accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        return data["data"]["subscribe_url"];
      } else {
        throw Exception(
            "Failed to retrieve subscription link: ${data["message"]}");
      }
    } else {
      throw Exception(
          "Failed to retrieve subscription link: ${response.statusCode}");
    }
  }

  // 获取套餐计划数据请求
  Future<List<Plan>> fetchPlanData(String accessToken) async {
    final result = await _getRequest("/api/v1/user/plan/fetch", headers: {
      'Authorization': accessToken,
    });

    if (result["status"] == "success") {
      return (result["data"] as List)
          .map((json) => Plan.fromJson(json))
          .toList();
    } else {
      throw Exception("Failed to retrieve plan data: ${result["message"]}");
    }
  }
  
    // 验证token的方法
  Future<bool> validateToken(String token) async {
    final url = Uri.parse("$_baseUrl/api/v1/user/getSubscribe");
    final response = await http.get(
      url,
      headers: {'Authorization': token},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["status"] == "success";
    } else if (response.statusCode == 401) {
      // 处理 token 过期的情况
      return false;
    } else {
      // 处理其他可能的错误
      return false;
    }
  }
}
