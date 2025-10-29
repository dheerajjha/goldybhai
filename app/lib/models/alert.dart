class Alert {
  final int? id;
  final int userId;
  final int commodityId;
  final String? commodityName;
  final String? symbol;
  final String? unit;
  final String? type;
  final String condition; // < or >
  final double targetPrice;
  final bool active;
  final String? createdAt;
  final String? triggeredAt;

  Alert({
    this.id,
    required this.userId,
    required this.commodityId,
    this.commodityName,
    this.symbol,
    this.unit,
    this.type,
    required this.condition,
    required this.targetPrice,
    this.active = true,
    this.createdAt,
    this.triggeredAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      commodityId: json['commodity_id'] as int,
      commodityName: json['commodity_name'] as String?,
      symbol: json['symbol'] as String?,
      unit: json['unit'] as String?,
      type: json['type'] as String?,
      condition: json['condition'] as String,
      targetPrice: _toDouble(json['target_price']) ?? 0,
      active: json['active'] == 1 || json['active'] == true,
      createdAt: json['created_at'] as String?,
      triggeredAt: json['triggered_at'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'commodityId': commodityId,
      'commodity_name': commodityName,
      'symbol': symbol,
      'unit': unit,
      'type': type,
      'condition': condition,
      'targetPrice': targetPrice,
      'active': active,
      'created_at': createdAt,
      'triggered_at': triggeredAt,
    };
  }

  // Helper methods
  bool get isTriggered => triggeredAt != null;

  String get conditionText => condition == '<' ? 'Below' : 'Above';

  String get statusText {
    if (!active) return 'Inactive';
    if (isTriggered) return 'Triggered';
    return 'Active';
  }
}
