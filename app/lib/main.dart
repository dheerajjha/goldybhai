import 'dart:async';
import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'models/rate.dart';
import 'models/commodity.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop Rates',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Rate>? _rates;
  List<Commodity>? _commodities;
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRates();
    _loadCommodities();

    // Auto-refresh every 1 second
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _loadRates();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCommodities() async {
    try {
      final commodities = await _apiClient.getCommodities();
      setState(() {
        _commodities = commodities;
      });
    } catch (e) {
      print('Error loading commodities: $e');
    }
  }

  Future<void> _loadRates() async {
    // Don't show loading on auto-refresh if we already have data
    if (_rates == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final rates = await _apiClient.getLatestRates();
      if (mounted) {
        setState(() {
          _rates = rates;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _showCreateAlertDialog() {
    if (_commodities == null || _commodities!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Loading commodities...')));
      return;
    }

    int? selectedCommodityId = _commodities!.first.id;
    String selectedCondition = '<';
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Price Alert'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedCommodityId,
                decoration: const InputDecoration(labelText: 'Commodity'),
                items: _commodities!.map((commodity) {
                  return DropdownMenuItem(
                    value: commodity.id,
                    child: Text(commodity.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedCommodityId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCondition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: const [
                  DropdownMenuItem(value: '<', child: Text('Below (<)')),
                  DropdownMenuItem(value: '>', child: Text('Above (>)')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedCondition = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Target Price',
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a price')),
                );
                return;
              }

              try {
                final price = double.parse(priceController.text);
                await _apiClient.createAlert(
                  commodityId: selectedCommodityId!,
                  condition: selectedCondition,
                  targetPrice: price,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Alert created successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Rates'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRates),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAlertDialog,
        icon: const Icon(Icons.add_alert),
        label: const Text('Create Alert'),
        backgroundColor: Colors.amber,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading rates',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _loadRates, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_rates == null || _rates!.isEmpty) {
      return const Center(child: Text('No rates available'));
    }

    return RefreshIndicator(
      onRefresh: _loadRates,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rates!.length,
        itemBuilder: (context, index) {
          final rate = _rates![index];
          return RateCard(rate: rate);
        },
      ),
    );
  }
}

class RateCard extends StatelessWidget {
  final Rate rate;

  const RateCard({super.key, required this.rate});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    Color? typeColor;
    IconData typeIcon;

    switch (rate.type?.toLowerCase()) {
      case 'gold':
        typeColor = Colors.amber[700];
        typeIcon = Icons.star;
        break;
      case 'silver':
        typeColor = Colors.grey[600];
        typeIcon = Icons.star_border;
        break;
      case 'coin':
        typeColor = Colors.orange[700];
        typeIcon = Icons.monetization_on;
        break;
      default:
        typeColor = Colors.blue[700];
        typeIcon = Icons.show_chart;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: typeColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rate.commodityName ?? rate.symbol ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (rate.unit != null)
                        Text(
                          rate.unit!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPriceColumn(
                  context,
                  'Buy',
                  rate.buyPrice,
                  numberFormat,
                  Colors.green,
                ),
                _buildPriceColumn(
                  context,
                  'Sell',
                  rate.sellPrice,
                  numberFormat,
                  Colors.red,
                ),
                _buildPriceColumn(
                  context,
                  'LTP',
                  rate.ltp,
                  numberFormat,
                  Colors.blue,
                ),
              ],
            ),
            if (rate.high != null && rate.low != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'High: ${numberFormat.format(rate.high)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    'Low: ${numberFormat.format(rate.low)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (rate.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Updated: ${_formatTime(rate.updatedAt!)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceColumn(
    BuildContext context,
    String label,
    double? price,
    NumberFormat format,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          price != null ? format.format(price) : 'N/A',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return DateFormat('MMM d, HH:mm').format(dateTime);
      }
    } catch (e) {
      return isoString;
    }
  }
}
