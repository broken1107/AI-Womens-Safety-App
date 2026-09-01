class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'ALERT',
    this.isRead = false,
    this.data = const {},
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type; // 'SOS', 'CRIME_ALERT', 'SYSTEM', 'ROUTE_UPDATE'
  final bool isRead;
  final Map<String, dynamic> data;
  final DateTime? createdAt;

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    Map<String, dynamic>? data,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: '${json['id'] ?? DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Safety Alert',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'ALERT',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['read_at'] != null,
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : {},
      createdAt: json['created_at'] != null ? DateTime.tryParse('${json['created_at']}') : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type,
    'is_read': isRead,
    'data': data,
    'created_at': createdAt?.toIso8601String(),
  };
}
