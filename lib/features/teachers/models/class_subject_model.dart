class ClassSubjectModel {
  final int id;
  final int classId;
  final String className;
  final int subjectId;
  final String subjectName;
  final String subjectCode;

  ClassSubjectModel({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
  });

  factory ClassSubjectModel.fromJson(Map<String, dynamic> json) {
    return ClassSubjectModel(
      id: json['id'] ?? 0,
      classId: json['classId'] ?? 0,
      className: json['className'] ?? '',
      subjectId: json['subjectId'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
    };
  }
}