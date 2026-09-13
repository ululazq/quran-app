import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/qari_model.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';

class QuranApiService extends ChangeNotifier {
  static const _quranCloudBase = 'https://api.alquran.cloud/v1';

  List<Qari> _qaris = List.from(Qari.defaultQaris);
  List<Surah> _surahs = [];
  Surah? _currentSurah;
  Qari? _currentQari = Qari.defaultQaris.first;
  bool _isLoading = false;
  String? _error;

  List<Qari> get qaris => _qaris;
  List<Surah> get surahs => _surahs;
  Surah? get currentSurah => _currentSurah;
  Qari? get currentQari => _currentQari ?? (_qaris.isNotEmpty ? _qaris.first : Qari.defaultQaris.first);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadQaris() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://mp3quran.net/api/v3/reciters?language=eng'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['reciters'] as List? ?? [];
        final parsedQaris = list
            .map((e) => Qari.fromJson(e as Map<String, dynamic>))
            .where((q) => q.server.isNotEmpty)
            .toList();

        if (parsedQaris.isNotEmpty) {
          _qaris = parsedQaris;
          _qaris.sort((a, b) => a.name.compareTo(b.name));
          if (_currentQari == null || !_qaris.contains(_currentQari)) {
            _currentQari = _qaris.first;
          }
        }
      } else {
        if (_qaris.isEmpty) {
          _qaris = List.from(Qari.defaultQaris);
        }
      }
    } catch (e) {
      debugPrint('Error loading qaris from API, using default list: $e');
      if (_qaris.isEmpty) {
        _qaris = List.from(Qari.defaultQaris);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSurahs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_quranCloudBase/surah'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['data'] as List? ?? [];
        _surahs = list.map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _error = 'Gagal memuat daftar Surah';
      }
    } catch (e) {
      _error = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mendapatkan URL audio untuk surah tertentu oleh Qari tertentu
  String getAudioUrl(int surahNumber, Qari qari) {
    // Format: 001, 010, 114
    final padded = surahNumber.toString().padLeft(3, '0');
    
    // Coba gunakan server dari data Qari
    if (qari.server.isNotEmpty) {
      return '${qari.server}$padded.mp3';
    }
    
    // Fallback ke MP3Quran
    return 'https://server11.mp3quran.net/afs/$padded.mp3';
  }

  final Map<int, List<Ayah>> _ayahsCache = {};
  bool _isLoadingAyahs = false;
  bool get isLoadingAyahs => _isLoadingAyahs;

  /// Mendapatkan teks Arab dan terjemahan Indonesia untuk setiap ayat
  Future<List<Ayah>> loadAyahs(int surahNumber) async {
    if (_ayahsCache.containsKey(surahNumber)) {
      return _ayahsCache[surahNumber]!;
    }

    _isLoadingAyahs = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_quranCloudBase/surah/$surahNumber/editions/quran-uthmani,id.indonesian'),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final editions = data['data'] as List? ?? [];
        if (editions.length >= 2) {
          final arabicList = (editions[0]['ayahs'] as List? ?? []);
          final translationList = (editions[1]['ayahs'] as List? ?? []);

          final List<Ayah> ayahs = [];
          for (int i = 0; i < arabicList.length; i++) {
            final ar = arabicList[i] as Map<String, dynamic>;
            final tr = i < translationList.length
                ? (translationList[i] as Map<String, dynamic>)
                : <String, dynamic>{};
            ayahs.add(Ayah.fromEditions(ar, tr));
          }

          _ayahsCache[surahNumber] = ayahs;
          return ayahs;
        }
      }
    } catch (e) {
      debugPrint('Error loading ayahs for surah $surahNumber: $e');
    } finally {
      _isLoadingAyahs = false;
      notifyListeners();
    }

    return _ayahsCache[surahNumber] ?? [];
  }

  final Set<int> _favoriteSurahNumbers = {};

  Set<int> get favoriteSurahNumbers => _favoriteSurahNumbers;

  bool isFavorite(int surahNumber) => _favoriteSurahNumbers.contains(surahNumber);

  void toggleFavorite(int surahNumber) {
    if (_favoriteSurahNumbers.contains(surahNumber)) {
      _favoriteSurahNumbers.remove(surahNumber);
    } else {
      _favoriteSurahNumbers.add(surahNumber);
    }
    notifyListeners();
  }

  List<Surah> get favoriteSurahs =>
      _surahs.where((s) => _favoriteSurahNumbers.contains(s.number)).toList();

  void selectSurah(Surah surah) {
    _currentSurah = surah;
    notifyListeners();
  }

  void selectQari(Qari qari) {
    _currentQari = qari;
    notifyListeners();
  }
}
