class AttendanceUpdateModel {
  final int teacherId;
  final String status;
  final String? remarks;

  AttendanceUpdateModel({
    required this.teacherId,
    required this.status,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'teacherId': teacherId,
      'status': status,
      'remarks': remarks,
    };
  }
}