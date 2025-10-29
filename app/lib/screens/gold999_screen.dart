import 'dart:async';
import 'package:flutter/material.dart';
import '../services/gold999_client.dart';
import '../widgets/gold_price_display.dart';
import '../widgets/gold_chart.dart';
import '../widgets/alert_card.dart';
import '../widgets/create_alert_dialog.dart';

/// Main screen focused on GOLD 999 WITH GST
class Gold999Screen extends StatefulWidget {
  const Gold999Screen({super.key});

  @override
  State<Gold999Screen> createState() => _Gold999ScreenState();
}

class _Gold999ScreenState extends State<Gold999Screen> with SingleTickerProviderStateMixin {
  final Gold999Client _client = Gold999Client();
  
  CurrentLTP? _currentLTP;
  ChartData? _chartData;
  List<Alert> _alerts = [];
  bool _loading = true;
  bool _loadingChart = false;
  String? _error;
  
  String _currentInterval = 'hourly';
  int _currentDays = 7;
  
  // Track last loaded interval/days to detect changes
  String? _lastLoadedInterval;
  int? _lastLoadedDays;
  
  Timer? _refreshTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadCurrentLTP();
    });
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
    // Skip if same interval/days already loaded
    if (_lastLoadedInterval == _currentInterval && 
        _lastLoadedDays == _currentDays && 
        _chartData != null) {
      return;
    }
    
    setState(() => _loadingChart = true);
    try {
      final chart = await _client.getChartData(
        interval: _currentInterval,
        days: _currentDays,
      );
      if (mounted) {
        setState(() {
          _chartData = chart;
          _lastLoadedInterval = _currentInterval;
          _lastLoadedDays = _currentDays;
        });
      }
    } catch (e) {
      if (mounted && _chartData == null) {
        // Don't show error if we have cached data
      }
    } finally {
      if (mounted) {
        setState(() => _loadingChart = false);
      }
    }
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
  }

  void _handleIntervalChange(String intervalStr) {
    final parts = intervalStr.split(':');
    if (parts.length == 2) {
      final newInterval = parts[0];
      final newDays = int.parse(parts[1]);
      // Only update if actually changing
      if (_currentInterval != newInterval || _currentDays != newDays) {
        setState(() {
          _currentInterval = newInterval;
          _currentDays = newDays;
        });
        _loadChartData();
      }
    }
  }

  Future<void> _createAlert(String condition, double targetPrice) async {
    try {
      await _client.createAlert(
        condition: condition,
        targetPrice: targetPrice,
      );
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAlert(int alertId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert?'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Gold Price Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.grey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.grey[900],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.grey[900],
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: 'Price'),
            Tab(icon: Icon(Icons.notifications), text: 'Alerts'),
          ],
        ),
      ),
      body: _loading && _currentLTP == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _currentLTP == null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPriceTab(),
                    _buildAlertsTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
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
              label: const Text('Create Alert'),
              backgroundColor: Colors.amber,
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
            if (_chartData != null)
              GoldChart(
                chartData: _chartData!,
                interval: _currentInterval,
                onIntervalChanged: _handleIntervalChange,
              )
            else if (_loadingChart)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No chart data available'),
                ),
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No alerts set',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an alert to get notified\nwhen price changes',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
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

