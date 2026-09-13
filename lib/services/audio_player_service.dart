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

  List<AudioSource>? _playlistSources;
  String? _playlistQariId;

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
    _playlistSources = null;
    _playlistQariId = null;
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
          seek(Duration.zero).then((_) => resume());
        } else if (_loopMode == QuranLoopMode.all || _autoPlayNext) {
          playNext();
        }
      }
    });

    _quranPlayer.currentIndexStream.listen((index) {
      if (index != null && _surahList.isNotEmpty && index >= 0 && index < _surahList.length) {
        final newSurah = _surahList[index];
        if (_currentSurah?.number != newSurah.number) {
          _currentSurah = newSurah;
          if (_currentQari != null) {
            _currentUrl = _buildAudioUrl(_currentQari!, newSurah.number);
          }
          notifyListeners();
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

  List<Surah> get _effectiveSurahList {
    if (_surahList.isNotEmpty) return _surahList;
    return List.generate(
      114,
      (i) => Surah(
        number: i + 1,
        name: 'Surah ${i + 1}',
        nameArabic: '',
        verses: 0,
        revelationType: 'Makkiyah',
      ),
    );
  }

  List<AudioSource> _createAudioSources(Qari qari) {
    return _effectiveSurahList.map((s) {
      final audioUrl = _buildAudioUrl(qari, s.number);
      return AudioSource.uri(
        Uri.parse(audioUrl),
        tag: MediaItem(
          id: '${s.number}',
          album: qari.name,
          title: s.name,
          displaySubtitle: s.nameArabic,
          displayDescription: '${s.revelationType} • ${s.verses} Ayat',
        ),
      );
    }).toList();
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

    final list = _effectiveSurahList;
    int targetIndex = list.indexWhere((s) => s.number == surah.number);
    if (targetIndex < 0) targetIndex = (surah.number - 1).clamp(0, list.length - 1);

    try {
      if (_playlistQariId != qari.id || _playlistSources == null) {
        final sources = _createAudioSources(qari);
        _playlistSources = sources;
        _playlistQariId = qari.id;
        await _quranPlayer.setAudioSources(
          sources,
          initialIndex: targetIndex,
          initialPosition: Duration.zero,
        );
      } else {
        if (_quranPlayer.currentIndex != targetIndex) {
          await _quranPlayer.seek(Duration.zero, index: targetIndex);
        } else {
          await _quranPlayer.seek(Duration.zero);
        }
      }
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
    final list = _effectiveSurahList;

    if (_isShuffle && list.length > 1) {
      final random = Random();
      int randomIndex;
      do {
        randomIndex = random.nextInt(list.length);
      } while (list[randomIndex].number == _currentSurah!.number);
      await play(qari, list[randomIndex]);
      return;
    }

    if (_quranPlayer.hasNext) {
      try {
        await _quranPlayer.seekToNext();
        await _quranPlayer.play();
        return;
      } catch (_) {}
    }

    if (list.isNotEmpty) {
      final currentIndex = list.indexWhere((s) => s.number == _currentSurah!.number);
      if (currentIndex >= 0 && currentIndex < list.length - 1) {
        await play(qari, list[currentIndex + 1]);
        return;
      } else {
        await play(qari, list.first);
        return;
      }
    }
  }

  Future<void> playPrevious() async {
    if (_currentSurah == null || _isChangingTrack) return;
    final qari = _currentQari ?? Qari.defaultQaris.first;
    final list = _effectiveSurahList;

    if (_quranPlayer.hasPrevious) {
      try {
        await _quranPlayer.seekToPrevious();
        await _quranPlayer.play();
        return;
      } catch (_) {}
    }

    if (list.isNotEmpty) {
      final currentIndex = list.indexWhere((s) => s.number == _currentSurah!.number);
      if (currentIndex > 0) {
        await play(qari, list[currentIndex - 1]);
        return;
      } else {
        await play(qari, list.last);
        return;
      }
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
