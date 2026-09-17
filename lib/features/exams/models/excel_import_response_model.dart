
class ExcelImportResponseModel {
  final int totalRows;
  final int created;
  final int updated;
  final int errors;
  final List<ExcelImportErrorModel> errorDetails;

  const ExcelImportResponseModel({
    required this.totalRows,
    required this.created,
    required this.updated,
    required this.errors,
    required this.errorDetails,
  });

  factory ExcelImportResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final errors = json['errorDetails'];

    return ExcelImportResponseModel(
      totalRows: _toInt(json['totalRows']),
      created: _toInt(json['created']),
      updated: _toInt(json['updated']),
      errors: _toInt(json['errors']),
      errorDetails: errors is List
          ? errors
              .whereType<Map>()
              .map(
                (item) => ExcelImportErrorModel.fromJson(
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

class ExcelImportErrorModel {
  final int row;
  final String message;

  const ExcelImportErrorModel({
    required this.row,
    required this.message,
  });

  factory ExcelImportErrorModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExcelImportErrorModel(
      row: _toInt(json['row']),
      message: json['message']?.toString() ?? 'Unknown error',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
