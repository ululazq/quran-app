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
    return Qari(
      id: json['Id']?.toString() ?? '',
      name: json['Name'] ?? '',
      server: json['Server'] ?? '',
      homePage: json['HomePage'],
      format: json['Format'],
      files: json['Files'],
    );
  }

  @override
  List<Object?> get props => [id, name, server];
}
