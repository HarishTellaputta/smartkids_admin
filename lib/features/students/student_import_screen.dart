import 'package:dio/dio.dart';
import 'package:excel/excel.dart' as excel;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/student_service.dart';

import 'package:smartkids_admin/features/exams/services/excel_file_picker_service.dart';

class StudentImportScreen extends StatefulWidget {
  final StudentService studentService;

  const StudentImportScreen({super.key, required this.studentService});

  @override
  State<StudentImportScreen> createState() => _StudentImportScreenState();
}

class _StudentImportScreenState extends State<StudentImportScreen> {
  String? selectedFileName;

  List<List<String>> rows = [];

  String? errorMessage;

  bool isLoading = false;
  bool isImporting = false;

  // Store selected Excel bytes so we can send
  // the same file to the backend.
  List<int>? selectedFileBytes;

  // ============================================================
  // PICK EXCEL FILE
  // ============================================================

  Future<void> _pickExcelFile() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      // Use the same working Excel picker service
      // already used by TimetableScreen.
      final selectedFile = await ExcelFilePickerService.pickExcelFile();

      if (selectedFile == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      debugPrint('SELECTED FILE: ${selectedFile.fileName}');

      final bytes = selectedFile.bytes;

      debugPrint('FILE BYTES: ${bytes.length}');

      if (bytes.isEmpty) {
        throw Exception('Selected Excel file is empty or could not be read.');
      }

      // ========================================================
      // READ EXCEL
      // ========================================================

      final workbook = excel.Excel.decodeBytes(bytes);

      if (workbook.tables.isEmpty) {
        throw Exception('Excel file does not contain any worksheet.');
      }

      final sheetName = workbook.tables.keys.first;
      final sheet = workbook.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('Excel worksheet is empty.');
      }

      final List<List<String>> parsedRows = [];

      for (final row in sheet.rows) {
        final List<String> rowData = [];

        for (final cell in row) {
          rowData.add(cell?.value?.toString().trim() ?? '');
        }

        parsedRows.add(rowData);
      }

      if (parsedRows.length < 2) {
        throw Exception(
          'Excel file must contain a header row and at least one student.',
        );
      }

      if (!mounted) return;

