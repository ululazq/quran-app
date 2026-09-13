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

  factory Qari.fromJson(Map<String, dynamic> json) {
    String serverUrl = '';
    if (json['moshaf'] is List && (json['moshaf'] as List).isNotEmpty) {
      final firstMoshaf = json['moshaf'][0];
      if (firstMoshaf is Map && firstMoshaf['server'] != null) {
        serverUrl = firstMoshaf['server'].toString();
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
      files: json['files'] is int ? json['files'] : (json['Files'] is int ? json['Files'] : null),
    );
  }

  static const List<Qari> defaultQaris = [
    Qari(
      id: '1',
      name: 'Mishary Rashid Alafasy',
      server: 'https://server8.mp3quran.net/afs/',
    ),
    Qari(
      id: '2',
      name: 'Abdul Basit Abdul Samad',
      server: 'https://server7.mp3quran.net/basit/',
    ),
    Qari(
      id: '3',
      name: 'Maher Al Muaiqly',
      server: 'https://server12.mp3quran.net/maher/',
    ),
    Qari(
      id: '4',
      name: 'Saad Al Ghamdi',
      server: 'https://server7.mp3quran.net/s_gmd/',
    ),
    Qari(
      id: '5',
      name: 'Yasser Al-Dosari',
      server: 'https://server11.mp3quran.net/yasser/',
    ),
    Qari(
      id: '6',
      name: 'Abu Bakr Al Shatri',
      server: 'https://server11.mp3quran.net/shatri/',
    ),
    Qari(
      id: '7',
      name: 'Mahmoud Khalil Al-Hussary',
      server: 'https://server13.mp3quran.net/hssr/',
    ),
    Qari(
      id: '8',
      name: 'Nasser Al Qatami',
      server: 'https://server6.mp3quran.net/qtm/',
    ),
  ];

  @override
  List<Object?> get props => [id, name, server];
}
