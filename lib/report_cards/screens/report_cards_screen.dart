import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';

import 'package:smartkids_admin/models/student_gender_summary.dart';
import 'package:smartkids_admin/features/exams/models/examination_model.dart';
import 'package:smartkids_admin/features/exams/services/examination_service.dart';

import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/services/class_service.dart';
import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/services/section_service.dart';
import 'package:smartkids_admin/services/student_service.dart';
import '../services/report_card_service.dart';
import 'report_card_view_screen.dart';

class ReportCardsScreen extends StatefulWidget {
  const ReportCardsScreen({super.key});

  @override
  State<ReportCardsScreen> createState() =>
      _ReportCardsScreenState();
}

class _ReportCardsScreenState extends State<ReportCardsScreen> {
  late final ClassService _classService;
  late final SectionService _sectionService;
  late final ReportCardService _reportCardService;

  StudentService? _studentService;
  ExaminationService? _examinationService;

  List<SchoolClass> _classes = [];
  List<Section> _sections = [];
  List<Student> _students = [];
  List<ExaminationModel> _examinations = [];

  SchoolClass? _selectedClass;
  Section? _selectedSection;
  Student? _selectedStudent;
  ExaminationModel? _selectedExamination;

  bool _initialLoading = true;
  bool _studentsLoading = false;
  bool _examinationsLoading = false;
  bool _reportLoading = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _classService = ClassService(ApiClient());
    _sectionService = SectionService(ApiClient());
    _reportCardService = ReportCardService(ApiClient());

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Authentication token not found. Please login again.',
        );
      }

      _studentService = StudentService(token);
      _examinationService = ExaminationService(token);

      final classes = await _classService.getClasses();

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _initialLoading = false;
      });

      await _loadExaminations();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _initialLoading = false;
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _loadExaminations() async {
    if (_examinationService == null) return;

    setState(() {
      _examinationsLoading = true;
    });

    try {
      final examinations =
          await _examinationService!.getExaminations();

      if (!mounted) return;

      setState(() {
        _examinations = examinations;
        _examinationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _examinationsLoading = false;
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _onClassChanged(
    SchoolClass? value,
  ) async {
    if (value == null) return;

    setState(() {
      _selectedClass = value;
      _selectedSection = null;
      _selectedStudent = null;
      _selectedExamination = null;

      _sections = [];
      _students = [];
      _error = null;
    });

    try {
      final sections =
          await _sectionService.getSectionsByClassId(
        value.id!,
      );

      if (!mounted) return;

      setState(() {
        _sections = sections;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    }
  }

  Future<void> _onSectionChanged(
    Section? value,
  ) async {
    if (value == null) return;

    setState(() {
      _selectedSection = value;
      _selectedStudent = null;
      _selectedExamination = null;
      _students = [];
      _studentsLoading = true;
      _error = null;
    });

    try {
      if (_studentService == null) {
        throw Exception(
          'Student service is not initialized.',
        );
      }

      final students =
          await _studentService!.getStudentsBySectionId(
        value.id,
      );

      if (!mounted) return;

      setState(() {
        _students = students;
        _studentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _studentsLoading = false;
        _error = _cleanError(e);
      });
    }
  }

  void _selectStudent(Student student) {
    setState(() {
      _selectedStudent = student;
      _selectedExamination = null;
      _error = null;
    });
  }

  Future<void> _openReportCard() async {
    final student = _selectedStudent;
    final examination = _selectedExamination;

    if (student?.id == null) {
      setState(() {
        _error = 'Please select a student.';
      });
      return;
    }

    if (examination?.id == null) {
      setState(() {
        _error = 'Please select an examination.';
      });
      return;
    }

    setState(() {
      _reportLoading = true;
      _error = null;
    });

    try {
      final report =
          await _reportCardService.getReportCard(
        studentId: student!.id!,
        examinationId: examination!.id!,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportCardViewScreen(
            reportCard: report,
            service: _reportCardService,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _reportLoading = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('DioException [bad response]: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: _initialLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _pageHeader(),

                  const SizedBox(height: 26),

                  _filterCard(),

                  const SizedBox(height: 22),

                  if (_error != null)
                    _errorCard(),

                  if (_selectedClass != null &&
                      _selectedSection != null)
                    _studentsSection(),

                  if (_selectedStudent != null)
                    _studentSelectionCard(),
                ],
              ),
            ),
    );
  }

  Widget _pageHeader() {
    return Row(
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4F46E5),
                Color(0xFF6366F1),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x224F46E5),
                blurRadius: 15,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: const Icon(
            Icons.description_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Report Cards',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Select a class and section to view student examination report cards.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                color: Color(0xFF4F46E5),
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Student Filters',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide =
                  constraints.maxWidth >= 700;

              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: _classDropdown(),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _sectionDropdown(),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _classDropdown(),
                  const SizedBox(height: 16),
                  _sectionDropdown(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _classDropdown() {
    return DropdownButtonFormField<SchoolClass>(
      value: _selectedClass,
      isExpanded: true,
      decoration: _dropdownDecoration(
        label: 'Class',
        icon: Icons.school_rounded,
      ),
      hint: const Text('Select Class'),
      items: _classes.map((schoolClass) {
        return DropdownMenuItem<SchoolClass>(
          value: schoolClass,
          child: Text(
            schoolClass.name ?? 'Class',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onClassChanged,
    );
  }

  Widget _sectionDropdown() {
    return DropdownButtonFormField<Section>(
      value: _selectedSection,
      isExpanded: true,
      decoration: _dropdownDecoration(
        label: 'Section',
        icon: Icons.grid_view_rounded,
      ),
      hint: Text(
        _selectedClass == null
            ? 'Select class first'
            : 'Select Section',
      ),
      items: _sections.map((section) {
        return DropdownMenuItem<Section>(
          value: section,
          child: Text(
            section.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged:
          _selectedClass == null
              ? null
              : _onSectionChanged,
    );
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF4F46E5),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFF4F46E5),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _studentsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _studentsHeader(),

          if (_studentsLoading)
            const Padding(
              padding: EdgeInsets.all(50),
              child: CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
            )
          else if (_students.isEmpty)
            _emptyStudents()
          else
            _studentsTable(),
        ],
      ),
    );
  }

  Widget _studentsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        22,
        24,
        18,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.people_alt_rounded,
            color: Color(0xFF4F46E5),
            size: 22,
          ),
          const SizedBox(width: 10),
          const Text(
            'Students',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              '${_students.length}',
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${_selectedClass?.name ?? ''} • ${_selectedSection?.name ?? ''}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentsTable() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 70,
                child: Text(
                  'Roll No.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Student Name',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Admission No.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ),
              SizedBox(
                width: 45,
                child: Text(''),
              ),
            ],
          ),
        ),

        const SizedBox(height: 5),

        ListView.separated(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: _students.length,
          separatorBuilder: (_, __) =>
              const Divider(
            height: 1,
            color: Color(0xFFF1F5F9),
          ),
          itemBuilder: (context, index) {
            final student = _students[index];

            return _studentRow(student);
          },
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Widget _studentRow(Student student) {
    final isSelected =
        _selectedStudent?.id == student.id;

    return Material(
      color: isSelected
          ? const Color(0xFFF5F3FF)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _selectStudent(student),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 36,
            vertical: 14,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  student.rollNumber ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),

              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      height: 38,
                      width: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : const Color(0xFFEEF2FF),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initial(
                          student.name,
                        ),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(
                                  0xFF4F46E5,
                                ),
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        student.name ?? 'Unknown Student',
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  student.admissionNo ?? '-',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              SizedBox(
                width: 45,
                child: Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFF1F5F9),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.check_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initial(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    return name.trim()[0].toUpperCase();
  }

  Widget _emptyStudents() {
    return Padding(
      padding: const EdgeInsets.all(50),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_off_rounded,
              size: 32,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No students found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'There are no students in the selected section.',
            style: TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentSelectionCard() {
    final student = _selectedStudent!;

    return Container(
      margin: const EdgeInsets.only(top: 22),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4F46E5),
                      Color(0xFF6366F1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _initial(student.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name ??
                          'Unknown Student',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedClass?.name ?? '-'} • ${_selectedSection?.name ?? '-'}'
                      '  •  Roll No. ${student.rollNumber ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Change student',
                onPressed: () {
                  setState(() {
                    _selectedStudent = null;
                    _selectedExamination = null;
                  });
                },
                icon: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    constraints.maxWidth >= 650;

                if (isWide) {
                  return Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child:
                            _examinationDropdown(),
                      ),
                      const SizedBox(width: 16),
                      _viewReportButton(),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    _examinationDropdown(),
                    const SizedBox(height: 16),
                    _viewReportButton(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _examinationDropdown() {
    return DropdownButtonFormField<
        ExaminationModel>(
      value: _selectedExamination,
      isExpanded: true,
      decoration: _dropdownDecoration(
        label: 'Examination',
        icon: Icons.assignment_rounded,
      ),
      hint: Text(
        _examinationsLoading
            ? 'Loading examinations...'
            : 'Select Examination',
      ),
      items: _examinations.map((exam) {
        return DropdownMenuItem<
            ExaminationModel>(
          value: exam,
          child: Text(
            exam.name,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _examinationsLoading
          ? null
          : (value) {
              setState(() {
                _selectedExamination = value;
                _error = null;
              });
            },
    );
  }

  Widget _viewReportButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed:
            _reportLoading ||
                    _selectedExamination == null
                ? null
                : _openReportCard,
        icon: _reportLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.visibility_rounded,
              ),
        label: Text(
          _reportLoading
              ? 'Loading...'
              : 'View Report Card',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFFE2E8F0),
          disabledForegroundColor:
              const Color(0xFF94A3B8),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(13),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 22,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
              color: Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }
}