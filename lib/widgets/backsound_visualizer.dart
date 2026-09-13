import 'dart:math';
import 'package:flutter/material.dart';

class BacksoundVisualizer extends StatefulWidget {
  final String? activeBacksoundId;
  final bool isPlaying;
  final double height;

  const BacksoundVisualizer({
    super.key,
    required this.activeBacksoundId,
    required this.isPlaying,
    this.height = 60,
  });

  @override
  State<BacksoundVisualizer> createState() => _BacksoundVisualizerState();
}

class _BacksoundVisualizerState extends State<BacksoundVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPlaying) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Audio Dijeda',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1DB954).withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildIconForTheme(),
              const SizedBox(width: 12),
              Expanded(child: _buildVisualizerTheme()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconForTheme() {
    IconData icon = Icons.graphic_eq;
    Color color = const Color(0xFF1DB954);
    String label = 'Tilawah Quran';

    switch (widget.activeBacksoundId) {
      case 'rain':
        icon = Icons.water_drop;
        color = const Color(0xFF4FC3F7);
        label = 'Rintik Hujan';
        break;
      case 'ocean':
        icon = Icons.waves;
        color = const Color(0xFF00E5FF);
        label = 'Deru Ombak';
        break;
      case 'wind':
        icon = Icons.air;
        color = const Color(0xFF81C784);
        label = 'Desir Angin';
        break;
      case 'birds':
        icon = Icons.nature;
        color = const Color(0xFFAED581);
        label = 'Kicau Burung';
        break;
      case 'night':
        icon = Icons.nights_stay;
        color = const Color(0xFFB39DDB);
        label = 'Suasana Malam';
        break;
      case 'fireplace':
        icon = Icons.local_fire_department;
        color = const Color(0xFFFF8A65);
        label = 'Api Unggun';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildVisualizerTheme() {
    final t = _controller.value * 2 * pi;
    final barsCount = 20;

    Color themeColor = const Color(0xFF1DB954);
    if (widget.activeBacksoundId == 'rain') themeColor = const Color(0xFF4FC3F7);
    if (widget.activeBacksoundId == 'ocean') themeColor = const Color(0xFF00E5FF);
    if (widget.activeBacksoundId == 'wind') themeColor = const Color(0xFF81C784);
    if (widget.activeBacksoundId == 'birds') themeColor = const Color(0xFFAED581);
    if (widget.activeBacksoundId == 'night') themeColor = const Color(0xFFB39DDB);
    if (widget.activeBacksoundId == 'fireplace') themeColor = const Color(0xFFFF8A65);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barsCount, (index) {
            double offset = index * 0.35;
            double factor;

            switch (widget.activeBacksoundId) {
              case 'rain':
                factor = ((sin(t * 3 + offset) + cos(t * 5 + offset * 2) + 2) / 4);
                break;
              case 'ocean':
                factor = ((sin(t + index * 0.2) + 1) / 2) * 0.85 + 0.15;
                break;
              case 'wind':
                factor = ((sin(t * 1.5 + offset * 0.8) + cos(t * 0.7) + 2) / 4);
                break;
              case 'birds':
                factor = (index % 4 == 0)
                    ? ((sin(t * 4 + offset) + 1) / 2)
                    : ((sin(t * 1.2 + offset) + 1) / 2) * 0.4 + 0.1;
                break;
              case 'night':
                factor = (index % 3 == 0)
                    ? ((sin(t * 6) > 0.5 ? 0.9 : 0.2))
                    : 0.25;
                break;
              case 'fireplace':
                factor = (index % 2 == 0)
                    ? ((sin(t * 8 + offset) + cos(t * 12) + 2) / 4)
                    : 0.3;
                break;
              default:
                factor = ((sin(t * 2 + offset) + 1) / 2) * 0.7 + 0.3;
            }

            final barHeight = (widget.height * 0.65 * factor).clamp(4.0, widget.height * 0.65);

            return Container(
              width: 3.5,
              height: barHeight,
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
