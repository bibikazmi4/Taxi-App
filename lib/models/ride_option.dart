enum RideCategory { bike, mini, car, courier }

extension RideCategoryX on RideCategory {
  String get label {
    switch (this) {
      case RideCategory.bike:
        return "Bike";
      case RideCategory.mini:
        return "Mini";
      case RideCategory.car:
        return "Car";
      case RideCategory.courier:
        return "Courier";
    }
  }

  /// Seats are shown for ride categories only.
  int get seats {
    switch (this) {
      case RideCategory.bike:
        return 1;
      case RideCategory.mini:
        return 3;
      case RideCategory.car:
        return 4;
      case RideCategory.courier:
        return 0;
    }
  }

  /// base fare in PKR
  double get baseFare {
    switch (this) {
      case RideCategory.bike:
        return 30;
      case RideCategory.mini:
        return 45;
      case RideCategory.car:
        return 70;
      case RideCategory.courier:
        return 60;
    }
  }

  /// per km fare in PKR
  double get perKm {
    switch (this) {
      case RideCategory.bike:
        return 16;
      case RideCategory.mini:
        return 20;
      case RideCategory.car:
        return 28;
      case RideCategory.courier:
        return 24;
    }
  }

  String get asset {
    switch (this) {
      case RideCategory.bike:
        return "assets/images/vehicle_bike.png";
      case RideCategory.mini:
        return "assets/images/vehicle_mini.png";
      case RideCategory.car:
        return "assets/images/vehicle_car.png";
      case RideCategory.courier:
        return "assets/images/vehicle_courier.png";
    }
  }

  bool get isDelivery => this == RideCategory.courier;
}

class RideOption {
  final RideCategory category;
  final double estimatedArrivalMinutes;
  final double price;

  const RideOption({
    required this.category,
    required this.estimatedArrivalMinutes,
    required this.price,
  });
}
