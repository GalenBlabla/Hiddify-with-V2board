import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hiddify/features/panel/v2board/models/plan_model.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart'; // 引入 Riverpod 库
import 'package:hiddify/core/localization/translations.dart'; // 引入本地化支持

class PurchasePage extends ConsumerWidget {
  // 改为 ConsumerWidget
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
  Widget build(BuildContext context, WidgetRef ref) {
    // 添加 WidgetRef 参数
    final t = ref.watch(translationsProvider); // 获取本地化对象

    return Scaffold(
      appBar: AppBar(
        title: Text(t.purchase.pageTitle), // 使用本地化页面标题
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
            return Center(
                child: Text(
                    '${t.purchase.fetchPlansError} ${snapshot.error}')); // 使用本地化错误信息
          } else if (snapshot.hasData && snapshot.data != null) {
            final plans = snapshot.data!;
            if (plans.isEmpty) {
              return Center(child: Text(t.purchase.noPlans)); // 使用本地化无套餐信息
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
                          plan.content ?? t.purchase.noData, // 使用本地化无描述信息
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: t.purchase.priceLabel, // 使用本地化价格标签
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${plan.onetimePrice ?? t.purchase.noData}', // 使用本地化无数据信息
                                    style: const TextStyle(
                                      fontSize: 20, // 更大字体
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red, // 红色数字
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${t.purchase.rmb}', // 使用本地化人民币标签
                                    style: const TextStyle(
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
                                _showSnackbar(context,
                                    "${t.purchase.subscribeSuccess} ${plan.name}"); // 使用本地化成功信息
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                t.purchase.subscribe, // 使用本地化订阅按钮文本
                                style: const TextStyle(color: Colors.white),
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
            return Center(child: Text(t.purchase.noData)); // 使用本地化无数据信息
          }
        },
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3), // 自动消失时间
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
