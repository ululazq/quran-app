class Ayah {
  final int numberInSurah;
  final String textArabic;
  final String translation;

  const Ayah({
    required this.numberInSurah,
    required this.textArabic,
    required this.translation,
  });

  factory Ayah.fromEditions(Map<String, dynamic> arabic, Map<String, dynamic> translation) {
    return Ayah(
      numberInSurah: arabic['numberInSurah'] ?? 0,
      textArabic: (arabic['text'] ?? '').toString(),
      translation: (translation['text'] ?? '').toString(),
    );
  }
}

/// Exact millisecond timestamp alignment for Ayah synchronization (Quran.com & Quranify standard)
class VerseTiming {
  final int verseNumber;
  final int timestampFrom; // milliseconds
  final int timestampTo;   // milliseconds
  final int duration;      // milliseconds

  const VerseTiming({
    required this.verseNumber,
    required this.timestampFrom,
    required this.timestampTo,
    required this.duration,
  });

  factory VerseTiming.fromJson(Map<String, dynamic> json) {
    final key = (json['verse_key'] ?? json['verseKey'] ?? '').toString();
    final parts = key.split(':');
    final verseNum = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;

    return VerseTiming(
      verseNumber: verseNum,
      timestampFrom: (json['timestamp_from'] as num?)?.toInt() ?? 0,
      timestampTo: (json['timestamp_to'] as num?)?.toInt() ?? 0,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}
