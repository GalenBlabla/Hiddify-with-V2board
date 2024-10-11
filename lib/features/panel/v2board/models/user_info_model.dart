class UserInfo {
  final String email;
  final double transferEnable;
  final int lastLoginAt;
  final int createdAt;
  final bool banned; // 账户状态, true: 被封禁, false: 正常
  final bool remindExpire;
  final bool remindTraffic;
  final int? expiredAt;
  final double balance; // 消费余额
  final double commissionBalance; // 剩余佣金余额
  final int planId;
  final double? discount;
  final double? commissionRate;
  final Object? telegramId;
  final String uuid;
  final String avatarUrl;

  UserInfo({
    required this.email,
    required this.transferEnable,
    required this.lastLoginAt,
    required this.createdAt,
    required this.banned,
    required this.remindExpire,
    required this.remindTraffic,
    this.expiredAt,
    required this.balance,
    required this.commissionBalance,
    required this.planId,
    this.discount,
    this.commissionRate,
    this.telegramId,
    required this.uuid,
    required this.avatarUrl,
  });

  // 从 JSON 创建 UserInfo 实例
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      email: json['email'],
      transferEnable: json['transfer_enable']?.toDouble() ?? 0.0,
      lastLoginAt: json['last_login_at'],
      createdAt: json['created_at'],
      banned: json['banned'] == 1,
      remindExpire: json['remind_expire'] == 1,
      remindTraffic: json['remind_traffic'] == 1,
      expiredAt: json['expired_at'],
      balance: json['balance']?.toDouble() ?? 0.0,
      commissionBalance: json['commission_balance']?.toDouble() ?? 0.0,
      planId: json['plan_id'],
      discount: json['discount']?.toDouble(),
      commissionRate: json['commission_rate']?.toDouble(),
      telegramId: json['telegram_id'],
      uuid: json['uuid'],
      avatarUrl: json['avatar_url'],
    );
  }
}
