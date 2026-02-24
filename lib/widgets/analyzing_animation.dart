import 'package:flutter/material.dart';
import 'dart:async';

class AnalyzingAnimation extends StatefulWidget {
  final List<String>? messages;
  const AnalyzingAnimation({super.key, this.messages});

  @override
  State<AnalyzingAnimation> createState() => _AnalyzingAnimationState();
}

class _AnalyzingAnimationState extends State<AnalyzingAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  late List<String> _messages;
  int _messageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _messages = widget.messages ?? [
      "Analyzing Performance...",
      "Verifying Knowledge...",
      "Unlocking Next Step...",
      "Updating Roadmap..."
    ];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE3F2FD), // Match page background
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer ripple 1
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value * 1.5,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withOpacity(1.0 - _controller.value), 
                            width: 2
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Outer ripple 2
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value * 1.2,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(1.0 - _controller.value), 
                            width: 2
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Core Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                    boxShadow: const [
                       BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0)
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 40, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _messages[_messageIndex],
                key: ValueKey<int>(_messageIndex),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto', // Or standard font
                  color: Colors.black,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
