import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import '../services/quran_api_service.dart';
import '../models/backsound_model.dart';
import '../models/ayah_model.dart';
import '../widgets/backsound_visualizer.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late StreamSubscription<PlayerState> _playerStateSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration?> _durationSubscription;

  final TextEditingController _searchController = TextEditingController();
  String _searchAyahQuery = '';

  @override
  void initState() {
    super.initState();
    final player = context.read<AudioPlayerService>();
    _playerStateSubscription = player.quranPlayer.playerStateStream.listen((state) {});
    _positionSubscription = player.quranPlayer.positionStream.listen((pos) {});
    _durationSubscription = player.quranPlayer.durationStream.listen((dur) {});
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    _positionSubscription.cancel();
    _durationSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Consumer2<AudioPlayerService, QuranApiService>(
        builder: (context, player, api, _) {
          if (player.currentSurah == null) {
            return const Center(
              child: Text('Tidak ada audio yang diputar', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildAppBar(player, api),
              _buildNowPlaying(player),
              _buildVisualizer(player),
              _buildProgressBar(player),
              _buildControls(player),
              _buildBacksoundSection(player),
              _buildLyricsSection(player, api),
              const SliverToBoxAdapter(child: SizedBox(height: 56)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AudioPlayerService player, QuranApiService api) {
    return SliverAppBar(
      expandedHeight: 90,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textPrimary, size: 34),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (player.currentSurah != null)
          IconButton(
            icon: Icon(
              api.isFavorite(player.currentSurah!.number) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: api.isFavorite(player.currentSurah!.number) ? Colors.redAccent : AppTheme.textSecondary,
              size: 26,
            ),
            onPressed: () => api.toggleFavorite(player.currentSurah!.number),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MEMUTAR SURAH',
              style: TextStyle(
                color: AppTheme.primaryEmerald,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              player.currentSurah?.name ?? '',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(bottom: 12),
        centerTitle: true,
      ),
    );
  }

  Widget _buildNowPlaying(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // Album art with glowing emerald gradient & star emblem
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.emeraldGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 4,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.primaryEmeraldLight.withValues(alpha: 0.6),
                  width: 3,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.auto_stories_rounded,
                    size: 72,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Surah Name (English)
            Text(
              player.currentSurah?.name ?? '',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Arabic Name
            Text(
              player.currentSurah?.nameArabic ?? '',
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: AppTheme.accentGoldLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Qari Name with verified checkmark
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mic_rounded, color: AppTheme.primaryEmerald, size: 16),
                const SizedBox(width: 6),
                Text(
                  player.currentQari?.name ?? 'Qari',
                  style: const TextStyle(
                    color: AppTheme.primaryEmeraldLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Revelation tag & Verses
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider, width: 1),
              ),
              child: Text(
                '${player.currentSurah?.revelationType.toUpperCase()} • ${player.currentSurah?.verses ?? 0} AYAT',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizer(AudioPlayerService player) {
    String? activeId;
    for (final b in Backsound.presets) {
      if (player.isBacksoundActive(b.id)) {
        activeId = b.id;
        break;
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        child: BacksoundVisualizer(
          activeBacksoundId: activeId,
          isPlaying: player.isPlaying,
          height: 46,
        ),
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primaryEmerald,
                inactiveTrackColor: AppTheme.bgElevated,
                thumbColor: Colors.white,
                overlayColor: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: player.duration.inSeconds > 0
                    ? player.position.inSeconds.toDouble().clamp(0.0, player.duration.inSeconds.toDouble())
                    : 0,
                max: player.duration.inSeconds > 0
                    ? player.duration.inSeconds.toDouble()
                    : 1,
                onChanged: (value) {
                  player.seek(Duration(seconds: value.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(player.position),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    _formatDuration(player.duration),
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textPrimary, size: 34),
                  tooltip: 'Surah Sebelumnya',
                  onPressed: () => player.playPrevious(),
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, color: AppTheme.textSecondary, size: 28),
                  tooltip: 'Mundur 10 detik',
                  onPressed: () => player.rewind(),
                ),
                Consumer<AudioPlayerService>(
                  builder: (context, p, _) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.35),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          p.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: AppTheme.primaryEmerald,
                          size: 68,
                        ),
                        onPressed: p.isPlaying ? () => p.pause() : () => p.resume(),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, color: AppTheme.textSecondary, size: 28),
                  tooltip: 'Maju 10 detik',
                  onPressed: () => player.fastForward(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textPrimary, size: 34),
                  tooltip: 'Surah Selanjutnya',
                  onPressed: () => player.playNext(),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Auto-play next pill button
            InkWell(
              onTap: () => player.toggleAutoPlayNext(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: player.autoPlayNext
                      ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                      : AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: player.autoPlayNext
                        ? AppTheme.primaryEmerald
                        : AppTheme.divider,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      player.autoPlayNext ? Icons.autorenew_rounded : Icons.repeat_one_rounded,
                      size: 16,
                      color: player.autoPlayNext ? AppTheme.primaryEmerald : AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      player.autoPlayNext ? 'Auto-play Next: Aktif' : 'Auto-play Next: Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: player.autoPlayNext ? AppTheme.primaryEmerald : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBacksoundSection(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.spa_rounded, color: AppTheme.primaryEmerald, size: 18),
                SizedBox(width: 8),
                Text(
                  'Backsound Relaksasi Suara Alam',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Backsound.presets.map((backsound) {
                final isActive = player.isBacksoundActive(backsound.id);
                final isLoading = player.isBacksoundLoading(backsound.id);

                return Material(
                  color: isActive ? AppTheme.primaryEmerald : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => player.toggleBacksound(backsound),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isActive ? AppTheme.primaryEmeraldLight : AppTheme.divider,
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoading)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            Icon(backsound.icon, size: 16, color: isActive ? Colors.black : AppTheme.textPrimary),
                          const SizedBox(width: 6),
                          Text(
                            backsound.name,
                            style: TextStyle(
                              color: isActive ? Colors.black : AppTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsSection(AudioPlayerService player, QuranApiService api) {
    final surahNumber = player.currentSurah?.number ?? 1;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lyrics_rounded, color: AppTheme.primaryEmerald, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Lirik Ayat & Terjemahan',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Uthmani & ID',
                      style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search field
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchAyahQuery = val),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Cari ayat atau kata terjemahan...',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryEmerald, size: 18),
                  suffixIcon: _searchAyahQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textTertiary, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchAyahQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ayahs list
              FutureBuilder<List<Ayah>>(
                future: api.loadAyahs(surahNumber),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !api.favoriteSurahNumbers.contains(surahNumber) &&
                      (snapshot.data == null || snapshot.data!.isEmpty)) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
                      ),
                    );
                  }

                  final ayahs = snapshot.data ?? [];
                  if (ayahs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28),
                        child: Text(
                          'Memuat ayat Al-Quran...',
                          style: TextStyle(color: AppTheme.textTertiary),
                        ),
                      ),
                    );
                  }

                  final filteredAyahs = ayahs.where((a) {
                    final q = _searchAyahQuery.toLowerCase();
                    return a.textArabic.contains(q) ||
                        a.translation.toLowerCase().contains(q) ||
                        a.numberInSurah.toString().contains(q);
                  }).toList();

                  // Estimated active ayah index based on position
                  int activeAyahIndex = 1;
                  if (player.duration.inSeconds > 0 && ayahs.isNotEmpty) {
                    final progress = player.position.inMilliseconds / player.duration.inMilliseconds;
                    activeAyahIndex = (progress * ayahs.length).floor() + 1;
                    if (activeAyahIndex > ayahs.length) activeAyahIndex = ayahs.length;
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAyahs.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.divider, height: 24),
                    itemBuilder: (context, index) {
                      final ayah = filteredAyahs[index];
                      final isCurrentAyah = ayah.numberInSurah == activeAyahIndex && player.isPlaying;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentAyah
                              ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isCurrentAyah
                              ? Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.45), width: 1.5)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header nomor ayat & copy button
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isCurrentAyah
                                        ? AppTheme.primaryEmerald
                                        : AppTheme.bgElevated,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${ayah.numberInSurah}',
                                      style: TextStyle(
                                        color: isCurrentAyah ? Colors.black : AppTheme.accentGoldLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textTertiary),
                                  tooltip: 'Salin Ayat',
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: '${ayah.textArabic}\n\nArtinya: "${ayah.translation}" (QS. ${player.currentSurah?.name}: ${ayah.numberInSurah})',
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ayat ${ayah.numberInSurah} disalin ke clipboard'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: AppTheme.primaryEmerald,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Teks Arab Uthmani
                            Text(
                              ayah.textArabic,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: isCurrentAyah ? AppTheme.primaryEmeraldLight : AppTheme.textPrimary,
                                fontSize: 24,
                                height: 2.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Terjemahan Bahasa Indonesia
                            Text(
                              ayah.translation,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: isCurrentAyah ? AppTheme.textPrimary : AppTheme.textSecondary,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
