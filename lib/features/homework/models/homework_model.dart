class HomeworkModel {
  final int? id;

  final int? classId;
  final String? className;

  final int? sectionId;
  final String? sectionName;

  final int? assignedByTeacherId;
  final String? assignedByTeacherName;
  final String? teacherEmployeeId;

  final int? subjectId;
  final String? subject;
  final String? subjectCode;

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
    this.subjectId,
    this.subject,
    this.subjectCode,
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
      // =========================================================
      // HOMEWORK
      // =========================================================

      id: _toInt(json['id']),

      // =========================================================
      // CLASS
      // =========================================================

      classId: _toInt(json['classId']),
      className: json['className']?.toString(),

      // =========================================================
      // SECTION
      // =========================================================

      sectionId: _toInt(json['sectionId']),
      sectionName: json['sectionName']?.toString(),

      // =========================================================
      // TEACHER
      // =========================================================

      assignedByTeacherId:
          _toInt(json['assignedByTeacherId']),

      assignedByTeacherName:
          json['assignedByTeacherName']?.toString(),

      teacherEmployeeId:
          json['teacherEmployeeId']?.toString(),

      // =========================================================
      // SUBJECT
      // Backend:
      // subjectId
      // subjectName
      // subjectCode
      //
      // UI uses `subject`, so subjectName is mapped to subject.
      // =========================================================

      subjectId: _toInt(json['subjectId']),

      subject: json['subjectName']?.toString() ??
          json['subject']?.toString(),

      subjectCode: json['subjectCode']?.toString(),

      // =========================================================
      // HOMEWORK DETAILS
      // =========================================================

      title: json['title']?.toString(),

      description:
          json['description']?.toString(),

      dueDate:
          json['dueDate']?.toString(),

      // =========================================================
      // STATUS
      // =========================================================

      status:
          json['status']?.toString(),

      // =========================================================
      // ATTACHMENT
      // =========================================================

      attachmentUrl:
          json['attachmentUrl']?.toString(),

      // =========================================================
      // PRIORITY
      // =========================================================

      priority:
          json['priority']?.toString(),

      // =========================================================
      // AUDIT
      // =========================================================

      createdAt:
          json['createdAt']?.toString(),

      updatedAt:
          json['updatedAt']?.toString(),
    );
  }

  // =============================================================
  // INTEGER CONVERTER
  // Handles:
  // int
  // double
  // String
  // null
  // =============================================================

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}