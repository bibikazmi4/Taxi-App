import 'driver_model.dart';
import 'location_model.dart';
import 'ride_option.dart';
import 'app_latlng.dart';

enum RideStatus {
  searching,
  driverAssigned,
  arriving,
  inTrip,
  completed,
  cancelled
}

extension RideStatusX on RideStatus {
  String get label {
    switch (this) {
      case RideStatus.searching:
        return "Searching";
      case RideStatus.driverAssigned:
        return "Driver Assigned";
      case RideStatus.arriving:
        return "Arriving";
      case RideStatus.inTrip:
        return "In Trip";
      case RideStatus.completed:
        return "Completed";
      case RideStatus.cancelled:
        return "Cancelled";
    }
  }

  /// 0.0 → 1.0 progress for UI (e.g., LinearProgressIndicator)
  double get progress {
    switch (this) {
      case RideStatus.searching:
        return 0.15;
      case RideStatus.driverAssigned:
        return 0.40;
      case RideStatus.arriving:
        return 0.65;
      case RideStatus.inTrip:
        return 0.85;
      case RideStatus.completed:
        return 1.0;
      case RideStatus.cancelled:
        return 0.0;
    }
  }
}

class RideModel {
  final String id;
  final DateTime createdAt;
  final LocationModel pickup;
  final LocationModel dropoff;
  final RideCategory category;
  final double distanceKm;
  final double durationMin;
  final double fare;
  final DriverModel driver;
  final List<AppLatLng> route; // polyline
  final RideStatus status;

  final int? driverRating; // 1..5
  final String? ratingComment;

  const RideModel({
    required this.id,
    required this.createdAt,
    required this.pickup,
    required this.dropoff,
    required this.category,
    required this.distanceKm,
    required this.durationMin,
    required this.fare,
    required this.driver,
    required this.route,
    required this.status,
    this.driverRating,
    this.ratingComment,
  });

  RideModel copyWith({
    RideStatus? status,
    List<AppLatLng>? route,
    double? durationMin,
    int? driverRating,
    String? ratingComment,
  }) {
    return RideModel(
      id: id,
      createdAt: createdAt,
      pickup: pickup,
      dropoff: dropoff,
      category: category,
      distanceKm: distanceKm,
      durationMin: durationMin ?? this.durationMin,
      fare: fare,
      driver: driver,
      route: route ?? this.route,
      status: status ?? this.status,
      driverRating: driverRating ?? this.driverRating,
      ratingComment: ratingComment ?? this.ratingComment,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "createdAt": createdAt.toIso8601String(),
        "pickup": pickup.toJson(),
        "dropoff": dropoff.toJson(),
        "category": category.name,
        "distanceKm": distanceKm,
        "durationMin": durationMin,
        "fare": fare,
        "driver": driver.toJson(),
        "route": route.map((p) => p.toJson()).toList(),
        "status": status.name,
        "driverRating": driverRating,
        "ratingComment": ratingComment,
      };

  factory RideModel.fromJson(Map<String, dynamic> json) => RideModel(
        id: json["id"] as String,
        createdAt: DateTime.parse(json["createdAt"] as String),
        pickup: LocationModel.fromJson(json["pickup"] as Map<String, dynamic>),
        dropoff:
            LocationModel.fromJson(json["dropoff"] as Map<String, dynamic>),
        category: RideCategory.values.firstWhere(
          (e) => e.name == (json["category"] as String),
        ),
        distanceKm: (json["distanceKm"] as num).toDouble(),
        durationMin: (json["durationMin"] as num).toDouble(),
        fare: (json["fare"] as num).toDouble(),
        driver: DriverModel.fromJson(json["driver"] as Map<String, dynamic>),
        route: (json["route"] as List<dynamic>)
            .map((e) => AppLatLng.fromJson(e as Map<String, dynamic>))
            .toList(),
        status: RideStatus.values.firstWhere(
          (e) => e.name == (json["status"] as String),
        ),
        driverRating: (json["driverRating"] as num?)?.toInt(),
        ratingComment: json["ratingComment"] as String?,
      );
}
