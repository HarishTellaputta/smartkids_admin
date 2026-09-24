
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/attendance/models/attendance_response_model.dart';
import 'package:smartkids_admin/features/attendance/models/attendance_update_model.dart';
import 'package:smartkids_admin/features/attendance/services/attendance_service.dart';

import '../teachers/models/class_model.dart';
import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/services/student_service.dart';
import '../teachers/services/class_service.dart';

class AttendanceDetailsScreen extends StatefulWidget {
  final SchoolClass schoolClass;
  final DateTime initialDate;

  const AttendanceDetailsScreen({
    super.key,
    required this.schoolClass,
    required this.initialDate,
  });

  @override
  State<AttendanceDetailsScreen> createState() =>
      _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState
    extends State<AttendanceDetailsScreen> {
  AttendanceService? _attendanceService;
  StudentService? _studentService;
  ClassService? _classService;

  late DateTime selectedDate;

  List<Student> allStudents = [];
  List<Student> students = [];

  final Map<int, AttendanceResponseModel> existingAttendance = {};
  final Map<int, String> attendanceStatus = {};
  final Map<int, String> originalStatus = {};

  final TextEditingController searchController =
      TextEditingController();

  String searchQuery = '';

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String? infoMessage;

  @override
  void initState() {
    super.initState();

    selectedDate = widget.initialDate;

    _initialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session expired. Please login again.',
        );
      }

      _attendanceService = AttendanceService(token);
      _studentService = StudentService(token);
      _classService = ClassService(token);

      await _loadAttendance();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadAttendance() async {
    if (_attendanceService == null ||
        _studentService == null ||
        widget.schoolClass.id == null) {
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      infoMessage = null;
    });

