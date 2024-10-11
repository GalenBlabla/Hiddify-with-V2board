import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/monitor_pay_status.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

void showPurchaseDialog(
    BuildContext context, Plan plan, Translations t, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PurchaseDetailsDialog(plan: plan, t: t, ref: ref);
    },
  );
}

class PurchaseDetailsDialog extends ConsumerStatefulWidget {
  final Plan plan;
  final Translations t;
  final WidgetRef ref;

  const PurchaseDetailsDialog(
      {super.key, required this.plan, required this.t, required this.ref});

  @override
  _PurchaseDetailsDialogState createState() => _PurchaseDetailsDialogState();
}

class _PurchaseDetailsDialogState extends ConsumerState<PurchaseDetailsDialog> {
  double? _selectedPrice;
  String? _selectedPeriod;
  String? _tradeNo; // 用于存储生成的订单号
  final PurchaseService _purchaseService = PurchaseService();
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _selectedPrice = _findCheapestPrice();
    _selectedPeriod = _findCheapestPeriod();
  }

  double? _findCheapestPrice() {
    final prices = [
      widget.plan.monthPrice,
      widget.plan.quarterPrice,
      widget.plan.halfYearPrice,
      widget.plan.yearPrice,
      widget.plan.twoYearPrice,
      widget.plan.threeYearPrice,
      widget.plan.onetimePrice
    ].where((price) => price != null).toList();

    if (prices.isNotEmpty) {
      return prices.reduce((a, b) => a! < b! ? a : b);
    }
    return null;
  }

  String? _findCheapestPeriod() {
    if (_selectedPrice == widget.plan.monthPrice) return 'month_price';
    if (_selectedPrice == widget.plan.quarterPrice) return 'quarter_price';
    if (_selectedPrice == widget.plan.halfYearPrice) return 'half_year_price';
    if (_selectedPrice == widget.plan.yearPrice) return 'year_price';
    if (_selectedPrice == widget.plan.twoYearPrice) return 'two_year_price';
    if (_selectedPrice == widget.plan.threeYearPrice) return 'three_year_price';
    if (_selectedPrice == widget.plan.onetimePrice) return 'onetime_price';
    return null;
  }

  Future<void> _handleSubscribe() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("Access token is null");
      return;
    }

    try {
      // 检查未支付的订单
      final List<Order> orders =
          await _orderService.fetchUserOrders(accessToken);
      for (final order in orders) {
        if (order.status == 0) {
          // 如果订单未支付
          await _orderService.cancelOrder(order.tradeNo!, accessToken);
          print('未支付订单 ${order.tradeNo} 已取消');
        }
      }

      // 继续创建新订单
      final orderResponse = await _purchaseService.createOrder(
        widget.plan.id,
        _selectedPeriod!,
        accessToken,
      );

      if (orderResponse != null && orderResponse['status'] == 'success') {
        _tradeNo = orderResponse['data']?.toString();
        print("订单创建成功 订单号$_tradeNo");
        final paymentMethods =
            await _purchaseService.getPaymentMethods(accessToken);
        if (paymentMethods.isNotEmpty) {
          _showPaymentMethodsDialog(paymentMethods);
        } else {
          print('No payment methods available.');
        }
      } else {
        print('Order failed: ${orderResponse?['message']}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handlePayment(dynamic selectedMethod) async {
    final accessToken = await getToken(); // 获取用户的token
    try {
      // 调用 submitOrder 并获取完整的响应字典
      final response = await _purchaseService.submitOrder(
        _tradeNo!,
        selectedMethod['id'].toString(),
        accessToken!,
      );

      print('Payment response: $response');

      // 获取 type 和 data 字段
      final type = response['type'];
      final data = response['data'];

      // 确保 type 是 int 并且 data 是期望的类型
      if (type is int) {
        // 如果 type 为 -1 且 data 为 true，表示订单已通过钱包余额支付成功
        if (type == -1 && data == true) {
          print('订单已通过钱包余额支付成功，无需跳转支付页面');
          _handlePaymentSuccess(); // 直接处理支付成功
          return;
        }

        // 如果 type 为 1 且 data 是 String 类型，认为它是支付链接
        if (type == 1 && data is String) {
          _openPaymentUrl(data); // 打开支付链接
          _monitorOrderStatus(); // 开始监听订单状态
          return;
        }
      }

      // 处理其他未知情况
      print('Failed to process payment: unexpected response.');
    } catch (e) {
      print('Payment error: $e');
    }
  }

  void _handlePaymentSuccess() {
    print('Order marked as paid.');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order has been successfully paid')),
    );
    Subscription.updateSubscription(context, widget.ref);
    Navigator.of(context).pop(); // 关闭对话框或页面
  }

  Future<void> _monitorOrderStatus() async {
    final accessToken = await getToken();
    if (accessToken == null) return;

    MonitorPayStatus().monitorOrderStatus(_tradeNo!, accessToken, (bool isPaid) {
      if (isPaid) {
        print('订单支付成功');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订单支付成功')),
        );
        Subscription.resetSubscription(context, widget.ref);
      } else {
        print('订单未支付');
      }
    });
  }

  Widget _buildPriceRadio(String label, double price, String period) {
    return RadioListTile<double>(
      title:
          Text('$label: ${price.toStringAsFixed(2)} ${widget.t.purchase.rmb}'),
      value: price,
      groupValue: _selectedPrice,
      onChanged: (double? value) {
        setState(() {
          _selectedPrice = value;
          _selectedPeriod = period;
        });
      },
    );
  }

  Future<void> _showPaymentMethodsDialog(List<dynamic> paymentMethods) async {
    final accessToken = await getToken();
    if (accessToken == null) return;

    // 获取订单详细信息，包括总金额和钱包抵扣金额
    final orderDetails =
        await _orderService.getOrderDetails(_tradeNo!, accessToken);
    if (orderDetails['status'] == 'success') {
      final orderData = orderDetails['data'];
      final totalAmount =
          (orderData['total_amount'] as num? ?? 0) / 100.0; // 转换为元并确保类型为 num
      final balanceAmount =
          (orderData['balance_amount'] as num? ?? 0) / 100.0; // 转换为元并确保类型为 num

      // 显示详细费用结算信息
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Select Payment Method"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total: ${totalAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Wallet Deduction: ${balanceAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Amount to Pay: ${totalAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // 如果 amountToPay 为 0，显示直接支付成功的按钮，否则显示支付方式选择
                if (totalAmount <= 0)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handlePayment({'id': 'wallet_balance'}); // 使用钱包余额支付
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Pay Now (Free)',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                else
                  ...paymentMethods.map((method) {
                    final Map<String, dynamic> paymentMethod =
                        method as Map<String, dynamic>;

                    final feePercent = paymentMethod['handling_fee_percent'] !=
                            null
                        ? double.tryParse(
                              paymentMethod['handling_fee_percent'].toString(),
                            ) ??
                            0.0
                        : 0.0;
                    final handlingFee = totalAmount * feePercent / 100;
                    final totalPrice = totalAmount + handlingFee;

                    return ListTile(
                      title:
                          Text(paymentMethod['name']?.toString() ?? "Unknown"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Handling fee: ${feePercent.toStringAsFixed(2)}%'),
                          Text(
                            'Total price: ${totalPrice.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '(${totalAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb} + '
                            '${handlingFee.toStringAsFixed(2)} ${widget.t.purchase.rmb} fee)',
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _handlePayment(paymentMethod); // 处理实际支付流程
                      },
                    );
                  }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      print('Failed to retrieve order details: ${orderDetails['message']}');
    }
  }

  void _openPaymentUrl(String paymentUrl) {
    final Uri url = Uri.parse(paymentUrl);
    launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plan.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   widget.plan.content ?? widget.t.purchase.noData,
            //   style: const TextStyle(fontSize: 16),
            // ),
            const SizedBox(height: 16),
            if (widget.plan.monthPrice != null)
              _buildPriceRadio(
                widget.t.purchase.monthPrice,
                widget.plan.monthPrice!,
                'month_price',
              ),
            if (widget.plan.quarterPrice != null)
              _buildPriceRadio(
                widget.t.purchase.quarterPrice,
                widget.plan.quarterPrice!,
                'quarter_price',
              ),
            if (widget.plan.halfYearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.halfYearPrice,
                widget.plan.halfYearPrice!,
                'half_year_price',
              ),
            if (widget.plan.yearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.yearPrice,
                widget.plan.yearPrice!,
                'year_price',
              ),
            if (widget.plan.twoYearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.twoYearPrice,
                widget.plan.twoYearPrice!,
                'two_year_price',
              ),
            if (widget.plan.threeYearPrice != null)
              _buildPriceRadio(
                widget.t.purchase.threeYearPrice,
                widget.plan.threeYearPrice!,
                'three_year_price',
              ),
            if (widget.plan.onetimePrice != null)
              _buildPriceRadio(
                widget.t.purchase.onetimePrice,
                widget.plan.onetimePrice!,
                'onetime_price',
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ${_selectedPrice != null ? '${_selectedPrice!.toStringAsFixed(2)} ${widget.t.purchase.rmb}' : widget.t.purchase.noData}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_selectedPrice != null && _selectedPeriod != null) {
                      await _handleSubscribe();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a price")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.t.purchase.subscribe,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
