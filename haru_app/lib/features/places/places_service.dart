import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'place_model.dart';

class PlacesService {
  PlacesService._();
  static final PlacesService instance = PlacesService._();

  static const _placesKey = 'haru_places_v1';
  static const _visitsKey = 'haru_place_visits_v1';

  List<PlaceModel> _places = [];
  List<PlaceVisit> _visits = [];
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    final placesJson = prefs.getString(_placesKey);
    if (placesJson != null) {
      try {
        final list = (jsonDecode(placesJson) as List).cast<Map<String, dynamic>>();
        _places = list.map(PlaceModel.fromJson).toList();
      } catch (_) {}
    }

    final visitsJson = prefs.getString(_visitsKey);
    if (visitsJson != null) {
      try {
        final list = (jsonDecode(visitsJson) as List).cast<Map<String, dynamic>>();
        _visits = list.map(PlaceVisit.fromJson).toList();
      } catch (_) {}
    }

    _loaded = true;
  }

  Future<void> _savePlaces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _placesKey, jsonEncode(_places.map((p) => p.toJson()).toList()));
  }

  Future<void> _saveVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final recent = _visits.where((v) => v.arrivedAt.isAfter(cutoff)).toList();
    await prefs.setString(
        _visitsKey, jsonEncode(recent.map((v) => v.toJson()).toList()));
  }

  Future<List<PlaceModel>> getPlaces() async {
    await _ensureLoaded();
    return List.unmodifiable(_places);
  }

  Future<void> addPlace(PlaceModel place) async {
    await _ensureLoaded();
    _places.add(place);
    await _savePlaces();
  }

  Future<void> deletePlace(String id) async {
    await _ensureLoaded();
    _places.removeWhere((p) => p.id == id);
    _visits.removeWhere((v) => v.placeId == id);
    await _savePlaces();
    await _saveVisits();
  }

  Future<List<PlaceVisit>> getVisitsForPlace(String placeId) async {
    await _ensureLoaded();
    final result = _visits.where((v) => v.placeId == placeId).toList();
    result.sort((a, b) => b.arrivedAt.compareTo(a.arrivedAt));
    return result;
  }

  Future<List<PlaceVisit>> getTodayVisits() async {
    await _ensureLoaded();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _visits.where((v) => v.arrivedAt.isAfter(today)).toList();
  }

  Future<void> recordCheckIn(String placeId) async {
    await _ensureLoaded();
    final alreadyIn =
        _visits.any((v) => v.placeId == placeId && v.departedAt == null);
    if (alreadyIn) return;

    _visits.add(PlaceVisit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      placeId: placeId,
      arrivedAt: DateTime.now(),
    ));
    await _saveVisits();
  }

  Future<void> recordCheckOut(String placeId) async {
    await _ensureLoaded();
    final idx =
        _visits.lastIndexWhere((v) => v.placeId == placeId && v.departedAt == null);
    if (idx < 0) return;
    final old = _visits[idx];
    _visits[idx] = PlaceVisit(
      id: old.id,
      placeId: old.placeId,
      arrivedAt: old.arrivedAt,
      departedAt: DateTime.now(),
    );
    await _saveVisits();
  }

  Future<List<PlaceModel>> getNearbyPlaces(Position position) async {
    await _ensureLoaded();
    return _places.where((place) {
      final dist = _distanceMeters(
        position.latitude, position.longitude,
        place.latitude, place.longitude,
      );
      return dist <= place.radiusMeters;
    }).toList();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  // Haversine 공식
  static double _distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double deg) => deg * pi / 180;
}
