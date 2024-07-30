import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hiddify/storage/token_storage.dart';
import 'package:html/parser.dart' as html_parser;

class Plan {
  final int id;
  final int groupId;
  final double transferEnable;
  final String name;
  final int speedLimit;
  final bool show;
  final String? content;
  final double? onetimePrice;

  Plan({
    required this.id,
    required this.groupId,
    required this.transferEnable,
    required this.name,
    required this.speedLimit,
    required this.show,
    this.content,
    this.onetimePrice,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // 清理 HTML 标签
    final rawContent = json['content'] ?? '';
    final document = html_parser.parse(rawContent);
    final cleanContent = document.body?.text ?? '';

    return Plan(
      id: json['id'],
      groupId: json['group_id'],
      transferEnable: json['transfer_enable']?.toDouble() ?? 0.0,
      name: json['name'],
      speedLimit: json['speed_limit'],
      show: json['show'] == 1,
      content: cleanContent,
      onetimePrice: json['onetime_price'] != null ? json['onetime_price'] / 100 : null,
    );
  }
}

Future<List<Plan>> fetchPlanData(String accessToken) async {
  final url = Uri.parse("https://clarityvpn.xyz/api/v1/user/plan/fetch");
  final response = await http.get(
    url,
    headers: {'Authorization': accessToken},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data["status"] == "success") {
      return (data["data"] as List)
          .map((json) => Plan.fromJson(json))
          .toList();
    } else {
      print("Failed to retrieve plan data: ${data["message"]}");
      return [];
    }
  } else {
    print("Failed to retrieve plan data: ${response.statusCode}");
    return [];
  }
}

class PurchasePage extends StatelessWidget {
  const PurchasePage({super.key});

  Future<List<Plan>> _fetchPlanDataWithStoredToken() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return [];
    }

    return await fetchPlanData(accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase"),
        leading: IconButton(
          icon: const Icon(FluentIcons.navigation_24_filled),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.shopping_bag_24_filled),
            onPressed: () {
              // 这里可以添加购物袋的功能
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Plan>>(
        future: _fetchPlanDataWithStoredToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final plans = snapshot.data!;
            if (plans.isEmpty) {
              return const Center(child: Text('没有可用的套餐'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          plan.content ?? '无描述',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: 'Price: ¥',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '${plan.onetimePrice ?? '未知'}',
                                    style: const TextStyle(
                                      fontSize: 20, // 更大字体
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red, // 红色数字
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' RMB',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // 在这里添加购买逻辑
                                print('User wants to subscribe to plan: ${plan.name}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Subscribe',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('没有数据'));
          }
        },
      ),
    );
  }
}
