import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'plan.dart';

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

Future<void> savePlansToLocal(List<Plan> plans) async {
  final prefs = await SharedPreferences.getInstance();
  final planList = plans.map((plan) => json.encode(plan.toJson())).toList();
  await prefs.setStringList('plans', planList);
}

Future<List<Plan>> getPlansFromLocal() async {
  final prefs = await SharedPreferences.getInstance();
  final planList = prefs.getStringList('plans');
  if (planList == null) return [];
  return planList.map((plan) => Plan.fromJson(json.decode(plan))).toList();
}
