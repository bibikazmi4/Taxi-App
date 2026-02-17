import 'app_latlng.dart';

class LocationModel {
  final String label;
  final AppLatLng position;

  const LocationModel({required this.label, required this.position});

  Map<String, dynamic> toJson() => {
        "label": label,
        "position": position.toJson(),
      };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        label: json["label"] as String,
        position: AppLatLng.fromJson(json["position"] as Map<String, dynamic>),
      );
}
