import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/quran_api_service.dart';
import '../models/qari_model.dart';
import '../models/backsound_model.dart';
import '../models/ayah_model.dart';
import '../widgets/ambient_background.dart';
import '../theme/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  final ScrollController _ayahScrollController = ScrollController();
  late PageController _pageController;
  late AnimationController _ayahAnimController;
  late Animation<double> _ayahAnim;
  List<Ayah> _loadedAyahs = [];
  List<VerseTiming> _loadedTimings = [];
  bool _isLoadingAyahs = false;
  bool _showAyahOverlay = false;
  int _lastLoadedSurah = -1;
  int _lastScrolledAyahIndex = -1;
  bool _isUserSwiping = false;

  @override
  void initState() {
    super.initState();
    final initialSurahNum = context.read<AudioPlayerService>().currentSurah?.number ?? 1;
    _pageController = PageController(initialPage: (initialSurahNum - 1).clamp(0, 113));
    _ayahAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _ayahAnim = CurvedAnimation(
      parent: _ayahAnimController,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAyahs();
    });
  }

  void _toggleAyahOverlay() {
    setState(() {
      _showAyahOverlay = !_showAyahOverlay;
      if (_showAyahOverlay) {
        _ayahAnimController.forward();
      } else {
        // Ensure PageController is precisely anchored to current surah without any horizontal swipe jump
        final currentSurahIdx = (context.read<AudioPlayerService>().currentSurah?.number ?? 1) - 1;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(currentSurahIdx);
        }
        _ayahAnimController.reverse();
      }
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
      final ayahsFuture = api.loadAyahs(surahNum);
      final qari = player.currentQari ?? api.currentQari ?? Qari.defaultQaris.first;
      final timingsFuture = api.loadVerseTimings(surahNum, qari);

      final results = await Future.wait([ayahsFuture, timingsFuture]);
      if (mounted) {
        setState(() {
          _loadedAyahs = results[0] as List<Ayah>;
          _loadedTimings = results[1] as List<VerseTiming>;
          _isLoadingAyahs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAyahs = false);
      }
    }
  }

  void _scrollToActiveAyah(int activeIndex) {
    if (!_showAyahOverlay || !_ayahScrollController.hasClients || _loadedAyahs.isEmpty) return;
    if (_lastScrolledAyahIndex == activeIndex) return;
    _lastScrolledAyahIndex = activeIndex;

    final targetOffset = ((activeIndex - 1) * 130.0).clamp(0.0, _ayahScrollController.position.maxScrollExtent);
    _ayahScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _ayahAnimController.dispose();
    _pageController.dispose();
    _ayahScrollController.dispose();
    super.dispose();
  }

  void _showPlaylistTopSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Daftar Putar',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        String searchQuery = '';

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
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
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              height: MediaQuery.of(context).size.height * 0.76,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D111D).withValues(alpha: 0.95),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
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
                                                    Navigator.pop(context);
                                                    final qari = player.currentQari ?? api.currentQari ?? Qari.defaultQaris.first;
                                                    player.play(qari, surah);
                                                    _fetchAyahs();
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Container(
                                      width: 44,
                                      height: 5,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
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
                ),
              ),
            ),
          ),
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

                              // 2. Integrated Ambient Backsound Volume Slider
                              Row(
                                children: [
                                  const Icon(
                                    Icons.spa_rounded,
                                    color: AppTheme.accentGoldLight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      activeBacksoundName != null
                                          ? 'Volume Suara Alam ($activeBacksoundName)'
                                          : 'Volume Suara Alam (Ambient)',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(player.ambientVolume * 100).round()}%',
                                    style: const TextStyle(
                                      color: AppTheme.accentGoldLight,
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
                                  value: player.ambientVolume,
                                  min: 0.0,
                                  max: 1.0,
                                  onChanged: (val) {
                                    player.setAmbientVolume(val);
                                  },
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


  int _calculateActiveAyahIndex(
    Duration position,
    Duration duration,
    List<Ayah> ayahs,
    List<VerseTiming> timings,
  ) {
    if (ayahs.isEmpty) return 1;
    final posMs = position.inMilliseconds;

    // 1. Exact Millisecond Timestamp Sync (Quran.com & Quranify standard)
    if (timings.isNotEmpty) {
      for (final t in timings) {
        if (posMs >= t.timestampFrom && posMs < t.timestampTo) {
          return t.verseNumber;
        }
      }
      if (posMs >= timings.last.timestampTo) {
        return timings.last.verseNumber;
      }
      return timings.first.verseNumber;
    }

    // 2. Fallback: Weighted syllable/character pacing algorithm
    if (duration.inMilliseconds <= 0 || posMs <= 0) return 1;
    final progress = (posMs / duration.inMilliseconds).clamp(0.0, 1.0);
    if (progress >= 0.999) return ayahs.length;

    final weights = ayahs.map((a) {
      final cleanLen = a.textArabic.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '').trim().length;
      return math.max(cleanLen, 8).toDouble();
    }).toList();

    final totalWeight = weights.fold<double>(0.0, (double sum, double w) => sum + w);
    if (totalWeight <= 0) return 1;

    final targetWeight = progress * totalWeight;
    double cumulative = 0.0;

    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (targetWeight <= cumulative) {
        return ayahs[i].numberInSurah;
      }
    }
    return ayahs.last.numberInSurah;
  }

  Duration _calculateAyahSeekPosition(
    int index,
    Duration duration,
    List<Ayah> ayahs,
    List<VerseTiming> timings,
  ) {
    if (ayahs.isEmpty) return Duration.zero;
    if (index <= 0) return Duration.zero;

    // 1. Exact millisecond seek
    if (timings.isNotEmpty) {
      final targetVerse = index + 1;
      final found = timings.firstWhere(
        (t) => t.verseNumber == targetVerse,
        orElse: () => timings[index.clamp(0, timings.length - 1)],
      );
      return Duration(milliseconds: found.timestampFrom);
    }

    // 2. Fallback weighted seek
    if (duration.inMilliseconds <= 0) return Duration.zero;
    if (index >= ayahs.length) return duration;

    final weights = ayahs.map((a) {
      final cleanLen = a.textArabic.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '').trim().length;
      return math.max(cleanLen, 8).toDouble();
    }).toList();

    final totalWeight = weights.fold<double>(0.0, (double sum, double w) => sum + w);
    if (totalWeight <= 0) return Duration.zero;

    double cumulative = 0.0;
    for (int i = 0; i < index; i++) {
      cumulative += weights[i];
    }

    final seekRatio = (cumulative / totalWeight).clamp(0.0, 1.0);
    return Duration(milliseconds: (seekRatio * duration.inMilliseconds).round());
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

          // Millisecond Accurate / Character-Weighted Active Ayah Calculation
          final activeAyahIndex = _calculateActiveAyahIndex(
            player.position,
            player.duration,
            _loadedAyahs,
            _loadedTimings,
          );

          // Active backsound id
          String? activeBacksoundId;
          for (final b in Backsound.presets) {
            if (player.isBacksoundActive(b.id)) {
              activeBacksoundId = b.id;
              break;
            }
          }

          final allSurahs = api.surahs.isNotEmpty ? api.surahs : player.surahList;

          // Keep PageController synced when surah changes externally
          final currentSurahIdx = (player.currentSurah?.number ?? 1) - 1;
          if (_pageController.hasClients &&
              _pageController.page?.round() != currentSurahIdx &&
              !_isUserSwiping) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients &&
                  _pageController.page?.round() != currentSurahIdx &&
                  !_isUserSwiping) {
                if (_showAyahOverlay) {
                  _pageController.jumpToPage(currentSurahIdx);
                } else {
                  _pageController.animateToPage(
                    currentSurahIdx,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                }
              }
            });
          }

          return Scaffold(
            backgroundColor: AppTheme.bgPrimary,
            body: Stack(
              children: [
                // Layer 1: Ambient Looping Background Video (Vivid & Clear)
                AmbientBackground(
                  activeBacksoundId: activeBacksoundId,
                  isPlaying: player.isPlaying,
                ),

                // Layer 2: Maximized Single-Screen Player Canvas
                SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(player, api),

                      // Center Canvas: Smooth Animated Transition between Centered Calligraphy and Frameless Ayah Reader
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _ayahAnim,
                          builder: (context, _) {
                            final animVal = _ayahAnim.value;
                            return Stack(
                              children: [
                                // 1. Gallery Carousel (Calligraphy Centered) - Slides up & fades out smoothly
                                Positioned.fill(
                                  child: Transform.translate(
                                    offset: Offset(0, -50 * animVal),
                                    child: Opacity(
                                      opacity: (1.0 - animVal).clamp(0.0, 1.0),
                                      child: IgnorePointer(
                                        ignoring: animVal > 0.5,
                                        child: _buildGalleryCarousel(player, api, allSurahs),
                                      ),
                                    ),
                                  ),
                                ),

                                // 2. Frameless Ayah Reader - Slides in from below & fades in seamlessly
                                Positioned.fill(
                                  child: Transform.translate(
                                    offset: Offset(0, 45 * (1.0 - animVal)),
                                    child: Opacity(
                                      opacity: animVal.clamp(0.0, 1.0),
                                      child: IgnorePointer(
                                        ignoring: animVal < 0.5,
                                        child: _buildFramelessAyahReader(player, _loadedAyahs, activeAyahIndex),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Bottom Playback Deck
                      _buildProgressBar(player),
                      _buildYouTubeStyleControls(player),
                      _buildSecondaryUtilityRow(player, api),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(AudioPlayerService player, QuranApiService api) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textPrimary,
              size: 34,
              shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.menu_book_rounded,
                  color: _showAyahOverlay ? AppTheme.primaryEmerald : AppTheme.textPrimary,
                  size: 22,
                  shadows: const [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
                tooltip: _showAyahOverlay ? 'Tutup Ayat' : 'Buka Ayat',
                onPressed: _toggleAyahOverlay,
              ),
              IconButton(
                icon: const Icon(
                  Icons.queue_music_rounded,
                  color: AppTheme.textPrimary,
                  size: 24,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
                tooltip: 'Daftar Putar Surah',
                onPressed: () => _showPlaylistTopSheet(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.textPrimary,
                  size: 24,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
                tooltip: 'Mixer & Suara Alam',
                onPressed: () => _showVolumeMixerBottomSheet(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Gallery-Style Carousel with real horizontal momentum, finger tracking, and animated transitions
  Widget _buildGalleryCarousel(
    AudioPlayerService player,
    QuranApiService api,
    List<dynamic> allSurahs,
  ) {
    final itemCount = allSurahs.isNotEmpty ? allSurahs.length : 114;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _isUserSwiping = true;
        } else if (notification is ScrollEndNotification) {
          _isUserSwiping = false;
        }
        return false;
      },
      child: PageView.builder(
        key: const ValueKey('gallery_carousel'),
        controller: _pageController,
        itemCount: itemCount,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (allSurahs.isNotEmpty && index < allSurahs.length) {
            final targetSurah = allSurahs[index];
            if (player.currentSurah?.number != targetSurah.number) {
              HapticFeedback.lightImpact();
              final qari = player.currentQari ?? api.currentQari ?? Qari.defaultQaris.first;
              player.play(qari, targetSurah);
              _fetchAyahs();
            }
          }
        },
        itemBuilder: (context, index) {
          final surah = (allSurahs.isNotEmpty && index < allSurahs.length)
              ? allSurahs[index]
              : null;
          final arabicTitle = surah?.nameArabic ?? (player.currentSurah?.nameArabic ?? '');
          final latinName = surah?.name ?? (player.currentSurah?.name ?? '');
          final qariName = player.currentQari?.name ?? 'Qari';

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    arabicTitle,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 28,
                          offset: Offset(0, 4),
                        ),
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 14,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    latinName,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mic_rounded,
                        color: AppTheme.primaryEmerald,
                        size: 15,
                        shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        qariName,
                        style: const TextStyle(
                          color: AppTheme.primaryEmeraldLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black87,
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Seamless, Frameless Ayah Reader blending 100% with the background canvas (Zero card boxes)
  Widget _buildFramelessAyahReader(
    AudioPlayerService player,
    List<Ayah> ayahs,
    int activeAyahIndex,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveAyah(activeAyahIndex);
    });

    return Column(
      children: [
        // Compact Top Header (Surah Calligraphy & Verse Count)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                player.currentSurah?.nameArabic ?? '',
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 16, offset: Offset(0, 2)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Ayat $activeAyahIndex/${ayahs.length}',
                  style: const TextStyle(
                    color: AppTheme.accentGoldLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Pure Frameless Scrollable Ayah List directly over canvas
        Expanded(
          child: _isLoadingAyahs && ayahs.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
                )
              : ayahs.isEmpty
                  ? const Center(
                      child: Text('Ayat tidak ditemukan', style: TextStyle(color: AppTheme.textTertiary)),
                    )
                  : ListView.builder(
                      controller: _ayahScrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: ayahs.length,
                      itemBuilder: (context, index) {
                        final ayah = ayahs[index];
                        final isCurrent = ayah.numberInSurah == activeAyahIndex && player.isPlaying;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final seekPos = _calculateAyahSeekPosition(index, player.duration, ayahs, _loadedTimings);
                              player.seek(seekPos);
                            },
                            splashColor: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                            highlightColor: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Minimal Verse Number Indicator & Action
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? AppTheme.accentGoldLight.withValues(alpha: 0.22)
                                              : Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isCurrent
                                                ? AppTheme.accentGoldLight.withValues(alpha: 0.6)
                                                : Colors.white.withValues(alpha: 0.12),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '${ayah.numberInSurah}',
                                              style: TextStyle(
                                                color: isCurrent ? AppTheme.accentGoldLight : AppTheme.textSecondary,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isCurrent) ...[
                                              const SizedBox(width: 4),
                                              const Icon(Icons.graphic_eq_rounded, size: 12, color: AppTheme.accentGoldLight),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: Icon(
                                          Icons.copy_rounded,
                                          size: 14,
                                          color: isCurrent ? AppTheme.accentGoldLight.withValues(alpha: 0.7) : Colors.white38,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        tooltip: 'Salin Ayat',
                                        onPressed: () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: '${ayah.textArabic}\n\n"${ayah.translation}" (QS. ${player.currentSurah?.name}: ${ayah.numberInSurah})',
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

                                  // Arabic Verse Text (Frameless, glowing highlight when active)
                                  Text(
                                    ayah.textArabic,
                                    textAlign: TextAlign.right,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      color: isCurrent ? AppTheme.accentGoldLight : Colors.white,
                                      fontSize: isCurrent ? 23 : 21,
                                      height: 1.95,
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                      shadows: isCurrent
                                          ? [
                                              Shadow(
                                                color: AppTheme.accentGold.withValues(alpha: 0.6),
                                                blurRadius: 18,
                                                offset: const Offset(0, 2),
                                              ),
                                              const Shadow(
                                                color: Colors.black87,
                                                blurRadius: 10,
                                                offset: Offset(0, 1),
                                              ),
                                            ]
                                          : const [
                                              Shadow(
                                                color: Colors.black87,
                                                blurRadius: 8,
                                                offset: Offset(0, 1),
                                              ),
                                            ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Translation Text (Crisp text floating directly on canvas)
                                  Text(
                                    ayah.translation,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.72),
                                      fontSize: 12.5,
                                      height: 1.45,
                                      fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black87,
                                          blurRadius: 8,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Divider(
                                    color: isCurrent
                                        ? AppTheme.accentGoldLight.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.08),
                                    height: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(AudioPlayerService player) {
    return Padding(
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Shuffle Button
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

          // 3. Big 68px Play / Pause Button with Emerald Radial Glow
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
    );
  }

  /// Secondary utility row with Favorite heart and active Sleep Timer indicator
  Widget _buildSecondaryUtilityRow(AudioPlayerService player, QuranApiService api) {
    final surahNum = player.currentSurah?.number ?? 1;
    final isFav = api.isFavorite(surahNum);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Favorite Button
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

          // 2. Sleep Timer indicator (if active)
          if (player.sleepTimerMinutes > 0)
            InkWell(
              onTap: () => _showVolumeMixerBottomSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
