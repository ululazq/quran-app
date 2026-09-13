import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class Backsound extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String assetPath;
  final IconData icon;
  final double defaultVolume;

  const Backsound({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.assetPath,
    required this.icon,
    this.defaultVolume = 0.3,
  });

  static const List<Backsound> presets = [
    Backsound(
      id: 'rain',
      name: 'Hujan (Rain)',
      nameAr: 'مطر',
      assetPath: 'assets/audio/backsounds/rain.wav',
      icon: Icons.water_drop,
    ),
    Backsound(
      id: 'ocean',
      name: 'Ombak (Ocean)',
      nameAr: 'أمواج',
      assetPath: 'assets/audio/backsounds/ocean.wav',
      icon: Icons.waves,
    ),
    Backsound(
      id: 'wind',
      name: 'Angin (Wind)',
      nameAr: 'رياح',
      assetPath: 'assets/audio/backsounds/wind.wav',
      icon: Icons.air,
    ),
    Backsound(
      id: 'birds',
      name: 'Burung (Birds)',
      nameAr: 'طيور',
      assetPath: 'assets/audio/backsounds/birds.wav',
      icon: Icons.nature,
    ),
    Backsound(
      id: 'night',
      name: 'Malam (Night)',
      nameAr: 'ليل',
      assetPath: 'assets/audio/backsounds/night.wav',
      icon: Icons.nights_stay,
    ),
    Backsound(
      id: 'fireplace',
      name: 'Perapian (Fire)',
      nameAr: 'نار',
      assetPath: 'assets/audio/backsounds/fireplace.wav',
      icon: Icons.local_fire_department,
    ),
  ];

  Backsound copyWith({double? volume, bool? isActive}) {
    return Backsound(
      id: id,
      name: name,
      nameAr: nameAr,
      assetPath: assetPath,
      icon: icon,
      defaultVolume: volume ?? defaultVolume,
    );
  }

  @override
  List<Object?> get props => [id, name, assetPath];
}
