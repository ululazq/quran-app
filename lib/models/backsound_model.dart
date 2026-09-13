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
      name: 'Rain',
      nameAr: 'hujan',
      assetPath: 'https://www.soundjay.com/weather/rain-01.mp3',
      icon: Icons.water_drop,
    ),
    Backsound(
      id: 'ocean',
      name: 'Ocean Waves',
      nameAr: 'ombak',
      assetPath: 'https://www.soundjay.com/weather/ocean-waves-1.mp3',
      icon: Icons.waves,
    ),
    Backsound(
      id: 'wind',
      name: 'Wind',
      nameAr: 'angin',
      assetPath: 'https://www.soundjay.com/weather/wind-1.mp3',
      icon: Icons.air,
    ),
    Backsound(
      id: 'birds',
      name: 'Birds',
      nameAr: 'burung',
      assetPath: 'https://www.soundjay.com/birds/bird-chirping-1.mp3',
      icon: Icons.paragliding,
    ),
    Backsound(
      id: 'night',
      name: 'Night Ambience',
      nameAr: 'malam',
      assetPath: 'https://www.soundjay.com/ambient/forest-night-1.mp3',
      icon: Icons.nights_stay,
    ),
    Backsound(
      id: 'fireplace',
      name: 'Fireplace',
      nameAr: 'perapian',
      assetPath: 'https://www.soundjay.com/fire/fireplace-1.mp3',
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
  List<Object?> get props => [id, name];
}
