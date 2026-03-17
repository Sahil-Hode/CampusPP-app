import 'package:flutter/material.dart';

class SeverityIndicator extends StatelessWidget {
  final String severity;
  final double size;

  const SeverityIndicator({
    super.key,
    required this.severity,
    this.size = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'critical':
        color = Colors.red.shade600;
        break;
      case 'warning':
        color = Colors.amber.shade600;
        break;
      case 'info':
      default:
        color = Colors.blue.shade600;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
