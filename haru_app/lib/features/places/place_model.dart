import 'package:flutter/material.dart';

class PlaceCategory {
  PlaceCategory._();
  static const school = 'school';
  static const academy = 'academy';
  static const work = 'work';
  static const home = 'home';
  static const cafe = 'cafe';
  static const gym = 'gym';
  static const other = 'other';

  static const all = [school, academy, work, home, cafe, gym, other];

  static String label(String cat) => switch (cat) {
        school => '학교',
        academy => '학원',
        work => '직장',
        home => '집',
        cafe => '카페',
        gym => '운동',
        _ => '기타',
      };

  static IconData icon(String cat) => switch (cat) {
        school => Icons.school_rounded,
        academy => Icons.menu_book_rounded,
        work => Icons.business_center_rounded,
        home => Icons.home_rounded,
        cafe => Icons.local_cafe_rounded,
        gym => Icons.fitness_center_rounded,
        _ => Icons.location_on_rounded,
      };

  static Color color(String cat) => switch (cat) {
        school => const Color(0xFF5B8DEF),
        academy => const Color(0xFF9B7FDB),
        work => const Color(0xFF4CAF50),
        home => const Color(0xFFFF8C42),
        cafe => const Color(0xFFD4934A),
        gym => const Color(0xFFE74C3C),
        _ => const Color(0xFF659B5E),
      };
}

class PlaceModel {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final DateTime createdAt;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.createdAt,
  });

  String get categoryLabel => PlaceCategory.label(category);
  IconData get categoryIcon => PlaceCategory.icon(category);
  Color get categoryColor => PlaceCategory.color(category);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PlaceModel.fromJson(Map<String, dynamic> json) => PlaceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        radiusMeters: json['radiusMeters'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class PlaceVisit {
  final String id;
  final String placeId;
  final DateTime arrivedAt;
  final DateTime? departedAt;

  const PlaceVisit({
    required this.id,
    required this.placeId,
    required this.arrivedAt,
    this.departedAt,
  });

  Duration? get duration => departedAt?.difference(arrivedAt);

  String get durationLabel {
    final d = duration;
    if (d == null) return '방문 중';
    if (d.inHours > 0) return '${d.inHours}시간 ${d.inMinutes % 60}분';
    if (d.inMinutes > 0) return '${d.inMinutes}분';
    return '잠깐';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'arrivedAt': arrivedAt.toIso8601String(),
        'departedAt': departedAt?.toIso8601String(),
      };

  factory PlaceVisit.fromJson(Map<String, dynamic> json) => PlaceVisit(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        arrivedAt: DateTime.parse(json['arrivedAt'] as String),
        departedAt: json['departedAt'] != null
            ? DateTime.parse(json['departedAt'] as String)
            : null,
      );
}
