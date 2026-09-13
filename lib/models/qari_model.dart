import 'package:equatable/equatable.dart';

class Qari extends Equatable {
  final String id;
  final String name;
  final String server;
  final String? homePage;
  final String? format;
  final int? files;

  const Qari({
    required this.id,
    required this.name,
    required this.server,
    this.homePage,
    this.format,
    this.files,
  });

  // Known inactive / dead servers from MP3Quran API
  static const Set<String> unavailableQariIds = {
    '7', '11', '28', '35', '37', '73', '82', '85',
    '128', '153', '154', '162', '166', '167',
    '183', '184', '185', '187', '209', '246', '247',
    '303', '306', '21200',
  };

  factory Qari.fromJson(Map<String, dynamic> json) {
    String serverUrl = '';
    int surahTotal = 0;

    if (json['moshaf'] is List && (json['moshaf'] as List).isNotEmpty) {
      final moshafList = (json['moshaf'] as List).whereType<Map<String, dynamic>>().toList();

      // 1. Prefer complete 114 surahs Hafs/Murattal
      Map<String, dynamic>? selectedMoshaf;
      for (final m in moshafList) {
        final total = m['surah_total'] is int ? m['surah_total'] as int : 0;
        final list = (m['surah_list']?.toString() ?? '').split(',');
        final count = total > 0 ? total : list.length;
        final name = (m['name']?.toString() ?? '').toLowerCase();

        if (count >= 114 && (name.contains('hafs') || name.contains('murattal'))) {
          selectedMoshaf = m;
          surahTotal = count;
          break;
        }
      }

      // 2. Secondary: Any complete 114 surahs moshaf
      if (selectedMoshaf == null) {
        for (final m in moshafList) {
          final total = m['surah_total'] is int ? m['surah_total'] as int : 0;
          final list = (m['surah_list']?.toString() ?? '').split(',');
          final count = total > 0 ? total : list.length;
          if (count >= 114) {
            selectedMoshaf = m;
            surahTotal = count;
            break;
          }
        }
      }

      // 3. Fallback: Moshaf with the largest available surah count
      if (selectedMoshaf == null && moshafList.isNotEmpty) {
        moshafList.sort((a, b) {
          final aTotal = a['surah_total'] is int ? a['surah_total'] as int : 0;
          final bTotal = b['surah_total'] is int ? b['surah_total'] as int : 0;
          return bTotal.compareTo(aTotal);
        });
        selectedMoshaf = moshafList.first;
        surahTotal = selectedMoshaf['surah_total'] is int ? selectedMoshaf['surah_total'] as int : 0;
      }

      if (selectedMoshaf != null && selectedMoshaf['server'] != null) {
        serverUrl = selectedMoshaf['server'].toString();
      }
    }

    if (serverUrl.isEmpty) {
      serverUrl = (json['server'] ?? json['Server'] ?? '').toString();
    }
    if (serverUrl.isNotEmpty && !serverUrl.endsWith('/')) {
      serverUrl = '$serverUrl/';
    }

    return Qari(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? 'Qari').toString(),
      server: serverUrl,
      homePage: json['homePage'] ?? json['HomePage'],
      format: json['format'] ?? json['Format'],
      files: surahTotal > 0 ? surahTotal : (json['files'] is int ? json['files'] : (json['Files'] is int ? json['Files'] : null)),
    );
  }

  static const List<Qari> defaultQaris = [
    Qari(
      id: '1',
      name: 'Mishary Rashid Alafasy',
      server: 'https://server8.mp3quran.net/afs/',
      files: 114,
    ),
    Qari(
      id: '2',
      name: 'Abdul Basit Abdul Samad',
      server: 'https://server7.mp3quran.net/basit/',
      files: 114,
    ),
    Qari(
      id: '3',
      name: 'Maher Al Muaiqly',
      server: 'https://server12.mp3quran.net/maher/',
      files: 114,
    ),
    Qari(
      id: '4',
      name: 'Saad Al Ghamdi',
      server: 'https://server7.mp3quran.net/s_gmd/',
      files: 114,
    ),
    Qari(
      id: '5',
      name: 'Yasser Al-Dosari',
      server: 'https://server11.mp3quran.net/yasser/',
      files: 114,
    ),
    Qari(
      id: '6',
      name: 'Abu Bakr Al Shatri',
      server: 'https://server11.mp3quran.net/shatri/',
      files: 114,
    ),
    Qari(
      id: '7',
      name: 'Mahmoud Khalil Al-Hussary',
      server: 'https://server13.mp3quran.net/husr/',
      files: 114,
    ),
    Qari(
      id: '8',
      name: 'Nasser Al Qatami',
      server: 'https://server6.mp3quran.net/qtm/',
      files: 114,
    ),
    Qari(
      id: '9',
      name: 'Saud Al-Shuraim',
      server: 'https://server7.mp3quran.net/shur/',
      files: 114,
    ),
    Qari(
      id: '10',
      name: 'Abdul Rahman Al-Sudais',
      server: 'https://server11.mp3quran.net/sds/',
      files: 114,
    ),
    Qari(
      id: '76',
      name: 'Ali Jaber',
      server: 'https://server11.mp3quran.net/a_jbr/',
      files: 114,
    ),
    Qari(
      id: '217',
      name: 'Bandar Balilah',
      server: 'https://server6.mp3quran.net/balilah/',
      files: 114,
    ),
  ];

  @override
  List<Object?> get props => [id, name, server];
}
