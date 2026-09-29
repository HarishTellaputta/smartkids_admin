import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/core/network/api_client.dart';

import '../features/exams/models/examination_model.dart';
import '../features/exams/models/exam_schedule_model.dart';
import '../features/exams/services/examination_service.dart';

import '../features/teachers/models/class_model.dart';
import '../features/teachers/services/class_service.dart';

import '../features/teachers/models/class_subject_model.dart';
import '../features/teachers/services/class_subject_service.dart';

import '../models/student_model.dart';
import '../services/student_service.dart';

class ExamResultExcelScreen extends StatefulWidget {
  const ExamResultExcelScreen({super.key});

  @override
  State<ExamResultExcelScreen> createState() => _ExamResultExcelScreenState();
}

class _ExamResultExcelScreenState extends State<ExamResultExcelScreen> {
  final ApiClient apiClient = ApiClient();

  // ============================================================
  // EXAMINATIONS
  // ============================================================

  List<ExaminationModel> _examinations = [];
  ExaminationModel? _selectedExamination;

  bool _loadingExaminations = false;
  String? _examinationError;

  // ============================================================
  // CLASSES
  // ============================================================

  List<SchoolClass> _classes = [];
  SchoolClass? _selectedClass;

  bool _loadingClasses = false;
  String? _classError;

  // ============================================================
  // SUBJECTS
  // ============================================================

  List<ClassSubjectModel> _subjects = [];
  ClassSubjectModel? _selectedSubject;

  bool _loadingSubjects = false;
  String? _subjectError;

  // ============================================================
  // EXAM SCHEDULES
  // ============================================================

  List<ExamScheduleModel> _schedules = [];
  ExamScheduleModel? _selectedSchedule;
  final Set<int> _selectedScheduleIds = {};

  bool _loadingSchedules = false;
  String? _scheduleError;

  // ============================================================
  // STUDENTS
  // ============================================================

  List<Student> _students = [];
  List<Student> _allClassStudents = [];

