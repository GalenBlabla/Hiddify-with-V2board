// subscription_utils.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'plan.dart';
import 'dart:convert';

// 订阅处理逻辑
Future<void> subscribeToPlan(BuildContext context, int planId) async {
  final url = Uri.parse("https://clarityvpn.xyz/api/v1/user/plan/fetch?id=$planId");
  
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        // 处理订阅成功的逻辑
        print("Subscription successful: ${data["data"]}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription successful!')),
        );
      } else {
        // 处理失败逻辑
        print("Subscription failed: ${data["message"]}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription failed: ${data["message"]}')),
        );
      }
    } else {
      print("Failed to subscribe: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to subscribe: ${response.statusCode}')),
      );
    }
  } catch (e) {
    print("Error during subscription: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error during subscription: $e')),
    );
  }
}

// 显示订阅确认对话框
void showSubscribeDialog(BuildContext context, Plan plan) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Subscribe to ${plan.name}'),
        content: Text('Do you want to subscribe to this plan?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Subscribe'),
            onPressed: () {
              subscribeToPlan(context, plan.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
