import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:hiddify/features/panel/v2board/models/plan_model.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/core/localization/translations.dart'; 

class PurchasePage extends ConsumerWidget {
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

  // 添加新订阅到配置文件的方法
  Future<void> _addSubscription(
      BuildContext context, String accessToken, WidgetRef ref) async {
    try {
      // 获取订阅链接
      final subscriptionLink =
          await AuthService().getSubscriptionLink(accessToken);
      if (subscriptionLink == null) {
        _showSnackbar(context, '无法获取订阅链接');
        return;
      }

      // 打印订阅链接
      print("Adding subscription link: $subscriptionLink");

      // 添加新的订阅链接到配置文件
      await ref.read(addProfileProvider.notifier).add(subscriptionLink);

      // 获取新添加的配置文件并设置为活动配置文件
      final profileRepository =
          await ref.read(profileRepositoryProvider.future);
      final profilesResult = await profileRepository.watchAll().first;
      final profiles = profilesResult.getOrElse((_) => []);
      final newProfile = profiles.firstWhere(
        (profile) =>
            profile is RemoteProfileEntity && profile.url == subscriptionLink,
        orElse: () {
          if (profiles.isNotEmpty) {
            return profiles[0];
          } else {
            throw Exception("No profiles available");
          }
        },
      );

      // 更新活跃配置文件状态
      ref.read(activeProfileProvider.notifier).update((_) => newProfile);

      // 显示成功的提示信息
      _showSnackbar(context, '成功添加订阅并设置为活动配置文件！');
    } catch (e) {
      print(e);
      _showSnackbar(context, "添加订阅时发生错误: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.purchase.pageTitle),
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
                child: Text('${t.purchase.fetchPlansError} ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final plans = snapshot.data!;
            if (plans.isEmpty) {
              return Center(child: Text(t.purchase.noPlans));
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
                          plan.content ?? t.purchase.noData,
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
                                    text: t.purchase.priceLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        '${plan.onetimePrice ?? t.purchase.noData}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' ${t.purchase.rmb}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                // 获取存储的 AccessToken
                                final accessToken = await getToken();
                                if (accessToken == null) {
                                  _showSnackbar(context, '无法获取访问令牌，请重新登录');
                                  return;
                                }

                                // 支付成功后添加订阅信息
                                await _addSubscription(
                                    context, accessToken, ref);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                t.purchase.subscribe,
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
            return Center(child: Text(t.purchase.noData));
          }
        },
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
