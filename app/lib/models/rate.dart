class Rate {
  final int? id;
  final int commodityId;
  final String? commodityName;
  final String? symbol;
  final String? unit;
  final String? type;
  final double? ltp;
  final double? buyPrice;
  final double? sellPrice;
  final double? high;
  final double? low;
  final String? updatedAt;
  final String? source;

  Rate({
    this.id,
    required this.commodityId,
    this.commodityName,
    this.symbol,
    this.unit,
    this.type,
    this.ltp,
    this.buyPrice,
    this.sellPrice,
    this.high,
    this.low,
    this.updatedAt,
    this.source,
  });

  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      id: json['id'] as int?,
      commodityId: json['commodity_id'] as int,
      commodityName: json['commodity_name'] as String?,
      symbol: json['symbol'] as String?,
      unit: json['unit'] as String?,
      type: json['type'] as String?,
      ltp: _toDouble(json['ltp']),
      buyPrice: _toDouble(json['buy_price']),
      sellPrice: _toDouble(json['sell_price']),
      high: _toDouble(json['high']),
      low: _toDouble(json['low']),
      updatedAt: json['updated_at'] as String?,
      source: json['source'] as String?,
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
      'commodity_id': commodityId,
      'commodity_name': commodityName,
      'symbol': symbol,
      'unit': unit,
      'type': type,
      'ltp': ltp,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'high': high,
      'low': low,
      'updated_at': updatedAt,
      'source': source,
    };
  }

  // Get current price (prefer ltp, fallback to buy_price)
  double? get currentPrice => ltp ?? buyPrice;

  // Calculate price change percentage
  double? get changePercent {
    if (high == null || low == null || high == 0) return null;
    final current = currentPrice ?? 0;
    final range = high! - low!;
    if (range == 0) return 0;
    return ((current - low!) / range) * 100;
  }
}
