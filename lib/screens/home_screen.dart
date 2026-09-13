import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quran_api_service.dart';
import '../services/audio_player_service.dart';
import '../models/backsound_model.dart';
import '../models/qari_model.dart';
import '../widgets/surah_card.dart';
import '../widgets/qari_card.dart';
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
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final apiService = context.read<QuranApiService>();
    await Future.wait([
      apiService.loadQaris(),
      apiService.loadSurahs(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      bottomNavigationBar: _buildBottomNav(),
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
              _SurahListView(),
              _QariListView(),
              _BacksoundView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    String title = 'Quran App';
    if (_selectedBottomNavIndex == 1) title = 'Surah Favorit';
    if (_selectedBottomNavIndex == 2) title = 'Pengaturan';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, size: 28, color: Color(0xFF1DB954)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Consumer<AudioPlayerService>(
            builder: (context, player, _) {
              if (player.currentSurah != null && player.isPlaying) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlayerScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DB954),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.equalizer, color: Colors.black, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Now Playing',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(
          color: Color(0xFF1DB954),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'Surah', icon: Icon(Icons.menu_book, size: 18)),
          Tab(text: 'Qari', icon: Icon(Icons.person, size: 18)),
          Tab(text: 'Backsound', icon: Icon(Icons.music_note, size: 18)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedBottomNavIndex,
      onTap: (index) => setState(() => _selectedBottomNavIndex = index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
      ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuranApiService, AudioPlayerService>(
      builder: (context, api, player, _) {
        if (api.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
        }

        if (api.error != null && api.surahs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(api.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => api.loadSurahs(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        final filteredSurahs = api.surahs.where((s) {
          final query = _searchQuery.toLowerCase();
          return s.name.toLowerCase().contains(query) ||
              s.number.toString().contains(query) ||
              s.nameArabic.contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari Surah (cth: Yasin, Al-Mulk, 36)...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF282828),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredSurahs.isEmpty
                  ? const Center(
                      child: Text('Surah tidak ditemukan', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
        }

        final activeQari = player.currentQari ?? api.currentQari;
        final filteredQaris = api.qaris.where((q) {
          final query = _searchQuery.toLowerCase();
          return q.name.toLowerCase().contains(query);
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari Qari (cth: Mishary, Sudais, Ghamdi)...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF282828),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredQaris.isEmpty
                  ? const Center(
                      child: Text('Qari tidak ditemukan', style: TextStyle(color: Colors.grey)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.4,
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
                                content: Text('Qari aktif: ${qari.name}'),
                                backgroundColor: const Color(0xFF1DB954),
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

class _BacksoundView extends StatelessWidget {
  const _BacksoundView();

  @override
  Widget build(BuildContext context) {
    final backsounds = Backsound.presets;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: backsounds.length,
      itemBuilder: (context, index) {
        final backsound = backsounds[index];
        return BacksoundCard(
          backsound: backsound,
          onTap: () {
            final player = context.read<AudioPlayerService>();
            player.toggleBacksound(backsound);
          },
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1DB954) : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF1DB954) : Colors.transparent,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              Icon(
                backsound.icon,
                size: 36,
                color: isActive ? Colors.black : Colors.white,
              ),
            const SizedBox(height: 8),
            Text(
              backsound.name,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              backsound.nameAr,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.volume_up : Icons.volume_mute,
                  size: 14,
                  color: isActive ? Colors.black : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Aktif' : 'Mati',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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
                  Icon(Icons.favorite_border, size: 72, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum Ada Surah Favorit',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tandai surah favorit kamu dengan menekan icon hati di halaman pemutar audio untuk akses cepat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
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

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // App Info Card
        Card(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF1DB954),
                  radius: 28,
                  child: Icon(Icons.auto_stories, color: Colors.black, size: 28),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quran App',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text('Versi 1.0.0 (Release)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Fitur & Audio',
          style: TextStyle(color: Color(0xFF1DB954), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildSettingTile(
          icon: Icons.headset,
          title: 'Pemutar Audio Background',
          subtitle: 'Audio tetap berputar saat aplikasi di latar belakang atau layar mati',
          trailing: const Icon(Icons.check_circle, color: Color(0xFF1DB954), size: 20),
        ),
        _buildSettingTile(
          icon: Icons.cloud_done,
          title: 'Sumber Data Qari & Surah',
          subtitle: 'MP3Quran.net & Al-Quran Cloud API',
          trailing: const Icon(Icons.cloud_queue, color: Colors.grey, size: 20),
        ),
        _buildSettingTile(
          icon: Icons.music_note,
          title: 'Mode Suara Alam (Backsound)',
          subtitle: 'Hujan, Ombak, Angin, Burung, Api Unggun & Malam',
          trailing: const Icon(Icons.spa, color: Color(0xFF1DB954), size: 20),
        ),

        const SizedBox(height: 20),
        const Text(
          'Aplikasi',
          style: TextStyle(color: Color(0xFF1DB954), fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildSettingTile(
          icon: Icons.dark_mode,
          title: 'Tema Aplikasi',
          subtitle: 'Gelap (Spotify Green Dark Theme)',
          trailing: const Icon(Icons.brightness_2, color: Colors.grey, size: 20),
        ),
        _buildSettingTile(
          icon: Icons.info_outline,
          title: 'Tentang Aplikasi',
          subtitle: 'Aplikasi Al-Quran Audio dengan pilihan Qari dan Backsound Relaksasi Alam',
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
  }) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1DB954)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)) : null,
        trailing: trailing,
      ),
    );
  }
}
