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
      body: Consumer2<AudioPlayerService, QuranApiService>(
        builder: (context, player, api, _) {
          if (player.currentSurah == null) {
            return const Center(child: Text('Tidak ada audio yang diputar'));
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
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AudioPlayerService player, QuranApiService api) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (player.currentSurah != null)
          IconButton(
            icon: Icon(
              api.isFavorite(player.currentSurah!.number) ? Icons.favorite : Icons.favorite_border,
              color: api.isFavorite(player.currentSurah!.number) ? Colors.red : Colors.white,
            ),
            onPressed: () => api.toggleFavorite(player.currentSurah!.number),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          player.currentSurah?.name ?? '',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        titlePadding: const EdgeInsets.only(bottom: 14),
        centerTitle: true,
      ),
    );
  }

  Widget _buildNowPlaying(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          children: [
            // Album art
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1DB954),
                    Color(0xFF1AA34A),
                    Color(0xFF15803D),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              player.currentSurah?.name ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              player.currentQari?.name ?? '',
              style: const TextStyle(
                color: Color(0xFF1DB954),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${player.currentSurah?.nameArabic} • ${player.currentSurah?.verses ?? 0} Ayat • ${player.currentSurah?.revelationType}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: BacksoundVisualizer(
          activeBacksoundId: activeId,
          isPlaying: player.isPlaying,
          height: 48,
        ),
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF1DB954),
                inactiveTrackColor: Colors.grey[800],
                thumbColor: Colors.white,
                overlayColor: const Color(0xFF1DB954).withValues(alpha: 0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(player.position),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _formatDuration(player.duration),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                  tooltip: 'Surah Sebelumnya',
                  onPressed: () => player.playPrevious(),
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10, color: Colors.white70, size: 28),
                  tooltip: 'Mundur 10 detik',
                  onPressed: () => player.rewind(),
                ),
                Consumer<AudioPlayerService>(
                  builder: (context, p, _) {
                    return IconButton(
                      icon: Icon(
                        p.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: const Color(0xFF1DB954),
                        size: 68,
                      ),
                      onPressed: p.isPlaying ? () => p.pause() : () => p.resume(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10, color: Colors.white70, size: 28),
                  tooltip: 'Maju 10 detik',
                  onPressed: () => player.fastForward(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                  tooltip: 'Surah Selanjutnya',
                  onPressed: () => player.playNext(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => player.toggleAutoPlayNext(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      player.autoPlayNext ? Icons.autorenew : Icons.repeat_one,
                      size: 16,
                      color: player.autoPlayNext ? const Color(0xFF1DB954) : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      player.autoPlayNext ? 'Auto-play Next: Aktif' : 'Auto-play Next: Nonaktif',
                      style: TextStyle(
                        fontSize: 12,
                        color: player.autoPlayNext ? const Color(0xFF1DB954) : Colors.grey,
                        fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.spa, color: Color(0xFF1DB954), size: 18),
                SizedBox(width: 8),
                Text(
                  'Suara Alam (Backsound Relaksasi)',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
                  color: isActive ? const Color(0xFF1DB954) : const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () => player.toggleBacksound(backsound),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
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
                            Icon(backsound.icon, size: 16, color: isActive ? Colors.black : Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            backsound.name,
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1DB954).withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lyrics, color: Color(0xFF1DB954), size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Lirik Ayat & Terjemahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Uthmani & ID',
                      style: TextStyle(color: Color(0xFF1DB954), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search inside lyrics
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchAyahQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari ayat atau kata terjemahan...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                  suffixIcon: _searchAyahQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchAyahQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF282828),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
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
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Color(0xFF1DB954)),
                      ),
                    );
                  }

                  final ayahs = snapshot.data ?? [];
                  if (ayahs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Memuat ayat Al-Quran...',
                          style: TextStyle(color: Colors.grey),
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

                  // Estimated active ayah
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
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF282828), height: 24),
                    itemBuilder: (context, index) {
                      final ayah = filteredAyahs[index];
                      final isCurrentAyah = ayah.numberInSurah == activeAyahIndex && player.isPlaying;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentAyah
                              ? const Color(0xFF1DB954).withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentAyah
                              ? Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.4))
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
                                        ? const Color(0xFF1DB954)
                                        : const Color(0xFF282828),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${ayah.numberInSurah}',
                                      style: TextStyle(
                                        color: isCurrentAyah ? Colors.black : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
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
                                        backgroundColor: const Color(0xFF1DB954),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Teks Arab
                            Text(
                              ayah.textArabic,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                color: isCurrentAyah ? const Color(0xFF1DB954) : Colors.white,
                                fontSize: 24,
                                height: 2.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Terjemahan Indonesia
                            Text(
                              ayah.translation,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: isCurrentAyah ? Colors.white : Colors.white70,
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
