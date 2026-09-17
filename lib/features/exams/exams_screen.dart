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

      print('========================================');
      print('EXAM SCREEN INITIALIZE');
      print('TOKEN EXISTS: ${token != null && token.isNotEmpty}');
      print('========================================');

      if (token == null || token.isEmpty) {
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
  // IMPORT EXAMINATIONS FROM EXCEL
  // ============================================================
  Future<void> _importExaminationsExcel() async {
    if (_importService == null) {
      _showSnack('Examination import service is not initialized.');
      return;
    }

    try {
      debugPrint('========================================');
      debugPrint('EXAMINATION IMPORT BUTTON CLICKED');
      debugPrint('IMPORT SERVICE EXISTS: ${_importService != null}');
      debugPrint('========================================');

      debugPrint('OPENING EXAMINATION EXCEL FILE PICKER...');

      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      debugPrint('EXAMINATION EXCEL PICKER RESULT: $selectedFile');

      if (selectedFile == null) {
        debugPrint('NO EXAMINATION EXCEL FILE SELECTED');
        return;
      }

      debugPrint('FILE NAME: ${selectedFile.fileName}');

      debugPrint('FILE BYTES: ${selectedFile.bytes.length}');

      setState(() {
        isSaving = true;
      });

      debugPrint('CALLING EXAMINATION IMPORT API...');

      final importResult = await _importService!.importExaminationsExcel(
        bytes: selectedFile.bytes,
        fileName: selectedFile.fileName,
      );

      debugPrint('EXAMINATION IMPORT API SUCCESS');

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
      debugPrint('EXAMINATION IMPORT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _importResultsExcel() async {
    if (_bulkImportService == null) {
      _showSnack('Bulk import service is not initialized.');
      return;
    }

    if (isImportingResults) {
      return;
    }

    debugPrint('========================================');
    debugPrint('RESULTS IMPORT BUTTON CLICKED');
    debugPrint('========================================');

    try {
      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      if (selectedFile == null) {
        debugPrint('NO RESULTS EXCEL FILE SELECTED');
        return;
      }

      debugPrint('SELECTED RESULTS FILE: ${selectedFile.fileName}');

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

      if (mounted) {
        await _loadExaminations();
      }
    } catch (e) {
      debugPrint('RESULTS IMPORT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isImportingResults = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _importSchedulesExcel() async {
    if (_bulkImportService == null) {
      _showSnack('Bulk import service is not initialized.');
      return;
    }

    if (isImportingSchedules) {
      return;
    }

    debugPrint('========================================');
    debugPrint('SCHEDULES IMPORT BUTTON CLICKED');
    debugPrint('========================================');

    try {
      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      if (selectedFile == null) {
        debugPrint('NO SCHEDULES EXCEL FILE SELECTED');
        return;
      }

      debugPrint('SELECTED SCHEDULES FILE: ${selectedFile.fileName}');

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

      if (mounted) {
        await _loadExaminations();
      }
    } catch (e) {
      debugPrint('SCHEDULES IMPORT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isImportingSchedules = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _importGradeRulesExcel() async {
    if (_bulkImportService == null) {
      _showSnack('Bulk import service is not initialized.');
      return;
    }

    if (isImportingGradeRules) {
      return;
    }

    debugPrint('========================================');
    debugPrint('GRADE RULES IMPORT BUTTON CLICKED');
    debugPrint('========================================');

    try {
      final selectedFile = await ExaminationExcelPickerService.pickExcelFile();

      if (selectedFile == null) {
        debugPrint('NO GRADE RULES EXCEL FILE SELECTED');
        return;
      }

      debugPrint('SELECTED GRADE RULES FILE: ${selectedFile.fileName}');

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

      if (mounted) {
        await _loadExaminations();
      }
    } catch (e) {
      debugPrint('GRADE RULES IMPORT ERROR: $e');

      if (!mounted) return;

      setState(() {
        isImportingGradeRules = false;
      });

      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showBulkImportResult({
    required String title,
    required ExcelImportResponseModel result,
  }) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
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
                        const Color(0xFFCA8A04),
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
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Error Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Row ${error.row}: ${error.message}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFDC2626),
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
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
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
                    fontWeight: FontWeight.bold,
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

      return statusMatch && typeMatch;
    }).toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get totalExams => exams.length;

  int get upcomingExams {
    return exams.where((e) {
      return e.status.toUpperCase() == 'UPCOMING';
    }).length;
  }

  int get scheduledExams {
    return exams.where((e) {
      return e.status.toUpperCase() == 'SCHEDULED';
    }).length;
  }

  int get completedExams {
    return exams.where((e) {
      return e.status.toUpperCase() == 'COMPLETED';
    }).length;
  }

  int get draftExams {
    return exams.where((e) => e.status.trim().toUpperCase() == 'DRAFT').length;
  }

  int get publishedExams {
    return exams
        .where((e) => e.status.trim().toUpperCase() == 'PUBLISHED')
        .length;
  }

  // ============================================================
  // CREATE EXAMINATION
  // ============================================================

  void _showCreateExamDialog() {
    _showExamDialog();
  }

  // ============================================================
  // EDIT EXAMINATION
  // ============================================================

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
              title: Text(
                exam == null ? 'Create New Examination' : 'Edit Examination',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: _inputDecoration(
                          'Exam Name',
                          Icons.assignment_outlined,
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Description',
                          Icons.description_outlined,
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
                                'Academic Year ID',
                                Icons.school_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: yearController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                'Year',
                                Icons.calendar_today_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      DropdownButtonFormField<String>(
                        value: examType,
                        decoration: _inputDecoration(
                          'Exam Type',
                          Icons.category_outlined,
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
                          'Status',
                          Icons.flag_outlined,
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
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
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

                            if (exam == null) {
                              setState(() {
                                exams.insert(0, result);
                              });

                              _showSnack('Examination created successfully.');
                            } else {
                              setState(() {
                                final index = exams.indexWhere(
                                  (e) => e.id == exam.id,
                                );

                                if (index != -1) {
                                  exams[index] = result;
                                }
                              });

                              _showSnack('Examination updated successfully.');
                            }
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

  Future<void> _showExamDetails(ExaminationModel exam) async {
    setState(() {
      selectedSchedules = [];
      isLoadingSchedules = true;
    });

    if (exam.id != null) {
      try {
        final schedules = await _service!.getSchedulesByExamination(exam.id!);

        if (!mounted) return;

        setState(() {
          selectedSchedules = schedules;
          isLoadingSchedules = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          isLoadingSchedules = false;
        });

        _showSnack(e.toString().replaceFirst('Exception: ', ''));
      }
    } else {
      setState(() {
        isLoadingSchedules = false;
      });
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            exam.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Exam ID', '${exam.id ?? '-'}'),
                  _detailRow('Academic Year', '${exam.academicYearId ?? '-'}'),
                  _detailRow('Exam Type', _prettyEnum(exam.examType)),
                  _detailRow('Year', '${exam.year}'),
                  _detailRow('Status', _prettyEnum(exam.status)),
                  _detailRow(
                    'Description',
                    exam.description.isEmpty ? '-' : exam.description,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Exam Schedules',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (isLoadingSchedules)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (selectedSchedules.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'No exam schedules found.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  else
                    _scheduleTable(),
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
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                _showEditExamDialog(exam);
              },
              icon: const Icon(Icons.edit_outlined, size: 17),
              label: const Text('Edit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
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
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 22,
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
                    style: const TextStyle(fontSize: 12),
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
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerText(),
              const SizedBox(height: 16),
              _headerActionButtons(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            _headerActionButtons(),
          ],
        );
      },
    );
  }

  Widget _headerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Examinations',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Create and manage school examinations and schedules.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _addExamButton() {
    return ElevatedButton.icon(
      onPressed: _showCreateExamDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Create Examination'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: const Text('Import Excel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF2563EB)),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.filter_list_rounded,
                      size: 19,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedStatus = 'All';
                        selectedExamType = 'All';
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 7),
                    _statusDropdown(),

                    const SizedBox(height: 14),

                    const Text(
                      'Exam Type',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 7),
                    _examTypeDropdown(),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 7),
                          _statusDropdown(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    SizedBox(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Exam Type',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 7),
                          _examTypeDropdown(),
                        ],
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
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 19),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                _prettyEnum(item),
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 3;

        if (constraints.maxWidth < 900) {
          columns = 2;
        }

        if (constraints.maxWidth < 550) {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4 : 2.5,
          children: [
            _summaryCard(
              'Total Exams',
              '$totalExams',
              Icons.assignment_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),

            _summaryCard(
              'Draft',
              '$draftExams',
              Icons.edit_note_outlined,
              const Color(0xFF6B7280),
              const Color(0xFFF3F4F6),
            ),

            _summaryCard(
              'Upcoming',
              '$upcomingExams',
              Icons.event_available_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
            ),

            _summaryCard(
              'Scheduled',
              '$scheduledExams',
              Icons.schedule_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),

            _summaryCard(
              'Published',
              '$publishedExams',
              Icons.publish_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF3E8FF),
            ),

            _summaryCard(
              'Completed',
              '$completedExams',
              Icons.task_alt_outlined,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Examination Schedule',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${data.length} exams',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
              DataCell(
                Text(
                  _prettyEnum(exam.examType),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Text('${exam.year}', style: const TextStyle(fontSize: 12)),
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
      width: 240,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'EX${exam.id ?? '-'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      child: Text(
        _prettyEnum(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButtons(ExaminationModel exam) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View Details',
          onPressed: () {
            _showExamDetails(exam);
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'Edit',
          onPressed: () {
            _showEditExamDialog(exam);
          },
          icon: const Icon(
            Icons.edit_outlined,
            size: 18,
            color: Color(0xFF2563EB),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 52, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text(
              'No examinations found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your filters or create a new examination.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                  _buildFilters(),

                  const SizedBox(height: 24),

                  _buildSummaryCards(),

                  const SizedBox(height: 24),

                  _buildExamList(),
                ],
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
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
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelImportSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bulk Excel Import',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Import exam schedules, results and grade rules using Excel files.',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _bulkImportButton(
                label: 'Import Schedules',
                icon: Icons.calendar_month_outlined,
                isLoading: isImportingSchedules,
                onPressed: isImportingSchedules ? null : _importSchedulesExcel,
              ),

              _bulkImportButton(
                label: 'Import Results',
                icon: Icons.assessment_outlined,
                isLoading: isImportingResults,
                onPressed: isImportingResults ? null : _importResultsExcel,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
