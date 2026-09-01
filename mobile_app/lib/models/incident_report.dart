class IncidentReport {
  const IncidentReport({
    required this.id,
    this.title,
    this.incidentType,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.address,
    this.area,
    this.photoUrl,
    this.status = 'PENDING',
    this.occurredAt,
    this.createdAt,
    this.userId,
  });

  final int id;
  final String? title;
  final String? incidentType;
  final String description;
  final double latitude;
  final double longitude;
  final String? address;
  final String? area;
  final String? photoUrl;
  final String status; // 'PENDING', 'VERIFIED', 'RESOLVED'
  final DateTime? occurredAt;
  final DateTime? createdAt;
  final int? userId;

  String get displayTitle => title ?? incidentType ?? 'Incident Report #$id';
  String get category => incidentType ?? title ?? 'General Safety';

  factory IncidentReport.fromJson(Map<String, dynamic> json) {
    return IncidentReport(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      title: json['title'] as String?,
      incidentType: json['incident_type'] as String? ?? json['category'] as String? ?? json['type'] as String?,
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse('${json['latitude']}') ?? 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse('${json['longitude']}') ?? 0.0,
      address: json['address'] as String?,
      area: json['area'] as String?,
      photoUrl: json['media_url'] as String? ?? json['photo_url'] as String? ?? json['photo'] as String?,
      status: (json['status'] as String? ?? 'PENDING').toUpperCase(),
      occurredAt: json['occurred_at'] != null ? DateTime.tryParse('${json['occurred_at']}') : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
      userId: json['user_id'] is int ? json['user_id'] as int : int.tryParse('${json['user_id']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'incident_type': incidentType,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'area': area,
    'photo_url': photoUrl,
    'status': status,
    'occurred_at': occurredAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'user_id': userId,
  };
}