  bool _loadingStudents = false;
  String? _studentError;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadExaminations();
    _loadClasses();
  }

  // ============================================================
  // LOAD EXAMINATIONS
  // ============================================================

  Future<void> _loadExaminations() async {
    setState(() {
      _loadingExaminations = true;
      _examinationError = null;
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
        _examinations = data;
        _loadingExaminations = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingExaminations = false;
        _examinationError = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD CLASSES
  // ============================================================

  Future<void> _loadClasses() async {
    setState(() {
      _loadingClasses = true;
      _classError = null;
    });

    try {
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

  // ============================================================
  // LOAD SUBJECTS
  // ============================================================

  Future<void> _loadSubjects() async {
    if (_selectedClass?.id == null) return;

    setState(() {
      _loadingSubjects = true;
      _subjectError = null;

      _subjects = [];
      _selectedSubject = null;

      _schedules = [];
      _selectedSchedule = null;

      // Do not clear students here.
      // Students for the selected class will be loaded below.
    });

    try {
      final service = ClassSubjectService(apiClient);

      final data = await service.getClassSubjects(_selectedClass!.id!);

      if (!mounted) return;

      setState(() {
        _subjects = data;
        _loadingSubjects = false;
      });

      // Load all students from the selected class.
      // This includes students from all sections.
      await _loadStudentsByClass(_selectedClass!.id!);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSubjects = false;
        _subjectError = e.toString();
      });
    }
  }
  // ============================================================
  // LOAD SCHEDULES
  // ============================================================

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
      _selectedSchedule = null;
      _selectedScheduleIds.clear();

      // _students = [];
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

      // If only one schedule exists,
      // automatically select it.
      // if (data.length == 1) {
      //   _selectSchedule(data.first);
      // }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSchedules = false;
        _scheduleError = e.toString();
      });
    }
  }

  // ============================================================
  // SELECT SCHEDULE
  // ============================================================
  Future<void> _selectSchedule(ExamScheduleModel schedule) async {
    if (schedule.id == null) return;

    setState(() {
      if (_selectedScheduleIds.contains(schedule.id)) {
        // Already selected → remove
        _selectedScheduleIds.remove(schedule.id);
      } else {
        // Not selected → add
        _selectedScheduleIds.add(schedule.id!);
      }

      // Backward compatibility
      if (_selectedScheduleIds.length == 1) {
        final selectedId = _selectedScheduleIds.first;

        _selectedSchedule = _schedules.firstWhere(
          (schedule) => schedule.id == selectedId,
        );
      } else {
        _selectedSchedule = null;
      }

      _studentError = null;
    });

    // --------------------------------------------------
    // NO SECTION SELECTED
    // → SHOW ALL CLASS STUDENTS
    // --------------------------------------------------
    if (_selectedScheduleIds.isEmpty) {
      final allStudents = List<Student>.from(_allClassStudents);

      allStudents.sort((a, b) {
        final rollA = int.tryParse(a.rollNumber ?? '');
        final rollB = int.tryParse(b.rollNumber ?? '');

        if (rollA != null && rollB != null) {
          return rollA.compareTo(rollB);
        }

        if (rollA != null) return -1;
        if (rollB != null) return 1;

        return (a.rollNumber ?? '').compareTo(b.rollNumber ?? '');
      });

      if (!mounted) return;

      setState(() {
        _students = allStudents;
      });

      return;
    }

    // --------------------------------------------------
    // GET SELECTED SECTION IDs
    // --------------------------------------------------
    final selectedSectionIds = _schedules
        .where(
          (schedule) =>
              schedule.id != null && _selectedScheduleIds.contains(schedule.id),
        )
        .map((schedule) => schedule.sectionId)
        .whereType<int>()
        .toSet();

    // --------------------------------------------------
    // ALWAYS FILTER FROM MASTER LIST
    // NOT FROM _students
    // --------------------------------------------------
    final filteredStudents = _allClassStudents
        .where(
          (student) =>
              student.sectionId != null &&
              selectedSectionIds.contains(student.sectionId),
        )
        .toList();

    // Sort by roll number
    filteredStudents.sort((a, b) {
      final rollA = int.tryParse(a.rollNumber ?? '');
      final rollB = int.tryParse(b.rollNumber ?? '');

      if (rollA != null && rollB != null) {
        return rollA.compareTo(rollB);
      }

      if (rollA != null) return -1;
      if (rollB != null) return 1;

      return (a.rollNumber ?? '').compareTo(b.rollNumber ?? '');
    });

    if (!mounted) return;

    setState(() {
      _students = filteredStudents;
    });
  }
  // ============================================================
  // LOAD STUDENTS BY SECTION
  // ============================================================

  Future<void> _loadStudents(int sectionId) async {
    setState(() {
      _loadingStudents = true;
      _studentError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final service = StudentService(token);

      final data = await service.getStudentsBySectionId(sectionId);

      // Sort by roll number.
      data.sort((a, b) {
        final rollA = int.tryParse(a.rollNumber ?? '');
        final rollB = int.tryParse(b.rollNumber ?? '');

        if (rollA != null && rollB != null) {
          return rollA.compareTo(rollB);
        }

        return (a.rollNumber ?? '').compareTo(b.rollNumber ?? '');
      });

      if (!mounted) return;

      setState(() {
        _students = data;
        _loadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStudents = false;
        _studentError = e.toString();
      });
    }
  }

  Future<void> _loadStudentsByClass(int classId) async {
    setState(() {
      _loadingStudents = true;
      _studentError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Login session not found. Please login again.');
      }

      final service = StudentService(token);
      final data = await service.getStudentsByClassId(classId);

      data.sort((a, b) {
        final rollA = int.tryParse(a.rollNumber ?? '');
        final rollB = int.tryParse(b.rollNumber ?? '');

        if (rollA != null && rollB != null) {
          return rollA.compareTo(rollB);
        }

        if (rollA != null) return -1;
        if (rollB != null) return 1;

        return (a.rollNumber ?? '').compareTo(b.rollNumber ?? '');
      });

      if (!mounted) return;

      setState(() {
        // MASTER LIST
        _allClassStudents = List<Student>.from(data);

        // Initially show all students
        _students = List<Student>.from(_allClassStudents);

        _loadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStudents = false;
        _studentError = e.toString();
        _allClassStudents = [];
        _students = [];
      });
    }
  } // ============================================================
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

    if (_selectedSubject == null) {
      _showMessage('Please select a subject.', isError: true);
      return;
    }

    if (_students.isEmpty) {
      _showMessage('No students found for the selected class.', isError: true);
      return;
    }

    try {
      final excel = ex.Excel.createExcel();

      final sheet = excel['Exam Results'];

      // ========================================================
      // HEADER
      // ========================================================

      final headers = [
        'Examination',
        'Class',
        'Section',
        'Subject',
        'Exam Date',
        'Admission No',
        'Roll Number',
        'Marks Obtained',
        'Remarks',
        'Status',
      ];

      sheet.appendRow(headers.map((value) => ex.TextCellValue(value)).toList());

      // ========================================================
      // MAP SCHEDULES BY SECTION
      // ========================================================

      final scheduleBySectionId = <int, ExamScheduleModel>{};

      for (final schedule in _schedules) {
        if (schedule.sectionId != null) {
          scheduleBySectionId[schedule.sectionId!] = schedule;
        }
      }

      // ========================================================
      // STUDENT ROWS
      // ========================================================

      for (final student in _students) {
        // If a section is selected, use that schedule.
        // If no section is selected, find the schedule
        // belonging to each student's section.
        final sectionSchedule = student.sectionId != null
            ? scheduleBySectionId[student.sectionId!]
            : null;

        final schedule = _selectedSchedule ?? sectionSchedule;

        sheet.appendRow([
          // Examination
          ex.TextCellValue(_selectedExamination!.name),

          // Class
          ex.TextCellValue(_selectedClass!.name ?? ''),

          // Student's actual section
          ex.TextCellValue(student.sectionName ?? ''),

          // Subject
          ex.TextCellValue(_selectedSubject!.subjectName),

          // Exam Date
          ex.TextCellValue(
            schedule != null ? _formatDate(schedule.examDate) : '',
          ),

          // Admission No
          ex.TextCellValue(student.admissionNo ?? ''),

          // Roll Number
          ex.TextCellValue(student.rollNumber ?? ''),

          // Marks Obtained
          // Teacher enters marks here.
          ex.TextCellValue(''),

          // Remarks
          ex.TextCellValue(''),

          // Status
          ex.TextCellValue(''),
        ]);
      }

      // ========================================================
      // COLUMN WIDTHS
      // ========================================================

      sheet.setColumnWidth(0, 25);
      sheet.setColumnWidth(1, 18);
      sheet.setColumnWidth(2, 12);
      sheet.setColumnWidth(3, 20);
      sheet.setColumnWidth(4, 15);
      sheet.setColumnWidth(5, 20);
      sheet.setColumnWidth(6, 14);
      sheet.setColumnWidth(7, 18);
      sheet.setColumnWidth(8, 20);
      sheet.setColumnWidth(9, 14);

      // ========================================================
      // DELETE DEFAULT SHEET
      // ========================================================

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // ========================================================
      // ENCODE EXCEL
      // ========================================================

      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('Failed to generate Exam Results Excel.');
      }

      // ========================================================
      // FILE NAME
      // ========================================================

      final sectionPart = _selectedSchedule != null
          ? _sanitizeFileName(_selectedSchedule!.sectionName)
          : 'All_Sections';

      final fileName =
          'exam_results_'
          '${_sanitizeFileName(_selectedExamination!.name)}_'
          '${_sanitizeFileName(_selectedClass!.name ?? '')}_'
          '${sectionPart}_'
          '${_sanitizeFileName(_selectedSubject!.subjectName)}';

      // ========================================================
      // SAVE FILE
      // ========================================================

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;

      _showMessage('Exam Results Excel generated successfully.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Failed to generate Exam Results Excel: $e', isError: true);
    }
  }
  // ============================================================
  // DATE FORMAT
  // ============================================================

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

  // ============================================================
  // FILE NAME
  // ============================================================

  String _sanitizeFileName(String value) {
    return value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(' ', '_');
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
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
      appBar: AppBar(
        title: const Text(
          'Exam Results Excel',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
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

            const SizedBox(height: 24),

            _buildStudentsCard(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exam Results',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172033),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Generate student-wise marks update Excel',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Exam Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildExaminationDropdown()),

              const SizedBox(width: 16),

              Expanded(child: _buildClassDropdown()),

              const SizedBox(width: 16),

              Expanded(child: _buildSubjectDropdown()),
            ],
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
        prefixIcon: const Icon(Icons.assignment_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      hint: _loadingExaminations
          ? const Text('Loading...')
          : const Text('Select examination'),
      items: _examinations.map((exam) {
        return DropdownMenuItem<ExaminationModel>(
          value: exam,
          child: Text(exam.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _loadingExaminations
          ? null
          : (value) {
              setState(() {
                _selectedExamination = value;

                _selectedSubject = null;
                _schedules = [];
                _selectedSchedule = null;
                _selectedScheduleIds.clear();
              });

              if (value != null &&
                  _selectedClass != null &&
                  _selectedSubject != null) {
                _loadSchedules();
              }
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
        prefixIcon: const Icon(Icons.class_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      hint: _loadingClasses
          ? const Text('Loading...')
          : const Text('Select class'),
      items: _classes.map((schoolClass) {
        return DropdownMenuItem<SchoolClass>(
          value: schoolClass,
          child: Text(schoolClass.name!, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _loadingClasses
          ? null
          : (value) {
              setState(() {
                _selectedClass = value;

                _selectedSubject = null;
                _subjects = [];

                _schedules = [];
                _selectedSchedule = null;
                _selectedScheduleIds.clear();
                _students = [];
                _allClassStudents = [];
              });

              if (value != null) {
                _loadSubjects();
              }
            },
    );
  }

  // ============================================================
  // SUBJECT DROPDOWN
  // ============================================================

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<ClassSubjectModel>(
      value: _selectedSubject,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Subject',
        prefixIcon: const Icon(Icons.menu_book_rounded),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      hint: _loadingSubjects
          ? const Text('Loading...')
          : const Text('Select subject'),
      items: _subjects.map((subject) {
        return DropdownMenuItem<ClassSubjectModel>(
          value: subject,
          child: Text(subject.subjectName, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: _loadingSubjects
          ? null
          : (value) {
              setState(() {
                _selectedSubject = value;

                _schedules = [];
                _selectedSchedule = null;

                _selectedScheduleIds.clear();
              });

              if (value != null &&
                  _selectedExamination != null &&
                  _selectedClass != null) {
                _loadSchedules();
              }
            },
    );
  }

  // ============================================================
  // SCHEDULE CARD
  // ============================================================

  Widget _buildScheduleCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Select the section for which marks need to be entered',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              ElevatedButton.icon(
                onPressed: _students.isNotEmpty ? _generateExcel : null,
                icon: const Icon(Icons.file_download_rounded),
                label: const Text('Generate Excel'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_loadingSchedules)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_scheduleError != null)
            _buildError(_scheduleError!)
          else if (_schedules.isEmpty)
            _buildEmpty(
              'Select examination, class and subject to load schedules.',
            )
          else
            _buildScheduleTable(),
        ],
      ),
    );
  }

  // ============================================================
  // SCHEDULE TABLE
  // ============================================================

  Widget _buildScheduleTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FB)),
        columns: const [
          DataColumn(label: Text('Select')),
          DataColumn(label: Text('Section')),
          DataColumn(label: Text('Exam Date')),
          DataColumn(label: Text('Start Time')),
          DataColumn(label: Text('Max Marks')),
          DataColumn(label: Text('Teacher')),
          DataColumn(label: Text('Status')),
        ],
        rows: _schedules.map((schedule) {
          final selected = _selectedSchedule?.id == schedule.id;

          return DataRow(
            selected: selected,
            cells: [
              DataCell(
                Checkbox(
                  value:
                      schedule.id != null &&
                      _selectedScheduleIds.contains(schedule.id),
                  onChanged: (_) {
                    _selectSchedule(schedule);
                  },
                ),
              ),
              DataCell(Text(schedule.sectionName)),
              DataCell(Text(_formatDate(schedule.examDate))),
              DataCell(Text(schedule.startTime)),
              DataCell(Text(schedule.maxMarks.toString())),
              DataCell(Text(schedule.subjectTeacherName)),
              DataCell(Text(schedule.status)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // STUDENTS CARD
  // ============================================================

  Widget _buildStudentsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9F0)),
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
                      'Students',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Students included in the generated Excel',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              if (_students.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_students.length} Students',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          if (_loadingStudents)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_studentError != null)
            _buildError(_studentError!)
          else if (_students.isEmpty)
            _buildEmpty(
              _selectedSchedule == null
                  ? 'No students found in this class.'
                  : 'No students found in this section.',
            )
          else
            _buildStudentsTable(),
        ],
      ),
    );
  }
  // ============================================================
  // STUDENTS TABLE
  // ============================================================

  Widget _buildStudentsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F7FB)),
        columns: const [
          DataColumn(label: Text('S.No')),
          DataColumn(label: Text('Roll Number')),
          DataColumn(label: Text('Admission No')),
          DataColumn(label: Text('Student Name')),
        ],
        rows: List.generate(_students.length, (index) {
          final student = _students[index];

          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(student.rollNumber ?? '-')),
              DataCell(Text(student.admissionNo ?? '-')),
              DataCell(Text(student.name ?? '-')),
            ],
          );
        }),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: TextStyle(color: Colors.red.shade700)),
    );
  }
}
