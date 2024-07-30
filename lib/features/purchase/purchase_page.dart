import 'package:flutter/material.dart';
import 'plan.dart';
import 'plan_repository.dart';
import 'plan_card.dart';

import 'package:hiddify/storage/token_storage.dart';
class PurchasePage extends StatelessWidget {
  const PurchasePage({super.key});

  Future<List<Plan>> _fetchPlanDataWithStoredToken() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return [];
    }

    final plans = await fetchPlanData(accessToken);
    if (plans.isNotEmpty) {
      await savePlansToLocal(plans);
    }
    return plans;
  }

  Future<List<Plan>> _loadPlans() async {
    final localPlans = await getPlansFromLocal();
    if (localPlans.isNotEmpty) {
      return localPlans;
    } else {
      return _fetchPlanDataWithStoredToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                '菜单',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Plan>>(
        future: _loadPlans(),
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
                return PlanCard(plan: plan);
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
