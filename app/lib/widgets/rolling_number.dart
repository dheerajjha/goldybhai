import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Rolling number animation widget (like petrol pump/odometer)
/// Animates digit changes with a smooth rolling effect
class RollingNumber extends StatefulWidget {
  final String number;
  final TextStyle? textStyle;
  final Duration duration;

  const RollingNumber({
    super.key,
    required this.number,
    this.textStyle,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _previousNumber = '';
  String _currentNumber = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _currentNumber = widget.number;
    _previousNumber = widget.number;
  }

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.number != widget.number) {
      setState(() {
        _previousNumber = _currentNumber;
        _currentNumber = widget.number;
      });
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildDigits(),
        );
      },
    );
  }

  List<Widget> _buildDigits() {
    final List<Widget> widgets = [];
    
    // Pad numbers to same length
    final maxLength = math.max(_previousNumber.length, _currentNumber.length);
    final prev = _previousNumber.padLeft(maxLength, ' ');
    final curr = _currentNumber.padLeft(maxLength, ' ');

    for (int i = 0; i < maxLength; i++) {
      final prevChar = prev[i];
      final currChar = curr[i];

      // If it's a digit, animate it
      if (_isDigit(currChar) && _isDigit(prevChar)) {
        widgets.add(_RollingDigit(
          previousDigit: int.parse(prevChar),
          currentDigit: int.parse(currChar),
          animation: _controller,
          textStyle: widget.textStyle,
        ));
      } else if (currChar == ',') {
        // Comma - no animation
        widgets.add(
          Text(',', style: widget.textStyle),
        );
      } else {
        // Space or other character
        widgets.add(
          Text(currChar, style: widget.textStyle),
        );
      }
    }

    return widgets;
  }

  bool _isDigit(String char) {
    return char.codeUnitAt(0) >= '0'.codeUnitAt(0) &&
        char.codeUnitAt(0) <= '9'.codeUnitAt(0);
  }
}

/// Single digit with rolling animation
class _RollingDigit extends StatelessWidget {
  final int previousDigit;
  final int currentDigit;
  final Animation<double> animation;
  final TextStyle? textStyle;

  const _RollingDigit({
    required this.previousDigit,
    required this.currentDigit,
    required this.animation,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    // If no change, just show the digit
    if (previousDigit == currentDigit) {
      return Text('$currentDigit', style: textStyle);
    }

    // Calculate the direction and distance
    int distance = currentDigit - previousDigit;
    
    // Handle wrap-around (e.g., 9 -> 0 should go down, not up)
    if (distance > 5) {
      distance = distance - 10;
    } else if (distance < -5) {
      distance = distance + 10;
    }

    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    final fontSize = textStyle?.fontSize ?? 14.0;
    final height = textStyle?.height ?? 1.0;
    final effectiveHeight = fontSize * height;

    return ClipRect(
      child: SizedBox(
        width: fontSize * 0.6, // Approximate width for a digit
        height: effectiveHeight,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Previous digit sliding out
            Positioned(
              left: 0,
              top: -curve.value * effectiveHeight * distance.sign,
              child: Opacity(
                opacity: 1 - curve.value,
                child: Text('$previousDigit', style: textStyle),
              ),
            ),
            // Current digit sliding in
            Positioned(
              left: 0,
              top: (1 - curve.value) * effectiveHeight * -distance.sign,
              child: Opacity(
                opacity: curve.value,
                child: Text('$currentDigit', style: textStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simplified rolling number for currency display
class RollingCurrencyNumber extends StatelessWidget {
  final double value;
  final TextStyle? textStyle;
  final Duration duration;

  const RollingCurrencyNumber({
    super.key,
    required this.value,
    this.textStyle,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    // Format number with commas (Indian numbering system)
    final formattedNumber = _formatIndianNumber(value.toInt());

    return RollingNumber(
      number: formattedNumber,
      textStyle: textStyle,
      duration: duration,
    );
  }

  String _formatIndianNumber(int number) {
    final str = number.toString();
    if (str.length <= 3) return str;

    final lastThree = str.substring(str.length - 3);
    final remaining = str.substring(0, str.length - 3);

    final List<String> parts = [];
    for (int i = remaining.length; i > 0; i -= 2) {
      final start = math.max(0, i - 2);
      parts.insert(0, remaining.substring(start, i));
    }

    return '${parts.join(',')},${lastThree}';
  }
}

