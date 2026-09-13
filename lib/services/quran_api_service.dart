import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/qari_model.dart';
import '../models/surah_model.dart';

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

  /// Mendapatkan teks Arab untuk setiap ayat
  Future<List<Map<String, dynamic>>> loadAyahs(int surahNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_quranCloudBase/surah/$surahNumber/ar.alafasy'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final ayahs = data['data']['ayahs'] as List? ?? [];
        return ayahs.map((a) => a as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint('Error loading ayahs: $e');
    }
    return [];
  }

  void selectSurah(Surah surah) {
    _currentSurah = surah;
    notifyListeners();
  }

  void selectQari(Qari qari) {
    _currentQari = qari;
    notifyListeners();
  }
}
