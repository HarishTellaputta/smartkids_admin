
class ExaminationImportResponseModel {
  final int totalRows;
  final int created;
  final int updated;
  final int errors;
  final List<ExaminationImportErrorModel> errorDetails;

  const ExaminationImportResponseModel({
    required this.totalRows,
    required this.created,
    required this.updated,
    required this.errors,
    required this.errorDetails,
  });

  factory ExaminationImportResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final errorList = json['errorDetails'];

    return ExaminationImportResponseModel(
      totalRows: _toInt(json['totalRows']),
      created: _toInt(json['created']),
      updated: _toInt(json['updated']),
      errors: _toInt(json['errors']),
      errorDetails: errorList is List
          ? errorList
              .whereType<Map>()
              .map(
                (item) => ExaminationImportErrorModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ExaminationImportErrorModel {
  final int row;
  final String message;

  const ExaminationImportErrorModel({
    required this.row,
    required this.message,
  });

  factory ExaminationImportErrorModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExaminationImportErrorModel(
      row: _toInt(json['row']),
      message: json['message']?.toString() ?? 'Unknown error',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

