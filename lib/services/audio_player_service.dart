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

  double _quranVolume = 1.0;

  List<Surah> get surahList => _surahList;
  Surah? get currentSurah => _currentSurah;
  Qari? get currentQari => _currentQari;
  String? get currentUrl => _currentUrl;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  double _ambientVolume = 0.5;

  bool get isPlaying => _isPlaying;
  bool get isChangingTrack => _isChangingTrack;
  bool get isSeekable => _duration.inSeconds > 0;
  bool get autoPlayNext => _autoPlayNext;
  bool get isShuffle => _isShuffle;
  QuranLoopMode get loopMode => _loopMode;
  int get sleepTimerMinutes => _sleepTimerMinutes;
  double get quranVolume => _quranVolume;
  String? get activeBacksoundId => _activeBacksoundIds.isNotEmpty ? _activeBacksoundIds.first : null;
  double get ambientVolume => _ambientVolume;
  double get activeBacksoundVolume => _ambientVolume;

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

  static final ap.AudioContext _backsoundAudioContext = ap.AudioContext(
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

  Future<void> initialize() async {
    try {
      await ap.AudioPlayer.global.setAudioContext(_backsoundAudioContext);
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
      _isPlaying = state.playing;
      if (state.playing) {
        _resumeActiveBacksounds();
      } else {
        _pauseActiveBacksounds();
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
      if (_isChangingTrack) return;
      final list = _effectiveSurahList;
      if (index != null && list.isNotEmpty && index >= 0 && index < list.length) {
        final newSurah = list[index];
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
    _currentQari = qari;
    _currentSurah = surah;
    _isPlaying = true;
    _isChangingTrack = true;
    notifyListeners();

    final url = _buildAudioUrl(qari, surah.number);
    _currentUrl = url;
    debugPrint('Playing audio URL: $url');

    final list = _effectiveSurahList;
    int targetIndex = list.indexWhere((s) => s.number == surah.number);
    if (targetIndex < 0) targetIndex = (surah.number - 1).clamp(0, list.length - 1);

    try {
      if (_playlistQariId != qari.id || _playlistSources == null || _quranPlayer.audioSource == null) {
        final sources = _createAudioSources(qari);
        _playlistSources = sources;
        _playlistQariId = qari.id;
        await _quranPlayer.setAudioSources(
          sources,
          initialIndex: targetIndex,
          initialPosition: Duration.zero,
        );
      } else {
        await _quranPlayer.seek(Duration.zero, index: targetIndex);
      }
      await _quranPlayer.play();
      _startPositionTimer();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    } finally {
      _isChangingTrack = false;
      _isPlaying = _quranPlayer.playing;
      notifyListeners();
    }
  }

  Future<void> playNext() async {
    if (_currentSurah == null) return;
    final qari = _currentQari ?? Qari.defaultQaris.first;
    final list = _effectiveSurahList;
    if (list.isEmpty) return;

    if (_isShuffle && list.length > 1) {
      final random = Random();
      int randomIndex;
      do {
        randomIndex = random.nextInt(list.length);
      } while (list[randomIndex].number == _currentSurah!.number);
      await play(qari, list[randomIndex]);
      return;
    }

    final currentIndex = list.indexWhere((s) => s.number == _currentSurah!.number);
    if (currentIndex >= 0 && currentIndex < list.length - 1) {
      await play(qari, list[currentIndex + 1]);
    } else {
      await play(qari, list.first);
    }
  }

  Future<void> playPrevious() async {
    if (_currentSurah == null) return;
    final qari = _currentQari ?? Qari.defaultQaris.first;
    final list = _effectiveSurahList;
    if (list.isEmpty) return;

    final currentIndex = list.indexWhere((s) => s.number == _currentSurah!.number);
    if (currentIndex > 0) {
      await play(qari, list[currentIndex - 1]);
    } else {
      await play(qari, list.last);
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    notifyListeners();
    await _pauseActiveBacksounds();
    try {
      await _quranPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing audio: $e');
    }
    _positionTimer?.cancel();
    notifyListeners();
  }

  Future<void> resume() async {
    _isPlaying = true;
    notifyListeners();
    try {
      await _quranPlayer.play();
    } catch (e) {
      debugPrint('Error resuming audio: $e');
    }
    await _resumeActiveBacksounds();
    _startPositionTimer();
    notifyListeners();
  }

  Future<void> stop() async {
    _isPlaying = false;
    notifyListeners();
    await _pauseActiveBacksounds();
    try {
      await _quranPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
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

  // === Gapless Dual-Player Looper for Backsound ===
  ap.AudioPlayer? _ambientPlayerA;
  ap.AudioPlayer? _ambientPlayerB;
  int _activeAmbientPlayerIndex = 0; // 0 = Player A, 1 = Player B
  Timer? _ambientLoopTimer;
  Timer? _ambientFadeTimer;
  String? _currentBacksoundAssetPath;
  Duration _currentBacksoundDuration = const Duration(seconds: 90);
  Duration _currentLoopTargetDuration = const Duration(seconds: 90);
  DateTime? _ambientPlayStartTime;
  Duration _ambientRemainingWhenPaused = Duration.zero;

  static const Map<String, Duration> _presetDurations = {
    'rain': Duration(milliseconds: 98940),
    'ocean': Duration(milliseconds: 96660),
    'wind': Duration(milliseconds: 71420),
    'birds': Duration(milliseconds: 113120),
    'night': Duration(milliseconds: 170540),
    'fireplace': Duration(milliseconds: 123400),
  };

  final Set<String> _activeBacksoundIds = {};
  final Set<String> _loadingBacksoundIds = {};

  bool isBacksoundActive(String id) => _activeBacksoundIds.contains(id);
  bool isBacksoundLoading(String id) => _loadingBacksoundIds.contains(id);
  double getBacksoundVolume(String id) => _ambientVolume;

  Future<void> _initAmbientPlayersIfNeeded() async {
    if (_ambientPlayerA == null) {
      _ambientPlayerA = ap.AudioPlayer();
      await _ambientPlayerA!.setAudioContext(_backsoundAudioContext);
      await _ambientPlayerA!.setReleaseMode(ap.ReleaseMode.stop);
      _ambientPlayerA!.onPlayerComplete.listen((_) {
        if (_activeAmbientPlayerIndex == 0 && _activeBacksoundIds.isNotEmpty && _isPlaying) {
          _crossfadeToNextAmbientPlayer();
        }
      });
    }
    if (_ambientPlayerB == null) {
      _ambientPlayerB = ap.AudioPlayer();
      await _ambientPlayerB!.setAudioContext(_backsoundAudioContext);
      await _ambientPlayerB!.setReleaseMode(ap.ReleaseMode.stop);
      _ambientPlayerB!.onPlayerComplete.listen((_) {
        if (_activeAmbientPlayerIndex == 1 && _activeBacksoundIds.isNotEmpty && _isPlaying) {
          _crossfadeToNextAmbientPlayer();
        }
      });
    }
  }

  void _scheduleNextAmbientLoop(Duration delay) {
    _ambientLoopTimer?.cancel();
    if (!_isPlaying || _activeBacksoundIds.isEmpty || _currentBacksoundAssetPath == null) return;
    final waitDuration = delay.isNegative ? Duration.zero : delay;
    _ambientLoopTimer = Timer(waitDuration, () async {
      if (!_isPlaying || _activeBacksoundIds.isEmpty || _currentBacksoundAssetPath == null) return;
      await _crossfadeToNextAmbientPlayer();
    });
  }

  Future<void> _crossfadeToNextAmbientPlayer() async {
    if (!_isPlaying || _activeBacksoundIds.isEmpty || _currentBacksoundAssetPath == null) return;

    final currentPlayer = _activeAmbientPlayerIndex == 0 ? _ambientPlayerA : _ambientPlayerB;
    final nextPlayer = _activeAmbientPlayerIndex == 0 ? _ambientPlayerB : _ambientPlayerA;

    if (currentPlayer == null || nextPlayer == null) return;

    bool nextPlayerStarted = false;
    try {
      await nextPlayer.setVolume(0.0);
      if (_isPlaying) {
        await nextPlayer.play(
          ap.AssetSource(_currentBacksoundAssetPath!),
          volume: 0.0,
        );
        nextPlayerStarted = true;
        nextPlayer.getDuration().then((dur) {
          if (dur != null && dur > const Duration(seconds: 10)) {
            _currentBacksoundDuration = dur;
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting next ambient player: $e');
    }

    if (!nextPlayerStarted) {
      debugPrint('Warning: Next ambient player failed to start, keeping current player active.');
      try {
        await currentPlayer.setVolume(_ambientVolume);
      } catch (_) {}
      return;
    }

    const crossfadeMs = 2000;
    const steps = 20;
    const stepDuration = Duration(milliseconds: crossfadeMs ~/ steps);
    int currentStep = 0;

    _ambientFadeTimer?.cancel();
    _ambientFadeTimer = Timer.periodic(stepDuration, (timer) async {
      if (!_isPlaying) {
        timer.cancel();
        try {
          await nextPlayer.setVolume(0.0);
          await currentPlayer.setVolume(0.0);
        } catch (_) {}
        return;
      }

      currentStep++;
      final t = (currentStep / steps).clamp(0.0, 1.0);

      final volNext = _ambientVolume * t;
      final volCurrent = _ambientVolume * (1.0 - t);

      try {
        await nextPlayer.setVolume(volNext);
        await currentPlayer.setVolume(volCurrent);
      } catch (_) {}

      if (currentStep >= steps) {
        timer.cancel();
        try {
          await currentPlayer.stop();
          if (_isPlaying) {
            await nextPlayer.setVolume(_ambientVolume);
          }
        } catch (_) {}
      }
    });

    _activeAmbientPlayerIndex = 1 - _activeAmbientPlayerIndex;
    _ambientPlayStartTime = DateTime.now();
    _ambientRemainingWhenPaused = Duration.zero;

    const crossfadeDuration = Duration(milliseconds: 2000);
    final leadTime = _currentBacksoundDuration - crossfadeDuration;
    _currentLoopTargetDuration = leadTime;
    _scheduleNextAmbientLoop(leadTime);
  }

  Future<void> _pauseActiveBacksounds() async {
    if (_ambientPlayStartTime != null) {
      final elapsed = DateTime.now().difference(_ambientPlayStartTime!);
      final remaining = _currentLoopTargetDuration - elapsed;
      _ambientRemainingWhenPaused = remaining.isNegative ? Duration.zero : remaining;
    }
    _ambientLoopTimer?.cancel();
    _ambientFadeTimer?.cancel();

    // 1. Mute both players immediately so zero audio leaks out
    try {
      await _ambientPlayerA?.setVolume(0.0);
    } catch (_) {}
    try {
      await _ambientPlayerB?.setVolume(0.0);
    } catch (_) {}

    // 2. Pause each player independently to guarantee both receive pause command
    try {
      await _ambientPlayerA?.pause();
    } catch (e) {
      debugPrint('Error pausing ambientPlayerA: $e');
    }
    try {
      await _ambientPlayerB?.pause();
    } catch (e) {
      debugPrint('Error pausing ambientPlayerB: $e');
    }
  }

  Future<void> _resumeActiveBacksounds() async {
    if (_activeBacksoundIds.isEmpty || !_isPlaying || _currentBacksoundAssetPath == null) return;

    final activePlayer = _activeAmbientPlayerIndex == 0 ? _ambientPlayerA : _ambientPlayerB;
    final otherPlayer = _activeAmbientPlayerIndex == 0 ? _ambientPlayerB : _ambientPlayerA;

    try {
      await otherPlayer?.setVolume(0.0);
      await otherPlayer?.pause();
    } catch (_) {}

    try {
      await activePlayer?.setVolume(_ambientVolume);
      await activePlayer?.resume();
    } catch (e) {
      debugPrint('Error resuming active ambient player: $e');
      try {
        await activePlayer?.play(ap.AssetSource(_currentBacksoundAssetPath!));
      } catch (_) {}
    }

    _ambientPlayStartTime = DateTime.now();
    const crossfadeDuration = Duration(milliseconds: 2000);
    final defaultLeadTime = _currentBacksoundDuration - crossfadeDuration;
    final scheduleDelay = _ambientRemainingWhenPaused > Duration.zero
        ? _ambientRemainingWhenPaused
        : defaultLeadTime;
    _currentLoopTargetDuration = scheduleDelay;
    _scheduleNextAmbientLoop(scheduleDelay);
  }

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
    notifyListeners();

    try {
      await _initAmbientPlayersIfNeeded();
      _ambientLoopTimer?.cancel();
      _ambientFadeTimer?.cancel();
      await _ambientPlayerA?.stop();
      await _ambientPlayerB?.stop();

      final relativeAssetPath = backsound.assetPath.startsWith('assets/')
          ? backsound.assetPath.substring(7)
          : backsound.assetPath;

      _currentBacksoundAssetPath = relativeAssetPath;
      _currentBacksoundDuration = _presetDurations[backsound.id] ?? const Duration(seconds: 90);
      _activeAmbientPlayerIndex = 0;

      if (!_isPlaying) {
        await _ambientPlayerA!.setVolume(0.0);
        await _ambientPlayerA!.play(ap.AssetSource(relativeAssetPath));
        await _ambientPlayerA!.pause();
      } else {
        await _ambientPlayerA!.setVolume(_ambientVolume);
        await _ambientPlayerA!.play(ap.AssetSource(relativeAssetPath));
        _ambientPlayStartTime = DateTime.now();
        const crossfadeDuration = Duration(milliseconds: 2000);
        final leadTime = _currentBacksoundDuration - crossfadeDuration;
        _currentLoopTargetDuration = leadTime;
        _scheduleNextAmbientLoop(leadTime);
      }

      _ambientPlayerA!.getDuration().then((dur) {
        if (dur != null && dur > const Duration(seconds: 10)) {
          _currentBacksoundDuration = dur;
        }
      });
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
    _ambientLoopTimer?.cancel();
    _ambientFadeTimer?.cancel();
    _currentBacksoundAssetPath = null;
    notifyListeners();

    try {
      await _ambientPlayerA?.stop();
      await _ambientPlayerB?.stop();
    } catch (e) {
      debugPrint('Error stopping ambient players: $e');
    }
  }

  Future<void> setQuranVolume(double volume) async {
    _quranVolume = volume.clamp(0.0, 1.0);
    await _quranPlayer.setVolume(_quranVolume);
    notifyListeners();
  }

  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume.clamp(0.0, 1.0);
    final activePlayer = _activeAmbientPlayerIndex == 0 ? _ambientPlayerA : _ambientPlayerB;
    try {
      await activePlayer?.setVolume(_ambientVolume);
    } catch (e) {
      debugPrint('Error setting ambient volume: $e');
    }
    notifyListeners();
  }

  Future<void> setBacksoundVolume(String id, double volume) async {
    await setAmbientVolume(volume);
  }

  void stopAllBacksounds() {
    _activeBacksoundIds.clear();
    _loadingBacksoundIds.clear();
    _ambientLoopTimer?.cancel();
    _ambientFadeTimer?.cancel();
    _currentBacksoundAssetPath = null;
    notifyListeners();

    _ambientPlayerA?.stop();
    _ambientPlayerB?.stop();
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
    _ambientLoopTimer?.cancel();
    _ambientFadeTimer?.cancel();
    _quranPlayer.dispose();
    _ambientPlayerA?.dispose();
    _ambientPlayerB?.dispose();
    super.dispose();
  }
}
