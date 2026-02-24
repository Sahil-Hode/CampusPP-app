import 'package:flutter/material.dart';
import 'dart:math';

class CelebrationOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  const CelebrationOverlay({super.key, required this.onFinished});

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Generate particles
    for (int i = 0; i < 50; i++) {
      _particles.add(ConfettiParticle(
        color: Colors.primaries[_random.nextInt(Colors.primaries.length)],
        x: 0.5, // Start from center
        y: 0.5,
        speed: _random.nextDouble() * 0.5 + 0.2,
        angle: _random.nextDouble() * 2 * pi,
        size: _random.nextDouble() * 10 + 5,
      ));
    }

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: ConfettiPainter(_particles, _controller.value),
          );
        },
      ),
    );
  }
}

class ConfettiParticle {
  final Color color;
  final double x; // Origin X (0.5)
  late double y; // Origin Y (0.5)
  final double speed;
  final double angle;
  final double size;

  ConfettiParticle({
    required this.color,
    required this.x,
    required this.y,
    required this.speed,
    required this.angle,
    required this.size,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var particle in particles) {
      final distance = particle.speed * progress * size.width; // Move outward
      final dx = centerX + cos(particle.angle) * distance;
      final dy = centerY + sin(particle.angle) * distance + (progress * 200); // Add gravity

      final paint = Paint()..color = particle.color.withOpacity(1.0 - progress);

      canvas.drawCircle(Offset(dx, dy), particle.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
