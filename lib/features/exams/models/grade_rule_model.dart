class GradeRuleModel {
  final int? id;
  final String grade;
  final double minimumPercentage;
  final double maximumPercentage;

  const GradeRuleModel({
    this.id,
    required this.grade,
    required this.minimumPercentage,
    required this.maximumPercentage,
  });

  factory GradeRuleModel.fromJson(Map<String, dynamic> json) {
    return GradeRuleModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      grade: json['grade']?.toString() ?? '',
      minimumPercentage:
          double.tryParse(json['minimumPercentage']?.toString() ?? '') ?? 0,
      maximumPercentage:
          double.tryParse(json['maximumPercentage']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'grade': grade,
      'minimumPercentage': minimumPercentage,
      'maximumPercentage': maximumPercentage,
    };
  }

  GradeRuleModel copyWith({
    int? id,
    String? grade,
    double? minimumPercentage,
    double? maximumPercentage,
  }) {
    return GradeRuleModel(
      id: id ?? this.id,
      grade: grade ?? this.grade,
      minimumPercentage: minimumPercentage ?? this.minimumPercentage,
      maximumPercentage: maximumPercentage ?? this.maximumPercentage,
    );
  }
}
