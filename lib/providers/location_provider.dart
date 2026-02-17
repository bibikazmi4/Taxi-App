import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_latlng.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _service;

  LocationProvider(this._service);

  bool isLoading = false;
  String? errorMessage;

  Position? currentPosition;
  LocationModel? pickup;
  LocationModel? dropoff;

  Future<void> loadCurrentLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final pos = await _service.getCurrentPosition();
      if (pos == null) {
        errorMessage =
            "Location permission denied or location services are turned off.";
      } else {
        currentPosition = pos;
      }
    } catch (e) {
      errorMessage = "Failed to get location: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setPickup(LocationModel value) {
    pickup = value;
    notifyListeners();
  }

  void setDropoff(LocationModel value) {
    dropoff = value;
    notifyListeners();
  }

  void swap() {
    final tmp = pickup;
    pickup = dropoff;
    dropoff = tmp;
    notifyListeners();
  }

  void clearSelection() {
    pickup = null;
    dropoff = null;
    notifyListeners();
  }

  /// Helper for Places-less mode
  List<LocationModel> get presetLocations => Constants.presetLocations
      .map((e) => LocationModel(
            label: e["label"] as String,
            position: AppLatLng((e["lat"] as num).toDouble(), (e["lng"] as num).toDouble()),
          ))
      .toList(growable: false);
}
