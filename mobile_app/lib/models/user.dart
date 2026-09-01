class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.emailVerifiedAt,
    this.profilePhotoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? emailVerifiedAt;
  final String? profilePhotoUrl;
  final String? createdAt;
  final String? updatedAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String? ?? json['avatar'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'email_verified_at': emailVerifiedAt,
    'profile_photo_url': profilePhotoUrl,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? emailVerifiedAt,
    String? profilePhotoUrl,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
