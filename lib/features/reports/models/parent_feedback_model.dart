
class ParentFeedbackModel {
  final int id;
  final String type;
  final String subject;
  final String message;
  final DateTime? createdAt;

  final int? parentId;
  final String parentName;
  final String? parentPhone;
  final String? parentEmail;

  final int? studentId;
  final String? studentName;
  final String? admissionNo;

  const ParentFeedbackModel({
    required this.id,
    required this.type,
    required this.subject,
    required this.message,
    this.createdAt,
    this.parentId,
    required this.parentName,
    this.parentPhone,
    this.parentEmail,
    this.studentId,
    this.studentName,
    this.admissionNo,
  });

  factory ParentFeedbackModel.fromJson(Map<String, dynamic> json) {
    return ParentFeedbackModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'COMPLAINT',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      parentId: (json['parentId'] as num?)?.toInt(),
      parentName: json['parentName']?.toString() ?? 'Parent',
      parentPhone: json['parentPhone']?.toString(),
      parentEmail: json['parentEmail']?.toString(),
      studentId: (json['studentId'] as num?)?.toInt(),
      studentName: json['studentName']?.toString(),
      admissionNo: json['admissionNo']?.toString(),
    );
  }

  bool get isSuggestion =>
      type.toUpperCase().contains('SUGGESTION');

  String get displayType =>
      isSuggestion ? 'Suggestion' : 'Complaint';
}
