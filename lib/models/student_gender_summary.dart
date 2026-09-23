class StudentGenderSummary {
  final int totalStudents;
  final int boys;
  final int girls;

  StudentGenderSummary({
    required this.totalStudents,
    required this.boys,
    required this.girls,
  });

  factory StudentGenderSummary.fromJson(Map<String, dynamic> json) {
    return StudentGenderSummary(
      totalStudents: (json['totalStudents'] as num?)?.toInt() ?? 0,
      boys: (json['boys'] as num?)?.toInt() ?? 0,
      girls: (json['girls'] as num?)?.toInt() ?? 0,
    );
  }
}