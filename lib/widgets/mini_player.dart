import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../models/backsound_model.dart';
import '../screens/player_screen.dart';
import '../theme/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, player, _) {
        final surah = player.currentSurah;
        if (surah == null) {
          return const SizedBox.shrink();
        }

        final qari = player.currentQari;

        // Find active backsound
        String? activeBacksoundName;
        for (final b in Backsound.presets) {
          if (player.isBacksoundActive(b.id)) {
            activeBacksoundName = b.name.split(' ').first;
            break;
          }
        }

        final progress = (player.duration.inMilliseconds > 0)
            ? (player.position.inMilliseconds / player.duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlayerScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Emerald Progress Bar
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2.5,
                    backgroundColor: AppTheme.bgElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Album Art / Quran Emblem
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppTheme.emeraldGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: player.isChangingTrack
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : Icon(
                                    player.isPlaying
                                        ? Icons.graphic_eq_rounded
                                        : Icons.menu_book_rounded,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Subtitle Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      surah.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    surah.nameArabic,
                                    textDirection: TextDirection.rtl,
                                    style: const TextStyle(
                                      color: AppTheme.accentGoldLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeBacksoundName != null
                                    ? '${qari?.name ?? "Qari"} • 🌿 $activeBacksoundName'
                                    : (qari?.name ?? '${surah.verses} Ayat'),
                                style: TextStyle(
                                  color: activeBacksoundName != null
                                      ? AppTheme.primaryEmeraldLight
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Action Controls
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                player.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                color: AppTheme.primaryEmerald,
                                size: 34,
                              ),
                              onPressed: () {
                                if (player.isPlaying) {
                                  player.pause();
                                } else {
                                  player.resume();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: AppTheme.textPrimary,
                                size: 28,
                              ),
                              tooltip: 'Surah Selanjutnya',
                              onPressed: () => player.playNext(),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppTheme.textTertiary,
                                size: 20,
                              ),
                              tooltip: 'Tutup',
                              onPressed: () => player.stop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
