import 'package:dio/dio.dart';
import '../models/commodity.dart';
import '../models/rate.dart';
import '../models/alert.dart';
import '../models/preferences.dart';

class ApiClient {
  late final Dio _dio;
  final String baseUrl;

  ApiClient({this.baseUrl = 'http://localhost:3000/api'}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add request/response interceptors for logging
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print('[API] $obj'),
      ),
    );
  }

  // ========================
  // COMMODITIES
  // ========================

  Future<List<Commodity>> getCommodities() async {
    try {
      final response = await _dio.get('/commodities');
      final data = response.data['data'] as List;
      return data.map((json) => Commodity.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Commodity> getCommodityById(int id) async {
    try {
      final response = await _dio.get('/commodities/$id');
      return Commodity.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Commodity>> getCommoditiesByType(String type) async {
    try {
      final response = await _dio.get('/commodities/type/$type');
      final data = response.data['data'] as List;
      return data.map((json) => Commodity.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========================
  // RATES
  // ========================

  Future<List<Rate>> getLatestRates() async {
    try {
      final response = await _dio.get('/rates/latest');
      final data = response.data['data'] as List;
      return data.map((json) => Rate.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Rate> getLatestRateByCommodity(int commodityId) async {
    try {
      final response = await _dio.get('/rates/$commodityId');
      return Rate.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Rate>> getRateHistory(
    int commodityId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/rates/$commodityId/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data['data']['rates'] as List;
      return data.map((json) => Rate.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========================
  // ALERTS
  // ========================

  Future<List<Alert>> getAlerts({int userId = 1}) async {
    try {
      final response = await _dio.get(
        '/alerts',
        queryParameters: {'userId': userId},
      );
      final data = response.data['data'] as List;
      return data.map((json) => Alert.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Alert>> getActiveAlerts({int userId = 1}) async {
    try {
      final response = await _dio.get(
        '/alerts/active',
        queryParameters: {'userId': userId},
      );
      final data = response.data['data'] as List;
      return data.map((json) => Alert.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Alert> getAlertById(int id) async {
    try {
      final response = await _dio.get('/alerts/$id');
      return Alert.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Alert> createAlert({
    int userId = 1,
    required int commodityId,
    required String condition,
    required double targetPrice,
  }) async {
    try {
      final response = await _dio.post(
        '/alerts',
        data: {
          'userId': userId,
          'commodityId': commodityId,
          'condition': condition,
          'targetPrice': targetPrice,
        },
      );
      return Alert.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

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

      final response = await _dio.put('/alerts/$id', data: data);
      return Alert.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAlert(int id) async {
    try {
      await _dio.delete('/alerts/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========================
  // PREFERENCES
  // ========================

  Future<Preferences> getPreferences({int userId = 1}) async {
    try {
      final response = await _dio.get(
        '/preferences',
        queryParameters: {'userId': userId},
      );
      return Preferences.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Preferences> updatePreferences({
    int userId = 1,
    int? refreshInterval,
    String? currency,
    bool? notificationsOn,
    String? theme,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (refreshInterval != null) data['refreshInterval'] = refreshInterval;
      if (currency != null) data['currency'] = currency;
      if (notificationsOn != null) data['notificationsOn'] = notificationsOn;
      if (theme != null) data['theme'] = theme;

      final response = await _dio.put(
        '/preferences',
        queryParameters: {'userId': userId},
        data: data,
      );
      return Preferences.fromJson(response.data['data']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ========================
  // ERROR HANDLING
  // ========================

  String _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection.';

        case DioExceptionType.connectionError:
          return 'Cannot connect to server. Make sure backend is running on $baseUrl';

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
