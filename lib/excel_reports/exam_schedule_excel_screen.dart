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
  ApiClient apiClient = ApiClient();
  List<ExaminationModel> _examinations = [];
  ExaminationModel? _selectedExamination;

  List<SchoolClass> _classes = [];
  SchoolClass? _selectedClass;

  bool _loadingExaminations = false;
  bool _loadingClasses = false;
  List<ClassSubjectModel> _subjects = [];
  ClassSubjectModel? _selectedSubject;

  List<ExamScheduleModel> _schedules = [];

  bool _loadingSchedules = false;
  String? _scheduleError;

  List<Section> _sections = [];
  List<TeacherAssignment> _teacherAssignments = [];

  bool _loadingSections = false;
  String? _sectionError;

  bool _loadingTeacherAssignments = false;
  String? _teacherAssignmentError;

  bool _loadingSubjects = false;
  String? _subjectError;

  String? _examinationError;
  String? _classError;

  @override
  void initState() {
    super.initState();
    _loadExaminations();
  }

  Future<void> _loadExaminations() async {
    setState(() {
      _loadingExaminations = true;
      _examinationError = null;
      _examinations = [];
      _selectedExamination = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final service = ExaminationService(token);

      final data = await service.getExaminations();

      if (!mounted) return;

      setState(() {
        // Show all examinations in dropdown.
        // Only PUBLISHED examinations can actually have schedules
        // according to backend validation.
        _examinations = data;
        _loadingExaminations = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingExaminations = false;
        _examinationError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadClasses() async {
    if (_selectedExamination?.id == null) return;

    setState(() {
      _loadingClasses = true;
      _classError = null;
      _classes = [];
      _selectedClass = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final service = ClassService(apiClient);

      final data = await service.getClasses();

      if (!mounted) return;

      setState(() {
        _classes = data;
        _loadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingClasses = false;
        _classError = e.toString();
      });
    }
  }

  Future<void> _loadSubjects() async {
    if (_selectedClass?.id == null) return;

    setState(() {
      _loadingSubjects = true;
      _subjectError = null;
      _subjects = [];
      _selectedSubject = null;
    });

    try {
      final classId = _selectedClass!.id!;

      final service = ClassSubjectService(apiClient);

      final data = await service.getClassSubjects(classId);

      if (!mounted) return;

      setState(() {
        _subjects = data;
        _loadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSubjects = false;
        _subjectError = e.toString();
      });
    }
  }

  Future<void> _loadSectionsAndTeachers() async {
    if (_selectedClass?.id == null || _selectedSubject?.subjectId == null) {
      return;
    }

    setState(() {
      _loadingSections = true;
      _loadingTeacherAssignments = true;

      _sectionError = null;
      _teacherAssignmentError = null;

      _sections = [];
      _teacherAssignments = [];

      _schedules = [];
      _scheduleError = null;
    });

    try {
      final classId = _selectedClass!.id!;
      final subjectId = _selectedSubject!.subjectId!;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final sectionService = SectionService(apiClient);

      final assignmentService = TeacherAssignmentService(token);

      // Load sections
      final sections = await sectionService.getSectionsByClassId(classId);

      // Load all teacher assignments for this class
      final assignments = await assignmentService.getAssignmentsByClass(
        classId,
      );

      // Keep only selected subject assignments
      final subjectAssignments = assignments
          .where(
            (assignment) =>
                assignment.subjectId == subjectId &&
                assignment.sectionId != null,
          )
          .toList();

      if (!mounted) return;

      setState(() {
        _sections = sections;
        _teacherAssignments = subjectAssignments;

        _loadingSections = false;
        _loadingTeacherAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSections = false;
        _loadingTeacherAssignments = false;

        _sectionError = e.toString();
        _teacherAssignmentError = e.toString();
      });
    }
  }

  Future<void> _loadSchedules() async {
    if (_selectedExamination?.id == null ||
        _selectedClass?.id == null ||
        _selectedSubject?.subjectId == null) {
      return;
    }

    setState(() {
      _loadingSchedules = true;
      _scheduleError = null;
      _schedules = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final service = ExaminationService(token);

      final data = await service.getSchedules(
        examinationId: _selectedExamination!.id!,
        classId: _selectedClass!.id!,
        subjectId: _selectedSubject!.subjectId,
      );

      if (!mounted) return;

      setState(() {
        _schedules = data;
        _loadingSchedules = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSchedules = false;
        _scheduleError = e.toString();
      });
    }
  }

  Future<void> _generateExcel() async {
    if (_selectedExamination?.id == null ||
        _selectedClass?.id == null ||
        _selectedSubject?.subjectId == null) {
      return;
    }

    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sections found for the selected class.'),
        ),
      );
      return;
    }

    try {
      final excel = ex.Excel.createExcel();

      final sheet = excel['Exam Schedule'];

      if (excel.sheets.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

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

      // ============================================================
      // HEADER
      // ============================================================

      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = ex.TextCellValue(
          headers[i],
        );
      }

      // ============================================================
      // ONE ROW PER SECTION
      // ============================================================

      for (int row = 0; row < _sections.length; row++) {
        final section = _sections[row];

        TeacherAssignment? assignment;

        for (final item in _teacherAssignments) {
          if (item.sectionId == section.id &&
              item.subjectId == _selectedSubject!.subjectId) {
            assignment = item;
            break;
          }
        }

        final teacherName = assignment?.teacherName?.trim().isNotEmpty == true
            ? assignment!.teacherName!
            : 'Not Assigned';

        final values = [
          _selectedExamination!.name,
          _selectedClass!.name ?? '',
          section.name,
          _selectedSubject!.subjectName,
          teacherName,

          // Editable fields
          '',
          '',
          '',
          '',
          '',
          'SCHEDULED',
        ];

        for (int column = 0; column < values.length; column++) {
          sheet
              .cell(
                ex.CellIndex.indexByColumnRow(
                  columnIndex: column,
                  rowIndex: row + 1,
                ),
              )
              .value = ex.TextCellValue(
            values[column].toString(),
          );
        }
      }

      // ============================================================
      // COLUMN WIDTHS
      // ============================================================

      final widths = [
        28.0, // Examination
        18.0, // Class
        12.0, // Section
        20.0, // Subject
        22.0, // Teacher
        15.0, // Exam Date
        14.0, // Start Time
        12.0, // Duration
        12.0, // Max Marks
        15.0, // Room Number
        14.0, // Status
      ];

      for (int i = 0; i < widths.length; i++) {
        sheet.setColumnWidth(i, widths[i]);
      }

      // ============================================================
      // SAVE
      // ============================================================

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Excel file.');
      }

      final fileName =
          'Exam_Schedule_'
          '${_selectedExamination!.name.replaceAll(' ', '_')}_'
          '${_selectedClass!.name?.replaceAll(' ', '_')}_'
          '${_selectedSubject!.subjectName.replaceAll(' ', '_')}';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam Schedule Excel generated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate Excel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Exam Schedule Excel',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            _buildSelectionCard(),

            const SizedBox(height: 24),

            _buildScheduleCard(),
          ],
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: Color(0xFF2563EB),
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exam Schedule',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Generate, edit and import examination schedules',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule Selection',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Select examination, class and subject',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int columns = 1;

              if (width >= 1000) {
                columns = 3;
              } else if (width >= 650) {
                columns = 2;
              }

              final itemWidth = (width - ((columns - 1) * 14)) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildExaminationDropdown(),
                  ),
                  SizedBox(width: itemWidth, child: _buildClassDropdown()),
                  SizedBox(width: itemWidth, child: _buildSubjectDropdown()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownPlaceholder({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),

        const SizedBox(height: 7),

        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF6B7280)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SCHEDULE CARD
  // ============================================================

  Widget _buildScheduleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Schedule',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Section-wise teacher assignments will be added to the Excel template',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),

              // OutlinedButton.icon(
              //   onPressed: _schedules.isEmpty
              //       ? null
              //       : () {
              //           // Excel import - next step
              //         },
              //   icon: const Icon(Icons.upload_file_rounded, size: 17),
              //   label: const Text(
              //     'Import Excel',
              //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              //   ),
              // ),
              const SizedBox(width: 10),

              ElevatedButton.icon(
                onPressed:
                    _sections.isEmpty ||
                        _loadingSections ||
                        _loadingTeacherAssignments
                    ? null
                    : _generateExcel,
                icon: const Icon(Icons.download_rounded, size: 17),
                label: const Text(
                  'Generate Excel',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF9CA3AF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          if (_loadingSections || _loadingTeacherAssignments)
            _buildScheduleLoading()
          else if (_sectionError != null)
            _buildScheduleError()
          else if (_selectedSubject == null)
            _buildScheduleEmpty(
              'Select examination, class and subject',
              'Section-wise schedule template will be generated here',
            )
          else if (_sections.isEmpty)
            _buildScheduleEmpty(
              'No sections found',
              'No sections are configured for this class',
            )
          else
            _buildSectionPreview(),
        ],
      ),
    );
  }

  Widget _buildSectionPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 54,
          dataRowMaxHeight: 60,
          columnSpacing: 28,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          columns: const [
            DataColumn(
              label: Text(
                'Section',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Subject',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Teacher',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
          rows: _sections.map((section) {
            TeacherAssignment? assignment;

            for (final item in _teacherAssignments) {
              if (item.sectionId == section.id &&
                  item.subjectId == _selectedSubject!.subjectId) {
                assignment = item;
                break;
              }
            }

            final teacherName =
                assignment?.teacherName?.trim().isNotEmpty == true
                ? assignment!.teacherName!
                : 'Not Assigned';

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    section.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    _selectedSubject!.subjectName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    teacherName,
                    style: TextStyle(
                      fontSize: 12,
                      color: teacherName == 'Not Assigned'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScheduleLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: 14),
          Text(
            'Loading schedules...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleEmpty(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.table_rows_rounded,
            size: 40,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _scheduleError!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
            ),
          ),
          IconButton(
            onPressed: _loadSchedules,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFDC2626)),
            tooltip: 'Retry',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 54,
          dataRowMaxHeight: 60,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          columns: const [
            DataColumn(
              label: Text(
                'Section',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Teacher',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Exam Date',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Start Time',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Duration',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Max Marks',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Room',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
          rows: _schedules.map((schedule) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    schedule.subjectName.isEmpty ? '-' : schedule.subjectName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    schedule.subjectTeacherName.isEmpty
                        ? '-'
                        : schedule.subjectTeacherName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(schedule.examDate, style: const TextStyle(fontSize: 12)),
                ),
                DataCell(
                  Text(
                    schedule.startTime,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(
                  Text(
                    '${schedule.duration} min',
                    style: const TextStyle(fontSize: 12),
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
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(_buildStatusChip(schedule.status)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final normalized = status.toUpperCase();

    Color background;
    Color foreground;

    if (normalized == 'SCHEDULED') {
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF166534);
    } else if (normalized == 'COMPLETED') {
      background = const Color(0xFFE0E7FF);
      foreground = const Color(0xFF3730A3);
    } else if (normalized == 'CANCELLED') {
      background = const Color(0xFFFEE2E2);
      foreground = const Color(0xFF991B1B);
    } else {
      background = const Color(0xFFF3F4F6);
      foreground = const Color(0xFF374151);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _classError != null
                  ? Colors.red.shade300
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: _loadingClasses
              ? const Row(
                  children: [
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading classes...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<SchoolClass>(
                    value: _selectedClass,
                    isExpanded: true,
                    hint: const Text(
                      'Select class',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    items: _classes.map((schoolClass) {
                      return DropdownMenuItem<SchoolClass>(
                        value: schoolClass,
                        child: Text(
                          schoolClass.name ?? 'Unnamed Class',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF111827),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedExamination == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedClass = value;

                              // Reset subject
                              _selectedSubject = null;
                              _subjects = [];

                              // Reset old schedules
                              _schedules = [];
                              _scheduleError = null;

                              // Reset section-wise data
                              _sections = [];
                              _teacherAssignments = [];

                              _sectionError = null;
                              _teacherAssignmentError = null;

                              // Reset subject loading/error
                              _subjectError = null;
                              _loadingSubjects = false;
                            });

                            if (value != null) {
                              _loadSubjects();
                            }
                          },
                  ),
                ),
        ),
        if (_classError != null) ...[
          const SizedBox(height: 5),
          Text(
            _classError!,
            style: const TextStyle(fontSize: 10, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildExaminationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Examination',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _examinationError != null
                  ? Colors.red.shade300
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: _loadingExaminations
              ? const Row(
                  children: [
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading examinations...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<ExaminationModel>(
                    value: _selectedExamination,
                    isExpanded: true,
                    hint: const Text(
                      'Select examination',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    items: _examinations.map((exam) {
                      return DropdownMenuItem<ExaminationModel>(
                        value: exam,
                        child: Text(
                          exam.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF111827),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExamination = value;

                        _selectedClass = null;
                        _selectedSubject = null;

                        _classes = [];
                        _subjects = [];
                        _schedules = [];

                        _classError = null;
                        _subjectError = null;
                        _scheduleError = null;
                      });

                      if (value != null) {
                        _loadClasses();
                      }
                    },
                  ),
                ),
        ),
        if (_examinationError != null) ...[
          const SizedBox(height: 5),
          Text(
            _examinationError!,
            style: const TextStyle(fontSize: 10, color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subject',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _subjectError != null
                  ? Colors.red.shade300
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: _loadingSubjects
              ? const Row(
                  children: [
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Loading subjects...',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<ClassSubjectModel>(
                    value: _selectedSubject,
                    isExpanded: true,
                    hint: const Text(
                      'Select subject',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    items: _subjects.map((subject) {
                      return DropdownMenuItem<ClassSubjectModel>(
                        value: subject,
                        child: Text(
                          subject.subjectCode.isNotEmpty
                              ? '${subject.subjectName} (${subject.subjectCode})'
                              : subject.subjectName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF111827),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedClass == null
                        ? null
                        : (value) {
                            setState(() {
                              _selectedSubject = value;
                              _schedules = [];
                              _scheduleError = null;
                            });

                            if (value != null) {
                              _loadSectionsAndTeachers();
                            }
                          },
                  ),
                ),
        ),
        if (_subjectError != null) ...[
          const SizedBox(height: 5),
          Text(
            _subjectError!,
            style: const TextStyle(fontSize: 10, color: Colors.red),
          ),
        ],
      ],
    );
  }
}

String _formatDate(String value) {
  if (value.isEmpty) return '';

  try {
    final date = DateTime.parse(value);

    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  } catch (_) {
    return value;
  }
}

String _formatTime(String value) {
  if (value.isEmpty) return '';

  if (value.length >= 5) {
    return value.substring(0, 5);
  }

  return value;
}
