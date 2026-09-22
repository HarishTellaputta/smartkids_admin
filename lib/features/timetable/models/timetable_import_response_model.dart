class TimetableImportResponseModel {
  final int totalRows;
  final int successCount;
  final int failedCount;
  final List<TimetableImportErrorModel> errors;

  const TimetableImportResponseModel({
    required this.totalRows,
    required this.successCount,
    required this.failedCount,
    required this.errors,
  });

  factory TimetableImportResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final errorsJson = json['errors'];

    return TimetableImportResponseModel(
      totalRows: _toInt(json['totalRows']),
      successCount: _toInt(json['successCount']),
      failedCount: _toInt(json['failedCount']),
      errors: errorsJson is List
          ? errorsJson
              .map(
                (item) => TimetableImportErrorModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class TimetableImportErrorModel {
  final int row;
  final String message;

  const TimetableImportErrorModel({
    required this.row,
    required this.message,
  });

  factory TimetableImportErrorModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TimetableImportErrorModel(
      row: _toInt(json['row']),
      message: json['message']?.toString() ?? 'Unknown error',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}