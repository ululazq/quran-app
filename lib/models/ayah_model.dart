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
