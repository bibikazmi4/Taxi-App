class AppLatLng {
  final double lat;
  final double lng;

  const AppLatLng(this.lat, this.lng);

  Map<String, dynamic> toJson() => {"lat": lat, "lng": lng};

  factory AppLatLng.fromJson(Map<String, dynamic> json) =>
      AppLatLng((json["lat"] as num).toDouble(), (json["lng"] as num).toDouble());

  @override
  String toString() => "$lat,$lng";
}
