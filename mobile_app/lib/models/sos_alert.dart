class SOSAlert {
  const SOSAlert({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.address,
    this.status = 'ACTIVE',
    this.userId,
    this.resolvedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final double latitude;
  final double longitude;
  final String? address;
  final String status; // 'ACTIVE', 'RESOLVED', 'CANCELLED'
  final int? userId;
  final dynamic resolvedAt;
  final dynamic createdAt;
  final dynamic updatedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      latitude: (json['latitude'] is num)
          ? (json['latitude'] as num).toDouble()
          : double.tryParse('${json['latitude']}') ?? 0.0,
      longitude: (json['longitude'] is num)
          ? (json['longitude'] as num).toDouble()
          : double.tryParse('${json['longitude']}') ?? 0.0,
      address: json['address'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id']}'),
      resolvedAt: json['resolved_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'status': status,
    'user_id': userId,
    'resolved_at': resolvedAt?.toString(),
    'created_at': createdAt?.toString(),
    'updated_at': updatedAt?.toString(),
  };
}
