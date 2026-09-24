
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/models/class_subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/teacher_assignment_model.dart';

import 'package:smartkids_admin/features/teachers/services/class_subject_service.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';
import 'package:smartkids_admin/features/teachers/services/teacher_assignment_service.dart';

import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/services/student_service.dart';

import 'package:smartkids_admin/models/section_model.dart';
import 'package:smartkids_admin/services/section_service.dart';

import 'package:smartkids_admin/features/attendance/models/attendance_response_model.dart';
import 'package:smartkids_admin/features/attendance/services/attendance_service.dart';

import '../timetable/models/timetable_model.dart';
import 'package:smartkids_admin/features/timetable/services/timetable_service.dart';

import 'package:smartkids_admin/features/teachers/services/teacher_service.dart';

class ClassDetailsScreen extends StatefulWidget {
  final SchoolClass schoolClass;

  const ClassDetailsScreen({
    super.key,
    required this.schoolClass,
  });

  @override
  State<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends State<ClassDetailsScreen> {
  StudentService? _studentService;
  SectionService? _sectionService;
  AttendanceService? _attendanceService;
  TimetableService? _timetableService;
  ClassSubjectService? _classSubjectService;
  SubjectService? _subjectService;
  TeacherAssignmentService? _teacherAssignmentService;
  TeacherService? _teacherService;

  bool _loading = true;
  String? _error;

  List<Student> _students = [];
  List<Section> _sections = [];
  List<AttendanceResponseModel> _attendance = [];
  List<TimetableEntry> _timetable = [];
  List<ClassSubjectModel> _classSubjects = [];
  List<TeacherAssignment> _assignments = [];

  final Map<int, List<dynamic>> _performanceBySubject = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Session expired. Please login again.';
      });

      return;
    }

    _studentService = StudentService(token);
    _sectionService = SectionService(token);
    _attendanceService = AttendanceService(token);
    _timetableService = TimetableService(token);
    _classSubjectService = ClassSubjectService(token);
    _subjectService = SubjectService(token);
    _teacherAssignmentService = TeacherAssignmentService(token);
    _teacherService = TeacherService(token);

    await _loadData();
  }

  Future<void> _loadData() async {
    final classId = widget.schoolClass.id;

    if (classId == null) {
      setState(() {
        _loading = false;
        _error = 'Class ID is missing.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _studentService!.getStudentsByClassId(classId),
        _sectionService!.getSectionsByClassId(classId),
        _attendanceService!.getClassAttendance(
          classId: classId,
          date: DateTime.now(),
        ),
        _timetableService!.getByClass(classId),
        _classSubjectService!.getClassSubjects(classId),
        _teacherAssignmentService!.getAssignmentsByClass(classId),
      ]);

      _students = results[0] as List<Student>;
      _sections = results[1] as List<Section>;
      _attendance = results[2] as List<AttendanceResponseModel>;
      _timetable = results[3] as List<TimetableEntry>;
      _classSubjects = results[4] as List<ClassSubjectModel>;
      _assignments = results[5] as List<TeacherAssignment>;

      await _loadPerformance();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadPerformance() async {
    _performanceBySubject.clear();

    final uniqueSubjectIds = _classSubjects
        .map((e) => e.subjectId)
        .whereType<int>()
        .toSet();

    for (final subjectId in uniqueSubjectIds) {
      try {
        final performance =
            await _subjectService!.getSubjectPerformance(subjectId);

        final classPerformance = performance
            .where(
              (item) => item.classId == widget.schoolClass.id,
            )
            .toList();

        _performanceBySubject[subjectId] = classPerformance;
      } catch (_) {
        _performanceBySubject[subjectId] = [];
      }
    }
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // ATTENDANCE
  // ============================================================

  int get _presentCount {
    return _attendance
        .where((a) => _status(a.status) == 'PRESENT')
        .length;
  }

  int get _absentCount {
    return _attendance
        .where((a) => _status(a.status) == 'ABSENT')
        .length;
  }

  int get _leaveCount {
    return _attendance
        .where((a) => _status(a.status) == 'LEAVE')
        .length;
  }

  int get _markedCount {
    return _attendance.length;
  }

  int get _notMarkedCount {
    final value = _students.length - _markedCount;
    return value < 0 ? 0 : value;
  }

  double get _attendancePercentage {
    if (_students.isEmpty) return 0;

    return (_presentCount / _students.length) * 100;
  }

  String _status(String? value) {
    return (value ?? '').trim().toUpperCase();
  }

  // ============================================================
  // TIMETABLE
  // ============================================================

  List<TimetableEntry> get _todayTimetable {
    final today = _weekdayName(DateTime.now().weekday);

    return _timetable.where((entry) {
      final day = (entry.dayOfWeek ?? '').trim().toUpperCase();

      return day == today ||
          day == today.substring(0, 3) ||
          day.contains(today);
    }).toList()
      ..sort((a, b) {
        return (a.startTime ?? '').compareTo(b.startTime ?? '');
      });
  }

  String _weekdayName(int weekday) {
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];

    return days[weekday - 1];
  }

  // ============================================================
  // TEACHER FOR SUBJECT
  // ============================================================

  List<TeacherAssignment> _teachersForSubject(int subjectId) {
    return _assignments
        .where((assignment) => assignment.subjectId == subjectId)
        .toList();
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Class Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xff172033),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildOverviewCards(),
                const SizedBox(height: 20),
                _buildAttendanceSection(),
                const SizedBox(height: 20),
                _buildMiddleSections(),
                const SizedBox(height: 20),
                _buildTimetableSection(),
                const SizedBox(height: 20),
                _buildSubjectsSection(),
                const SizedBox(height: 20),
                _buildPerformanceSection(),
                const SizedBox(height: 20),
                _buildStudentsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xffe8ebf2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 18,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: const Color(0xffeef2ff),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xff4f46e5),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.schoolClass.name ?? 'Class',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff172033),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.schoolClass.grade ?? 'Grade'} • '
                    'Academic Year ${widget.schoolClass.year ?? '-'}',
                    style: const TextStyle(
                      color: Color(0xff667085),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xffecfdf3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 9,
                  color: Color(0xff12b76a),
                ),
                SizedBox(width: 8),
                Text(
                  'Active Class',
                  style: TextStyle(
                    color: Color(0xff027a48),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 900
            ? (constraints.maxWidth - 48) / 4
            : constraints.maxWidth >= 600
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Students',
                value: '${_students.length}',
                subtitle: 'Total students',
                icon: Icons.people_alt_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Sections',
                value: '${_sections.length}',
                subtitle: 'Class sections',
                icon: Icons.grid_view_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Subjects',
                value: '${_classSubjects.length}',
                subtitle: 'Assigned subjects',
                icon: Icons.menu_book_rounded,
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                title: 'Attendance',
                value:
                    '${_attendancePercentage.toStringAsFixed(1)}%',
                subtitle: 'Today',
                icon: Icons.fact_check_rounded,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe8ebf2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xfff1f3ff),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xff4f46e5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff172033),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff98a2b3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return _sectionCard(
      title: "Today's Attendance",
      subtitle: _formatDate(DateTime.now()),
      icon: Icons.fact_check_rounded,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 700
                  ? (constraints.maxWidth - 36) / 4
                  : constraints.maxWidth >= 400
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _attendanceBox(
                      'Present',
                      _presentCount,
                      Icons.check_circle_rounded,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _attendanceBox(
                      'Absent',
                      _absentCount,
                      Icons.cancel_rounded,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _attendanceBox(
                      'Leave',
                      _leaveCount,
                      Icons.event_busy_rounded,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _attendanceBox(
                      'Not Marked',
                      _notMarkedCount,
                      Icons.help_outline_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: (_attendancePercentage / 100).clamp(0, 1),
                    backgroundColor: const Color(0xffeef0f4),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${_attendancePercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff172033),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _attendanceBox(
    String title,
    int value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffafbfc),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xffeaecf0)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: const Color(0xff475467),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff667085),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleSections() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;

        if (!wide) {
          return Column(
            children: [
              _buildSectionsCard(),
              const SizedBox(height: 20),
              _buildClassInfoCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSectionsCard()),
            const SizedBox(width: 20),
            Expanded(child: _buildClassInfoCard()),
          ],
        );
      },
    );
  }

  Widget _buildSectionsCard() {
    return _sectionCard(
      title: 'Sections',
      subtitle: '${_sections.length} sections',
      icon: Icons.grid_view_rounded,
      child: _sections.isEmpty
          ? _emptyText('No sections assigned to this class.')
          : Column(
              children: _sections.map((section) {
                final sectionStudents = _students
                    .where((student) => student.sectionId == section.id)
                    .length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xfffafbfc),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xffeaecf0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xffeef2ff),
                        ),
                        child: Text(
                          section.name?.isNotEmpty == true
                              ? section.name![0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xff4f46e5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.name ?? 'Section',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$sectionStudents students'
                              '${section.capacity != null ? ' • Capacity ${section.capacity}' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildClassInfoCard() {
    return _sectionCard(
      title: 'Class Information',
      subtitle: 'Basic details',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _infoRow(
            'Class Name',
            widget.schoolClass.name ?? '-',
          ),
          _infoRow(
            'Class Code',
            widget.schoolClass.code ?? '-',
          ),
          _infoRow(
            'Grade',
            widget.schoolClass.grade ?? '-',
          ),
          _infoRow(
            'Academic Year',
            '${widget.schoolClass.year ?? '-'}',
          ),
          _infoRow(
            'School',
            widget.schoolClass.schoolName ?? '-',
          ),
          _infoRow(
            'Description',
            widget.schoolClass.description ?? '-',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xffeaecf0),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xff667085),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xff172033),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSection() {
    final timetable = _todayTimetable;

    return _sectionCard(
      title: "Today's Timetable",
      subtitle: '${_weekdayName(DateTime.now().weekday)} • ${timetable.length} periods',
      icon: Icons.schedule_rounded,
      child: timetable.isEmpty
          ? _emptyText("No timetable entries for today's class.")
          : Column(
              children: timetable.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xfffafbfc),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xffeaecf0),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          entry.timeRange,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Color(0xff4f46e5),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 42,
                        color: const Color(0xffe4e7ec),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.subject ?? 'Subject',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xff172033),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.teacherName ?? 'Teacher not assigned',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff667085),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.sectionName != null &&
                          entry.sectionName!.isNotEmpty)
                        _smallChip(
                          entry.sectionName!,
                          Icons.grid_view_rounded,
                        ),
                      if (entry.roomNumber != null &&
                          entry.roomNumber!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _smallChip(
                          entry.roomNumber!,
                          Icons.meeting_room_outlined,
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSubjectsSection() {
    return _sectionCard(
      title: 'Subjects & Teachers',
      subtitle: '${_classSubjects.length} assigned subjects',
      icon: Icons.menu_book_rounded,
      child: _classSubjects.isEmpty
          ? _emptyText('No subjects assigned to this class.')
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _classSubjects.map((subject) {
                final subjectId = subject.subjectId;

                final teachers = subjectId == null
                    ? <TeacherAssignment>[]
                    : _teachersForSubject(subjectId);

                return Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfffafbfc),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xffeaecf0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xffeef2ff),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 19,
                              color: Color(0xff4f46e5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              subject.subjectName ?? 'Subject',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subject.subjectCode ?? '-',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xff667085),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (teachers.isEmpty)
                        const Text(
                          'Teacher not assigned',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff98a2b3),
                          ),
                        )
                      else
                        ...teachers.map(
                          (teacher) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  size: 16,
                                  color: Color(0xff667085),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    teacher.teacherName ??
                                        'Teacher',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff344054),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPerformanceSection() {
    final performanceItems = <Widget>[];

    for (final subject in _classSubjects) {
      final subjectId = subject.subjectId;

      if (subjectId == null) continue;

      final records = _performanceBySubject[subjectId] ?? [];

      if (records.isEmpty) continue;

      // Backend returns latest first.
      final latest = records.first;

      performanceItems.add(
        _performanceCard(
          subjectName: subject.subjectName ?? 'Subject',
          percentage:
              latest.performancePercentage.toDouble(),
          examName: latest.examName,
          averageMarks:
              latest.averageMarks.toDouble(),
          maxMarks: latest.maxMarks,
          previousCount: records.length > 1
              ? records.length - 1
              : 0,
        ),
      );
    }

    return _sectionCard(
      title: 'Academic Performance',
      subtitle: 'Latest examination performance',
      icon: Icons.analytics_rounded,
      child: performanceItems.isEmpty
          ? _emptyText(
              'No examination performance available for this class.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth >= 900
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth >= 600
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: performanceItems
                      .map(
                        (item) => SizedBox(
                          width: width,
                          child: item,
                        ),
                      )
                      .toList(),
                );
              },
            ),
    );
  }

  Widget _performanceCard({
    required String subjectName,
    required double percentage,
    required String examName,
    required double averageMarks,
    required int maxMarks,
    required int previousCount,
  }) {
    final safePercentage = percentage.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfffafbfc),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffeaecf0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subjectName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '${safePercentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xff4f46e5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: safePercentage / 100,
              backgroundColor: const Color(0xffe9ecf2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            examName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xff344054),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Average: ${averageMarks.toStringAsFixed(1)} / $maxMarks',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff667085),
            ),
          ),
          if (previousCount > 0) ...[
            const SizedBox(height: 7),
            Text(
              '$previousCount previous performance record'
              '${previousCount == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xff4f46e5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentsSection() {
    return _sectionCard(
      title: 'Students',
      subtitle: '${_students.length} students in this class',
      icon: Icons.people_alt_rounded,
      child: _students.isEmpty
          ? _emptyText('No students found in this class.')
          : Column(
              children: [
                ..._students.take(10).map(
                  (student) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xfffafbfc),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: const Color(0xffeaecf0),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xffeef2ff),
                            child: Text(
                              (student.name ?? 'S')
                                  .trim()
                                  .isNotEmpty
                                  ? (student.name ?? 'S')
                                      .trim()[0]
                                      .toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xff4f46e5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name ?? 'Student',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Admission No: '
                                  '${student.admissionNo ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xff667085),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (student.sectionName != null)
                            _smallChip(
                              student.sectionName!,
                              Icons.grid_view_rounded,
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (_students.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+ ${_students.length - 10} more students',
                      style: const TextStyle(
                        color: Color(0xff4f46e5),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xffe8ebf2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xfff1f3ff),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xff4f46e5),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff98a2b3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _smallChip(
    String text,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xfff2f4f7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: const Color(0xff667085),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xff475467),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 25,
        horizontal: 15,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xff98a2b3),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xffe8ebf2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xffd92d20),
              ),
              const SizedBox(height: 15),
              const Text(
                'Unable to load class details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff667085),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
