class Commodity {
  final int id;
  final String name;
  final String symbol;
  final String unit;
  final String type; // gold, silver, coin
  final String? createdAt;

  Commodity({
    required this.id,
    required this.name,
    required this.symbol,
    required this.unit,
    required this.type,
    this.createdAt,
  });

  factory Commodity.fromJson(Map<String, dynamic> json) {
    return Commodity(
      id: json['id'] as int,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      unit: json['unit'] as String,
      type: json['type'] as String,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'symbol': symbol,
      'unit': unit,
      'type': type,
      'created_at': createdAt,
    };
  }
}
