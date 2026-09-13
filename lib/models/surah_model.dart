import 'package:equatable/equatable.dart';

class Surah extends Equatable {
  final int number;
  final String name;
  final String nameArabic;
  final int verses;
  final String revelationType;

  const Surah({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.verses,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? json['no'] ?? 0,
      name: json['name'] ?? '',
      nameArabic: json['nameArabic'] ?? json['name_arabic'] ?? '',
      verses: json['verses'] ?? json['num_of_aya'] ?? 0,
      revelationType: json['revelationType'] ?? json['revelation_type'] ?? '',
    );
  }

  @override
  List<Object?> get props => [number, name, nameArabic];
}
