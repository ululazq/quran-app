import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/quran_api_service.dart';
import 'services/audio_player_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

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
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
