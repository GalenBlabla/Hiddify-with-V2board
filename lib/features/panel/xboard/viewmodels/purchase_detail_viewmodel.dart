// viewmodels/purchase_detail_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/services/monitor_pay_status.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseDetailViewModel extends ChangeNotifier {
  final PurchaseService _purchaseService;
  final OrderService _orderService;

  double? _selectedPrice;
  String? _selectedPeriod;
  String? _tradeNo;
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _paymentMethods = [];

  double? get selectedPrice => _selectedPrice;
  String? get selectedPeriod => _selectedPeriod;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get paymentMethods => _paymentMethods;

  PurchaseDetailViewModel({
    required PurchaseService purchaseService,
    required OrderService orderService,
  })  : _purchaseService = purchaseService,
        _orderService = orderService;

  void selectPrice(double price, String period) {
    _selectedPrice = price;
    _selectedPeriod = period;
    notifyListeners();
  }

  Future<void> createOrder(Plan plan) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await getToken();
      if (token == null) return;

      // Cancel any unpaid orders
      final orders = await _orderService.fetchUserOrders(token);
      for (final order in orders) {
        if (order.status == 0) {
          await _orderService.cancelOrder(order.tradeNo!, token);
        }
      }

      // Create a new order
      final orderResponse = await _purchaseService.createOrder(
        plan.id,
        _selectedPeriod!,
        token,
      );

      if (orderResponse != null && orderResponse['status'] == 'success') {
        _tradeNo = orderResponse['data']?.toString();
        await fetchPaymentMethods(token);
      } else {
        _errorMessage = orderResponse?['message']?.toString();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPaymentMethods(String token) async {
    _paymentMethods = await _purchaseService.getPaymentMethods(token);
    notifyListeners();
  }

  Future<void> handlePayment(dynamic selectedMethod) async {
    final token = await getToken();
    if (token == null) return;

    try {
      final response = await _purchaseService.submitOrder(
        _tradeNo!,
        selectedMethod['id'].toString(),
        token,
      );

      final type = response['type'];
      final data = response['data'];

      if (type == -1 && data == true) {
        // Payment succeeded using wallet balance
        _handlePaymentSuccess();
      } else if (type == 1 && data is String) {
        // Payment URL returned
        _openPaymentUrl(data);
        _monitorOrderStatus(token);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void _handlePaymentSuccess() {
    _errorMessage = 'Payment successful';
    notifyListeners();
  }

  Future<void> _monitorOrderStatus(String token) async {
    MonitorPayStatus().monitorOrderStatus(
      _tradeNo!,
      token,
      (bool isPaid) {
        if (isPaid) {
          _handlePaymentSuccess();
        } else {
          _errorMessage = 'Payment failed';
          notifyListeners();
        }
      },
    );
  }

  void _openPaymentUrl(String paymentUrl) {
    final Uri url = Uri.parse(paymentUrl);
    launchUrl(url);
  }
}
