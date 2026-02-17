class DriverModel {
  final String name;
  final double rating;
  final String vehicleName;
  final String plateNumber;
  final int seats;
  final String avatarAsset;
  final String phone; // NEW FIELD

  const DriverModel({
    required this.name,
    required this.rating,
    required this.vehicleName,
    required this.plateNumber,
    required this.seats,
    required this.avatarAsset,
    required this.phone, // NEW FIELD
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "rating": rating,
        "vehicleName": vehicleName,
        "plateNumber": plateNumber,
        "seats": seats,
        "avatarAsset": avatarAsset,
        "phone": phone, // NEW FIELD
      };

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
        name: json["name"] as String,
        rating: (json["rating"] as num).toDouble(),
        vehicleName: json["vehicleName"] as String,
        plateNumber: json["plateNumber"] as String,
        seats: (json["seats"] as num).toInt(),
        avatarAsset: json["avatarAsset"] as String,
        phone: json["phone"] as String, // NEW FIELD
      );
}
