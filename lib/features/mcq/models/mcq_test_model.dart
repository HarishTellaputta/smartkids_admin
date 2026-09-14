class McqTestQuestionModel {
  final int? id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final int marks;

  McqTestQuestionModel({
    this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.marks,
  });

  factory McqTestQuestionModel.fromJson(Map<String, dynamic> json) {
    return McqTestQuestionModel(
      id: json['id'] as int?,
      question: json['question']?.toString() ?? '',
      optionA: json['optionA']?.toString() ?? '',
      optionB: json['optionB']?.toString() ?? '',
      optionC: json['optionC']?.toString() ?? '',
      optionD: json['optionD']?.toString() ?? '',
      marks: json['marks'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
      'marks': marks,
    };
  }
}

class McqTestModel {
  final int? id;

  final int classId;
  final int? sectionId;

  final String? className;
  final String? sectionName;

  final String subject;
  final String status;

  final String date;
  final String startTime;

  final int duration;
  final int numberOfQuestions;

  final List<McqTestQuestionModel> questions;

  McqTestModel({
    this.id,
    required this.classId,
    this.sectionId,
    this.className,
    this.sectionName,
    required this.subject,
    required this.status,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.numberOfQuestions,
    required this.questions,
  });

  factory McqTestModel.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'];

    List<McqTestQuestionModel> parsedQuestions = [];

    if (questionsJson is List) {
      parsedQuestions = questionsJson
          .whereType<Map>()
          .map(
            (question) => McqTestQuestionModel.fromJson(
              Map<String, dynamic>.from(question),
            ),
          )
          .toList();
    }

    return McqTestModel(
      id: json['id'] as int?,
      classId: json['classId'] ?? 0,
      sectionId: json['sectionId'] as int?,
      className: json['className']?.toString(),
      sectionName: json['sectionName']?.toString(),
      subject: json['subject']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      duration: json['duration'] ?? 0,
      numberOfQuestions: json['numberOfQuestions'] ?? 0,
      questions: parsedQuestions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'sectionId': sectionId,
      'subject': subject,
      'date': date,
      'startTime': startTime,
      'duration': duration,
      'numberOfQuestions': numberOfQuestions,
    };
  }
}