// viewmodels/purchase_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';

class PurchaseViewModel extends ChangeNotifier {
  final PurchaseService _purchaseService;
  List<Plan> _plans = [];
  String? _errorMessage;
  bool _isLoading = false;
  bool _hasFetched = false; // 增加的标志位

  List<Plan> get plans => _plans;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  PurchaseViewModel({required PurchaseService purchaseService})
      : _purchaseService = purchaseService;

  Future<void> fetchPlans() async {
    if (_hasFetched) return; // 如果已经获取过数据，就直接返回，避免重复请求
    _hasFetched = true; // 设置标志位，表示已经发起过请求

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plans = await _purchaseService.fetchPlanData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
