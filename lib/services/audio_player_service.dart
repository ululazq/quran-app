import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../models/qari_model.dart';
import '../models/surah_model.dart';
import '../models/backsound_model.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _quranPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _backsounds = {};
  final Map<String, double> _volumes = {};

  List<Surah> _surahList = [];
  Surah? _currentSurah;
  Qari? _currentQari;
  String? _currentUrl;
  PlayerState _playerState = PlayerState(false, ProcessingState.idle);
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _autoPlayNext = true;
  Timer? _positionTimer;

  List<Surah> get surahList => _surahList;
  Surah? get currentSurah => _currentSurah;
  Qari? get currentQari => _currentQari;
  String? get currentUrl => _currentUrl;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isSeekable => _duration.inSeconds > 0;
  bool get autoPlayNext => _autoPlayNext;

  AudioPlayer get quranPlayer => _quranPlayer;

  void setSurahList(List<Surah> list) {
    _surahList = list;
    notifyListeners();
  }

  void setAutoPlayNext(bool value) {
    _autoPlayNext = value;
    notifyListeners();
  }

  void toggleAutoPlayNext() {
    _autoPlayNext = !_autoPlayNext;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Warning configuring audio session: $e');
    }

    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.quran.app.channel.audio',
        androidNotificationChannelName: 'Quran Playback',
        androidNotificationOngoing: true,
        androidShowNotificationBadge: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationClickStartsActivity: true,
      );
    } catch (e) {
      debugPrint('Warning initializing background audio service: $e');
    }

    _quranPlayer.playerStateStream.listen((state) {
      _playerState = state;
      _isPlaying = state.playing;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        if (_autoPlayNext) {
          playNext();
        }
      }
    });

    _quranPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _quranPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });
  }

  Future<void> play(Qari qari, Surah surah) async {
    _currentQari = qari;
    _currentSurah = surah;
    final url = _buildAudioUrl(qari, surah.number);
    _currentUrl = url;
    debugPrint('Playing audio URL: $url');

    try {
      await _quranPlayer.stop();
      await _quranPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: '${surah.number}',
            album: qari.name,
            title: surah.name,
            displaySubtitle: surah.nameArabic,
          ),
        ),
      );
      await _quranPlayer.play();
      _startPositionTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> playNext() async {
    if (_currentSurah == null) return;
    final qari = _currentQari ?? Qari.defaultQaris.first;

    if (_surahList.isNotEmpty) {
      final currentIndex = _surahList.indexWhere((s) => s.number == _currentSurah!.number);
      if (currentIndex >= 0 && currentIndex < _surahList.length - 1) {
        final nextSurah = _surahList[currentIndex + 1];
        await play(qari, nextSurah);
        return;
      } else if (currentIndex == _surahList.length - 1) {
        final nextSurah = _surahList.first;
        await play(qari, nextSurah);
        return;
      }
    }

    if (_currentSurah!.number < 114) {
      final nextNumber = _currentSurah!.number + 1;
      final fallbackSurah = Surah(
        number: nextNumber,
        name: 'Surah $nextNumber',
        nameArabic: '',
        verses: 0,
        revelationType: 'Makkiyah',
      );
      await play(qari, fallbackSurah);
    }
  }

  Future<void> playPrevious() async {
    if (_currentSurah == null) return;
    final qari = _currentQari ?? Qari.defaultQaris.first;

    if (_surahList.isNotEmpty) {
      final currentIndex = _surahList.indexWhere((s) => s.number == _currentSurah!.number);
      if (currentIndex > 0) {
        final prevSurah = _surahList[currentIndex - 1];
        await play(qari, prevSurah);
        return;
      } else if (currentIndex == 0) {
        final prevSurah = _surahList.last;
        await play(qari, prevSurah);
        return;
      }
    }

    if (_currentSurah!.number > 1) {
      final prevNumber = _currentSurah!.number - 1;
      final fallbackSurah = Surah(
        number: prevNumber,
        name: 'Surah $prevNumber',
        nameArabic: '',
        verses: 0,
        revelationType: 'Makkiyah',
      );
      await play(qari, fallbackSurah);
    }
  }

  Future<void> pause() async {
    await _quranPlayer.pause();
    _positionTimer?.cancel();
    notifyListeners();
  }

  Future<void> resume() async {
    await _quranPlayer.play();
    _startPositionTimer();
    notifyListeners();
  }

  Future<void> stop() async {
    await _quranPlayer.stop();
    _positionTimer?.cancel();
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _quranPlayer.seek(position);
    notifyListeners();
  }

  Future<void> fastForward() async {
    await seek(_position + const Duration(seconds: 10));
  }

  Future<void> rewind() async {
    await seek(_position - const Duration(seconds: 10));
  }

  // === Backsound Management ===
  final Set<String> _activeBacksoundIds = {};
  final Set<String> _loadingBacksoundIds = {};

  bool isBacksoundActive(String id) => _activeBacksoundIds.contains(id);
  bool isBacksoundLoading(String id) => _loadingBacksoundIds.contains(id);
  double getBacksoundVolume(String id) => _volumes[id] ?? 0.3;

  Future<void> toggleBacksound(Backsound backsound) async {
    if (_activeBacksoundIds.contains(backsound.id)) {
      await stopBacksound(backsound.id);
    } else {
      await playBacksound(backsound);
    }
  }

  Future<void> playBacksound(Backsound backsound) async {
    _activeBacksoundIds.add(backsound.id);
    _loadingBacksoundIds.add(backsound.id);
    final volume = _volumes[backsound.id] ?? backsound.defaultVolume;
    _volumes[backsound.id] = volume;
    notifyListeners();

    try {
      AudioPlayer? player = _backsounds[backsound.id];
      if (player == null) {
        player = AudioPlayer();
        _backsounds[backsound.id] = player;
        if (backsound.assetPath.startsWith('http')) {
          await player.setUrl(backsound.assetPath);
        } else {
          await player.setAsset(backsound.assetPath);
        }
        await player.setLoopMode(LoopMode.all);
      }
      await player.setVolume(volume);
      await player.play();
    } catch (e) {
      debugPrint('Error playing backsound ${backsound.id}: $e');
      _activeBacksoundIds.remove(backsound.id);
    } finally {
      _loadingBacksoundIds.remove(backsound.id);
      notifyListeners();
    }
  }

  Future<void> stopBacksound(String id) async {
    _activeBacksoundIds.remove(id);
    _loadingBacksoundIds.remove(id);
    notifyListeners();

    try {
      await _backsounds[id]?.pause();
    } catch (e) {
      debugPrint('Error pausing backsound $id: $e');
    }
  }

  Future<void> setBacksoundVolume(String id, double volume) async {
    _volumes[id] = volume;
    if (_activeBacksoundIds.contains(id)) {
      await _backsounds[id]?.setVolume(volume);
    }
    notifyListeners();
  }

  void stopAllBacksounds() {
    for (final id in _activeBacksoundIds.toList()) {
      _backsounds[id]?.pause();
    }
    _activeBacksoundIds.clear();
    _loadingBacksoundIds.clear();
    notifyListeners();
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _position = _quranPlayer.position;
      notifyListeners();
    });
  }

  String _buildAudioUrl(Qari qari, int surahNumber) {
    final padded = surahNumber.toString().padLeft(3, '0');
    if (qari.server.isNotEmpty) {
      final base = qari.server.endsWith('/') ? qari.server : '${qari.server}/';
      return '$base$padded.mp3';
    }
    return 'https://server8.mp3quran.net/afs/$padded.mp3';
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _quranPlayer.dispose();
    for (final player in _backsounds.values) {
      player.dispose();
    }
    super.dispose();
  }
}
