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
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(
                color: AppTheme.divider,
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2.5,
                    backgroundColor: AppTheme.bgElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryEmerald),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
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

                        // Full 5-Button Action Controls Deck: [Shuffle, Prev, Play/Pause, Next, Loop]
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Shuffle / Randomize
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.shuffle_rounded,
                                color: player.isShuffle ? AppTheme.primaryEmerald : AppTheme.textTertiary,
                                size: 20,
                              ),
                              tooltip: player.isShuffle ? 'Acak: Aktif' : 'Acak: Nonaktif',
                              onPressed: () => player.toggleShuffle(),
                            ),
                            const SizedBox(width: 2),

                            // 2. Previous Surah
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                color: AppTheme.textPrimary,
                                size: 24,
                              ),
                              tooltip: 'Surah Sebelumnya',
                              onPressed: () => player.playPrevious(),
                            ),
                            const SizedBox(width: 2),

                            // 3. Play / Pause
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(1),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                player.isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                color: AppTheme.primaryEmerald,
                                size: 36,
                              ),
                              onPressed: () {
                                if (player.isPlaying) {
                                  player.pause();
                                } else {
                                  player.resume();
                                }
                              },
                            ),
                            const SizedBox(width: 2),

                            // 4. Next Surah
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: AppTheme.textPrimary,
                                size: 24,
                              ),
                              tooltip: 'Surah Selanjutnya',
                              onPressed: () => player.playNext(),
                            ),
                            const SizedBox(width: 2),

                            // 5. Loop / Repeat Mode
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(3),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                player.loopMode == QuranLoopMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded,
                                color: player.loopMode != QuranLoopMode.off
                                    ? AppTheme.primaryEmerald
                                    : AppTheme.textTertiary,
                                size: 20,
                              ),
                              tooltip: player.loopMode == QuranLoopMode.all
                                  ? 'Ulang: Semua Surat'
                                  : player.loopMode == QuranLoopMode.one
                                      ? 'Ulang: 1 Surat'
                                      : 'Ulang: Nonaktif',
                              onPressed: () => player.toggleLoopMode(),
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
