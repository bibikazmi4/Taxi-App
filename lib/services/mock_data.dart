import 'dart:math';
import '../models/driver_model.dart';
import '../models/ride_option.dart';

class MockData {
  static final _rand = Random();

  static DriverModel randomDriver(RideCategory cat) {
    final names = ["Ali", "Hassan", "Ayesha", "Zain", "Sara", "Usman"];
    final vehicles = {
      RideCategory.bike: "Honda CD 70",
      RideCategory.mini: "Suzuki Alto",
      RideCategory.car: "Toyota Corolla",
      RideCategory.courier: "Courier Delivery",
    };
    final plates = ["KHI-1234", "KHI-9081", "KHI-5510", "KHI-7741", "KHI-6640"];
    final phones = [
      "+92 300 1234567",
      "+92 301 2345678",
      "+92 302 3456789",
      "+92 303 4567890",
      "+92 304 5678901"
    ];

    return DriverModel(
      name:
          "${names[_rand.nextInt(names.length)]} ${String.fromCharCode(65 + _rand.nextInt(26))}.",
      rating: 4.2 + _rand.nextDouble() * 0.7,
      vehicleName: vehicles[cat]!,
      plateNumber: plates[_rand.nextInt(plates.length)],
      seats: cat.seats,
      avatarAsset: "assets/images/driver_avatar.png",
      phone: phones[_rand.nextInt(phones.length)], // NEW
    );
  }
}