      setState(() {
        selectedFileName = selectedFile.fileName;

        // IMPORTANT:
        // Keep the Excel bytes for backend upload.
        selectedFileBytes = bytes;

        rows = parsedRows;

        isLoading = false;
      });
    } catch (e) {
      debugPrint('EXCEL READ ERROR: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');

        isLoading = false;
        rows = [];
        selectedFileBytes = null;
      });
    }
  }

  // ============================================================
  // IMPORT EXCEL TO BACKEND
  // ============================================================
  Future<void> _importStudents() async {
    if (selectedFileBytes == null || selectedFileBytes!.isEmpty) {
      await _showImportFailure(
        'Please select an Excel file before starting the import.',
      );
      return;
    }

    setState(() {
      errorMessage = null;
      isImporting = true;
    });

    try {
      debugPrint('========== STUDENT EXCEL IMPORT ==========');
      debugPrint('FILE NAME: $selectedFileName');
      debugPrint('FILE SIZE: ${selectedFileBytes!.length}');

      final result = await widget.studentService.importStudentsExcel(
        bytes: selectedFileBytes!,
        fileName: selectedFileName ?? 'students.xlsx',
      );

      debugPrint('========== IMPORT SUCCESS ==========');
      debugPrint('RESULT: $result');

      if (!mounted) return;

      setState(() {
        isImporting = false;
      });

      await _showImportSuccess(result);
    } on DioException catch (e) {
      debugPrint('IMPORT DIO ERROR: ${e.message}');
      debugPrint('IMPORT STATUS: ${e.response?.statusCode}');
      debugPrint('IMPORT RESPONSE: ${e.response?.data}');

      if (!mounted) return;

      final message = _getBackendErrorMessage(e);

      setState(() {
        isImporting = false;
        errorMessage = message;
      });

      await _showImportFailure(message);
    } catch (e) {
      debugPrint('IMPORT ERROR: $e');

      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        isImporting = false;
        errorMessage = message;
      });

      await _showImportFailure(message);
    }
  }

  // ============================================================
  // BACKEND ERROR MESSAGE
  // ============================================================

  String _getBackendErrorMessage(DioException e) {
    final data = e.response?.data;

    if (data is String && data.trim().isNotEmpty) {
      return data;
    }

    if (data is Map) {
      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    if (e.response?.statusCode == 401) {
      return 'Session expired. Please login again.';
    }

    if (e.response?.statusCode == 403) {
      return 'You do not have permission to import students.';
    }

    if (e.response?.statusCode == 400) {
      return 'Invalid Excel file or student data.';
    }

    return e.message ?? 'Failed to import students.';
  }

  // ============================================================
  // SUCCESS DIALOG
  // ============================================================

  Future<void> _showImportSuccess(String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 35,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --------------------------------------------------
                  // SUCCESS HEADER
                  // --------------------------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(26),
                        topRight: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Import Successful',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          'Student records have been imported successfully.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --------------------------------------------------
                  // CONTENT
                  // --------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Import Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // File information
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF16A34A,
                                  ).withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.description_outlined,
                                  color: Color(0xFF16A34A),
                                  size: 22,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Excel File',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      selectedFileName ?? 'students.xlsx',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Backend response
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF16A34A),
                                size: 21,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  message,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF166534),
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Done button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();

                              // Return to StudentsScreen
                              Navigator.of(context).pop(true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 19),
                                SizedBox(width: 8),
                                Text(
                                  'Done',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showImportFailure(String message) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 35,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --------------------------------------------------
                  // ERROR HEADER
                  // --------------------------------------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(26),
                        topRight: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.17),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Import Failed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          'We could not import the student records.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --------------------------------------------------
                  // ERROR CONTENT
                  // --------------------------------------------------
                  Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxHeight: 220),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7F7),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: SingleChildScrollView(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 21,
                                ),

                                const SizedBox(width: 11),

                                Expanded(
                                  child: SelectableText(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF991B1B),
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Please check the Excel format and student data, then try again.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF92400E),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF374151),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Import Students'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadSection(),

            const SizedBox(height: 20),

            if (errorMessage != null) _buildError(),

            if (rows.isNotEmpty) ...[
              _buildPreviewHeader(),

              const SizedBox(height: 12),

              Expanded(child: _buildPreviewTable()),

              const SizedBox(height: 14),

              _buildImportButton(),
            ] else if (!isLoading)
              Expanded(child: _buildEmptyState()),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UPLOAD SECTION
  // ============================================================

  Widget _buildUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.table_chart_outlined, color: Colors.green),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Import Students from Excel',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 4),

                Text(
                  selectedFileName ??
                      'Select an .xlsx file containing student details.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          OutlinedButton.icon(
            onPressed: isLoading || isImporting ? null : _pickExcelFile,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(isLoading ? 'Reading...' : 'Choose Excel'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMPORT BUTTON
  // ============================================================

  Widget _buildImportButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: isImporting ? null : _importStudents,
        icon: isImporting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload_outlined, size: 19),
        label: Text(isImporting ? 'Importing...' : 'Import Students'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREVIEW HEADER
  // ============================================================

  Widget _buildPreviewHeader() {
    final dataRows = rows.length - 1;

    return Row(
      children: [
        const Text(
          'Preview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),

        const SizedBox(width: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$dataRows students',
            style: const TextStyle(
              color: Colors.indigo,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PREVIEW TABLE
  // ============================================================

  Widget _buildPreviewTable() {
    final headers = rows.first;
    final dataRows = rows.skip(1).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowHeight: 48,
            dataRowMinHeight: 46,
            dataRowMaxHeight: 56,
            columns: [
              ...headers.map(
                (header) => DataColumn(
                  label: Text(
                    header.isEmpty ? '-' : header,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            rows: dataRows.map((row) {
              return DataRow(
                cells: List.generate(headers.length, (index) {
                  final value = index < row.length ? row[index] : '';

                  return DataCell(
                    Text(
                      value.isEmpty ? '-' : value,
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: 56,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 12),

          const Text(
            'No Excel file selected',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          Text(
            'Choose an .xlsx file to preview student records.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
