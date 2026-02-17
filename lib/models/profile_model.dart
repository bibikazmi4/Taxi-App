class ProfileModel {
  final String name;
  final String phone;
  final String email;

  const ProfileModel({
    required this.name,
    required this.phone,
    required this.email,
  });

  ProfileModel copyWith({String? name, String? phone, String? email}) {
    return ProfileModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': 1,
        'name': name,
        'phone': phone,
        'email': email,
      };

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
        name: (map['name'] as String?) ?? '',
        phone: (map['phone'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
      );
}
