import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchAyahQuery = '';
  List<Ayah> _loadedAyahs = [];
  bool _isLoadingAyahs = false;
  int _lastLoadedSurah = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAyahs();
    });
  }

  void _fetchAyahs() async {
    final player = context.read<AudioPlayerService>();
    final api = context.read<QuranApiService>();
    final surahNum = player.currentSurah?.number ?? 1;

    if (_lastLoadedSurah == surahNum && _loadedAyahs.isNotEmpty) return;

    setState(() => _isLoadingAyahs = true);
    final ayahs = await api.loadAyahs(surahNum);
    if (mounted) {
      setState(() {
        _loadedAyahs = ayahs;
        _lastLoadedSurah = surahNum;
        _isLoadingAyahs = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Consumer2<AudioPlayerService, QuranApiService>(
          builder: (context, player, api, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: AppTheme.primaryEmerald, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Pengaturan Pemutaran & Suara',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sleep Timer Quick Selection
                    const Text(
                      'SLEEP TIMER (MATI OTOMATIS)',
                      style: TextStyle(
                        color: AppTheme.primaryEmerald,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [0, 15, 30, 45, 60].map((mins) {
                          final isSelected = player.sleepTimerMinutes == mins;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(mins == 0 ? 'Matikan' : '$mins Menit'),
                              selected: isSelected,
                              selectedColor: AppTheme.primaryEmerald,
                              backgroundColor: AppTheme.bgSurface,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.black : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryEmerald : AppTheme.divider,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              showCheckmark: false,
                              onSelected: (selected) {
                                if (selected) {
                                  player.setSleepTimer(mins);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        mins == 0
                                            ? 'Sleep Timer dimatikan'
                                            : 'Sleep Timer aktif: Audio berhenti dalam $mins menit',
                                      ),
                                      backgroundColor: AppTheme.primaryEmerald,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Backsound Quick Picker
                    const Text(
                      'PILIH SUARA ALAM (BACKSOUND)',
                      style: TextStyle(
                        color: AppTheme.primaryEmerald,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Backsound.presets.map((b) {
                        final isActive = player.isBacksoundActive(b.id);
                        return ChoiceChip(
                          avatar: Icon(
                            b.icon,
                            size: 16,
                            color: isActive ? Colors.black : AppTheme.textPrimary,
                          ),
                          label: Text(b.name.split(' ').first),
                          selected: isActive,
                          selectedColor: AppTheme.primaryEmerald,
                          backgroundColor: AppTheme.bgSurface,
                          labelStyle: TextStyle(
                            color: isActive ? Colors.black : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isActive ? AppTheme.primaryEmerald : AppTheme.divider,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          showCheckmark: false,
                          onSelected: (_) {
                            player.toggleBacksound(b);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

          // Auto update ayahs when surah changes
          if (player.currentSurah?.number != _lastLoadedSurah) {
            _fetchAyahs();
          }

          final filteredAyahs = _loadedAyahs.where((a) {
            final q = _searchAyahQuery.toLowerCase();
            return a.textArabic.contains(q) ||
                a.translation.toLowerCase().contains(q) ||
                a.numberInSurah.toString().contains(q);
          }).toList();

          // Estimated active ayah index
          int activeAyahIndex = 1;
          if (player.duration.inSeconds > 0 && _loadedAyahs.isNotEmpty) {
            final progress = player.position.inMilliseconds / player.duration.inMilliseconds;
            activeAyahIndex = (progress * _loadedAyahs.length).floor() + 1;
            if (activeAyahIndex > _loadedAyahs.length) activeAyahIndex = _loadedAyahs.length;
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(player, api),
              _buildNowPlaying(player),
              _buildVisualizer(player),
              _buildProgressBar(player),
              _buildYouTubeStyleControls(player),
              _buildSecondaryUtilityRow(player, api),
              _buildLyricsHeader(),
              
              // High-Performance Virtualized SliverList (Zero Lag on 200+ verses!)
              if (_isLoadingAyahs && _loadedAyahs.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
                    ),
                  ),
                )
              else if (filteredAyahs.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('Ayat tidak ditemukan', style: TextStyle(color: AppTheme.textTertiary)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ayah = filteredAyahs[index];
                        final isCurrentAyah = ayah.numberInSurah == activeAyahIndex && player.isPlaying;

                        return Container(
                          key: ValueKey('ayah_${ayah.numberInSurah}'),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCurrentAyah
                                ? AppTheme.primaryEmerald.withValues(alpha: 0.12)
                                : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrentAyah
                                  ? AppTheme.primaryEmerald.withValues(alpha: 0.5)
                                  : AppTheme.divider.withValues(alpha: 0.5),
                              width: isCurrentAyah ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Number & Copy Button
                              Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
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
                                          content: Text('Ayat ${ayah.numberInSurah} disalin'),
                                          duration: const Duration(seconds: 1),
                                          backgroundColor: AppTheme.primaryEmerald,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Arabic text (Uthmani)
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

                              // Indonesian Translation
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
                      childCount: filteredAyahs.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 56)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AudioPlayerService player, QuranApiService api) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.bgPrimary,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textPrimary, size: 34),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textPrimary, size: 24),
          tooltip: 'Pengaturan Audio & Timer',
          onPressed: () => _showSettingsBottomSheet(context),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            // Album art with glowing emerald gradient
            Container(
              width: 160,
              height: 160,
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
                    width: 130,
                    height: 130,
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
                    size: 68,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

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
            const SizedBox(height: 4),

            // Qari Name
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: BacksoundVisualizer(
          activeBacksoundId: activeId,
          isPlaying: player.isPlaying,
          height: 44,
        ),
      ),
    );
  }

  Widget _buildProgressBar(AudioPlayerService player) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
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

  /// Exact 5-Button Control Deck like YouTube Music & Spotify
  Widget _buildYouTubeStyleControls(AudioPlayerService player) {
    IconData loopIcon = Icons.repeat_rounded;
    Color loopColor = AppTheme.textTertiary;
    if (player.loopMode == QuranLoopMode.all) {
      loopIcon = Icons.repeat_rounded;
      loopColor = AppTheme.primaryEmerald;
    } else if (player.loopMode == QuranLoopMode.one) {
      loopIcon = Icons.repeat_one_rounded;
      loopColor = AppTheme.primaryEmerald;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 1. Shuffle / Randomize Button
            IconButton(
              icon: Icon(
                Icons.shuffle_rounded,
                color: player.isShuffle ? AppTheme.primaryEmerald : AppTheme.textTertiary,
                size: 26,
              ),
              tooltip: player.isShuffle ? 'Acak: Aktif' : 'Acak: Nonaktif',
              onPressed: () => player.toggleShuffle(),
            ),

            // 2. Previous Surah
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, color: AppTheme.textPrimary, size: 36),
              tooltip: 'Surah Sebelumnya',
              onPressed: () => player.playPrevious(),
            ),

            // 3. Big 70px Play / Pause Button with Emerald Radial Glow
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

            // 4. Next Surah
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, color: AppTheme.textPrimary, size: 36),
              tooltip: 'Surah Selanjutnya',
              onPressed: () => player.playNext(),
            ),

            // 5. Repeat / Loop Button
            IconButton(
              icon: Icon(
                loopIcon,
                color: loopColor,
                size: 26,
              ),
              tooltip: player.loopMode == QuranLoopMode.one
                  ? 'Ulangi 1 Surah'
                  : (player.loopMode == QuranLoopMode.all ? 'Ulangi Semua' : 'Loop Mati'),
              onPressed: () => player.toggleLoopMode(),
            ),
          ],
        ),
      ),
    );
  }

  /// Secondary utility row with Favorite heart aligned horizontally, Backsound badge, and Sleep timer status
  Widget _buildSecondaryUtilityRow(AudioPlayerService player, QuranApiService api) {
    final surahNum = player.currentSurah?.number ?? 1;
    final isFav = api.isFavorite(surahNum);

    // Active backsound name
    String? activeBacksoundName;
    for (final b in Backsound.presets) {
      if (player.isBacksoundActive(b.id)) {
        activeBacksoundName = b.name.split(' ').first;
        break;
      }
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Favorite Button (Moved down from header)
            InkWell(
              onTap: () => api.toggleFavorite(surahNum),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.redAccent : AppTheme.textTertiary,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isFav ? 'Favorit' : 'Sukai',
                      style: TextStyle(
                        color: isFav ? Colors.redAccent : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Backsound status pill
            InkWell(
              onTap: () => _showSettingsBottomSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeBacksoundName != null
                      ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                      : AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: activeBacksoundName != null ? AppTheme.primaryEmerald : AppTheme.divider,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.spa_rounded,
                      size: 14,
                      color: activeBacksoundName != null ? AppTheme.primaryEmerald : AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activeBacksoundName ?? 'Backsound',
                      style: TextStyle(
                        fontSize: 11,
                        color: activeBacksoundName != null ? AppTheme.primaryEmerald : AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sleep Timer indicator
            if (player.sleepTimerMinutes > 0)
              InkWell(
                onTap: () => _showSettingsBottomSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryEmerald, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_rounded, size: 14, color: AppTheme.primaryEmerald),
                      const SizedBox(width: 4),
                      Text(
                        '${player.sleepTimerMinutes}m',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryEmerald,
                          fontWeight: FontWeight.bold,
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

  Widget _buildLyricsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.lyrics_rounded, color: AppTheme.primaryEmerald, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Lirik Ayat & Terjemahan',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchAyahQuery = val),
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Cari ayat...',
                    hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    isDense: true,
                    border: InputBorder.none,
                    suffixIcon: _searchAyahQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 14, color: AppTheme.textTertiary),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchAyahQuery = '');
                            },
                          )
                        : null,
                  ),
                ),
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
