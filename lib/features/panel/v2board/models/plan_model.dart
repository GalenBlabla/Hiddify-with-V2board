import 'package:html/parser.dart' as html_parser;

class Plan {
  final int id;
  final int groupId;
  final double transferEnable;
  final String name;
  final int speedLimit;
  final bool show;
  final String? content;
  final double? onetimePrice;

  Plan({
    required this.id,
    required this.groupId,
    required this.transferEnable,
    required this.name,
    required this.speedLimit,
    required this.show,
    this.content,
    this.onetimePrice,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // 清理 HTML 标签
    final rawContent = json['content'] ?? '';
    final document = html_parser.parse(rawContent);
    final cleanContent = document.body?.text ?? '';

    return Plan(
      id: json['id'] ?? 0, // 如果 id 是 null，则提供一个默认值 0
      groupId: json['group_id'] ?? 0, // 同样处理 groupId
      transferEnable: json['transfer_enable']?.toDouble() ??
          0.0, // 处理 transfer_enable 可能为 null 的情况
      name: json['name'] ?? '未知', // 如果 name 是 null，提供默认名称
      speedLimit: json['speed_limit'] ?? 0, // 同样处理 speed_limit
      show: json['show'] == 1, // 如果 show 不是 1，则默认为 false
      content: cleanContent.isNotEmpty
          ? cleanContent
          : null, // 如果内容为空字符串，则将 content 设置为 null
      onetimePrice: json['onetime_price'] != null
          ? json['onetime_price'] / 100
          : null, // 处理 onetime_price 可能为 null 的情况
    );
  }
}
