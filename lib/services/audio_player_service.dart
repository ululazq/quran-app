import 'dart:async';
import 'dart:math';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/foundation.dart';
import '../models/qari_model.dart';
import '../models/surah_model.dart';
import '../models/backsound_model.dart';

enum QuranLoopMode {
  all, // Loop playlist / Auto-advance
  one, // Repeat current surah
  off, // Stop after current surah
}

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _quranPlayer = AudioPlayer();
  final Map<String, ap.AudioPlayer> _backsounds = {};
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
  bool _isShuffle = false;
  QuranLoopMode _loopMode = QuranLoopMode.all;
  bool _isChangingTrack = false;
  Timer? _positionTimer;
  Timer? _sleepTimer;
  int _sleepTimerMinutes = 0;

  List<Surah> get surahList => _surahList;
  Surah? get currentSurah => _currentSurah;
  Qari? get currentQari => _currentQari;
  String? get currentUrl => _currentUrl;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isChangingTrack => _isChangingTrack;
  bool get isSeekable => _duration.inSeconds > 0;
  bool get autoPlayNext => _autoPlayNext;
  bool get isShuffle => _isShuffle;
  QuranLoopMode get loopMode => _loopMode;
  int get sleepTimerMinutes => _sleepTimerMinutes;

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

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    notifyListeners();
  }

  void toggleLoopMode() {
    switch (_loopMode) {
      case QuranLoopMode.all:
        _loopMode = QuranLoopMode.one;
        break;
      case QuranLoopMode.one:
        _loopMode = QuranLoopMode.off;
        break;
      case QuranLoopMode.off:
        _loopMode = QuranLoopMode.all;
        break;
    }
    notifyListeners();
  }

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    notifyListeners();

    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        pause();
        stopAllBacksounds();
        _sleepTimerMinutes = 0;
        notifyListeners();
      });
    }
  }

  Future<void> initialize() async {
    try {
      final audioContext = ap.AudioContext(
        android: const ap.AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: ap.AndroidContentType.music,
          usageType: ap.AndroidUsageType.media,
          audioFocus: ap.AndroidAudioFocus.none,
        ),
        iOS: ap.AudioContextIOS(
          category: ap.AVAudioSessionCategory.ambient,
          options: const {
            ap.AVAudioSessionOptions.mixWithOthers,
          },
        ),
      );
      await ap.AudioPlayer.global.setAudioContext(audioContext);
    } catch (e) {
      debugPrint('Warning configuring audioplayers context: $e');
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
      if (!_isChangingTrack) {
        _isPlaying = state.playing;
      }
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        if (_isChangingTrack) return;

        if (_loopMode == QuranLoopMode.one) {
          // Replay current surah
          seek(Duration.zero).then((_) => resume());
        } else if (_loopMode == QuranLoopMode.all || _autoPlayNext) {
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
    if (_isChangingTrack) return;
    _isChangingTrack = true;
    _currentQari = qari;
    _currentSurah = surah;
    _isPlaying = true;
    notifyListeners();

    final url = _buildAudioUrl(qari, surah.number);
    _currentUrl = url;
    debugPrint('Playing audio URL: $url');

    try {
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
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _isPlaying = false;
    } finally {
      _isChangingTrack = false;
      notifyListeners();
    }
  }

  Future<void> playNext() async {
    if (_currentSurah == null || _isChangingTrack) return;
    final qari = _currentQari ?? Qari.defaultQaris.first;

    if (_isShuffle && _surahList.isNotEmpty && _surahList.length > 1) {
      final random = Random();
      int randomIndex;
      do {
        randomIndex = random.nextInt(_surahList.length);
      } while (_surahList[randomIndex].number == _currentSurah!.number);
      await play(qari, _surahList[randomIndex]);
      return;
    }

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
    } else {
      const fallbackSurah = Surah(
        number: 1,
        name: 'Al-Fatihah',
        nameArabic: 'الفاتحة',
        verses: 7,
        revelationType: 'Makkiyah',
      );
      await play(qari, fallbackSurah);
    }
  }

  Future<void> playPrevious() async {
    if (_currentSurah == null || _isChangingTrack) return;
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
    } else {
      const fallbackSurah = Surah(
        number: 114,
        name: 'An-Nas',
        nameArabic: 'الناس',
        verses: 6,
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
    _currentSurah = null;
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
    for (final otherId in _activeBacksoundIds.toList()) {
      if (otherId != backsound.id) {
        await stopBacksound(otherId);
      }
    }

    _activeBacksoundIds.add(backsound.id);
    _loadingBacksoundIds.add(backsound.id);
    final volume = _volumes[backsound.id] ?? backsound.defaultVolume;
    _volumes[backsound.id] = volume;
    notifyListeners();

    try {
      ap.AudioPlayer? player = _backsounds[backsound.id];
      if (player == null) {
        player = ap.AudioPlayer();
        _backsounds[backsound.id] = player;
        await player.setReleaseMode(ap.ReleaseMode.loop);
      }
      
      final relativeAssetPath = backsound.assetPath.startsWith('assets/')
          ? backsound.assetPath.substring(7)
          : backsound.assetPath;

      await player.setVolume(volume);
      await player.play(ap.AssetSource(relativeAssetPath));
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
      await _backsounds[id]?.stop();
    } catch (e) {
      debugPrint('Error stopping backsound $id: $e');
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
      _backsounds[id]?.stop();
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
    _sleepTimer?.cancel();
    _quranPlayer.dispose();
    for (final player in _backsounds.values) {
      player.dispose();
    }
    super.dispose();
  }
}
