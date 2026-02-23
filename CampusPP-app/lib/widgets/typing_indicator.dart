import 'package:flutter/material.dart';
import 'dart:math';

class TypingIndicator extends StatefulWidget {
  final Color color;
  const TypingIndicator({super.key, this.color = Colors.black54});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double start = index * 0.2;
              final double end = start + 0.4;
              final double value = _controller.value;
              
              double opacity = 0.3;
              if (value >= start && value <= end) {
                // Peak opacity at the center of the interval
                final double progress = (value - start) / 0.4;
                opacity = 0.3 + 0.7 * sin(progress * pi);
              }
              
              // Handle wrap around for smooth infinite loop visual? 
              // Simple sine wave based on time is easier
              
              double wave = sin((_controller.value * 2 * pi) - (index * 1.0));
              double yOffset = wave * 3; // Bounce up and down slightly

              return Transform.translate(
                offset: Offset(0, yOffset),
                child: Opacity(
                  opacity: (wave + 1) / 2 * 0.7 + 0.3, // Map -1..1 to 0.3..1.0
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
