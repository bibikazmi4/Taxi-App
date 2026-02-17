import 'dart:convert';
import 'dart:math';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/app_latlng.dart';
import '../utils/constants.dart';

class RouteResult {
  final List<AppLatLng> points;
  final double distanceKm;
  final double durationMin;
  final bool isFallback;

  const RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMin,
    required this.isFallback,
  });
}

class MapService {
  bool get hasRealDirectionsKey =>
      Constants.googleMapsApiKey.isNotEmpty &&
      Constants.googleMapsApiKey != "YOUR_GOOGLE_MAPS_API_KEY" &&
      Constants.googleMapsApiKey != "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE";

  /// Fetch Directions API route, else return a fallback straight-line.
  Future<RouteResult> getRoute({
    required AppLatLng origin,
    required AppLatLng destination,
  }) async {
    // Always use fallback on web if API key check fails
    if (kIsWeb && !hasRealDirectionsKey) {
      print("⚠️ Web: Using fallback route (API key check failed)");
      return _fallbackRoute(origin, destination);
    }

    // If no API key or key is placeholder, use fallback
    if (!hasRealDirectionsKey) {
      print("⚠️ Using fallback route (no valid API key)");
      return _fallbackRoute(origin, destination);
    }

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/directions/json',
        {
          'origin': '${origin.lat},${origin.lng}',
          'destination': '${destination.lat},${destination.lng}',
          'key': Constants.googleMapsApiKey,
          'mode': 'driving',
        },
      );

      print("🌍 Fetching route from Google Maps API...");
      final res = await http.get(uri);

      if (res.statusCode != 200) {
        print("❌ Google Maps API error: ${res.statusCode}");
        return _fallbackRoute(origin, destination);
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      // Check for API errors
      if (data['status'] != 'OK') {
        print("❌ Google Maps API status: ${data['status']}");
        if (data.containsKey('error_message')) {
          print("❌ Error message: ${data['error_message']}");
        }
        return _fallbackRoute(origin, destination);
      }

      final routes = (data['routes'] as List?) ?? [];
      if (routes.isEmpty) {
        print("❌ No routes found");
        return _fallbackRoute(origin, destination);
      }

      final overview = routes.first['overview_polyline'];
      final polyline = overview?['points'] as String?;
      if (polyline == null || polyline.isEmpty) {
        print("❌ No polyline data");
        return _fallbackRoute(origin, destination);
      }

      // Decode polyline points
      final decoded = PolylinePoints().decodePolyline(polyline);
      final points = decoded
          .map((p) => AppLatLng(p.latitude, p.longitude))
          .toList(growable: false);

      // Extract distance and duration
      final legs = (routes.first['legs'] as List?) ?? [];
      double distanceMeters = 0;
      double durationSeconds = 0;

      if (legs.isNotEmpty) {
        final leg0 = legs.first as Map<String, dynamic>;
        distanceMeters = ((leg0['distance']?['value'] ?? 0) as num).toDouble();
        durationSeconds = ((leg0['duration']?['value'] ?? 0) as num).toDouble();
      }

      print(
          "✅ Route fetched: ${points.length} points, ${(distanceMeters / 1000).toStringAsFixed(1)} km, ${(durationSeconds / 60).toStringAsFixed(0)} min");

      return RouteResult(
        points: points,
        distanceKm: distanceMeters / 1000.0,
        durationMin: durationSeconds / 60.0,
        isFallback: false,
      );
    } catch (e) {
      print("❌ Error fetching Google Maps route: $e");
      return _fallbackRoute(origin, destination);
    }
  }

  RouteResult _fallbackRoute(AppLatLng o, AppLatLng d) {
    // Simple estimate using Haversine and 30 km/h average speed.
    final km = _haversineKm(o.lat, o.lng, d.lat, d.lng);
    final durationMin = (km / 30.0) * 60.0; // 30 km/h

    // Create a simple curved route for visualization
    final points = _createCurvedRoute(o, d);

    print(
        "⚠️ Using fallback route: ${km.toStringAsFixed(1)} km, ${durationMin.toStringAsFixed(0)} min");

    return RouteResult(
      points: points,
      distanceKm: km,
      durationMin: durationMin,
      isFallback: true,
    );
  }

  // Create a simple curved route for fallback
  List<AppLatLng> _createCurvedRoute(AppLatLng start, AppLatLng end) {
    final points = <AppLatLng>[];

    // Add start point
    points.add(start);

    // Add 3 intermediate points for a curved effect
    for (int i = 1; i <= 3; i++) {
      final t = i / 4.0;
      final lat = start.lat + (end.lat - start.lat) * t + 0.001 * sin(t * pi);
      final lng = start.lng + (end.lng - start.lng) * t + 0.001 * cos(t * pi);
      points.add(AppLatLng(lat, lng));
    }

    // Add end point
    points.add(end);

    return points;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = pow(sin(dLat / 2), 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * (pi / 180.0);
}
