import 'dart:math';
import 'package:flutter/material.dart';

/// Dynamic looping ambient scene visualizer that changes based on the selected backsound.
/// Generates hardware-accelerated 60 FPS weather and nature animations (Rain, Ocean, Birds/Forest, Night Stars/Fireflies, Wind, Fireplace Embers, and Quran Aura).
class AmbientBackground extends StatefulWidget {
  final String? activeBacksoundId;
  final bool isPlaying;

  const AmbientBackground({
    super.key,
    required this.activeBacksoundId,
    required this.isPlaying,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _AmbientScenePainter(
                progress: _controller.value,
                backsoundId: widget.activeBacksoundId,
                isPlaying: widget.isPlaying,
              ),
              child: Container(
                decoration: BoxDecoration(
                  // Gradient overlay to keep text and lyrics perfectly readable
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0F1117).withValues(alpha: 0.82),
                      const Color(0xFF0F1117).withValues(alpha: 0.65),
                      const Color(0xFF0F1117).withValues(alpha: 0.90),
                      const Color(0xFF0F1117),
                    ],
                    stops: const [0.0, 0.35, 0.75, 1.0],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AmbientScenePainter extends CustomPainter {
  final double progress;
  final String? backsoundId;
  final bool isPlaying;

  _AmbientScenePainter({
    required this.progress,
    required this.backsoundId,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (backsoundId) {
      case 'rain':
        _paintRainScene(canvas, size);
        break;
      case 'ocean':
        _paintOceanScene(canvas, size);
        break;
      case 'birds':
        _paintForestScene(canvas, size);
        break;
      case 'night':
        _paintNightScene(canvas, size);
        break;
      case 'wind':
        _paintWindScene(canvas, size);
        break;
      case 'fireplace':
        _paintFireplaceScene(canvas, size);
        break;
      default:
        _paintDefaultQuranAura(canvas, size);
        break;
    }
  }

  /// 1. Rain Scene: Falling rain streaks with depth, splashing ripple rings at bottom, soft thundercloud ambiance
  void _paintRainScene(Canvas canvas, Size size) {
    // Ambient dark blue-slate gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle cloud lightning pulse
    final lightningPulse = (sin(progress * 2 * pi * 0.5) > 0.96) ? 0.08 : 0.0;
    if (lightningPulse > 0) {
      final flashPaint = Paint()..color = Colors.cyanAccent.withValues(alpha: lightningPulse);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }

    final rainPaint = Paint()
      ..color = const Color(0xFF67E8F9).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final fastRainPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.55)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    // Layer 1: Background slow rain
    const dropCount = 45;
    for (int i = 0; i < dropCount; i++) {
      final seed = i * 79.19;
      final x = (sin(seed) * 0.5 + 0.5) * size.width;
      final speed = 1.2 + (i % 5) * 0.2;
      final y = ((progress * speed + (i / dropCount)) % 1.0) * size.height;
      final length = 16.0 + (i % 4) * 6;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3.5, y + length),
        rainPaint,
      );
    }

    // Layer 2: Foreground fast rain
    const fgDropCount = 30;
    for (int i = 0; i < fgDropCount; i++) {
      final seed = i * 137.5;
      final x = (cos(seed) * 0.5 + 0.5) * size.width;
      final speed = 2.0 + (i % 3) * 0.4;
      final y = ((progress * speed + (i / fgDropCount)) % 1.0) * size.height;
      final length = 26.0 + (i % 3) * 10;

      canvas.drawLine(
        Offset(x, y),
        Offset(x - 5.0, y + length),
        fastRainPaint,
      );
    }

    // Layer 3: Water ripple rings at bottom
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 6; i++) {
      final seed = i * 211.3;
      final cx = (sin(seed) * 0.4 + 0.5) * size.width;
      final cy = size.height * 0.85 + (cos(seed) * 0.1) * size.height;
      final rippleProgress = ((progress * 1.5 + i * 0.25) % 1.0);
      final radius = rippleProgress * 32.0;
      final opacity = (1.0 - rippleProgress).clamp(0.0, 1.0) * 0.35;

      ripplePaint.color = const Color(0xFF38BDF8).withValues(alpha: opacity);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: radius * 2, height: radius * 0.8),
        ripplePaint,
      );
    }
  }

  /// 2. Ocean Scene: Dynamic sine waves, glowing foam lines, moonlight shimmer
  void _paintOceanScene(Canvas canvas, Size size) {
    // Deep ocean gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF031926), Color(0xFF064E3B), Color(0xFF0C4A6E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final wavePaint1 = Paint()
      ..color = const Color(0xFF0284C7).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final wavePaint2 = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final wavePaint3 = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    // Draw wave layer 1
    _drawSineWave(canvas, size, wavePaint1, heightOffset: size.height * 0.68, amplitude: 22, freq: 1.2, speedOffset: progress * 2 * pi);
    // Draw wave layer 2
    _drawSineWave(canvas, size, wavePaint2, heightOffset: size.height * 0.76, amplitude: 16, freq: 1.8, speedOffset: -progress * 2 * pi * 1.3);
    // Draw wave layer 3
    _drawSineWave(canvas, size, wavePaint3, heightOffset: size.height * 0.84, amplitude: 12, freq: 2.4, speedOffset: progress * 2 * pi * 0.8);

    // Floating water sparkles
    final sparklePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 20; i++) {
      final sx = (sin(i * 91.3) * 0.5 + 0.5) * size.width;
      final sy = size.height * 0.65 + (cos(i * 47.7) * 0.5 + 0.5) * (size.height * 0.3);
      final sparkleScale = (sin(progress * 4 * pi + i) + 1) / 2;
      sparklePaint.color = Colors.white.withValues(alpha: sparkleScale * 0.4);
      canvas.drawCircle(Offset(sx, sy), 1.5 * sparkleScale + 0.5, sparklePaint);
    }
  }

  void _drawSineWave(Canvas canvas, Size size, Paint paint, {
    required double heightOffset,
    required double amplitude,
    required double freq,
    required double speedOffset,
  }) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, heightOffset);

    for (double x = 0; x <= size.width; x += 10) {
      final y = heightOffset + sin((x / size.width * freq * 2 * pi) + speedOffset) * amplitude;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 3. Forest & Birds Scene: Lush canopy light-rays, floating foliage & sunlit pollen
  void _paintForestScene(Canvas canvas, Size size) {
    // Forest canopy gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF052E16), Color(0xFF064E3B), Color(0xFF065F46)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Diagonal sun rays (God rays)
    final rayPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFA7F3D0).withValues(alpha: 0.12),
          const Color(0xFF10B981).withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final rayPath = Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.6, 0)
      ..lineTo(size.width, size.height * 0.8)
      ..lineTo(size.width * 0.4, size.height * 0.8)
      ..close();
    canvas.drawPath(rayPath, rayPaint);

    // Floating leaves & pollen
    final leafPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 28; i++) {
      final seed = i * 67.3;
      final x = ((sin(seed) * 0.5 + 0.5) * size.width + sin(progress * 2 * pi + i) * 30) % size.width;
      final y = ((progress * 0.8 + (i / 28)) % 1.0) * size.height;
      final scale = (sin(i.toDouble()) * 0.5 + 0.5);

      leafPaint.color = const Color(0xFF34D399).withValues(alpha: 0.25 + scale * 0.25);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 2 * pi + i);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 6 + scale * 6, height: 3 + scale * 3),
        leafPaint,
      );
      canvas.restore();
    }
  }

  /// 4. Night Scene: Deep indigo sky, twinkling stars, shooting star, glowing fireflies
  void _paintNightScene(Canvas canvas, Size size) {
    // Night sky gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF030712), Color(0xFF0B0F19), Color(0xFF1E1B4B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final starPaint = Paint()..style = PaintingStyle.fill;

    // Constellation twinkling stars
    for (int i = 0; i < 40; i++) {
      final sx = (sin(i * 123.45) * 0.5 + 0.5) * size.width;
      final sy = (cos(i * 87.65) * 0.5 + 0.5) * (size.height * 0.65);
      final twinkle = (sin(progress * (3 + (i % 5)) * pi + i * 2) + 1) / 2;
      final radius = 0.8 + (i % 3) * 0.6;

      starPaint.color = (i % 4 == 0 ? const Color(0xFFA5B4FC) : Colors.white)
          .withValues(alpha: 0.2 + twinkle * 0.65);
      canvas.drawCircle(Offset(sx, sy), radius, starPaint);
    }

    // Shooting star (periodic)
    final meteorCycle = (progress * 3) % 1.0;
    if (meteorCycle < 0.25) {
      final mProg = meteorCycle / 0.25;
      final startX = size.width * 0.8;
      final startY = size.height * 0.1;
      final endX = size.width * 0.2;
      final endY = size.height * 0.35;

      final curX = startX + (endX - startX) * mProg;
      final curY = startY + (endY - startY) * mProg;

      final meteorPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: 1.0 - mProg), Colors.transparent],
        ).createShader(Rect.fromPoints(Offset(curX, curY), Offset(curX + 40, curY - 20)))
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(curX, curY), Offset(curX + 35, curY - 18), meteorPaint);
    }

    // Glowing drifting fireflies
    final fireflyPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 16; i++) {
      final fx = (sin(i * 73.1 + progress * pi) * 0.4 + 0.5) * size.width;
      final fy = size.height * 0.45 + (cos(i * 37.9 - progress * 1.5 * pi) * 0.35 + 0.35) * size.height * 0.45;
      final glow = (sin(progress * 6 * pi + i * 3) + 1) / 2;

      // Outer glow
      fireflyPaint.color = const Color(0xFFFDE047).withValues(alpha: glow * 0.25);
      canvas.drawCircle(Offset(fx, fy), 8 * glow + 2, fireflyPaint);

      // Core
      fireflyPaint.color = const Color(0xFFFEF08A).withValues(alpha: 0.6 + glow * 0.4);
      canvas.drawCircle(Offset(fx, fy), 2.2, fireflyPaint);
    }
  }

  /// 5. Wind Scene: Aerodynamic breeze ribbons & swirling particles
  void _paintWindScene(Canvas canvas, Size size) {
    // Breeze gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F172A), Color(0xFF064E3B), Color(0xFF042F2E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final windPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final yBase = size.height * 0.2 + (i * size.height * 0.12);
      final pOffset = (progress + (i * 0.18)) % 1.0;
      final startX = -100 + pOffset * (size.width + 200);

      final path = Path();
      path.moveTo(startX, yBase);
      path.cubicTo(
        startX + 80,
        yBase - 25 * sin(progress * 2 * pi + i),
        startX + 160,
        yBase + 25 * cos(progress * 2 * pi + i),
        startX + 240,
        yBase,
      );

      final alpha = (sin(pOffset * pi) * 0.4).clamp(0.0, 1.0);
      windPaint.color = const Color(0xFF2DD4BF).withValues(alpha: alpha);
      canvas.drawPath(path, windPaint);
    }
  }

  /// 6. Fireplace Scene: Warm amber glow, floating campfire embers drifting upwards
  void _paintFireplaceScene(Canvas canvas, Size size) {
    // Fireplace warm ember gradient
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF180A04), Color(0xFF2D0E02), Color(0xFF451A03)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Warm radial fire pulse from bottom center
    final firePulse = (sin(progress * 8 * pi) + cos(progress * 14 * pi) + 2) / 4;
    final radialPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 0.95),
        radius: 0.85 + firePulse * 0.15,
        colors: [
          const Color(0xFFF97316).withValues(alpha: 0.25 + firePulse * 0.15),
          const Color(0xFFEA580C).withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), radialPaint);

    // Rising glowing embers
    final emberPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 35; i++) {
      final seed = i * 43.7;
      final speed = 1.0 + (i % 4) * 0.3;
      final rawY = (1.0 - ((progress * speed + (i / 35)) % 1.0));
      final y = size.height * 0.35 + rawY * (size.height * 0.65);
      final sway = sin(progress * 4 * pi + seed) * 20;
      final x = (sin(seed) * 0.35 + 0.5) * size.width + sway;
      final sizeScale = (1.0 - rawY).clamp(0.2, 1.0);

      emberPaint.color = (i % 3 == 0 ? const Color(0xFFFBBF24) : const Color(0xFFFB923C))
          .withValues(alpha: (rawY * 0.7).clamp(0.0, 0.8));
      canvas.drawCircle(Offset(x, y), 1.5 + sizeScale * 2.0, emberPaint);
    }
  }

  /// 7. Default Quran Emerald Aura: Rotating sacred mandala aura with stardust
  void _paintDefaultQuranAura(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF090D16), Color(0xFF064E3B), Color(0xFF0F172A)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final center = Offset(size.width * 0.5, size.height * 0.32);

    // Slow rotating emerald aura
    final auraPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.7,
        colors: [
          const Color(0xFF10B981).withValues(alpha: isPlaying ? 0.22 : 0.08),
          const Color(0xFF059669).withValues(alpha: isPlaying ? 0.10 : 0.03),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.55));
    canvas.drawCircle(center, size.width * 0.55, auraPaint);

    // Gold floating particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * pi + (progress * 2 * pi * 0.2);
      final dist = (sin(progress * 2 * pi + i) * 0.2 + 0.6) * (size.width * 0.38);
      final px = center.dx + cos(angle) * dist;
      final py = center.dy + sin(angle) * dist;
      final pulse = (sin(progress * 4 * pi + i * 2) + 1) / 2;

      particlePaint.color = const Color(0xFFFBBF24).withValues(alpha: 0.25 + pulse * 0.4);
      canvas.drawCircle(Offset(px, py), 1.2 + pulse * 1.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientScenePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backsoundId != backsoundId ||
        oldDelegate.isPlaying != isPlaying;
  }
}
