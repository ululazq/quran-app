import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/quran_api_service.dart';
import '../models/qari_model.dart';
import '../models/backsound_model.dart';
import '../models/ayah_model.dart';
import '../widgets/backsound_visualizer.dart';
import '../widgets/ambient_background.dart';
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
    if (!mounted) return;
    final player = context.read<AudioPlayerService>();
    final api = context.read<QuranApiService>();
    final surahNum = player.currentSurah?.number ?? 1;

    if (_lastLoadedSurah == surahNum && _loadedAyahs.isNotEmpty) return;
    if (_isLoadingAyahs) return;

    _lastLoadedSurah = surahNum;
    setState(() => _isLoadingAyahs = true);

    try {
      final ayahs = await api.loadAyahs(surahNum);
      if (mounted) {
        setState(() {
          _loadedAyahs = ayahs;
          _isLoadingAyahs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAyahs = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showPlaylistBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Consumer2<AudioPlayerService, QuranApiService>(
              builder: (context, player, api, _) {
                final allSurahs = api.surahs.isNotEmpty ? api.surahs : player.surahList;
                final filteredSurahs = allSurahs.where((s) {
                  final q = searchQuery.toLowerCase();
                  return s.name.toLowerCase().contains(q) ||
                      s.nameArabic.contains(q) ||
                      s.number.toString().contains(q) ||
                      s.revelationType.toLowerCase().contains(q);
                }).toList();

                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.78,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D111D).withValues(alpha: 0.94),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Handle bar
                          Center(
                            child: Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Header Row
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.queue_music_rounded,
                                    color: AppTheme.primaryEmerald,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Daftar Putar Surah',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${filteredSurahs.length} dari ${allSurahs.length} Surah • ${player.currentQari?.name ?? "Qari"}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: AppTheme.textTertiary, size: 22),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Glassmorphic Search Bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: searchQuery.isNotEmpty
                                      ? AppTheme.primaryEmerald.withValues(alpha: 0.6)
                                      : AppTheme.divider.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  setSheetState(() => searchQuery = val);
                                },
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Cari surah (nama, no, arab)...',
                                  hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                                  suffixIcon: searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textTertiary),
                                          onPressed: () {
                                            setSheetState(() => searchQuery = '');
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Divider(color: AppTheme.divider, height: 1),

                          // Virtualized Surah List
                          Expanded(
                            child: filteredSurahs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Surah tidak ditemukan',
                                      style: TextStyle(color: AppTheme.textTertiary),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    itemCount: filteredSurahs.length,
                                    itemBuilder: (context, index) {
                                      final surah = filteredSurahs[index];
                                      final isPlaying = player.currentSurah?.number == surah.number;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: isPlaying
                                              ? AppTheme.primaryEmerald.withValues(alpha: 0.16)
                                              : Colors.white.withValues(alpha: 0.03),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isPlaying
                                                ? AppTheme.primaryEmerald.withValues(alpha: 0.6)
                                                : Colors.white.withValues(alpha: 0.05),
                                            width: isPlaying ? 1.5 : 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                          leading: Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: isPlaying ? AppTheme.emeraldGradient : null,
                                              color: isPlaying ? null : AppTheme.bgElevated,
                                            ),
                                            child: Center(
                                              child: isPlaying
                                                  ? const Icon(
                                                      Icons.graphic_eq_rounded,
                                                      color: Colors.black,
                                                      size: 20,
                                                    )
                                                  : Text(
                                                      '${surah.number}',
                                                      style: const TextStyle(
                                                        color: AppTheme.accentGoldLight,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  surah.name,
                                                  style: TextStyle(
                                                    color: isPlaying
                                                        ? AppTheme.primaryEmeraldLight
                                                        : AppTheme.textPrimary,
                                                    fontSize: 15,
                                                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (isPlaying)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryEmerald,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'DIPUTAR',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 0.6,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            '${surah.revelationType} • ${surah.verses} Ayat',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: Text(
                                            surah.nameArabic,
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                              color: isPlaying
                                                  ? AppTheme.accentGoldLight
                                                  : AppTheme.textSecondary,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(ctx);
                                            final qari = player.currentQari ?? api.currentQari ?? Qari.defaultQaris.first;
                                            player.play(qari, surah);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showVolumeMixerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D111D).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
              child: Consumer2<AudioPlayerService, QuranApiService>(
                builder: (context, player, api, _) {
                  final activeBacksoundId = player.activeBacksoundId;
                  String? activeBacksoundName;
                  for (final b in Backsound.presets) {
                    if (b.id == activeBacksoundId) {
                      activeBacksoundName = b.name;
                      break;
                    }
                  }

                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handle Bar
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: AppTheme.primaryEmerald,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Mixer & Pengaturan Audio',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppTheme.textTertiary, size: 22),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // === DUAL VOLUME MIXER CARD ===
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.divider, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Qari Tilawah Volume Slider
                              Row(
                                children: [
                                  const Icon(Icons.record_voice_over_rounded, color: AppTheme.primaryEmerald, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Volume Tilawah (${player.currentQari?.name.split(' ').first ?? 'Qari'})',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(player.quranVolume * 100).round()}%',
                                    style: const TextStyle(
                                      color: AppTheme.primaryEmerald,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppTheme.primaryEmerald,
                                  inactiveTrackColor: AppTheme.bgElevated,
                                  thumbColor: Colors.white,
                                  overlayColor: AppTheme.primaryEmerald.withValues(alpha: 0.2),
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: player.quranVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) {
                                    player.setQuranVolume(val);
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 2. Ambient Backsound Volume Slider
                              Row(
                                children: [
                                  Icon(
                                    Icons.spa_rounded,
                                    color: activeBacksoundId != null ? AppTheme.accentGoldLight : AppTheme.textTertiary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      activeBacksoundName != null
                                          ? 'Volume Suara ($activeBacksoundName)'
                                          : 'Volume Suara Alam (Nonaktif)',
                                      style: TextStyle(
                                        color: activeBacksoundId != null ? AppTheme.textPrimary : AppTheme.textTertiary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    activeBacksoundId != null
                                        ? '${(player.activeBacksoundVolume * 100).round()}%'
                                        : '0%',
                                    style: TextStyle(
                                      color: activeBacksoundId != null ? AppTheme.accentGoldLight : AppTheme.textTertiary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SliderTheme(
                                data: SliderThemeData(
                                  activeTrackColor: AppTheme.accentGoldLight,
                                  inactiveTrackColor: AppTheme.bgElevated,
                                  thumbColor: Colors.white,
                                  overlayColor: AppTheme.accentGoldLight.withValues(alpha: 0.2),
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: activeBacksoundId != null ? player.activeBacksoundVolume : 0.0,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: activeBacksoundId != null
                                      ? (val) {
                                          player.setBacksoundVolume(activeBacksoundId, val);
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // === AMBIENT SOUND PRESETS ===
                        const Text(
                          'PILIH SUARA ALAM (BACKSOUND LOOP)',
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
                          children: [
                            ...Backsound.presets.map((b) {
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
                            }),
                            if (activeBacksoundId != null)
                              ActionChip(
                                avatar: const Icon(Icons.volume_off_rounded, size: 16, color: Colors.redAccent),
                                label: const Text('Matikan'),
                                backgroundColor: AppTheme.bgSurface,
                                labelStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                onPressed: () {
                                  player.stopAllBacksounds();
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // === SLEEP TIMER ===
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
                            children: [0, 15, 30, 45, 60, 90].map((mins) {
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
                                                : 'Sleep Timer aktif: Berhenti dalam $mins menit',
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
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
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

          // Auto update ayahs safely when surah changes
          if (player.currentSurah != null &&
              player.currentSurah!.number != _lastLoadedSurah &&
              !_isLoadingAyahs) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _fetchAyahs();
            });
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

          // Active backsound id
          String? activeBacksoundId;
          for (final b in Backsound.presets) {
            if (player.isBacksoundActive(b.id)) {
              activeBacksoundId = b.id;
              break;
            }
          }

          return Stack(
            children: [
              // Dynamic Atmospheric Looping Visualizer
              AmbientBackground(
                activeBacksoundId: activeBacksoundId,
                isPlaying: player.isPlaying,
              ),

              // Foreground Scroll Content
              CustomScrollView(
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
                                    ? AppTheme.primaryEmerald.withValues(alpha: 0.16)
                                    : AppTheme.bgCard.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCurrentAyah
                                      ? AppTheme.primaryEmerald.withValues(alpha: 0.6)
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
              ),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textPrimary, size: 34),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.queue_music_rounded, color: AppTheme.textPrimary, size: 24),
          tooltip: 'Daftar Putar Surah',
          onPressed: () => _showPlaylistBottomSheet(context),
        ),
        IconButton(
          icon: const Icon(Icons.tune_rounded, color: AppTheme.textPrimary, size: 24),
          tooltip: 'Mixer & Suara Alam',
          onPressed: () => _showVolumeMixerBottomSheet(context),
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

  /// Secondary utility row with Favorite heart aligned horizontally, Playlist pill, Backsound & Mixer badge, and Sleep timer status
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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

            // Playlist Pill
            InkWell(
              onTap: () => _showPlaylistBottomSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.divider, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.queue_music_rounded, size: 15, color: AppTheme.primaryEmerald),
                    SizedBox(width: 5),
                    Text(
                      'Playlist',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Backsound & Mixer status pill
            InkWell(
              onTap: () => _showVolumeMixerBottomSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      Icons.tune_rounded,
                      size: 15,
                      color: activeBacksoundName != null ? AppTheme.primaryEmerald : AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      activeBacksoundName ?? 'Mixer',
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
                onTap: () => _showVolumeMixerBottomSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
