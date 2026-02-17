import 'dart:math';
import 'package:flutter/material.dart';

import '../models/app_latlng.dart';
import '../models/location_model.dart';
import '../models/ride_model.dart';
import '../models/ride_option.dart';
import '../services/database_service.dart';
import '../services/map_service.dart';
import '../services/mock_data.dart';

class RideProvider extends ChangeNotifier {
  final MapService _mapService;
  final DatabaseService _db;

  RideProvider(this._mapService, this._db);

  bool isLoading = false;
  String? errorMessage;

  RouteResult? lastRoute;
  RideOption? selectedOption;
  RideModel? activeRide;
  List<RideModel> rideHistory = [];

  Future<void> loadHistory() async {
    rideHistory = await _db.getRides();
    notifyListeners();
  }

  Future<void> buildRoute({
    required LocationModel pickup,
    required LocationModel dropoff,
  }) async {
    isLoading = true;
    errorMessage = null;
    selectedOption = null;
    notifyListeners();

    try {
      lastRoute = await _mapService.getRoute(
        origin: pickup.position,
        destination: dropoff.position,
      );
    } catch (e) {
      errorMessage = "Failed to load route: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<RideOption> buildRideOptions() {
    final route = lastRoute;
    if (route == null) return const [];
    final distanceKm = max(0.5, route.distanceKm);
    final r = Random();
    return RideCategory.values.map((cat) {
      final price = cat.baseFare + (distanceKm * cat.perKm);
      final eta = 3 + r.nextInt(8) + (cat == RideCategory.car ? 2 : 0);
      return RideOption(
        category: cat,
        estimatedArrivalMinutes: eta.toDouble(),
        price: price,
      );
    }).toList(growable: false);
  }

  void selectOption(RideOption option) {
    selectedOption = option;
    notifyListeners();
  }

  Future<void> confirmRide({
    required LocationModel pickup,
    required LocationModel dropoff,
  }) async {
    final route = lastRoute;
    final option = selectedOption;
    if (route == null || option == null) {
      errorMessage = "Please choose a ride first.";
      notifyListeners();
      return;
    }

    final ride = RideModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      pickup: pickup,
      dropoff: dropoff,
      category: option.category,
      distanceKm: route.distanceKm,
      durationMin: route.durationMin,
      fare: option.price,
      driver: MockData.randomDriver(option.category),
      route: route.points,
      status: RideStatus.driverAssigned,
    );

    activeRide = ride;
    await _db.saveRide(ride);
    await loadHistory();
  }

  Future<void> updateActiveRideStatus(RideStatus status) async {
    final ride = activeRide;
    if (ride == null) return;
    activeRide = ride.copyWith(status: status);
    await _db.saveRide(activeRide!);
    await loadHistory();
    notifyListeners();
  }

  Future<void> completeActiveRide() async {
    await updateActiveRideStatus(RideStatus.completed);
  }

  Future<void> cancelActiveRide() async {
    await updateActiveRideStatus(RideStatus.cancelled);
  }

    Future<void> saveRideRating({
    required String rideId,
    required int rating,
    required String comment,
  }) async {
    final clamped = rating.clamp(1, 5);

    RideModel? updated;

    if (activeRide != null && activeRide!.id == rideId) {
      updated = activeRide!.copyWith(driverRating: clamped, ratingComment: comment);
      activeRide = updated;
    }

    final idx = rideHistory.indexWhere((r) => r.id == rideId);
    if (idx != -1) {
      updated = rideHistory[idx].copyWith(driverRating: clamped, ratingComment: comment);
      rideHistory[idx] = updated;
    }

    if (updated != null) {
      await _db.saveRide(updated);
    }

    notifyListeners();
  }

  void clearActiveRide() {
    activeRide = null;
    notifyListeners();
  }

  List<AppLatLng> get routePoints => lastRoute?.points ?? const [];
}
