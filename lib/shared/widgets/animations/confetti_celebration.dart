import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConfettiCelebration extends StatefulWidget {
  final VoidCallback? onAnimationFinished;

  const ConfettiCelebration({this.onAnimationFinished, super.key});

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationFinished?.call();
      }
    });

    // Generate random particles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < 100; i++) {
        _particles.add(_ConfettiParticle(
          x: _random.nextDouble() * size.width,
          y: -_random.nextDouble() * 100 - 20,
          color: _randomColor(),
          size: _random.nextDouble() * 8 + 6,
          speedY: _random.nextDouble() * 150 + 150,
          speedX: _random.nextDouble() * 80 - 40,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: _random.nextDouble() * 4 - 2,
          type: _randomType(),
        ));
      }
      _controller.forward();
    });
  }

  Color _randomColor() {
    final colors = [
      const Color(0xFFF47B20), // Recipely Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
    ];
    return colors[_random.nextInt(colors.length)];
  }

  _ParticleType _randomType() {
    const types = _ParticleType.values;
    return types[_random.nextInt(types.length)];
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
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

enum _ParticleType { circle, square, triangle }

class _ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double speedY;
  final double speedX;
  final double rotation;
  final double rotationSpeed;
  final _ParticleType type;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.type,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Calculate animated positions
      // Fall down
      final currentY = p.y + p.speedY * progress;
      // Drift sideways using a sine wave + initial speedX
      final currentX = p.x + p.speedX * progress + math.sin(progress * 10 + p.x) * 15;
      final currentRotation = p.rotation + p.rotationSpeed * progress;

      // Fade out towards the end (last 20%)
      double alpha = 1.0;
      if (progress > 0.8) {
        alpha = (1.0 - progress) / 0.2;
      }
      paint.color = p.color.withValues(alpha: alpha);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRotation);

      switch (p.type) {
        case _ParticleType.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ParticleType.square:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
          break;
        case _ParticleType.triangle:
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(-p.size / 2, p.size / 2)
            ..lineTo(p.size / 2, p.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
