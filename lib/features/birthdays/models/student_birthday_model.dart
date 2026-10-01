class StudentBirthdayModel {
  final int? studentId;
  final String? studentName;
  final String? admissionNo;
  final DateTime? dateOfBirth;
  final DateTime? birthdayDate;
  final bool birthdayToday;
  final bool photoAlreadyAdded;
  final int? birthdayStatusId;
  final String? photoUrl;
  final String? message;

  StudentBirthdayModel({
    this.studentId,
    this.studentName,
    this.admissionNo,
    this.dateOfBirth,
    this.birthdayDate,
    this.birthdayToday = false,
    this.photoAlreadyAdded = false,
    this.birthdayStatusId,
    this.photoUrl,
    this.message,
  });

  factory StudentBirthdayModel.fromJson(Map<String, dynamic> json) {
    return StudentBirthdayModel(
      studentId: json['studentId'],
      studentName: json['studentName'],
      admissionNo: json['admissionNo'],
      dateOfBirth: _parseDate(json['dateOfBirth']),
      birthdayDate: _parseDate(json['birthdayDate']),
      birthdayToday: json['birthdayToday'] ?? false,
      photoAlreadyAdded: json['photoAlreadyAdded'] ?? false,
      birthdayStatusId: json['birthdayStatusId'],
      photoUrl: json['photoUrl'],
      message: json['message'],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}