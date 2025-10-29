import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Dialog for creating price alerts
class CreateAlertDialog extends StatefulWidget {
  final double currentPrice;
  final Function(String condition, double targetPrice) onCreate;

  const CreateAlertDialog({
    super.key,
    required this.currentPrice,
    required this.onCreate,
  });

  @override
  State<CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<CreateAlertDialog> {
  String _condition = '>';
  final _priceController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_alert, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          const Text('Set Price Alert'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Price: ${priceFormat.format(widget.currentPrice)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Alert when price:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: '>',
                  label: Text('Rises Above'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: '<',
                  label: Text('Drops Below'),
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
              selected: {_condition},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _condition = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Target Price (₹)',
                prefixText: '₹',
                hintText: priceFormat.format(widget.currentPrice),
                border: const OutlineInputBorder(),
                helperText: _condition == '>'
                    ? 'You\'ll be notified when price goes above this'
                    : 'You\'ll be notified when price goes below this',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCreate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.grey[900],
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create Alert'),
        ),
      ],
    );
  }

  void _handleCreate() {
    final priceText = _priceController.text.trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target price')),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() => _isLoading = true);
    widget.onCreate(_condition, price);
  }
}

