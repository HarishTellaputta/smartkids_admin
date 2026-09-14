class McqQuestionModel {
  final int? id;

  final String subject;

  final int classId;
  final String? className;

  final int? createdByTeacherId;

  final String questionDate;

  final String question;

  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  final String correctAnswer;

  final int marks;

  final String? explanation;

  final String? questionImageUrl;
  final String? optionAImageUrl;
  final String? optionBImageUrl;
  final String? optionCImageUrl;
  final String? optionDImageUrl;

  final String? createdAt;
  final String? updatedAt;

  McqQuestionModel({
    this.id,
    required this.subject,
    required this.classId,
    this.className,
    this.createdByTeacherId,
    required this.questionDate,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.marks,
    this.explanation,
    this.questionImageUrl,
    this.optionAImageUrl,
    this.optionBImageUrl,
    this.optionCImageUrl,
    this.optionDImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory McqQuestionModel.fromJson(Map<String, dynamic> json) {
    return McqQuestionModel(
      id: json['id'] as int?,
      subject: json['subject']?.toString() ?? '',
      classId: json['classId'] ?? 0,
      className: json['className']?.toString(),
      createdByTeacherId: json['createdByTeacherId'] as int?,
      questionDate: json['questionDate']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      optionA: json['optionA']?.toString() ?? '',
      optionB: json['optionB']?.toString() ?? '',
      optionC: json['optionC']?.toString() ?? '',
      optionD: json['optionD']?.toString() ?? '',
      correctAnswer: json['correctAnswer']?.toString() ?? '',
      marks: json['marks'] ?? 0,
      explanation: json['explanation']?.toString(),
      questionImageUrl: json['questionImageUrl']?.toString(),
      optionAImageUrl: json['optionAImageUrl']?.toString(),
      optionBImageUrl: json['optionBImageUrl']?.toString(),
      optionCImageUrl: json['optionCImageUrl']?.toString(),
      optionDImageUrl: json['optionDImageUrl']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'classId': classId,
      'questionDate': questionDate,
      'question': question,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'correctAnswer': correctAnswer,
      'marks': marks,
      'explanation': explanation,
      'questionImageUrl': questionImageUrl,
      'optionAImageUrl': optionAImageUrl,
      'optionBImageUrl': optionBImageUrl,
      'optionCImageUrl': optionCImageUrl,
      'optionDImageUrl': optionDImageUrl,
    };
  }
}