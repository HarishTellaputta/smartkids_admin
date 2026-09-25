import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartkids_admin/features/exams/models/examination_model.dart';
import 'package:smartkids_admin/features/exams/services/examination_service.dart';
import 'package:smartkids_admin/features/exams/services/examination_import_service.dart';
import 'package:smartkids_admin/features/exams/widgets/examination_import_dialog.dart';
import 'package:smartkids_admin/features/exams/services/examination_excel_picker_service.dart';
import 'package:smartkids_admin/features/exams/models/excel_import_response_model.dart';
import 'package:smartkids_admin/features/exams/services/excel_file_picker_service.dart';
import 'package:smartkids_admin/features/exams/services/examination_bulk_import_service.dart';
import '../../features/exams/exam_details_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  ExaminationService? _service;
  ExaminationImportService? _importService;
  ExaminationBulkImportService? _bulkImportService;

  List<ExaminationModel> exams = [];
  List<ExamScheduleModel> selectedSchedules = [];

  bool isLoading = true;
  bool isSaving = false;
  bool isLoadingSchedules = false;

  bool isImportingResults = false;
  bool isImportingSchedules = false;
  bool isImportingGradeRules = false;

  String selectedStatus = 'All';
  String selectedExamType = 'All';
  String searchQuery = '';

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      debugPrint('========================================');
      debugPrint('EXAM SCREEN INITIALIZE');
      debugPrint('TOKEN EXISTS: ${token != null && token.isNotEmpty}');
      debugPrint('========================================');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = 'Authentication token not found.';
        });
        return;
      }

      _service = ExaminationService(token);
      _importService = ExaminationImportService(token);
      _bulkImportService = ExaminationBulkImportService(token);

      await _loadExaminations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD EXAMINATIONS
  // ============================================================

  Future<void> _loadExaminations() async {
    if (_service == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _service!.getExaminations();

      if (!mounted) return;

      setState(() {
        exams = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // IMPORT EXAMINATIONS
  // ============================================================

  Future<void> _importExaminationsExcel() async {
    if (_importService == null) {
      _showSnack('Examination import service is not initialized.');
      return;
    }

    try {
      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      if (selectedFile == null) return;

      setState(() {
        isSaving = true;
      });

      final importResult = await _importService!.importExaminationsExcel(
        bytes: selectedFile.bytes,
        fileName: selectedFile.fileName,
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      await showDialog(
        context: context,
        builder: (context) {
          return ExaminationImportDialog(result: importResult);
        },
      );

      await _loadExaminations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // BULK RESULTS IMPORT
  // ============================================================

  Future<void> _importResultsExcel() async {
    if (_bulkImportService == null) {
      _showSnack('Bulk import service is not initialized.');
      return;
    }

    if (isImportingResults) return;

    try {
      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      if (selectedFile == null) return;

      if (!mounted) return;

      setState(() {
        isImportingResults = true;
      });

      final result = await _bulkImportService!.importResults(
        bytes: selectedFile.bytes,
        fileName: selectedFile.fileName,
      );

      if (!mounted) return;

      setState(() {
        isImportingResults = false;
      });

      await _showBulkImportResult(title: 'Exam Results Import', result: result);

      await _loadExaminations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isImportingResults = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // BULK SCHEDULE IMPORT
  // ============================================================

  Future<void> _importSchedulesExcel() async {
    if (_bulkImportService == null) {
      _showSnack('Bulk import service is not initialized.');
      return;
    }

    if (isImportingSchedules) return;

    try {
      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      if (selectedFile == null) return;

      if (!mounted) return;

      setState(() {
        isImportingSchedules = true;
      });

      final result = await _bulkImportService!.importSchedules(
        bytes: selectedFile.bytes,
        fileName: selectedFile.fileName,
      );

      if (!mounted) return;

      setState(() {
        isImportingSchedules = false;
      });

      await _showBulkImportResult(
        title: 'Exam Schedules Import',
        result: result,
      );

      await _loadExaminations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isImportingSchedules = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // BULK GRADE RULE IMPORT
  // ============================================================

  Future<void> _importGradeRulesExcel() async {
    if (_bulkImportService == null) {
      _showSnack('Bulk import service is not initialized.');
      return;
    }

    if (isImportingGradeRules) return;

    try {
      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      if (selectedFile == null) return;

      if (!mounted) return;

      setState(() {
        isImportingGradeRules = true;
      });

      final result = await _bulkImportService!.importGradeRules(
        bytes: selectedFile.bytes,
        fileName: selectedFile.fileName,
      );

      if (!mounted) return;

      setState(() {
        isImportingGradeRules = false;
      });

      await _showBulkImportResult(title: 'Grade Rules Import', result: result);

      await _loadExaminations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isImportingGradeRules = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // BULK IMPORT RESULT
  // ============================================================

  Future<void> _showBulkImportResult({
    required String title,
    required ExcelImportResponseModel result,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 550,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _importResultCard(
                        'Total Rows',
                        result.totalRows.toString(),
                        Icons.table_rows_outlined,
                        const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _importResultCard(
                        'Created',
                        result.created.toString(),
                        Icons.add_circle_outline,
                        const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _importResultCard(
                        'Updated',
                        result.updated.toString(),
                        Icons.edit_outlined,
                        const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _importResultCard(
                        'Errors',
                        result.errors.toString(),
                        Icons.error_outline,
                        const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                if (result.errorDetails.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Error Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: result.errorDetails.length,
                      itemBuilder: (context, index) {
                        final error = result.errorDetails[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Row ${error.row}: ${error.message}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  Widget _importResultCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.14)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERED EXAMS
  // ============================================================

  List<ExaminationModel> get filteredExams {
    return exams.where((exam) {
      final examStatus = exam.status.trim().toUpperCase();
      final examType = exam.examType.trim().toUpperCase();

      final statusMatch =
          selectedStatus == 'All' ||
          examStatus == selectedStatus.trim().toUpperCase();

      final typeMatch =
          selectedExamType == 'All' ||
          examType == selectedExamType.trim().toUpperCase();

      final searchMatch =
          searchQuery.isEmpty ||
          exam.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          exam.examType.toLowerCase().contains(searchQuery.toLowerCase()) ||
          exam.status.toLowerCase().contains(searchQuery.toLowerCase());

      return statusMatch && typeMatch && searchMatch;
    }).toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get totalExams => exams.length;

  int get upcomingExams =>
      exams.where((e) => e.status.toUpperCase() == 'UPCOMING').length;

  int get scheduledExams =>
      exams.where((e) => e.status.toUpperCase() == 'SCHEDULED').length;

  int get completedExams =>
      exams.where((e) => e.status.toUpperCase() == 'COMPLETED').length;

  int get draftExams =>
      exams.where((e) => e.status.trim().toUpperCase() == 'DRAFT').length;

  int get publishedExams =>
      exams.where((e) => e.status.trim().toUpperCase() == 'PUBLISHED').length;

  // ============================================================
  // CREATE / EDIT
  // ============================================================

  void _showCreateExamDialog() {
    _showExamDialog();
  }

  void _showEditExamDialog(ExaminationModel exam) {
    _showExamDialog(exam: exam);
  }

  // ============================================================
  // EXAM DIALOG
  // ============================================================

  void _showExamDialog({ExaminationModel? exam}) {
    final nameController = TextEditingController(text: exam?.name ?? '');

    final descriptionController = TextEditingController(
      text: exam?.description ?? '',
    );

    final academicYearController = TextEditingController(
      text: exam?.academicYearId?.toString() ?? '1',
    );

    final yearController = TextEditingController(
      text: exam?.year.toString() ?? DateTime.now().year.toString(),
    );

    String examType = exam?.examType ?? 'UNIT_TEST';
    String status = exam?.status ?? 'DRAFT';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              title: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exam == null
                          ? 'Create New Examination'
                          : 'Edit Examination',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: _inputDecoration(
                          label: 'Exam Name',
                          icon: Icons.assignment_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          label: 'Description',
                          icon: Icons.description_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: academicYearController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                label: 'Academic Year ID',
                                icon: Icons.school_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: yearController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                label: 'Year',
                                icon: Icons.calendar_today_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: examType,
                        decoration: _inputDecoration(
                          label: 'Exam Type',
                          icon: Icons.category_outlined,
                        ),
                        items:
                            const [
                              'UNIT_TEST',
                              'PERIODIC_TEST',
                              'MID_TERM',
                              'ANNUAL',
                              'TERMINAL',
                              'HALF_YEARLY',
                              'OTHER',
                            ].map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(_prettyEnum(item)),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              examType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: _inputDecoration(
                          label: 'Status',
                          icon: Icons.flag_outlined,
                        ),
                        items:
                            const [
                              'DRAFT',
                              'UPCOMING',
                              'SCHEDULED',
                              'PUBLISHED',
                              'COMPLETED',
                              'CANCELLED',
                            ].map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(_prettyEnum(item)),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              status = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final description = descriptionController.text.trim();

                          final academicYearId = int.tryParse(
                            academicYearController.text.trim(),
                          );

                          final year = int.tryParse(yearController.text.trim());

                          if (name.isEmpty) {
                            _showSnack('Please enter exam name.');
                            return;
                          }

                          if (academicYearId == null) {
                            _showSnack('Please enter valid Academic Year ID.');
                            return;
                          }

                          if (year == null) {
                            _showSnack('Please enter valid year.');
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            ExaminationModel result;

                            if (exam == null) {
                              result = await _service!.createExamination(
                                academicYearId: academicYearId,
                                name: name,
                                description: description,
                                examType: examType,
                                year: year,
                                status: status,
                              );
                            } else {
                              result = await _service!.updateExamination(
                                id: exam.id!,
                                academicYearId: academicYearId,
                                name: name,
                                description: description,
                                examType: examType,
                                year: year,
                                status: status,
                              );
                            }

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            setState(() {
                              if (exam == null) {
                                exams.insert(0, result);
                              } else {
                                final index = exams.indexWhere(
                                  (e) => e.id == exam.id,
                                );

                                if (index != -1) {
                                  exams[index] = result;
                                }
                              }
                            });

                            _showSnack(
                              exam == null
                                  ? 'Examination created successfully.'
                                  : 'Examination updated successfully.',
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              isSaving = false;
                            });

                            _showSnack(
                              e.toString().replaceFirst('Exception: ', ''),
                            );
                          } finally {
                            isSaving = false;
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(exam == null ? 'Create Exam' : 'Update Exam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showExamDetails(ExaminationModel exam) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExamDetailsScreen(
        exam: exam,
        service: _service!,
      ),
    ),
  );
}

  Widget _detailHeaderCard(ExaminationModel exam) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _detailMetric(
                  'Exam ID',
                  '${exam.id ?? '-'}',
                  Icons.tag_outlined,
                ),
              ),
              Expanded(
                child: _detailMetric(
                  'Year',
                  '${exam.year}',
                  Icons.calendar_today_outlined,
                ),
              ),
              Expanded(
                child: _detailMetric(
                  'Academic Year',
                  '${exam.academicYearId ?? '-'}',
                  Icons.school_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _detailMetric(
                  'Exam Type',
                  _prettyEnum(exam.examType),
                  Icons.category_outlined,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    _statusBadge(exam.status),
                  ],
                ),
              ),
            ],
          ),
          if (exam.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.75),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                exam.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF4F46E5)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SCHEDULE TABLE
  // ============================================================

  Widget _scheduleTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
          headingRowHeight: 46,
          dataRowMinHeight: 56,
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
          columns: const [
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Class')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Marks')),
            DataColumn(label: Text('Room')),
            DataColumn(label: Text('Status')),
          ],
          rows: selectedSchedules.map((schedule) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    schedule.subject,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${schedule.classId ?? '-'}'
                    '${schedule.sectionId != null ? ' / ${schedule.sectionId}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    _formatApiDate(schedule.examDate),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                DataCell(
                  Text(
                    _formatTime(schedule.startTime),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                DataCell(
                  Text(
                    '${schedule.maxMarks}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    schedule.roomNumber.isEmpty ? '-' : schedule.roomNumber,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                DataCell(_statusBadge(schedule.status)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerText(),
              const SizedBox(height: 18),
              _headerActionButtons(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _headerText()),
            _headerActionButtons(),
          ],
        );
      },
    );
  }

  Widget _headerText() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(.20),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.assignment_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Examinations',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Create, schedule and manage school examinations.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addExamButton() {
    return ElevatedButton.icon(
      onPressed: _showCreateExamDialog,
      icon: const Icon(Icons.add_rounded, size: 19),
      label: const Text('Create Examination'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  Widget _headerActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: isSaving ? null : _importExaminationsExcel,
          icon: isSaving
              ? const SizedBox(
                  height: 17,
                  width: 17,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(isSaving ? 'Importing...' : 'Import Excel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFFBFDBFE)),
            backgroundColor: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
        ),
        _addExamButton(),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 19,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Filter Examinations',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedStatus = 'All';
                        selectedExamType = 'All';
                        searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isMobile)
                Column(
                  children: [
                    _searchField(),
                    const SizedBox(height: 14),
                    _filterDropdown(label: 'Status', child: _statusDropdown()),
                    const SizedBox(height: 14),
                    _filterDropdown(
                      label: 'Exam Type',
                      child: _examTypeDropdown(),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _searchField()),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _filterDropdown(
                        label: 'Status',
                        child: _statusDropdown(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _filterDropdown(
                        label: 'Exam Type',
                        child: _examTypeDropdown(),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value.trim();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search examinations...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: Color(0xFF93C5FD)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }

  Widget _filterDropdown({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _statusDropdown() {
    return _dropdown(
      value: selectedStatus,
      items: const [
        'All',
        'DRAFT',
        'UPCOMING',
        'SCHEDULED',
        'PUBLISHED',
        'COMPLETED',
        'CANCELLED',
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedStatus = value;
        });
      },
    );
  }

  Widget _examTypeDropdown() {
    return _dropdown(
      value: selectedExamType,
      items: const [
        'All',
        'UNIT_TEST',
        'PERIODIC_TEST',
        'MID_TERM',
        'ANNUAL',
        'TERMINAL',
        'HALF_YEARLY',
        'OTHER',
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          selectedExamType = value;
        });
      },
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                _prettyEnum(item),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 3;

        if (constraints.maxWidth < 1000) {
          columns = 2;
        }

        if (constraints.maxWidth < 560) {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4.2 : 2.25,
          children: [
            _summaryCard(
              'Total Examinations',
              '$totalExams',
              Icons.assignment_rounded,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Draft',
              '$draftExams',
              Icons.edit_note_rounded,
              const Color(0xFF6B7280),
              const Color(0xFFF3F4F6),
            ),
            _summaryCard(
              'Upcoming',
              '$upcomingExams',
              Icons.event_available_rounded,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
            ),
            _summaryCard(
              'Scheduled',
              '$scheduledExams',
              Icons.schedule_rounded,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _summaryCard(
              'Published',
              '$publishedExams',
              Icons.publish_rounded,
              const Color(0xFF9333EA),
              const Color(0xFFF3E8FF),
            ),
            _summaryCard(
              'Completed',
              '$completedExams',
              Icons.task_alt_rounded,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXAM LIST
  // ============================================================

  Widget _buildExamList() {
    final data = filteredExams;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.list_alt_rounded,
                  size: 19,
                  color: Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Examinations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${data.length} exams',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          data.isEmpty ? _emptyState() : _examTable(data),
        ],
      ),
    );
  }

  Widget _examTable(List<ExaminationModel> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 30,
        horizontalMargin: 8,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 82,
        headingRowHeight: 48,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Examination')),
          DataColumn(label: Text('Exam Type')),
          DataColumn(label: Text('Year')),
          DataColumn(label: Text('Academic Year')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((exam) {
          return DataRow(
            cells: [
              DataCell(_examNameCell(exam)),
              DataCell(_typeBadge(exam.examType)),
              DataCell(
                Text(
                  '${exam.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${exam.academicYearId ?? '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(_statusBadge(exam.status)),
              DataCell(_actionButtons(exam)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _examNameCell(ExaminationModel exam) {
    return SizedBox(
      width: 250,
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'EX${exam.id ?? '-'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _prettyEnum(type),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    Color background;

    switch (status.trim().toUpperCase()) {
      case 'DRAFT':
        color = const Color(0xFF6B7280);
        background = const Color(0xFFF3F4F6);
        break;

      case 'UPCOMING':
        color = const Color(0xFF2563EB);
        background = const Color(0xFFDBEAFE);
        break;

      case 'SCHEDULED':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
        break;

      case 'PUBLISHED':
        color = const Color(0xFF7C3AED);
        background = const Color(0xFFF3E8FF);
        break;

      case 'COMPLETED':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;

      case 'CANCELLED':
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEE2E2);
        break;

      default:
        color = const Color(0xFF6B7280);
        background = const Color(0xFFF3F4F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _prettyEnum(status),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(ExaminationModel exam) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'View Details',
          child: IconButton(
            onPressed: () => _showExamDetails(exam),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF9FAFB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Edit',
          child: IconButton(
            onPressed: () => _showEditExamDialog(exam),
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 65),
      child: Center(
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 34,
                color: Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No examinations found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              searchQuery.isNotEmpty ||
                      selectedStatus != 'All' ||
                      selectedExamType != 'All'
                  ? 'Try changing your filters.'
                  : 'Create a new examination to get started.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: const Color(0xFF6B7280)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXCEL IMPORT SECTION
  // ============================================================

  Widget _buildExcelImportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.table_view_rounded,
                      color: Color(0xFF059669),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bulk Excel Import',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quickly import schedules, results and grade rules.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (mobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _bulkImportButton(
                      label: 'Import Schedules',
                      icon: Icons.calendar_month_outlined,
                      isLoading: isImportingSchedules,
                      onPressed: isImportingSchedules
                          ? null
                          : _importSchedulesExcel,
                    ),
                    const SizedBox(height: 9),
                    _bulkImportButton(
                      label: 'Import Results',
                      icon: Icons.assessment_outlined,
                      isLoading: isImportingResults,
                      onPressed: isImportingResults
                          ? null
                          : _importResultsExcel,
                    ),
                    const SizedBox(height: 9),
                    _bulkImportButton(
                      label: 'Import Grade Rules',
                      icon: Icons.rule_outlined,
                      isLoading: isImportingGradeRules,
                      onPressed: isImportingGradeRules
                          ? null
                          : _importGradeRulesExcel,
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _bulkImportButton(
                      label: 'Import Schedules',
                      icon: Icons.calendar_month_outlined,
                      isLoading: isImportingSchedules,
                      onPressed: isImportingSchedules
                          ? null
                          : _importSchedulesExcel,
                    ),
                    _bulkImportButton(
                      label: 'Import Results',
                      icon: Icons.assessment_outlined,
                      isLoading: isImportingResults,
                      onPressed: isImportingResults
                          ? null
                          : _importResultsExcel,
                    ),
                    _bulkImportButton(
                      label: 'Import Grade Rules',
                      icon: Icons.rule_outlined,
                      isLoading: isImportingGradeRules,
                      onPressed: isImportingGradeRules
                          ? null
                          : _importGradeRulesExcel,
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _bulkImportButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(isLoading ? 'Importing...' : label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _prettyEnum(String value) {
    if (value.isEmpty) return '-';

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';

          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _formatApiDate(String value) {
    if (value.isEmpty) return '-';

    try {
      final date = DateTime.parse(value);

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day.toString().padLeft(2, '0')} '
          '${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  String _formatTime(String value) {
    if (value.isEmpty) return '-';

    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExaminations,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 24),

                    _buildExcelImportSection(),

                    const SizedBox(height: 24),

                    if (errorMessage != null) _errorBanner(),

                    if (errorMessage != null) const SizedBox(height: 16),

                    _buildSummaryCards(),

                    const SizedBox(height: 24),

                    _buildFilters(),

                    const SizedBox(height: 24),

                    _buildExamList(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Color(0xFFDC2626),
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            onPressed: _loadExaminations,
            icon: const Icon(Icons.refresh_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
