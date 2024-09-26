import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hiddify/features/v2board/models/plan_model.dart';
import 'package:hiddify/features/v2board/storage/token_storage.dart';
import 'package:hiddify/features/v2board/service/auth_service.dart';


class PurchasePage extends StatelessWidget {
  const PurchasePage({super.key});

  // 通过存储的令牌获取套餐数据
  Future<List<Plan>> _fetchPlanDataWithStoredToken() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return [];
    }

    return await AuthService().fetchPlanData(accessToken);
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
                                print(
                                    'User wants to subscribe to plan: ${plan.name}');
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
