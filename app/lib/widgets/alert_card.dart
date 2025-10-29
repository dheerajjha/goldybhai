import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/gold999_client.dart';

/// Alert card widget for displaying price alerts
class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.active ? Colors.amber.shade300 : Colors.grey.shade300,
          width: alert.active ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  alert.condition == '<' ? Icons.arrow_downward : Icons.arrow_upward,
                  color: alert.condition == '<' ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.condition == '<'
                        ? 'Alert when price drops below'
                        : 'Alert when price rises above',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Chip(
                  label: Text(
                    alert.active ? 'Active' : 'Inactive',
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: alert.active
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: alert.active ? Colors.green.shade900 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              priceFormat.format(alert.targetPrice),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
            ),
            if (alert.triggeredAt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Triggered: ${DateFormat('MMM d, h:mm a').format(alert.triggeredAt!)}',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onToggle,
                    icon: Icon(alert.active ? Icons.pause : Icons.play_arrow),
                    label: Text(alert.active ? 'Disable' : 'Enable'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

