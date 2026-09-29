import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClassesExcelCard extends StatefulWidget {
  const ClassesExcelCard({super.key});

  @override
  State<ClassesExcelCard> createState() => _ClassesExcelCardState();
}

class _ClassesExcelCardState extends State<ClassesExcelCard> {
  bool _loading = false;

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // ============================================================
  // DIO
  // ============================================================

  Dio _createDio(String token) {
    return Dio(
      BaseOptions(
        baseUrl: 'http://localhost:8080',
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ============================================================
  // DOWNLOAD TEMPLATE
  // ============================================================

  Future<void> _downloadTemplate() async {
    try {
      final workbook = excel.Excel.createExcel();

      if (workbook.tables.containsKey('Sheet1')) {
        workbook.delete('Sheet1');
      }

      final sheet = workbook['Classes & Sections'];

      sheet.appendRow([
        excel.TextCellValue('Class Name'),
        excel.TextCellValue('Section Name'),
        excel.TextCellValue('Capacity'),
        excel.TextCellValue('Status'),
      ]);

      sheet.appendRow([
        excel.TextCellValue('Class 1'),
        excel.TextCellValue('A'),
        excel.IntCellValue(40),
        excel.TextCellValue('ACTIVE'),
      ]);

      sheet.appendRow([
        excel.TextCellValue('Class 1'),
        excel.TextCellValue('B'),
        excel.IntCellValue(40),
        excel.TextCellValue('ACTIVE'),
      ]);

      final bytes = workbook.encode();

      if (bytes == null) {
        _showMessage(
          'Failed to generate Excel file.',
          isError: true,
        );
        return;
      }

      final fileBytes = Uint8List.fromList(bytes);

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save Classes & Sections Template',
        fileName: 'classes_sections_template.xlsx',
        bytes: fileBytes,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;

      if (savedPath != null) {
        _showMessage(
          'Classes & Sections template saved successfully.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to create Excel template: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // COPY TABLE
  // ============================================================

  Future<void> _copyTable() async {
    const table = '''Class Name\tSection Name\tCapacity\tStatus
Class 1\tA\t40\tACTIVE
Class 1\tB\t40\tACTIVE''';

    await Clipboard.setData(
      const ClipboardData(
        text: table,
      ),
    );

    if (!mounted) return;

    _showMessage(
      'Classes & Sections table copied. Paste it directly into Excel.',
    );
  }

  // ============================================================
  // IMPORT EXCEL
  // ============================================================

  Future<void> _importExcel() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        _showMessage(
          'Selected Excel file is empty.',
          isError: true,
        );
        return;
      }

      final token = await _getToken();

      if (token == null || token.isEmpty) {
        _showMessage(
          'Login session expired. Please login again.',
          isError: true,
        );
        return;
      }

      setState(() {
        _loading = true;
      });

      final dio = _createDio(token);

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: file.name,
        ),
      });

      final response = await dio.post(
        '/api/v1/classes/import',
        data: formData,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      final data = response.data;

      final int totalRows =
          int.tryParse('${data['totalRows'] ?? 0}') ?? 0;

      final int created =
          int.tryParse('${data['created'] ?? 0}') ?? 0;

      final int updated =
          int.tryParse('${data['updated'] ?? 0}') ?? 0;

      final int errors =
          int.tryParse('${data['errors'] ?? 0}') ?? 0;

      _showImportResult(
        totalRows: totalRows,
        created: created,
        updated: updated,
        errors: errors,
        errorDetails: data['errorDetails'],
      );
    } on DioException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      String message = 'Excel import failed.';

      if (e.response?.data is Map &&
          e.response?.data['message'] != null) {
        message = e.response?.data['message'].toString() ?? message;
      } else if (e.response?.statusCode == 400) {
        message = 'Invalid Excel file or data.';
      } else if (e.response?.statusCode == 401) {
        message = 'Unauthorized. Please login again.';
      } else if (e.response?.statusCode == 403) {
        message = 'You do not have permission to import Excel.';
      } else if (e.response?.statusCode == 404) {
        message = 'Classes import API not found.';
      } else if (e.response?.statusCode != null &&
          e.response!.statusCode! >= 500) {
        message = 'Server error. Please try again later.';
      }

      _showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Something went wrong: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // IMPORT RESULT
  // ============================================================

  void _showImportResult({
    required int totalRows,
    required int created,
    required int updated,
    required int errors,
    dynamic errorDetails,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Classes & Sections Import Result',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultRow(
                    'Total Rows',
                    totalRows.toString(),
                  ),
                  _resultRow(
                    'Created',
                    created.toString(),
                  ),
                  _resultRow(
                    'Updated',
                    updated.toString(),
                  ),
                  _resultRow(
                    'Errors',
                    errors.toString(),
                  ),

                  if (errors > 0 &&
                      errorDetails is List &&
                      errorDetails.isNotEmpty) ...[
                    const SizedBox(height: 18),

                    const Text(
                      'Error Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),

                    const SizedBox(height: 8),

                    ...errorDetails.map(
                      (error) {
                        final row =
                            error is Map ? error['row'] : null;

                        final message =
                            error is Map
                                ? error['message']
                                : error.toString();

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(
                            bottom: 7,
                          ),
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFFECACA),
                            ),
                          ),
                          child: Text(
                            'Row $row: $message',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _resultRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.class_rounded,
                  color: Color(0xFF2563EB),
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),

              const Expanded(
                child: Text(
                  'Classes & Sections',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Classes, sections, capacity and status',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),

          const SizedBox(height: 14),

          // ------------------------------------------------------
          // TEMPLATE + COPY
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _loading ? null : _downloadTemplate,
                  icon: const Icon(
                    Icons.download_rounded,
                    size: 15,
                  ),
                  label: const Text(
                    'Template',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF2563EB),
                    side: const BorderSide(
                      color: Color(0xFF2563EB),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _loading ? null : _copyTable,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 15,
                  ),
                  label: const Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF374151),
                    side: const BorderSide(
                      color: Color(0xFFD1D5DB),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // IMPORT
          // ------------------------------------------------------

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _loading ? null : _importExcel,
              icon: _loading
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.upload_file_rounded,
                      size: 16,
                    ),
              label: Text(
                _loading
                    ? 'Importing...'
                    : 'Import Excel',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF93C5FD),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}