import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用于复制到剪贴板
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

import 'package:intl/intl.dart'; // 用于格式化日期

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  late Future<List<Order>> _ordersFuture; // 初始化 late 变量

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchUserOrders(); // 在 initState 中初始化 _ordersFuture
  }

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _fetchUserOrders(); // 刷新订单数据
    });
  }

  Future<List<Order>> _fetchUserOrders() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      throw Exception("No access token found.");
    }
    return await OrderService().fetchUserOrders(accessToken);
  }

  String _getOrderStatusText(int? status) {
    switch (status) {
      case 0:
        return '未支付';
      case 3:
        return '已支付';
      case 2:
        return '已取消';
      default:
        return '未知状态';
    }
  }

  // 将Unix时间戳转换为可读的日期格式
  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) {
      return '未知';
    }
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单管理'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders, // 下拉刷新调用刷新方法
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture, // 使用已初始化的 _ordersFuture
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data != null) {
              final orders = snapshot.data!;
              if (orders.isEmpty) {
                return const Center(child: Text('暂无订单'));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
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
                          // 订单号，长按复制订单号
                          GestureDetector(
                            onLongPress: () {
                              Clipboard.setData(
                                ClipboardData(text: order.tradeNo ?? '未知'),
                              );
                              _showSnackbar(context, '订单号已复制');
                            },
                            child: Text(
                              '订单号: ${order.tradeNo ?? '未知'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 金额
                          Text(
                            '金额: ¥${(order.totalAmount != null ? (order.totalAmount! / 100).toStringAsFixed(2) : '未知')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 支付周期
                          Text(
                            '支付周期: ${order.period ?? '未知'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 订单状态
                          Text(
                            '订单状态: ${_getOrderStatusText(order.status)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _getStatusColor(order.status),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 订单创建时间
                          Text(
                            '下单时间: ${_formatTimestamp(order.createdAt)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          if (order.status == 0) const Divider(height: 24),

                          // 只有未支付状态时显示支付和取消按钮
                          if (order.status == 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    // 处理支付逻辑
                                    _handlePayment(order);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue, // 支付按钮颜色
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('支付'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    // 处理取消订单逻辑
                                    _handleCancel(order);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red, // 取消按钮颜色
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('取消'),
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
              return const Center(child: Text('暂无订单'));
            }
          },
        ),
      ),
    );
  }

  // 根据订单状态设置不同颜色
  Color _getStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 3:
        return Colors.green;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 支付逻辑处理函数
  void _handlePayment(Order order) {
    // 这里处理订单支付逻辑
    print('Processing payment for order: ${order.tradeNo}');
    // 可以根据需求跳转到支付页面或者发起支付请求
  }

  // 取消订单逻辑处理函数
  Future<void> _handleCancel(Order order) async {
    // 这里处理取消订单逻辑
    print('Cancelling order: ${order.tradeNo}');
    // 发起取消订单的API请求
    final authService = OrderService();
    final tradeNo = order.tradeNo; // 替换为真实订单号
    final accessToken = await getToken(); // 假设你有获取 access token 的方法

    try {
      final result = await authService.cancelOrder(tradeNo!, accessToken!);
      print("订单取消结果: $result");
      if (result['status'] == 'success') {
        _showSnackbar(context, "订单取消成功");
        await _refreshOrders(); // 取消成功后刷新订单
      } else {
        _showSnackbar(context, "订单取消失败");
      }
    } catch (e) {
      _showSnackbar(context, "取消订单失败: $e");
    }
  }

  // 显示提示信息
  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
