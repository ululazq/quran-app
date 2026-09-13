import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/quran_api_service.dart';
import 'services/audio_player_service.dart';
import 'models/qari_model.dart';
import 'models/surah_model.dart';
import 'models/backsound_model.dart';
import 'widgets/surah_card.dart';
import 'widgets/qari_card.dart';
import 'screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final playerService = AudioPlayerService();
  await playerService.initialize();
  runApp(QuranApp(playerService: playerService));
}

class QuranApp extends StatelessWidget {
  final AudioPlayerService playerService;

  const QuranApp({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuranApiService()),
        ChangeNotifierProvider.value(value: playerService),
      ],
      child: MaterialApp(
        title: 'Quran App',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFF1DB954);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: const Color(0xFF121212),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF1AA34A),
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        onPrimary: Colors.black,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      listTileTheme: const ListTileThemeData(iconColor: Colors.grey, textColor: Colors.white),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Colors.grey[700],
        thumbColor: primary,
        overlayColor: primary.withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        titleLarge: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.grey, fontSize: 14),
        bodySmall: TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final apiService = context.read<QuranApiService>();
    await Future.wait([apiService.loadQaris(), apiService.loadSurahs()]);
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
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.auto_stories, size: 32, color: Color(0xFF1DB954)),
          const SizedBox(width: 12),
          const Text('Quran App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          Consumer<AudioPlayerService>(
            builder: (context, player, _) {
              if (player.currentSurah != null && player.isPlaying) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF1DB954), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.black, size: 18),
                        SizedBox(width: 6),
                        Text('Now Playing', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600)),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(
          color: Color(0xFF1DB954),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        tabs: const [
          Tab(text: 'Surah', icon: Icon(Icons.menu_book, size: 18)),
          Tab(text: 'Qari', icon: Icon(Icons.person, size: 18)),
          Tab(text: 'Backsound', icon: Icon(Icons.music_note, size: 18)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return const BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorit'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
      ],
    );
  }
}

class _SurahListView extends StatelessWidget {
  const _SurahListView();

  @override
  Widget build(BuildContext context) {
    return Consumer2<QuranApiService, AudioPlayerService>(
      builder: (context, api, player, _) {
        if (api.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
        if (api.error != null) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(api.error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => api.loadSurahs(), child: const Text('Coba Lagi')),
        ]));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: api.surahs.length,
          itemBuilder: (context, index) {
            final surah = api.surahs[index];
            final isSelected = player.currentSurah?.number == surah.number;
            return SurahCard(
              surah: surah,
              isSelected: isSelected,
              onTap: () {
                api.selectSurah(surah);
                if (player.currentQari != null) {
                  player.play(player.currentQari!, surah);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih Qari terlebih dahulu')));
                }
              },
            );
          },
        );
      },
    );
  }
}

class _QariListView extends StatelessWidget {
  const _QariListView();

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranApiService>(
      builder: (context, api, _) {
        if (api.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF1DB954)));
        if (api.qaris.isEmpty) return const Center(child: Text('Belum ada data Qari', style: TextStyle(color: Colors.grey)));
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5),
          itemCount: api.qaris.length,
          itemBuilder: (context, index) {
            final qari = api.qaris[index];
            return QariCard(
              qari: qari,
              isSelected: api.currentQari?.id == qari.id,
              onTap: () {
                api.selectQari(qari);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Qari dipilih: ${qari.name}'), backgroundColor: const Color(0xFF1DB954)));
              },
            );
          },
        );
      },
    );
  }
}

class _BacksoundView extends StatelessWidget {
  const _BacksoundView();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.3),
      itemCount: Backsound.presets.length,
      itemBuilder: (context, index) {
        final backsound = Backsound.presets[index];
        return BacksoundCard(backsound: backsound, onTap: () {
          final player = context.read<AudioPlayerService>();
          player.registerBacksound(backsound);
          player.toggleBacksound(backsound);
        });
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1DB954) : const Color(0xFF282828),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? const Color(0xFF1DB954) : Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(backsound.icon, size: 40, color: isActive ? Colors.black : Colors.white),
            const SizedBox(height: 8),
            Text(backsound.name, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.w500)),
            Text(backsound.nameAr, style: TextStyle(color: isActive ? Colors.black54 : Colors.white70, fontSize: 12)),
            if (isActive) const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.play_arrow, size: 16, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
