import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'services/audio_player_service.dart';
import 'services/quran_api_service.dart';
import 'models/backsound_model.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late StreamSubscription<PlayerState> _playerStateSubscription;
  late StreamSubscription<Duration> _positionSubscription;
  late StreamSubscription<Duration?> _durationSubscription;
  
  bool _isFavorite = false;
  final TextEditingController _searchController = TextEditingController();

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
              _buildProgressBar(player),
              _buildControls(player),
              _buildBacksoundSection(player),
              _buildLyricsSection(api),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AudioPlayerService player, QuranApiService api) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF121212),
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () => setState(() => _isFavorite = !_isFavorite),
        ),
        IconButton(
          icon: const Icon(Icons.queue_music, color: Colors.white),
          onPressed: () {},
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          player.currentSurah?.name ?? '',
          style: const TextStyle(color: Colors.white),
        ),
        titlePadding: const EdgeInsets.only(bottom: 16),
        centerTitle: true,
      ),
    );
  }

  Widget _buildNowPlaying(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Album art placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1DB954),
                    const Color(0xFF1AA34A),
                    const Color(0xFF15803D),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1DB954).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 100,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Surah info
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
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${player.currentSurah?.nameArabic} • ${player.currentSurah?.verses ?? 0} Ayat',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
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
                overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: player.duration.inSeconds > 0
                    ? player.position.inSeconds.toDouble()
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
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.shuffle, color: Colors.grey),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
              onPressed: () => player.rewind(),
            ),
            Consumer<AudioPlayerService>(
              builder: (context, p, _) {
                return IconButton(
                  icon: Icon(
                    p.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 64,
                  ),
                  onPressed: p.isPlaying ? () => p.pause() : () => p.resume(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
              onPressed: () => player.fastForward(),
            ),
            IconButton(
              icon: const Icon(Icons.repeat, color: Colors.grey),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBacksoundSection(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backsound',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Backsound.presets.map((backsound) {
                final isActive = player.isBacksoundActive(backsound.id);
                return Material(
                  color: isActive ? const Color(0xFF1DB954) : const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      player.registerBacksound(backsound);
                      player.toggleBacksound(backsound);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(backsound.icon, size: 16, color: isActive ? Colors.black : Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            backsound.name,
                            style: TextStyle(
                              color: isActive ? Colors.black : Colors.white,
                              fontSize: 12,
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

  Widget _buildLyricsSection(QuranApiService api) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ayat & Terjemahan',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari ayat...',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF282828),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fitur ini akan menampilkan teks Arab dan terjemahan per ayat.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
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
