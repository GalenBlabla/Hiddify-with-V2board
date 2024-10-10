import 'package:hiddify/features/panel/v2board/models/invite_code_model.dart';
import 'package:hiddify/features/panel/v2board/models/order_model.dart';
import 'package:hiddify/features/panel/v2board/models/plan_model.dart';
import 'package:hiddify/features/panel/v2board/models/user_info_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const _baseUrl = "https://abcd168.icu";
  static const _inviteLinkBase = "$_baseUrl/#/register?code=";

  // 获取完整邀请码链接的方法
  static String getInviteLink(String code) {
    return '$_inviteLinkBase$code';
  }

  // 统一的 POST 请求方法
  Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse("$_baseUrl$endpoint");

    try {
      final response = await http.post(
        url,
        headers: headers ?? {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      print("$endpoint response.body${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
            "Post to $endpoint failed: ${response.statusCode}, ${response.body},");
      }
    } catch (e) {
      rethrow;
    }
  }

  // 统一的 GET 请求方法
  Future<Map<String, dynamic>> _getRequest(String endpoint,
      {Map<String, String>? headers}) async {
    final url = Uri.parse("$_baseUrl$endpoint");

    try {
      final response = await http.get(
        url,
        headers: headers,
      );
      print("$endpoint response.body${response.body}");
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          "get to $endpoint failed: ${response.statusCode}, ${response.body}",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

// 支付回调
  Future<dynamic> getOrderDetails(String tradeNo, String accessToken) async {
    final endpoint = "/api/v1/user/order/detail?trade_no=$tradeNo";
    return await _getRequest(endpoint, headers: {
      'Authorization': accessToken,
      'Content-Type': 'application/json'
    });
  }

  // 取消订单的方法
  Future<Map<String, dynamic>> cancelOrder(
      String tradeNo, String accessToken) async {
    const endpoint = "/api/v1/user/order/cancel";
    final body = {"trade_no": tradeNo};

    return await _postRequest(
      endpoint,
      body,
      headers: {
        'Authorization': accessToken,
        'Content-Type': 'application/json',
      },
    );
  }

  // 获取用户订单数据
  Future<List<Order>> fetchUserOrders(String accessToken) async {
    final result = await _getRequest(
      "/api/v1/user/order/fetch",
      headers: {
        'Authorization': accessToken,
      },
    );

    if (result["status"] == "success") {
      final ordersJson = result["data"] as List;
      return ordersJson
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Failed to fetch user orders: ${result['message']}");
    }
  }

// 提交订单，获取支付链接的方法
  Future<String?> submitOrder(
      String tradeNo, String method, String accessToken) async {
    const endpoint = "/api/v1/user/order/checkout";
    final body = {"trade_no": tradeNo, "method": method};

    final response = await _postRequest(
      endpoint,
      body,
      headers: {
        'Authorization': accessToken,
      },
    );
    print(response);
    print(body);
    if (response.containsKey("data")) {
      final data = response["data"];
      if (data is String) {
        return data; // 返回支付链接字符串
      }
    }
    return null;
  }

  // 提交订单的方法
  Future<Map<String, dynamic>> createOrder(
      String accessToken, int planId, String period) async {
    const endpoint = "/api/v1/user/order/save";
    final body = {"plan_id": planId, "period": period};
    return await _postRequest(
      endpoint,
      body,
      headers: {
        'Authorization': accessToken,
      },
    );
  }

  // 获取支付方式的方法
  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    const endpoint = "/api/v1/user/order/getPaymentMethod";
    final response = await _getRequest(
      endpoint,
      headers: {
        'Authorization': accessToken,
      },
    );
    return (response['data'] as List).cast<dynamic>();
  }

  // 划转佣金到余额的方法
  Future<bool> transferCommission(
    String accessToken,
    int transferAmount,
  ) async {
    await _postRequest(
      '/api/v1/user/transfer',
      {'transfer_amount': transferAmount},
      headers: {'Authorization': accessToken}, // 需要用户的认证令牌
    );
    return true;
  }

  // 生成邀请码的方法
  Future<bool> generateInviteCode(String accessToken) async {
    await _getRequest(
      "/api/v1/user/invite/save",
      headers: {
        'Authorization': accessToken,
      },
    );
    return true;
  }

  // 获取邀请码数据
  Future<List<InviteCode>> fetchInviteCodes(String accessToken) async {
    final result = await _getRequest(
      "/api/v1/user/invite/fetch",
      headers: {
        'Authorization': accessToken,
      },
    );
    return (result["data"]["codes"] as List)
        .cast<Map<String, dynamic>>()
        .map((json) => InviteCode.fromJson(json))
        .toList();
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
    const endpoint = "/api/v1/passport/comm/sendEmailVerify";
    final body = {'email': email};
    return await _postRequest(endpoint, body);
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
    final result = await _getRequest(
      "/api/v1/user/getSubscribe",
      headers: {
        'Authorization': accessToken,
      },
    );
    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is Map<String, dynamic> && data.containsKey("subscribe_url")) {
        return data["subscribe_url"] as String?;
      }
    }

    // 返回 null 或抛出异常，如果数据结构不匹配
    throw Exception("Failed to retrieve subscription link");
  }

  // 获取套餐计划数据请求
  Future<List<Plan>> fetchPlanData(String accessToken) async {
    final result = await _getRequest(
      "/api/v1/user/plan/fetch",
      headers: {
        'Authorization': accessToken,
      },
    );
    return (result["data"] as List)
        .cast<Map<String, dynamic>>()
        .map((json) => Plan.fromJson(json))
        .toList();
  }

  // 验证token的方法
  Future<bool> validateToken(String token) async {
    try {
      final response = await _getRequest(
        "/api/v1/user/getSubscribe",
        headers: {
          'Authorization': token,
        },
      );
      // 检查响应状态和数据是否表示token有效
      if (response['status'] == 'success') {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // 请求失败或其他异常，视为token无效
      return false;
    }
  }

// 获取用户信息
  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    final result = await _getRequest(
      "/api/v1/user/info",
      headers: {
        'Authorization': accessToken,
      },
    );
    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is Map<String, dynamic>) {
        return UserInfo.fromJson(data);
      }
    }
    throw Exception("Failed to retrieve user info");
  }

// 重置订阅链接的方法
  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _getRequest(
      "/api/v1/user/resetSecurity",
      headers: {
        'Authorization': accessToken,
      },
    );
    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is String) {
        return data; // 如果 'data' 是字符串，直接返回
      }
    }
    throw Exception("Failed to reset subscription link");
  }
}
