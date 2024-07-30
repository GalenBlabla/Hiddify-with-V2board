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
    final rawContent = json['content'] ?? '';
    final document = html_parser.parse(rawContent);
    final cleanContent = document.body?.text ?? '';

    return Plan(
      id: json['id'],
      groupId: json['group_id'],
      transferEnable: json['transfer_enable']?.toDouble() ?? 0.0,
      name: json['name'],
      speedLimit: json['speed_limit'],
      show: json['show'] == 1,
      content: cleanContent,
      onetimePrice: json['onetime_price'] != null ? json['onetime_price'] / 100 : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'transfer_enable': transferEnable,
      'name': name,
      'speed_limit': speedLimit,
      'show': show ? 1 : 0,
      'content': content,
      'onetime_price': onetimePrice != null ? (onetimePrice! * 100).toInt() : null,
    };
  }
}
