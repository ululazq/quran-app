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
      assetPath: 'https://ia801309.us.archive.org/11/items/RainSounds_201603/Rain.mp3',
      icon: Icons.water_drop,
    ),
    Backsound(
      id: 'ocean',
      name: 'Ombak (Ocean)',
      nameAr: 'أمواج',
      assetPath: 'https://ia800201.us.archive.org/13/items/OceanWavesCrashing/Ocean%20Waves.mp3',
      icon: Icons.waves,
    ),
    Backsound(
      id: 'wind',
      name: 'Angin (Wind)',
      nameAr: 'رياح',
      assetPath: 'https://ia800302.us.archive.org/27/items/WindSounds_201603/Wind.mp3',
      icon: Icons.air,
    ),
    Backsound(
      id: 'birds',
      name: 'Burung (Birds)',
      nameAr: 'طيور',
      assetPath: 'https://ia800204.us.archive.org/11/items/ForestBirdsSinging/ForestBirds.mp3',
      icon: Icons.nature,
    ),
    Backsound(
      id: 'night',
      name: 'Malam (Night)',
      nameAr: 'ليل',
      assetPath: 'https://ia800301.us.archive.org/30/items/NightCricketsSound/NightCrickets.mp3',
      icon: Icons.nights_stay,
    ),
    Backsound(
      id: 'fireplace',
      name: 'Perapian (Fire)',
      nameAr: 'نار',
      assetPath: 'https://ia800302.us.archive.org/17/items/FireplaceCracklingSound/Fireplace.mp3',
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
