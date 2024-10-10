import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/v2board/models/plan_model.dart';
import 'package:hiddify/features/panel/v2board/pages/order_page.dart';
import 'package:hiddify/features/panel/v2board/pages/purchase_details_page.dart';
import 'package:hiddify/features/panel/v2board/service/purchase_service.dart';
import 'package:hiddify/features/panel/v2board/widget/price_widget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PurchasePage extends ConsumerWidget {
  const PurchasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.purchase.pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 跳转到订单管理页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderPage(),
                ),
              );
            },
            child: const Text(
              '订单管理', // 订单文字
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Plan>>(
        future: PurchaseService().fetchPlanData(),
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
                        _buildUniformStyledContent(
                            plan.content ?? t.purchase.noData),
                        const SizedBox(height: 8),
                        PriceWidget(
                          plan: plan,
                          priceLabel: t.purchase.priceLabel,
                          currency: t.purchase.rmb,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
showPurchaseDialog(context, plan, t, ref);
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

  // 将内容按行解析并统一应用样式
  Widget _buildUniformStyledContent(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              const Icon(
                FluentIcons.checkmark_circle_24_filled, // 可以根据需求更换图标
                color: Colors.blue, // 图标颜色
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  line.trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87, // 统一的字体颜色
                    height: 1.5, // 设置统一的行高
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
