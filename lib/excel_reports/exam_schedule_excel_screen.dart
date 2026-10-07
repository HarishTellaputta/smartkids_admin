import 'package:flutter/material.dart';
import 'package:smartkids_admin/core/network/api_client.dart';

import '../features/exams/services/examination_service.dart';

import '../features/exams/models/examination_model.dart';
import '../features/exams/models/exam_schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/teachers/models/class_model.dart';
import '../features/teachers/services/class_service.dart';
import '../features/teachers/services/class_subject_service.dart';
import '../features/teachers/models/class_subject_model.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';

import '../models/section_model.dart';
import '../services/section_service.dart';
import '../features/teachers/models/teacher_assignment_model.dart';
import '../features/teachers/services/teacher_assignment_service.dart';

class ExamScheduleExcelScreen extends StatefulWidget {
  const ExamScheduleExcelScreen({super.key});

  @override
  State<ExamScheduleExcelScreen> createState() =>
      _ExamScheduleExcelScreenState();
}

class _ExamScheduleExcelScreenState extends State<ExamScheduleExcelScreen> {
  // ============================================================
  // API CLIENT
  // ============================================================

  final ApiClient apiClient = ApiClient();

  // ============================================================
  // EXAMINATIONS
  // ============================================================

  List<ExaminationModel> _examinations = [];
  ExaminationModel? _selectedExamination;

  bool _isLoadingExaminations = false;
  String? _examinationError;

  // ============================================================
  // CLASSES
  // ============================================================

  List<SchoolClass> _classes = [];
  SchoolClass? _selectedClass;

  bool _isLoadingClasses = false;
  String? _classError;

  // ============================================================
  // SUBJECTS
  // ============================================================

  List<ClassSubjectModel> _subjects = [];

  bool _isLoadingSubjects = false;
  String? _subjectError;

  // ============================================================
  // SECTIONS
  // ============================================================

  List<Section> _sections = [];

  bool _isLoadingSections = false;
  String? _sectionError;

  // ============================================================
  // TEACHER ASSIGNMENTS
  // ============================================================

  List<TeacherAssignment> _teacherAssignments = [];

  bool _isLoadingTeacherAssignments = false;
  String? _teacherAssignmentError;

  // ============================================================
  // GENERAL
  // ============================================================

