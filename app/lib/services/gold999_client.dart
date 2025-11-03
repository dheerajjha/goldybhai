import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simplified API client focused only on GOLD 999 WITH GST
class Gold999Client {
  late final Dio _dio;
  final String baseUrl;
  static const String _cacheKeyCurrent = 'gold999_current';
  static const String _cacheKeyChart = 'gold999_chart';
  static const String _cacheTimestamp = 'gold999_cache_time';

  Gold999Client({this.baseUrl = 'https://api-goldy.sexy.dog/api'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    
    // Add logging interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🌐 API REQUEST: ${options.method} ${options.uri}');
          if (options.data != null) {
            print('📤 Request Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ API RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
          print('📥 Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API ERROR: ${error.requestOptions.uri}');
          print('❌ Error: ${error.message}');
          if (error.response != null) {
            print('❌ Status: ${error.response?.statusCode}');
            print('❌ Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Get last 1 hour chart data with 1-minute intervals
  Future<ChartData> getLastHourData() async {
    print('📊 Fetching last 1 hour chart data...');
    try {
      final response = await _dio.get('/gold999/last-hour');
      final data = response.data;

      final chartData = ChartData(
        data: (data['data'] as List).map((item) {
          return ChartPoint(
            ltp: item['ltp'].toDouble(),
            timestamp: DateTime.parse(item['timestamp']),
          );
        }).toList(),
        interval: data['interval'],
        period: data['period'],
      );

      print('✅ Fetched ${chartData.data.length} data points for last hour');
      
      // Cache it
      await _cacheChart(_cacheKeyChart, chartData);

      return chartData;
    } catch (e) {
      print('❌ Error fetching last hour data: $e');
      // Try cache on error
      final cached = await _getCachedChart(_cacheKeyChart);
      if (cached != null) {
        print('📦 Using cached chart data (${cached.data.length} points)');
        return cached;
      }
      rethrow;
    }
  }

  /// Get current LTP (ultra-lightweight, ~150 bytes)
  Future<CurrentLTP> getCurrentLTP({bool useCache = true}) async {
    try {
      // Try cache first
      if (useCache) {
        final cached = await _getCachedCurrent();
        if (cached != null) {
          print('💰 Using cached LTP: ₹${cached.ltp.toStringAsFixed(0)}');
          // Still fetch fresh data but return cached immediately
          _fetchCurrentLTP(); // Fire and forget
          return cached;
        }
      }

      final response = await _dio.get('/gold999/current');
      final data = response.data;

      final current = CurrentLTP(
        ltp: data['ltp'].toDouble(),
        updatedAt: DateTime.parse(data['updated_at']),
        change: data['change']?.toDouble() ?? 0.0,
        changePercent: data['change_percent']?.toDouble() ?? 0.0,
      );

      print('💰 Current LTP: ₹${current.ltp.toStringAsFixed(0)} (${current.changePercent >= 0 ? '+' : ''}${current.changePercent.toStringAsFixed(2)}%)');

      // Cache it
      await _cacheCurrent(current);

      return current;
    } catch (e) {
      print('❌ Error fetching current LTP: $e');
      // Return cached if available
      final cached = await _getCachedCurrent();
      if (cached != null) {
        print('📦 Using cached LTP on error');
        return cached;
      }
      throw _handleError(e);
    }
  }

  /// Get chart data with aggregation
  Future<ChartData> getChartData({
    String interval = 'hourly',
    int days = 7,
    bool useCache = true,
  }) async {
    try {
      final cacheKey = '${_cacheKeyChart}_${interval}_$days';

      // Try cache first
      if (useCache) {
        final cached = await _getCachedChart(cacheKey);
        if (cached != null) {
          // Still fetch fresh but return cached
          _fetchChartData(interval, days); // Fire and forget
          return cached;
        }
      }

      final response = await _dio.get(
        '/gold999/chart',
        queryParameters: {
          'interval': interval,
          'days': days,
          'limit': interval == 'daily' ? 30 : 50,
        },
      );

      final data = response.data;
      final chartData = ChartData.fromJson(data);

      // Cache it
      await _cacheChart(cacheKey, chartData);

      return chartData;
    } catch (e) {
      // Return cached if available
      final cached = await _getCachedChart(
        '${_cacheKeyChart}_${interval}_$days',
      );
      if (cached != null) return cached;
      throw _handleError(e);
    }
  }

  /// Get latest full rate details
  Future<RateDetail> getLatestRate() async {
    try {
      final response = await _dio.get('/gold999/latest');
      return RateDetail.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get alerts for GOLD 999
  Future<List<Alert>> getAlerts({int userId = 1}) async {
    try {
      final response = await _dio.get(
        '/gold999/alerts',
        queryParameters: {'userId': userId},
      );
      final data = response.data['data'] as List;
      return data.map((json) => Alert.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create alert for GOLD 999
  Future<Alert> createAlert({
    required String condition,
    required double targetPrice,
    int userId = 1,
  }) async {
    try {
      final response = await _dio.post(
        '/gold999/alerts',
        data: {
          'userId': userId,
          'condition': condition,
          'targetPrice': targetPrice,
        },
      );
      return Alert.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update alert
  Future<Alert> updateAlert(
    int id, {
    String? condition,
    double? targetPrice,
    bool? active,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (condition != null) data['condition'] = condition;
      if (targetPrice != null) data['targetPrice'] = targetPrice;
      if (active != null) data['active'] = active;

      final response = await _dio.put('/gold999/alerts/$id', data: data);
      return Alert.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete alert
  Future<void> deleteAlert(int id) async {
    try {
      await _dio.delete('/gold999/alerts/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get notifications for GOLD 999 alerts
  Future<NotificationList> getNotifications({
    int userId = 1,
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        '/gold999/notifications',
        queryParameters: {
          'userId': userId,
          'limit': limit,
          'unreadOnly': unreadOnly,
        },
      );
      return NotificationList.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount({int userId = 1}) async {
    try {
      final response = await _dio.get(
        '/gold999/notifications/unread-count',
        queryParameters: {'userId': userId},
      );
      return response.data['unread_count'] as int? ?? 0;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(
    int notificationId, {
    int userId = 1,
  }) async {
    try {
      await _dio.put(
        '/gold999/notifications/$notificationId/read',
        queryParameters: {'userId': userId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead({int userId = 1}) async {
    try {
      await _dio.put(
        '/gold999/notifications/read-all',
        queryParameters: {'userId': userId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Background fetch methods (fire and forget)
  void _fetchCurrentLTP() {
    getCurrentLTP(useCache: false).catchError((e) {
      // Silently ignore errors in background fetch
      return Future<CurrentLTP>.value(
        CurrentLTP(
          ltp: 0,
          updatedAt: DateTime.now(),
          change: 0,
          changePercent: 0,
        ),
      );
    });
  }

  void _fetchChartData(String interval, int days) {
    getChartData(interval: interval, days: days, useCache: false).catchError((
      e,
    ) {
      // Silently ignore errors in background fetch
      return Future<ChartData>.value(
        ChartData(data: [], interval: '1m', period: '1h'),
      );
    });
  }

  // Cache methods
  Future<void> _cacheCurrent(CurrentLTP current) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKeyCurrent, jsonEncode(current.toJson()));
    await prefs.setString(_cacheTimestamp, DateTime.now().toIso8601String());
  }

  Future<CurrentLTP?> _getCachedCurrent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKeyCurrent);
      final timestamp = prefs.getString(_cacheTimestamp);

      if (cached != null && timestamp != null) {
        final cacheTime = DateTime.parse(timestamp);
        final age = DateTime.now().difference(cacheTime);

        // Use cache if less than 10 seconds old (for 1s refresh)
        if (age.inSeconds < 10) {
          return CurrentLTP.fromJson(jsonDecode(cached));
        }
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  Future<void> _cacheChart(String key, ChartData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(data.toJson()));
    } catch (e) {
      // Ignore cache errors
    }
  }

  Future<ChartData?> _getCachedChart(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(key);
      if (cached != null) {
        return ChartData.fromJson(jsonDecode(cached));
      }
    } catch (e) {
      // Ignore cache errors
    }
    return null;
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet.';
        case DioExceptionType.connectionError:
          return 'Cannot connect to server. Make sure backend is running.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data['error'] ?? 'Unknown error';
          return 'Error $statusCode: $message';
        default:
          return 'Network error: ${error.message}';
      }
    }
    return 'Unexpected error: $error';
  }
}

// Data Models
class CurrentLTP {
  final double ltp;
  final DateTime updatedAt;
  final double change;
  final double changePercent;

  CurrentLTP({
    required this.ltp,
    required this.updatedAt,
    required this.change,
    required this.changePercent,
  });

  factory CurrentLTP.fromJson(Map<String, dynamic> json) {
    return CurrentLTP(
      ltp: json['ltp'].toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
      change: json['change']?.toDouble() ?? 0.0,
      changePercent: json['change_percent']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ltp': ltp,
      'updated_at': updatedAt.toIso8601String(),
      'change': change,
      'change_percent': changePercent,
    };
  }
}

class ChartData {
  final List<ChartPoint> data;
  final String interval;
  final String period;

  ChartData({
    required this.data,
    required this.interval,
    required this.period,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      data: (json['data'] as List).map((p) => ChartPoint.fromJson(p)).toList(),
      interval: json['interval'] as String,
      period: json['period'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.map((p) => p.toJson()).toList(),
      'interval': interval,
      'period': period,
    };
  }
}

class ChartPoint {
  final DateTime timestamp;
  final double ltp;

  ChartPoint({required this.timestamp, required this.ltp});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      timestamp: DateTime.parse(json['timestamp'] as String),
      ltp: json['ltp'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'ltp': ltp,
    };
  }
}

class RateDetail {
  final int id;
  final int commodityId;
  final double ltp;
  final double? buyPrice;
  final double? sellPrice;
  final double? high;
  final double? low;
  final DateTime updatedAt;
  final String? source;

  RateDetail({
    required this.id,
    required this.commodityId,
    required this.ltp,
    this.buyPrice,
    this.sellPrice,
    this.high,
    this.low,
    required this.updatedAt,
    this.source,
  });

  factory RateDetail.fromJson(Map<String, dynamic> json) {
    return RateDetail(
      id: json['id'] as int,
      commodityId: json['commodity_id'] as int,
      ltp: json['ltp'].toDouble(),
      buyPrice: json['buy_price']?.toDouble(),
      sellPrice: json['sell_price']?.toDouble(),
      high: json['high']?.toDouble(),
      low: json['low']?.toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
      source: json['source'] as String?,
    );
  }
}

class Alert {
  final int id;
  final int userId;
  final int commodityId;
  final String condition;
  final double targetPrice;
  final bool active;
  final DateTime createdAt;
  final DateTime? triggeredAt;
  final String commodityName;
  final String symbol;

  Alert({
    required this.id,
    required this.userId,
    required this.commodityId,
    required this.condition,
    required this.targetPrice,
    required this.active,
    required this.createdAt,
    this.triggeredAt,
    required this.commodityName,
    required this.symbol,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      commodityId: json['commodity_id'] as int,
      condition: json['condition'] as String,
      targetPrice: json['target_price'].toDouble(),
      active: json['active'] == 1 || json['active'] == true,
      createdAt: DateTime.parse(json['created_at']),
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'])
          : null,
      commodityName: json['commodity_name'] as String,
      symbol: json['symbol'] as String,
    );
  }
}

class NotificationList {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationList({required this.notifications, required this.unreadCount});

  factory NotificationList.fromJson(Map<String, dynamic> json) {
    return NotificationList(
      notifications: (json['data'] as List)
          .map((n) => AppNotification.fromJson(n))
          .toList(),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

class AppNotification {
  final int id;
  final int alertId;
  final String message;
  final DateTime sentAt;
  final bool delivered;
  final bool read;
  final double? targetPrice;
  final String? condition;
  final DateTime? triggeredAt;

  AppNotification({
    required this.id,
    required this.alertId,
    required this.message,
    required this.sentAt,
    required this.delivered,
    required this.read,
    this.targetPrice,
    this.condition,
    this.triggeredAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      alertId: json['alert_id'] as int,
      message: json['message'] as String,
      sentAt: DateTime.parse(json['sent_at']),
      delivered: json['delivered'] == 1 || json['delivered'] == true,
      read: json['read'] == 1 || json['read'] == true,
      targetPrice: json['target_price']?.toDouble(),
      condition: json['condition'] as String?,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'])
          : null,
    );
  }
}