    try {
      final classId = widget.schoolClass.id!;

      final results = await Future.wait([
        _studentService!.getStudentsByClassId(classId),
        _attendanceService!.getClassAttendance(
          classId: classId,
          date: selectedDate,
        ),
      ]);

      final loadedStudents = results[0] as List<Student>;
      final attendance =
          results[1] as List<AttendanceResponseModel>;

      final attendanceMap = <int, AttendanceResponseModel>{};

      for (final record in attendance) {
        if (record.studentId != null) {
          attendanceMap[record.studentId!] = record;
        }
      }

      final statusMap = <int, String>{};
      final originalMap = <int, String>{};

      for (final student in loadedStudents) {
        if (student.id == null) continue;

        final record = attendanceMap[student.id!];

        if (record != null) {
          final status = _displayStatus(record.status);

          statusMap[student.id!] = status;
          originalMap[student.id!] = status;
        }
      }

      if (!mounted) return;

      setState(() {
        allStudents = loadedStudents;
        students = loadedStudents;

        existingAttendance
          ..clear()
          ..addAll(attendanceMap);

        attendanceStatus
          ..clear()
          ..addAll(statusMap);

        originalStatus
          ..clear()
          ..addAll(originalMap);

        isLoading = false;

        if (attendance.isEmpty) {
          infoMessage =
              'Attendance has not been marked for this class on this date.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _displayStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return 'Present';
      case 'ABSENT':
        return 'Absent';
      case 'LEAVE':
        return 'Leave';
      default:
        return status;
    }
  }

  String _apiStatus(String status) {
    switch (status) {
      case 'Present':
        return 'PRESENT';
      case 'Absent':
        return 'ABSENT';
      case 'Leave':
        return 'LEAVE';
      default:
        return status.toUpperCase();
    }
  }

  void _changeAttendance(
    Student student,
    String status,
  ) {
    if (student.id == null) return;

    setState(() {
      attendanceStatus[student.id!] = status;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });

    await _loadAttendance();
  }

  void _filterStudents(String value) {
    setState(() {
      searchQuery = value.toLowerCase().trim();

      if (searchQuery.isEmpty) {
        students = allStudents;
        return;
      }

      students = allStudents.where((student) {
        final name =
            student.name?.toLowerCase() ?? '';

        final admission =
            student.admissionNo?.toLowerCase() ?? '';

        final roll =
            student.id?.toString().toLowerCase() ?? '';

        return name.contains(searchQuery) ||
            admission.contains(searchQuery) ||
            roll.contains(searchQuery);
      }).toList();
    });
  }

  Future<void> _saveChanges() async {
    if (_attendanceService == null) return;

    final changedRecords = <AttendanceResponseModel>[];

    for (final entry in attendanceStatus.entries) {
      final studentId = entry.key;
      final newStatus = entry.value;

      final oldStatus = originalStatus[studentId];

      if (oldStatus == newStatus) {
        continue;
      }

      final attendance = existingAttendance[studentId];

      if (attendance != null) {
        changedRecords.add(attendance);
      }
    }

    if (changedRecords.isEmpty) {
      _showMessage(
        'No attendance changes to save.',
        isError: false,
      );
      return;
    }

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      for (final attendance in changedRecords) {
        final studentId = attendance.studentId;

        if (studentId == null) continue;

        final newStatus = attendanceStatus[studentId];

        if (newStatus == null) continue;

        await _attendanceService!.updateAttendance(
          attendance.id,
          AttendanceUpdateModel(
            teacherId: attendance.markedByTeacherId!,
            status: _apiStatus(newStatus),
            remarks: attendance.remarks,
          ),
        );
      }

      if (!mounted) return;

      _showMessage(
        'Attendance updated successfully.',
        isError: false,
      );

      await _loadAttendance();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });
    }
  }

  void _showMessage(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : Colors.green,
      ),
    );
  }

  int get presentCount {
    return attendanceStatus.values
        .where((status) => status == 'Present')
        .length;
  }

  int get absentCount {
    return attendanceStatus.values
        .where((status) => status == 'Absent')
        .length;
  }

  int get leaveCount {
    return attendanceStatus.values
        .where((status) => status == 'Leave')
        .length;
  }

  int get markedCount {
    return attendanceStatus.length;
  }

  double get attendancePercentage {
    if (allStudents.isEmpty) return 0;

    return (presentCount / allStudents.length) * 100;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          '${widget.schoolClass.name ?? 'Class'} Attendance',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF111827),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading && allStudents.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(),
        const SizedBox(height: 20),
        _buildControls(),
        const SizedBox(height: 20),
        if (errorMessage != null) _buildError(),
        if (infoMessage != null) _buildInfo(),
        _buildSummary(),
        const SizedBox(height: 22),
        _buildStudentList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.schoolClass.name ??
                      'Unnamed Class',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDate(selectedDate)}'
                  '${widget.schoolClass.code != null ? ' • ${widget.schoolClass.code}' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _CircularPercentage(
            percentage: attendancePercentage,
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        final date = _buildDateButton();
        final search = _buildSearch();

        if (compact) {
          return Column(
            children: [
              date,
              const SizedBox(height: 12),
              search,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: date),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: search),
          ],
        );
      },
    );
  }

  Widget _buildDateButton() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 19,
              color: Color(0xFF64748B),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatDate(selectedDate),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: _filterStudents,
              decoration: const InputDecoration(
                hintText:
                    'Search student by name, roll number...',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _SummaryItem(
            title: 'Students',
            value: allStudents.length,
            icon: Icons.groups_outlined,
            color: const Color(0xFF2563EB),
          ),
          _SummaryItem(
            title: 'Marked',
            value: markedCount,
            icon: Icons.fact_check_outlined,
            color: const Color(0xFF7C3AED),
          ),
          _SummaryItem(
            title: 'Present',
            value: presentCount,
            icon: Icons.check_circle_outline,
            color: const Color(0xFF059669),
          ),
          _SummaryItem(
            title: 'Absent',
            value: absentCount,
            icon: Icons.cancel_outlined,
            color: const Color(0xFFDC2626),
          ),
          _SummaryItem(
            title: 'Leave',
            value: leaveCount,
            icon: Icons.event_busy_outlined,
            color: const Color(0xFFD97706),
          ),
        ];

        final columns =
            constraints.maxWidth >= 1100
                ? 5
                : constraints.maxWidth >= 700
                    ? 3
                    : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            return _SummaryCard(item: cards[index]);
          },
        );
      },
    );
  }

  Widget _buildStudentList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Student Attendance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      isSaving ? null : _saveChanges,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                          size: 18,
                        ),
                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : 'Save Changes',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    size: 44,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No students found',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ...students.map(_buildStudentRow),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Student student) {
    final id = student.id;

    final status =
        id == null ? null : attendanceStatus[id];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final studentInfo = Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor:
                    const Color(0xFFEFF6FF),
                child: Text(
                  (student.name ?? 'S')
                      .trim()
                      .isNotEmpty
                      ? (student.name ?? 'S')
                          .trim()
                          .substring(0, 1)
                          .toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
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
                      student.name ?? 'Unnamed Student',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (student.id != null)
                          'Roll ${student.id}',
                        if (student.admissionNo != null)
                          student.admissionNo!,
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final buttons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusButton(
                label: 'P',
                tooltip: 'Present',
                selected: status == 'Present',
                color: const Color(0xFF059669),
                onTap: id == null
                    ? null
                    : () => _changeAttendance(
                          student,
                          'Present',
                        ),
              ),
              const SizedBox(width: 6),
              _StatusButton(
                label: 'A',
                tooltip: 'Absent',
                selected: status == 'Absent',
                color: const Color(0xFFDC2626),
                onTap: id == null
                    ? null
                    : () => _changeAttendance(
                          student,
                          'Absent',
                        ),
              ),
              const SizedBox(width: 6),
              _StatusButton(
                label: 'L',
                tooltip: 'Leave',
                selected: status == 'Leave',
                color: const Color(0xFFD97706),
                onTap: id == null
                    ? null
                    : () => _changeAttendance(
                          student,
                          'Leave',
                        ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                studentInfo,
                const SizedBox(height: 12),
                buttons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: studentInfo),
              buttons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              infoMessage!,
              style: const TextStyle(
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _CircularPercentage extends StatelessWidget {
  final double percentage;

  const _CircularPercentage({
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 7,
            valueColor:
                const AlwaysStoppedAnimation(
              Color(0xFFE2E8F0),
            ),
          ),
          CircularProgressIndicator(
            value: (percentage / 100)
                .clamp(0.0, 1.0),
            strokeWidth: 7,
            strokeCap: StrokeCap.round,
            valueColor:
                const AlwaysStoppedAnimation(
              Color(0xFF2563EB),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.color.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value.toString(),
                  style: const TextStyle(
                    fontSize: 19,
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
}

class _StatusButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  const _StatusButton({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 150),
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? color
                : color.withValues(alpha: 0.07),
            borderRadius:
                BorderRadius.circular(9),
            border: Border.all(
              color: color.withValues(
                alpha: selected ? 1 : 0.2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

