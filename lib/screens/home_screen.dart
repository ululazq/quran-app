import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../models/backsound_model.dart';
import '../models/qari_model.dart';
import '../theme/app_theme.dart';
import '../widgets/surah_card.dart';
import '../widgets/qari_card.dart';
import '../widgets/mini_player.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final apiService = context.read<QuranApiService>();
    final playerService = context.read<AudioPlayerService>();
    await Future.wait([
      apiService.loadQaris(),
      apiService.loadSurahs(),
    ]);
    if (mounted && apiService.surahs.isNotEmpty) {
      playerService.setSurahList(apiService.surahs);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(
                index: _selectedBottomNavIndex,
                children: [
                  _buildMainHome(),
                  const _FavoritesView(),
                  const _SettingsView(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildMainHome() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _QariListView(),
              _SurahListView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    String title = 'Al-Quran Digital';
    String subtitle = 'Dengarkan tilawah & backsound relaksasi alam';
    if (_selectedBottomNavIndex == 1) {
      title = 'Surah Favorit';
      subtitle = 'Daftar surah yang sering kamu dengarkan';
    }
    if (_selectedBottomNavIndex == 2) {
      title = 'Pengaturan';
      subtitle = 'Kualitas audio, sleep timer & preferensi';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.emeraldGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, size: 22, color: Colors.black),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppTheme.emeraldGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.record_voice_over_rounded, size: 16),
                SizedBox(width: 6),
                Text('Qari'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded, size: 16),
                SizedBox(width: 6),
                Text('Surah'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _selectedBottomNavIndex,
        onTap: (index) => setState(() => _selectedBottomNavIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_filled),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            activeIcon: Icon(Icons.favorite_rounded),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}

class _SurahListView extends StatefulWidget {
  const _SurahListView();

  @override
  State<_SurahListView> createState() => _SurahListViewState();
}

class _SurahListViewState extends State<_SurahListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuranApiService, AudioPlayerService>(
      builder: (context, api, player, _) {
        if (api.isLoading && api.surahs.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
          );
        }

        if (api.error != null && api.surahs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.amber, size: 48),
                  const SizedBox(height: 12),
                  Text(api.error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => api.loadSurahs(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter surahs
        final filteredSurahs = api.surahs.where((s) {
          final query = _searchQuery.toLowerCase();
          final matchesQuery = s.name.toLowerCase().contains(query) ||
              s.number.toString().contains(query) ||
              s.nameArabic.contains(query);

          if (!matchesQuery) return false;

          if (_selectedFilter == 'Makkiyah') {
            return s.revelationType.toLowerCase().contains('meccan') ||
                s.revelationType.toLowerCase().contains('makki');
          } else if (_selectedFilter == 'Madaniyah') {
            return s.revelationType.toLowerCase().contains('medinan') ||
                s.revelationType.toLowerCase().contains('madani');
          } else if (_selectedFilter == 'Juz \'Amma') {
            return s.number >= 78;
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Cari Surah (cth: Yasin, Al-Mulk, 36)...',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryEmerald, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textTertiary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 1.5),
                  ),
                ),
              ),
            ),

            // Category Chips (Semua, Makkiyah, Madaniyah, Juz Amma)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Semua', 'Makkiyah', 'Madaniyah', 'Juz \'Amma'].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedFilter = filter);
                        }
                      },
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),

            // Surahs List
            Expanded(
              child: filteredSurahs.isEmpty
                  ? const Center(
                      child: Text('Surah tidak ditemukan', style: TextStyle(color: AppTheme.textTertiary)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      itemCount: filteredSurahs.length,
                      itemBuilder: (context, index) {
                        final surah = filteredSurahs[index];
                        final isSelected = player.currentSurah?.number == surah.number;
                        return SurahCard(
                          surah: surah,
                          isSelected: isSelected,
                          onTap: () {
                            api.selectSurah(surah);
                            final qari = player.currentQari ?? api.currentQari ?? Qari.defaultQaris.first;
                            player.play(qari, surah);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PlayerScreen()),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _QariListView extends StatefulWidget {
  const _QariListView();

  @override
  State<_QariListView> createState() => _QariListViewState();
}

class _QariListViewState extends State<_QariListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuranApiService, AudioPlayerService>(
      builder: (context, api, player, _) {
        if (api.isLoading && api.qaris.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryEmerald));
        }

        final activeQari = player.currentQari ?? api.currentQari;
        final filteredQaris = api.qaris.where((q) {
          final query = _searchQuery.toLowerCase();
          return q.name.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Cari Qari (cth: Mishary, Sudais, Ghamdi)...',
                  hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryEmerald, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppTheme.textTertiary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.bgSurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.divider, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.primaryEmerald, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredQaris.isEmpty
                  ? const Center(
                      child: Text('Qari tidak ditemukan', style: TextStyle(color: AppTheme.textTertiary)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.18,
                      ),
                      itemCount: filteredQaris.length,
                      itemBuilder: (context, index) {
                        final qari = filteredQaris[index];
                        final isSelected = activeQari?.id == qari.id || activeQari?.name == qari.name;
                        return QariCard(
                          qari: qari,
                          isSelected: isSelected,
                          onTap: () {
                            api.selectQari(qari);
                            if (player.currentSurah != null) {
                              player.play(qari, player.currentSurah!);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Qari aktif diubah: ${qari.name}'),
                                backgroundColor: AppTheme.primaryEmerald,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class BacksoundCard extends StatelessWidget {
  final Backsound backsound;
  final VoidCallback onTap;

  const BacksoundCard({super.key, required this.backsound, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final isActive = player.isBacksoundActive(backsound.id);
    final isLoading = player.isBacksoundLoading(backsound.id);

    Color themeColor = AppTheme.primaryEmerald;
    if (backsound.id == 'rain') themeColor = const Color(0xFF38BDF8);
    if (backsound.id == 'ocean') themeColor = const Color(0xFF0284C7);
    if (backsound.id == 'wind') themeColor = const Color(0xFF2DD4BF);
    if (backsound.id == 'birds') themeColor = const Color(0xFF84CC16);
    if (backsound.id == 'night') themeColor = const Color(0xFF818CF8);
    if (backsound.id == 'fireplace') themeColor = const Color(0xFFF97316);

    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? themeColor.withValues(alpha: 0.15)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? themeColor : AppTheme.divider.withValues(alpha: 0.6),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: themeColor,
                    ),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isActive ? themeColor : AppTheme.bgElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      backsound.icon,
                      size: 24,
                      color: isActive ? Colors.black : Colors.white,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  backsound.name,
                  style: TextStyle(
                    color: isActive ? themeColor : AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  backsound.nameAr,
                  style: TextStyle(
                    color: isActive ? themeColor.withValues(alpha: 0.8) : AppTheme.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive ? themeColor.withValues(alpha: 0.2) : AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        size: 12,
                        color: isActive ? themeColor : AppTheme.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isActive ? 'Memutar' : 'Mati',
                        style: TextStyle(
                          fontSize: 10,
                          color: isActive ? themeColor : AppTheme.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesView extends StatelessWidget {
  const _FavoritesView();

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuranApiService, AudioPlayerService>(
      builder: (context, api, player, _) {
        final favoriteSurahs = api.favoriteSurahs;

        if (favoriteSurahs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.divider, width: 1),
                    ),
                    child: const Icon(Icons.favorite_border_rounded, size: 40, color: AppTheme.textTertiary),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Belum Ada Surah Favorit',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tandai surah yang kamu sukai dengan menekan icon hati pada halaman pemutar audio untuk akses instan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favoriteSurahs.length,
          itemBuilder: (context, index) {
            final surah = favoriteSurahs[index];
            final isSelected = player.currentSurah?.number == surah.number;
            return SurahCard(
              surah: surah,
              isSelected: isSelected,
              onTap: () {
                api.selectSurah(surah);
                final qari = player.currentQari ?? api.currentQari ?? Qari.defaultQaris.first;
                player.play(qari, surah);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PlayerScreen()),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  bool _backgroundPlayEnabled = true;
  String _selectedQuality = 'Standar (128 kbps)';

  void _setSleepTimer(int minutes) {
    final player = context.read<AudioPlayerService>();
    player.setSleepTimer(minutes);
    if (minutes > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sleep Timer aktif: Audio akan berhenti dalam $minutes menit.'),
          backgroundColor: AppTheme.primaryEmerald,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep Timer dimatikan.'),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kualitas Streaming Audio', style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Hemat Data (64 kbps)',
            'Standar (128 kbps)',
            'Kualitas Tinggi (192 kbps)',
          ].map((quality) {
            return RadioListTile<String>(
              title: Text(quality, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
              value: quality,
              groupValue: _selectedQuality,
              activeColor: AppTheme.primaryEmerald,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedQuality = val);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Kualitas audio diubah ke $val'),
                      backgroundColor: AppTheme.primaryEmerald,
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSleepTimerDialog() {
    final player = context.read<AudioPlayerService>();
    final currentMins = player.sleepTimerMinutes;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.timer_rounded, color: AppTheme.primaryEmerald),
            SizedBox(width: 8),
            Text('Sleep Timer (Mati Otomatis)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            0,
            15,
            30,
            45,
            60,
          ].map((mins) {
            final isSelected = currentMins == mins;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? AppTheme.primaryEmerald : Colors.grey,
              ),
              title: Text(
                mins == 0 ? 'Matikan Timer' : '$mins Menit',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _setSleepTimer(mins);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _clearCache() {
    context.read<QuranApiService>().clearMemoryCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache ayat dan memori sementara berhasil dibersihkan!'),
        backgroundColor: AppTheme.primaryEmerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: AppTheme.primaryEmerald),
            SizedBox(width: 10),
            Text('Tentang Quranizer', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aplikasi Al-Quran Digital Modern',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dilengkapi dengan tilawah dari Qari internasional terbaik, pemutar audio background tanpa henti, lirik ayat per ayat bahasa Indonesia, serta backsound relaksasi suara alam (hujan, ombak, angin, kicau burung, suasana malam, dan perapian).',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.code_rounded, color: AppTheme.primaryEmerald, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Pembuat / Kontributor:',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ululazq',
                          style: TextStyle(color: AppTheme.accentGoldLight, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppTheme.divider, height: 1),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: '085645567856'));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nomor 085645567856 berhasil disalin!'),
                            backgroundColor: AppTheme.primaryEmerald,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.volunteer_activism_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kritik, saran dan gopay hubungi 085645567856',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Icon(Icons.copy_rounded, size: 16, color: AppTheme.primaryEmerald),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sumber API: MP3Quran.net, AlQuran.cloud & Quran.com\nVersi 1.0.1 (Build 2)',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(color: AppTheme.primaryEmerald, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sleepMins = context.watch<AudioPlayerService>().sleepTimerMinutes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.emeraldGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Icon(Icons.auto_stories_rounded, color: Colors.black, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quranizer',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text('Dibuat oleh ululazq • Versi 1.0.1 (Build 2)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'PENGATURAN PEMUTARAN & AUDIO',
          style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 8),

        _buildActionTile(
          icon: Icons.headset_rounded,
          title: 'Pemutar Latar Belakang (Background)',
          subtitle: 'Audio tetap berputar saat layar mati atau membuka aplikasi lain',
          trailing: Switch(
            value: _backgroundPlayEnabled,
            activeColor: AppTheme.primaryEmerald,
            onChanged: (val) {
              setState(() => _backgroundPlayEnabled = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val
                      ? 'Pemutaran latar belakang aktif.'
                      : 'Pemutaran latar belakang dinonaktifkan.'),
                  backgroundColor: AppTheme.primaryEmerald,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          onTap: () {
            setState(() => _backgroundPlayEnabled = !_backgroundPlayEnabled);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_backgroundPlayEnabled
                    ? 'Pemutaran latar belakang aktif.'
                    : 'Pemutaran latar belakang dinonaktifkan.'),
                backgroundColor: AppTheme.primaryEmerald,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),

        _buildActionTile(
          icon: Icons.timer_outlined,
          title: 'Sleep Timer (Mati Otomatis)',
          subtitle: sleepMins > 0 ? 'Aktif: $sleepMins menit' : 'Tidak aktif',
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textTertiary),
          onTap: _showSleepTimerDialog,
        ),

        _buildActionTile(
          icon: Icons.high_quality_rounded,
          title: 'Kualitas Streaming Audio',
          subtitle: _selectedQuality,
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textTertiary),
          onTap: _showQualityDialog,
        ),

        const SizedBox(height: 20),
        const Text(
          'KONTRIBUTOR & DUKUNGAN',
          style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 8),

        _buildActionTile(
          icon: Icons.person_rounded,
          title: 'Pembuat / Kontributor',
          subtitle: 'ululazq',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.primaryEmerald.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'Creator',
              style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          onTap: _showAboutDialog,
        ),

        _buildActionTile(
          icon: Icons.volunteer_activism_rounded,
          title: 'Kritik, Saran & GoPay',
          subtitle: 'kritik, saran dan gopay hubungi 085645567856',
          trailing: const Icon(Icons.copy_rounded, color: AppTheme.primaryEmerald, size: 20),
          onTap: () {
            Clipboard.setData(const ClipboardData(text: '085645567856'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nomor 085645567856 berhasil disalin ke clipboard!'),
                backgroundColor: AppTheme.primaryEmerald,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        const Text(
          'PENYIMPANAN & APLIKASI',
          style: TextStyle(color: AppTheme.primaryEmerald, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 8),

        _buildActionTile(
          icon: Icons.cleaning_services_rounded,
          title: 'Bersihkan Cache Data',
          subtitle: 'Kosongkan memori sementara',
          trailing: const Icon(Icons.delete_outline_rounded, color: AppTheme.textTertiary),
          onTap: _clearCache,
        ),

        _buildActionTile(
          icon: Icons.info_outline_rounded,
          title: 'Tentang Aplikasi & Sumber API',
          subtitle: 'Informasi lisensi dan pengembang',
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textTertiary),
          onTap: _showAboutDialog,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: AppTheme.primaryEmerald, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
