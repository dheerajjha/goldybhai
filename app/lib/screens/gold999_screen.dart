import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../services/gold999_client.dart';
import '../widgets/gold_price_display.dart';
import '../widgets/gold_chart.dart';
import '../widgets/alert_card.dart';
import '../widgets/create_alert_dialog.dart';
import '../widgets/language_switcher.dart';
import '../widgets/empty_state.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'notifications_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Main screen focused on GOLD 999 WITH GST
class Gold999Screen extends StatefulWidget {
  const Gold999Screen({super.key});

  @override
  State<Gold999Screen> createState() => _Gold999ScreenState();
}

class _Gold999ScreenState extends State<Gold999Screen>
    with SingleTickerProviderStateMixin {
  final Gold999Client _client = Gold999Client();

  CurrentLTP? _currentLTP;
  ChartData? _chartData;
  List<Alert> _alerts = [];
  int _unreadNotificationCount = 0;
  bool _loading = true;
  bool _loadingChart = false;
  String? _error;

  String _currentInterval = 'hourly';
  int _currentDays = 1;

  Timer? _refreshTimer;
  Timer? _notificationPollTimer;
  late TabController _tabController;

  // Local notifications
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Language selection
  String _currentLocale = 'en';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedLocale();
    _initializeLocalNotifications();
    _loadData();
    _setupAutoRefresh();
    _setupNotificationPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _notificationPollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString('app_locale') ?? 'en';
    if (mounted) {
      setState(() {
        _currentLocale = savedLocale;
      });
    }
  }

  Future<void> _changeLanguage(String locale) async {
    // Haptic feedback
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 50);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_locale', locale);
    if (mounted) {
      setState(() {
        _currentLocale = locale;
      });

      // Notify the app to change locale
      final localeProvider = context
          .findAncestorWidgetOfExactType<LocaleProvider>();
      if (localeProvider != null) {
        localeProvider.setLocale(Locale(locale));
      }

      // Show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Language changed to ${LanguageSwitcher.languages[locale]!['native']}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Navigate to notifications screen when tapped
        if (response.payload == 'open_notifications') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        }
      },
    );

    // Request permissions
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadCurrentLTP();
    });
  }

  void _setupNotificationPolling() {
    // Poll for unread count every 10 seconds
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkUnreadNotifications();
    });
    // Check immediately
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final previousCount = _unreadNotificationCount;
      final count = await _client.getUnreadCount();

      if (mounted) {
        final countIncreased = count > previousCount;

        setState(() {
          _unreadNotificationCount = count;
        });

        // If count increased and we had previous count, show local notification
        if (countIncreased && previousCount >= 0 && count > 0) {
          await _showLocalNotification(count);
        }
      }
    } catch (e) {
      // Silently fail - polling errors shouldn't disrupt app
    }
  }

  Future<void> _showLocalNotification(int unreadCount) async {
    const androidDetails = AndroidNotificationDetails(
      'gold_alerts',
      'Gold Price Alerts',
      channelDescription: 'Notifications for gold price alerts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      'Gold Price Alert',
      unreadCount == 1
          ? 'You have a new alert notification'
          : 'You have $unreadCount new alert notifications',
      details,
      payload: 'open_notifications',
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadCurrentLTP(),
        _loadChartData(),
        _loadAlerts(),
      ]);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadCurrentLTP() async {
    try {
      final current = await _client.getCurrentLTP();
      if (mounted) {
        setState(() {
          _currentLTP = current;
        });

        // Add to chart for real-time updates
        if (_currentLTP != null && _chartData != null) {
          _addChartDataPoint(_currentLTP!.ltp, _currentLTP!.updatedAt);
        }
      }
    } catch (e) {
      if (mounted && _currentLTP == null) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadChartData() async {
    setState(() => _loadingChart = true);
    try {
      ChartData chart;
      if (_currentInterval == 'hourly') {
        // Use last hour endpoint for hourly view (1-minute intervals)
        chart = await _client.getLastHourData();
      } else {
        // Use chart endpoint with hourly aggregation for 24-hour view
        chart = await _client.getChartData(
          interval: 'hourly',
          days: 1,
        );
      }

      if (mounted) {
        setState(() {
          _chartData = chart;
        });
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() => _loadingChart = false);
      }
    }
  }

  Future<void> _changeInterval(String interval) async {
    setState(() {
      _currentInterval = interval;
    });
    await _loadChartData();
  }

  /// Add new data point to chart (for real-time updates)
  /// Only adds a point if it's been at least 1 minute since the last point
  /// Only applies to 1-hour view - 24-hour view uses hourly aggregated data
  void _addChartDataPoint(double ltp, DateTime timestamp) {
    if (_chartData == null || _chartData!.data.isEmpty) return;

    // Don't add real-time points to 24-hour view (it uses hourly aggregated data)
    if (_currentInterval == 'daily') return;

    // Only add a new point if it's been at least 1 minute since the last point
    final lastPoint = _chartData!.data.last;
    final timeSinceLastPoint = timestamp.difference(lastPoint.timestamp);

    if (timeSinceLastPoint.inSeconds < 60) {
      // Update the last point's price instead of adding a new point
      final updatedData = List<ChartPoint>.from(_chartData!.data);
      updatedData[updatedData.length - 1] = ChartPoint(
        ltp: ltp,
        timestamp: lastPoint.timestamp, // Keep the same timestamp
      );

      setState(() {
        _chartData = ChartData(
          data: updatedData,
          interval: _chartData!.interval,
          period: _chartData!.period,
        );
      });
      return;
    }

    // Add new point (it's been more than 1 minute)
    final newPoint = ChartPoint(ltp: ltp, timestamp: timestamp);
    final updatedData = List<ChartPoint>.from(_chartData!.data)..add(newPoint);

    // Keep only last hour of data (using local time)
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final filteredData = updatedData
        .where((point) => point.timestamp.isAfter(oneHourAgo))
        .toList();

    setState(() {
      _chartData = ChartData(
        data: filteredData,
        interval: _chartData!.interval,
        period: _chartData!.period,
      );
    });
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _client.getAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
        });
      }
    } catch (e) {
      // Silently fail - alerts are optional
    }
    // Also check unread count when loading alerts
    _checkUnreadNotifications();
  }

  // Removed - chart is fixed to 24 hours

  Future<void> _createAlert(String condition, double targetPrice) async {
    try {
      await _client.createAlert(condition: condition, targetPrice: targetPrice);
      if (mounted) {
        Navigator.pop(context);
        await _loadAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Alert created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleAlert(int alertId, bool currentActive) async {
    try {
      await _client.updateAlert(alertId, active: !currentActive);
      await _loadAlerts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteAlert(int alertId) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.deleteAlert ?? 'Delete Alert?'),
        content: Text(
          l10n?.deleteAlertConfirm ??
              'Are you sure you want to delete this alert?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _client.deleteAlert(alertId);
        await _loadAlerts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildIntervalButton(String label, String interval) {
    final isSelected = _currentInterval == interval;
    return GestureDetector(
      onTap: () => _changeInterval(interval),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.grey[900] : Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.appTitle ?? 'Gold Price Tracker',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          LanguageSwitcher(
            currentLocale: _currentLocale,
            onLanguageChanged: _changeLanguage,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.grey[900],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.grey[900],
          tabs: [
            Tab(
              icon: const Icon(Icons.show_chart),
              text: AppLocalizations.of(context)?.priceTab ?? 'Price',
            ),
            Tab(
              icon: const Icon(Icons.notifications),
              text: AppLocalizations.of(context)?.alertsTab ?? 'Alerts',
            ),
          ],
        ),
      ),
      body: _loading && _currentLTP == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _currentLTP == null
          ? _buildErrorView()
          : TabBarView(
              controller: _tabController,
              children: [_buildPriceTab(), _buildAlertsTab()],
            ),
      floatingActionButton: _tabController.index == 1
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_unreadNotificationCount > 0)
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ).then((_) => _checkUnreadNotifications());
                    },
                    backgroundColor: Colors.red,
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$_unreadNotificationCount',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 16),
                FloatingActionButton.extended(
                  onPressed: _currentLTP != null
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => CreateAlertDialog(
                              currentPrice: _currentLTP!.ltp,
                              onCreate: _createAlert,
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.add_alert),
                  label: Text(
                    AppLocalizations.of(context)?.createAlert ?? 'Create Alert',
                  ),
                  backgroundColor: Colors.amber,
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Unable to load data',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTab() {
    final l10n = AppLocalizations.of(context);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentLTP != null)
              GoldPriceDisplay(
                ltp: _currentLTP!.ltp,
                change: _currentLTP!.change,
                changePercent: _currentLTP!.changePercent,
                updatedAt: _currentLTP!.updatedAt,
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentInterval == 'hourly'
                      ? (l10n?.last24Hours ?? 'Last 1 Hour')
                      : 'Last 24 Hours',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Interval selector
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildIntervalButton('1 Hour', 'hourly'),
                  ),
                  Expanded(
                    child: _buildIntervalButton('24 Hours', 'daily'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                if (_chartData != null) {
                  return GoldChart(
                    chartData: _chartData!,
                    interval: _chartData!.interval,
                    period: _chartData!.period,
                  );
                } else if (_loadingChart) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No chart data available'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsTab() {
    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: _alerts.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none_outlined,
              title:
                  AppLocalizations.of(context)?.noAlertsYet ?? 'No alerts yet',
              message:
                  AppLocalizations.of(context)?.createFirstAlert ??
                  'Create your first price alert to get notified when gold price reaches your target.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final alert = _alerts[index];
                return AlertCard(
                  alert: alert,
                  onToggle: () => _toggleAlert(alert.id, alert.active),
                  onDelete: () => _deleteAlert(alert.id),
                );
              },
            ),
    );
  }
}
