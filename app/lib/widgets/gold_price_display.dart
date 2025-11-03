import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import 'rolling_number.dart';

/// Large, prominent price display widget for worried users
class GoldPriceDisplay extends StatefulWidget {
  final double ltp;
  final double change;
  final double changePercent;
  final DateTime updatedAt;

  const GoldPriceDisplay({
    super.key,
    required this.ltp,
    required this.change,
    required this.changePercent,
    required this.updatedAt,
  });

  @override
  State<GoldPriceDisplay> createState() => _GoldPriceDisplayState();
}

class _GoldPriceDisplayState extends State<GoldPriceDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  Animation<Color?>? _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Initialize with transparent animation
    _colorAnimation = AlwaysStoppedAnimation<Color?>(Colors.transparent);
  }

  @override
  void didUpdateWidget(GoldPriceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Trigger flash animation when price changes
    if (oldWidget.ltp != widget.ltp) {
      final isIncrease = widget.ltp > oldWidget.ltp;
      _colorAnimation = ColorTween(
        begin: isIncrease ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        end: Colors.transparent,
      ).animate(_animationController);
      
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _sharePrice() {
    final priceFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    final changeSign = widget.change >= 0 ? '+' : '';
    final message = '''
🏆 Gold Price Update

GOLD 999 WITH GST (1 KG)
Price: ${priceFormat.format(widget.ltp)}
Change: $changeSign${priceFormat.format(widget.change)} (${changeSign}${widget.changePercent.toStringAsFixed(2)}%)

Updated: ${DateFormat('MMM d, h:mm a').format(widget.updatedAt)}

via Gold Price Tracker App
''';
    
    Share.share(message, subject: 'Gold Price Update');
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    
    final priceFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          color: _colorAnimation?.value ?? Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.shade50,
            Colors.amber.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)?.gold999WithGst ?? 'GOLD 999 WITH GST',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)?.perKg ?? '1 KG',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${isPositive ? '+' : ''}${widget.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey[700],
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: RollingCurrencyNumber(
                  value: widget.ltp,
                  duration: const Duration(milliseconds: 600),
                  textStyle: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${isPositive ? '+' : ''}${priceFormat.format(widget.change)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Share button
              IconButton(
                onPressed: _sharePrice,
                icon: Icon(Icons.share, size: 20, color: Colors.grey[600]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Share price',
              ),
              const SizedBox(width: 8),
              Text(
                _formatUpdateTime(widget.updatedAt, context),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  String _formatUpdateTime(DateTime time, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final l10n = AppLocalizations.of(context);

    String timeStr;
    if (diff.inSeconds < 60) {
      timeStr = '${diff.inSeconds}s';
    } else if (diff.inMinutes < 60) {
      timeStr = '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      timeStr = '${diff.inHours}h';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
    
    return l10n?.updatedAgo(timeStr) ?? 'Updated $timeStr ago';
  }
}

