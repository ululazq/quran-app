import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart';
import '../models/qari_model.dart';
import '../models/surah_model.dart';
import '../models/backsound_model.dart';

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _quranPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _backsounds = {};
  final Map<String, double> _volumes = {};

  Surah? _currentSurah;
  Qari? _currentQari;
  String? _currentUrl;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  Timer? _positionTimer;

  Surah? get currentSurah => _currentSurah;
  Qari? get currentQari => _currentQari;
  String? get currentUrl => _currentUrl;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _isPlaying;
  bool get isSeekable => _duration.inSeconds > 0;

  AudioPlayer get quranPlayer => _quranPlayer;

  Future<void> initialize() async {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.quran.app.channel.audio',
      androidNotificationChannelName: 'Quran Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationClickStartsActivity: true,
    );

    _quranPlayer.playerStateStream.listen((state) {
      _playerState = state;
      _isPlaying = state.playing;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        _stopAllBacksounds();
      }
    });

    _quranPlayer.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _quranPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur!;
        notifyListeners();
      }
    });
  }

  Future<void> play(Qari qari, Surah surah) async {
    _currentQari = qari;
    _currentSurah = surah;
    final url = _buildAudioUrl(qari, surah.number);
    _currentUrl = url;

    try {
      await _quranPlayer.setUrl(AudioSource.uri(Uri.parse(url)));
      await _quranPlayer.play();
      _startPositionTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing audio: $e');
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

  void registerBacksound(Backsound backsound) {
    if (_backsounds.containsKey(backsound.id)) return;

    final player = AudioPlayer();
    _backsounds[backsound.id] = player;
    _volumes[backsound.id] = backsound.defaultVolume;

    Future<void> loadAudio() async {
      if (backsound.assetPath.startsWith('http')) {
        await player.setUrl(backsound.assetPath);
      } else {
        await player.setAsset(backsound.assetPath);
      }
      player.setLoopMode(LoopMode.all);
      notifyListeners();
    }

    loadAudio().catchError((e) {
      debugPrint('Error loading backsound ${backsound.id}: $e');
    });
  }

  Future<void> toggleBacksound(Backsound backsound) async {
    final isActive = _volumes[backsound.id] ?? 0 > 0;

    if (isActive) {
      await setBacksoundVolume(backsound.id, 0);
    } else {
      await setBacksoundVolume(backsound.id, backsound.defaultVolume);
      await _backsounds[backsound.id]?.play();
    }
    notifyListeners();
  }

  Future<void> setBacksoundVolume(String id, double volume) async {
    _volumes[id] = volume;
    await _backsounds[id]?.setVolume(volume);

    if (volume > 0 && !(_backsounds[id]?.playing ?? false)) {
      await _backsounds[id]?.play();
    } else if (volume == 0) {
      await _backsounds[id]?.pause();
    }

    notifyListeners();
  }

  double getBacksoundVolume(String id) => _volumes[id] ?? 0;
  bool isBacksoundActive(String id) => (_volumes[id] ?? 0) > 0;

  void _stopAllBacksounds() {
    for (final player in _backsounds.values) {
      player.pause();
    }
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
      return '${qari.server}$padded.mp3';
    }
    return 'https://server11.mp3quran.net/afs/$padded.mp3';
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
