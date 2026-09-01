class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.userId,
    this.isPrimary = false,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String phone;
  final String relationship;
  final int? userId;
  final bool isPrimary;
  final String? createdAt;
  final String? updatedAt;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? json['phone_number'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'Family',
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id']}'),
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'relationship': relationship,
    'user_id': userId,
    'is_primary': isPrimary,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  EmergencyContact copyWith({
    int? id,
    String? name,
    String? phone,
    String? relationship,
    int? userId,
    bool? isPrimary,
    String? createdAt,
    String? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      userId: userId ?? this.userId,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