  bool _isGenerating = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadExaminations();
  }

  // ============================================================
  // LOAD EXAMINATIONS
  // ============================================================

  Future<void> _loadExaminations() async {
    setState(() {
      _isLoadingExaminations = true;
      _examinationError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Login session expired. Please login again.');
      }

      final service = ExaminationService(token);

      final examinations = await service.getExaminations();

      if (!mounted) return;

      setState(() {
        _examinations = examinations;
        _isLoadingExaminations = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingExaminations = false;
        _examinationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // LOAD CLASSES
  // ============================================================

  Future<void> _loadClasses() async {
    setState(() {
      _isLoadingClasses = true;
      _classError = null;
    });

    try {
      final service = ClassService(apiClient);

      final classes = await service.getClasses();

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _isLoadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingClasses = false;
        _classError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // LOAD ALL CLASS DATA
  //
  // After selecting class:
  //
  // 1. Subjects
  // 2. Sections
  // 3. Teacher assignments
  //
  // All are loaded automatically.
  // ============================================================

  Future<void> _loadClassScheduleData() async {
    final classId = _selectedClass?.id;

    if (classId == null) {
      return;
    }

    setState(() {
      _subjects = [];
      _sections = [];
      _teacherAssignments = [];

      _subjectError = null;
      _sectionError = null;
      _teacherAssignmentError = null;

      _isLoadingSubjects = true;
      _isLoadingSections = true;
      _isLoadingTeacherAssignments = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Login session expired. Please login again.');
      }

      final classSubjectService = ClassSubjectService(apiClient);

      final sectionService = SectionService(apiClient);

      final teacherAssignmentService = TeacherAssignmentService(token);

      // --------------------------------------------------------
      // LOAD IN PARALLEL
      // --------------------------------------------------------

      final results = await Future.wait([
        classSubjectService.getClassSubjects(classId),
        sectionService.getSectionsByClassId(classId),
        teacherAssignmentService.getAssignmentsByClass(classId),
      ]);

      if (!mounted) return;

      final subjects = results[0] as List<ClassSubjectModel>;

      final sections = results[1] as List<Section>;

      final assignments = results[2] as List<TeacherAssignment>;

      setState(() {
        _subjects = subjects;
        _sections = sections;
        _teacherAssignments = assignments;

        _isLoadingSubjects = false;
        _isLoadingSections = false;
        _isLoadingTeacherAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _isLoadingSubjects = false;
        _isLoadingSections = false;
        _isLoadingTeacherAssignments = false;

        _subjectError = message;
        _sectionError = message;
        _teacherAssignmentError = message;
      });
    }
  }

  // ============================================================
  // FIND TEACHER
  //
  // Teacher is matched using:
  //
  // sectionId + subjectId
  // ============================================================

  TeacherAssignment? _findTeacherAssignment({
    required int sectionId,
    required int subjectId,
  }) {
    for (final assignment in _teacherAssignments) {
      if (assignment.sectionId == sectionId &&
          assignment.subjectId == subjectId) {
        return assignment;
      }
    }

    return null;
  }

  // ============================================================
  // TEACHER NAME
  // ============================================================

  String _getTeacherName({required int sectionId, required int subjectId}) {
    final assignment = _findTeacherAssignment(
      sectionId: sectionId,
      subjectId: subjectId,
    );

    final teacherName = assignment?.teacherName?.trim();

    if (teacherName == null || teacherName.isEmpty) {
      return 'Not Assigned';
    }

    return teacherName;
  }

  // ============================================================
  // GENERATE EXCEL
  // ============================================================

  Future<void> _generateExcel() async {
    if (_selectedExamination == null) {
      _showMessage('Please select an examination.', isError: true);
      return;
    }

    if (_selectedClass == null) {
      _showMessage('Please select a class.', isError: true);
      return;
    }

    if (_sections.isEmpty) {
      _showMessage('No sections found for this class.', isError: true);
      return;
    }

    if (_subjects.isEmpty) {
      _showMessage('No subjects assigned to this class.', isError: true);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final workbook = ex.Excel.createExcel();

      final sheet = workbook['Exam Schedule'];

      // Remove default Sheet1 if present.
      if (workbook.sheets.containsKey('Sheet1')) {
        workbook.delete('Sheet1');
      }

      // ========================================================
      // HEADER
      // ========================================================

      final headers = [
        'Examination',
        'Class',
        'Section',
        'Subject',
        'Teacher',
        'Exam Date',
        'Start Time',
        'Duration',
        'Max Marks',
        'Room Number',
        'Status',
      ];

      for (int column = 0; column < headers.length; column++) {
        sheet
            .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
            )
            .value = ex.TextCellValue(
          headers[column],
        );
      }

      // ========================================================
      // DATA
      //
      // One row for:
      //
      // Section × Subject
      //
      // Example:
      //
      // A | Hindi
      // A | English
      // A | Maths
      // B | Hindi
      // B | English
      // B | Maths
      // ========================================================

      int rowIndex = 1;

      for (final section in _sections) {
        for (final subject in _subjects) {
          final teacherName = _getTeacherName(
            sectionId: section.id,
            subjectId: subject.subjectId,
          );

          final row = [
            _selectedExamination!.name,
            _selectedClass!.name,
            section.name,
            subject.subjectName,
            teacherName,

            // Editable fields - intentionally blank.
            '',
            '',
            '',
            '',
            '',

            // Default status.
            'SCHEDULED',
          ];

          for (int column = 0; column < row.length; column++) {
            sheet
                .cell(
                  ex.CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: rowIndex,
                  ),
                )
                .value = ex.TextCellValue(
              row[column].toString(),
            );
          }

          rowIndex++;
        }
      }

      // ========================================================
      // COLUMN WIDTHS
      // ========================================================

      sheet.setColumnWidth(0, 28);
      sheet.setColumnWidth(1, 18);
      sheet.setColumnWidth(2, 14);
      sheet.setColumnWidth(3, 20);
      sheet.setColumnWidth(4, 25);
      sheet.setColumnWidth(5, 16);
      sheet.setColumnWidth(6, 16);
      sheet.setColumnWidth(7, 14);
      sheet.setColumnWidth(8, 14);
      sheet.setColumnWidth(9, 16);
      sheet.setColumnWidth(10, 16);

      // ========================================================
      // HEADER STYLE
      // ========================================================

      for (int column = 0; column < headers.length; column++) {
        final cell = sheet.cell(
          ex.CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0),
        );

        cell.cellStyle = ex.CellStyle(
          bold: true,
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Center,
        );
      }

      // ========================================================
      // ENCODE
      // ========================================================

      final List<int>? bytes = workbook.encode();

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to create Excel file.');
      }

      final Uint8List fileBytes = Uint8List.fromList(bytes);

      // ========================================================
      // FILE NAME
      // ========================================================

      final examName = _selectedExamination!.name
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');

      final className = _selectedClass!.name!
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(' ', '_');

      final fileName = 'Exam_Schedule_${examName}_$className';

      // ========================================================
      // SAVE FILE
      // ========================================================

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: fileBytes,
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      _showMessage(
        'Excel generated successfully with '
        '${rowIndex - 1} schedule rows.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red.shade700 : null,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildSelectionCard(),

              const SizedBox(height: 24),

              _buildPreviewCard(),

              const SizedBox(height: 24),

              _buildGenerateCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.table_view_rounded,
              color: Colors.indigo,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam Schedule Excel',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 5),

                Text(
                  'Select examination and class. '
                  'Subjects, sections and teachers are loaded automatically.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTION CARD
  // ============================================================

  Widget _buildSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exam Selection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    _buildExaminationDropdown(),

                    const SizedBox(height: 16),

                    _buildClassDropdown(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _buildExaminationDropdown()),

                  const SizedBox(width: 20),

                  Expanded(child: _buildClassDropdown()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXAMINATION DROPDOWN
  // ============================================================

  Widget _buildExaminationDropdown() {
    return DropdownButtonFormField<ExaminationModel>(
      value: _selectedExamination,
      isExpanded: true,

      decoration: InputDecoration(
        labelText: 'Examination',
        prefixIcon: const Icon(Icons.assignment_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),

      hint: _isLoadingExaminations
          ? const Text('Loading examinations...')
          : const Text('Select examination'),

      items: _examinations.map((exam) {
        return DropdownMenuItem<ExaminationModel>(
          value: exam,
          child: Text(exam.name!, overflow: TextOverflow.ellipsis),
        );
      }).toList(),

      onChanged: _isLoadingExaminations
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                _selectedExamination = value;

                _selectedClass = null;
                _classes = [];

                _subjects = [];
                _sections = [];
                _teacherAssignments = [];

                _classError = null;
                _subjectError = null;
                _sectionError = null;
                _teacherAssignmentError = null;
              });

              _loadClasses();
            },
    );
  }

  // ============================================================
  // CLASS DROPDOWN
  // ============================================================

  Widget _buildClassDropdown() {
    return DropdownButtonFormField<SchoolClass>(
      value: _selectedClass,
      isExpanded: true,

      decoration: InputDecoration(
        labelText: 'Class',
        prefixIcon: const Icon(Icons.school_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),

      hint: _isLoadingClasses
          ? const Text('Loading classes...')
          : _selectedExamination == null
          ? const Text('Select examination first')
          : const Text('Select class'),

      items: _classes.map((classItem) {
        return DropdownMenuItem<SchoolClass>(
          value: classItem,
          child: Text(classItem.name!, overflow: TextOverflow.ellipsis),
        );
      }).toList(),

      onChanged: _selectedExamination == null || _isLoadingClasses
          ? null
          : (value) {
              if (value == null) return;

              setState(() {
                _selectedClass = value;

                _subjects = [];
                _sections = [];
                _teacherAssignments = [];

                _subjectError = null;
                _sectionError = null;
                _teacherAssignmentError = null;
              });

              _loadClassScheduleData();
            },
    );
  }

  // ============================================================
  // PREVIEW CARD
  // ============================================================

  Widget _buildPreviewCard() {
    final isLoading =
        _isLoadingSubjects ||
        _isLoadingSections ||
        _isLoadingTeacherAssignments;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Schedule Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),

              if (_selectedClass != null && !isLoading)
                _buildCountChip('${_sections.length} Sections'),

              const SizedBox(width: 8),

              if (_selectedClass != null && !isLoading)
                _buildCountChip('${_subjects.length} Subjects'),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Each section will get one row for every subject.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 20),

          if (_selectedClass == null)
            _buildEmptyState(
              icon: Icons.info_outline,
              title: 'Select a class',
              message:
                  'Select a class to load sections, subjects and teachers.',
            )
          else if (isLoading)
            _buildLoadingState()
          else if (_subjects.isEmpty)
            _buildEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No subjects found',
              message: 'No subjects are assigned to this class.',
            )
          else if (_sections.isEmpty)
            _buildEmptyState(
              icon: Icons.groups_outlined,
              title: 'No sections found',
              message: 'No sections are available for this class.',
            )
          else
            _buildSectionSubjectPreview(),
        ],
      ),
    );
  }

  // ============================================================
  // PREVIEW TABLE
  // ============================================================

  Widget _buildSectionSubjectPreview() {
    final totalRows = _sections.length * _subjects.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: Colors.indigo),

              const SizedBox(width: 8),

              Text(
                '$totalRows schedule rows will be created',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 60,

              columns: const [
                DataColumn(
                  label: Text(
                    'Section',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Subject',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Code',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Teacher',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],

              rows: [
                for (final section in _sections)
                  for (final subject in _subjects)
                    DataRow(
                      cells: [
                        DataCell(Text(section.name)),

                        DataCell(Text(subject.subjectName)),

                        DataCell(Text(subject.subjectCode)),

                        DataCell(
                          _buildTeacherCell(
                            sectionId: section.id,
                            subjectId: subject.subjectId,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TEACHER CELL
  // ============================================================

  Widget _buildTeacherCell({required int sectionId, required int subjectId}) {
    final assignment = _findTeacherAssignment(
      sectionId: sectionId,
      subjectId: subjectId,
    );

    final teacherName = assignment?.teacherName?.trim();

    if (teacherName == null || teacherName.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            'Not Assigned',
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.person_outline, size: 18, color: Colors.green),
        const SizedBox(width: 6),
        Text(teacherName, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ============================================================
  // GENERATE CARD
  // ============================================================

  Widget _buildGenerateCard() {
    final canGenerate =
        _selectedExamination != null &&
        _selectedClass != null &&
        _sections.isNotEmpty &&
        _subjects.isNotEmpty &&
        !_isLoadingSubjects &&
        !_isLoadingSections &&
        !_isLoadingTeacherAssignments &&
        !_isGenerating;

    final totalRows = _sections.length * _subjects.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generate Excel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 6),

                Text(
                  canGenerate
                      ? '$totalRows rows will be created. '
                            'Exam details can be entered later in Excel.'
                      : 'Select examination and class to continue.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          ElevatedButton.icon(
            onPressed: canGenerate ? _generateExcel : null,

            icon: _isGenerating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),

            label: Text(_isGenerating ? 'Generating...' : 'Generate Excel'),

            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COUNT CHIP
  // ============================================================

  Widget _buildCountChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.indigo,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      child: const Column(
        children: [
          CircularProgressIndicator(),

          SizedBox(height: 16),

          Text(
            'Loading subjects, sections and teachers...',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: Colors.grey.shade400),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 5),

          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
