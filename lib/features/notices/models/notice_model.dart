class NoticeModel {
  final int? id;
  final String type;
  final String title;
  final String message;
  final String? payload;
  final String? recipientRole;
  final int? recipientUserId;
  final int? recipientId;
  final bool read;
  final DateTime? createdAt;
  final DateTime? readAt;

  final String? category;
  final String? audience;
  final String? status;
  final DateTime? publishedAt;

  NoticeModel({
    this.id,
    required this.type,
    required this.title,
    required this.message,
    this.payload,
    this.recipientRole,
    this.recipientUserId,
    this.recipientId,
    required this.read,
    this.createdAt,
    this.readAt,
    this.category,
    this.audience,
    this.status,
    this.publishedAt,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'],
      type: json['type'] ?? 'SCHOOL_NOTICE',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      payload: json['payload'],
      recipientRole: json['recipientRole'],
      recipientUserId: json['recipientUserId'],
      recipientId: json['recipientId'],
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'])
          : null,
      category: json['category'],
      audience: json['audience'],
      status: json['status'],
      publishedAt: json['publishedAt'] != null
          ? DateTime.tryParse(json['publishedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'payload': payload,
      'category': category,
      'audience': audience,
      'status': status,
    };
  }
}