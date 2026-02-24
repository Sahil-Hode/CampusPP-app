import 'package:flutter/material.dart';

class ScanningAnimation extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const ScanningAnimation({
    super.key,
    this.width = 100,
    this.height = 100,
    this.color = Colors.blue,
  });

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Document Icon Base
          Icon(
            Icons.description_outlined,
            size: widget.height * 0.8,
            color: Colors.grey[300],
          ),
          
          // Scanning Line
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: _controller.value * (widget.height - 10), // Move from top to bottom
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withOpacity(0),
                        widget.color,
                        widget.color.withOpacity(0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Scanning Overlay (Optional: localized glow)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                  top: _controller.value * (widget.height - 40),
                  child: Opacity(
                    opacity: 0.2,
                    child: Container(
                      width: widget.width,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                             widget.color.withOpacity(0.5),
                             widget.color.withOpacity(0),
                          ]
                        )
                      ),
                    ),
                  )
              );
            }
          ),
        ],
      ),
    );
  }
}
