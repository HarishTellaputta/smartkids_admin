class HomeworkModel {
  final int? id;
  final int? classId;
  final String? className;
  final int? sectionId;
  final String? sectionName;
  final int? assignedByTeacherId;
  final String? assignedByTeacherName;
  final String? teacherEmployeeId;
  final String? subject;
  final String? title;
  final String? description;
  final String? dueDate;
  final String? status;
  final String? attachmentUrl;
  final String? priority;
  final String? createdAt;
  final String? updatedAt;

  HomeworkModel({
    this.id,
    this.classId,
    this.className,
    this.sectionId,
    this.sectionName,
    this.assignedByTeacherId,
    this.assignedByTeacherName,
    this.teacherEmployeeId,
    this.subject,
    this.title,
    this.description,
    this.dueDate,
    this.status,
    this.attachmentUrl,
    this.priority,
    this.createdAt,
    this.updatedAt,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: _toInt(json['id']),
      classId: _toInt(json['classId']),
      className: json['className']?.toString(),
      sectionId: _toInt(json['sectionId']),
      sectionName: json['sectionName']?.toString(),
      assignedByTeacherId: _toInt(json['assignedByTeacherId']),
      assignedByTeacherName:
          json['assignedByTeacherName']?.toString(),
      teacherEmployeeId:
          json['teacherEmployeeId']?.toString(),
      subject: json['subject']?.toString(),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      dueDate: json['dueDate']?.toString(),
      status: json['status']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      priority: json['priority']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value.toString());
  }
}