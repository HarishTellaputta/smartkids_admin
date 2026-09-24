import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/attendance/services/attendance_service.dart';
import 'package:smartkids_admin/features/attendance/models/attendance_response_model.dart';

import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/services/student_service.dart';
import '../attendance/attendance_details_screen.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/attendance/models/attendance_response_model.dart';
import 'package:smartkids_admin/features/attendance/models/attendance_update_model.dart';
import 'package:smartkids_admin/features/attendance/services/attendance_service.dart';

import 'package:smartkids_admin/features/teachers/models/class_model.dart';
import 'package:smartkids_admin/features/teachers/services/class_service.dart';

import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/services/student_service.dart';

class AttendanceDashboardScreen extends StatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState extends State<AttendanceDashboardScreen> {
  static const int _schoolId = 1;

  AttendanceService? _attendanceService;
  StudentService? _studentService;
  ClassService? _classService;

  DateTime _selectedDate = DateTime.now();

  List<SchoolClass> _classes = [];
  List<_ClassAttendanceSummary> _summaries = [];

  int? _selectedClassId;

  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      _attendanceService = AttendanceService(token);
      _studentService = StudentService(token);
      _classService = ClassService(token);

      await _loadClasses();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadClasses() async {
    if (_classService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final classes = await _classService!.getClassesBySchool(_schoolId);

      if (!mounted) return;

      setState(() {
        _classes = classes;

        if (_selectedClassId != null &&
            !classes.any((c) => c.id == _selectedClassId)) {
          _selectedClassId = null;
        }
      });

      await _loadAttendance();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadAttendance() async {
    if (_attendanceService == null || _studentService == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final classesToLoad = _selectedClassId == null
          ? _classes
          : _classes.where((c) => c.id == _selectedClassId).toList();

      final results = await Future.wait(
        classesToLoad
            .where((schoolClass) => schoolClass.id != null)
            .map(_loadClassSummary),
      );

      if (!mounted) return;

      setState(() {
        _summaries = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<_ClassAttendanceSummary> _loadClassSummary(
    SchoolClass schoolClass,
  ) async {
    final classId = schoolClass.id!;

    final results = await Future.wait([
      _studentService!.getStudentsByClassId(classId),
      _attendanceService!.getClassAttendance(
        classId: classId,
        date: _selectedDate,
      ),
    ]);

    final students = results[0] as List<Student>;
    final attendance = results[1] as List<AttendanceResponseModel>;

    int present = 0;
    int absent = 0;
    int leave = 0;

    for (final record in attendance) {
      switch (record.status.toUpperCase()) {
        case 'PRESENT':
          present++;
          break;

        case 'ABSENT':
          absent++;
          break;

        case 'LEAVE':
          leave++;
          break;
      }
    }

    final totalStudents = students.length;
    final marked = attendance.length;

    final percentage = totalStudents == 0
        ? 0.0
        : (present / totalStudents) * 100;

    return _ClassAttendanceSummary(
      schoolClass: schoolClass,
      totalStudents: totalStudents,
      marked: marked,
      present: present,
      absent: absent,
      leave: leave,
      attendancePercentage: percentage,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    await _loadAttendance();
  }

  Future<void> _onClassChanged(int? classId) async {
    setState(() {
      _selectedClassId = classId;
    });

    await _loadAttendance();
  }

  List<_ClassAttendanceSummary> get _filteredSummaries {
    if (_searchQuery.trim().isEmpty) {
      return _summaries;
    }

    final query = _searchQuery.toLowerCase().trim();

    return _summaries.where((summary) {
      final name = summary.schoolClass.name?.toLowerCase() ?? '';
      final code = summary.schoolClass.code?.toLowerCase() ?? '';
      final grade = summary.schoolClass.grade?.toLowerCase() ?? '';

      return name.contains(query) ||
          code.contains(query) ||
          grade.contains(query);
    }).toList();
  }

  int get _totalStudents {
    return _summaries.fold(0, (sum, item) => sum + item.totalStudents);
  }

  int get _totalMarked {
    return _summaries.fold(0, (sum, item) => sum + item.marked);
  }

  int get _totalPresent {
    return _summaries.fold(0, (sum, item) => sum + item.present);
  }

  int get _totalAbsent {
    return _summaries.fold(0, (sum, item) => sum + item.absent);
  }

  int get _totalLeave {
    return _summaries.fold(0, (sum, item) => sum + item.leave);
  }

  double get _overallPercentage {
    if (_totalStudents == 0) return 0;

    return (_totalPresent / _totalStudents) * 100;
  }

  String _formatDate(DateTime date) {
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
  }

  String _selectedClassName() {
    if (_selectedClassId == null) {
      return 'All Classes';
    }

    final selected = _classes.firstWhere(
      (item) => item.id == _selectedClassId,
      orElse: () => const SchoolClass(),
    );

    return selected.name ?? 'Selected Class';
  }

  void _openDetails(_ClassAttendanceSummary summary) {
    if (summary.schoolClass.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceDetailsScreen(
          schoolClass: summary.schoolClass,
          initialDate: _selectedDate,
        ),
      ),
    ).then((changed) {
      if (changed == true) {
        _loadAttendance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _loadAttendance,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(onRefresh: _loadAttendance, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _summaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _summaries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [const SizedBox(height: 100), _buildErrorCard()],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _buildPageHeader(),
        const SizedBox(height: 24),
        _buildFilters(),
        const SizedBox(height: 24),
        _buildSummaryCards(),
        const SizedBox(height: 32),
        _buildClassSection(),
      ],
    );
  }

  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Flex(
            direction: compact ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: compact
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.fact_check_outlined,
                  color: Color(0xFF2563EB),
                  size: 30,
                ),
              ),
              SizedBox(width: compact ? 0 : 18, height: compact ? 18 : 0),
              Expanded(
                flex: compact ? 0 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attendance Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Monitor daily attendance across all classes',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_selectedClassName()} • ${_formatDate(_selectedDate)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) _buildHeaderPercentage(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderPercentage() {
    return _CircularAttendance(
      percentage: _overallPercentage,
      size: 82,
      strokeWidth: 8,
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 850;

        if (compact) {
          return Column(
            children: [
              _buildDateFilter(),
              const SizedBox(height: 12),
              _buildClassFilter(),
              const SizedBox(height: 12),
              _buildSearch(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildDateFilter()),
            const SizedBox(width: 14),
            Expanded(child: _buildClassFilter()),
            const SizedBox(width: 14),
            Expanded(child: _buildSearch()),
          ],
        );
      },
    );
  }

  Widget _buildDateFilter() {
    return _FilterContainer(
      icon: Icons.calendar_today_outlined,
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(_selectedDate),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassFilter() {
    return _FilterContainer(
      icon: Icons.school_outlined,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedClassId,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
          ),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text(
                'All Classes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            ..._classes.map(
              (schoolClass) => DropdownMenuItem<int?>(
                value: schoolClass.id,
                child: Text(
                  schoolClass.name ?? 'Unnamed Class',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          onChanged: _isLoading ? null : _onClassChanged,
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return _FilterContainer(
      icon: Icons.search_rounded,
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search class...',
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;

        if (width >= 1200) {
          columns = 5;
        } else if (width >= 750) {
          columns = 3;
        } else {
          columns = 2;
        }

        final cards = [
          _SummaryCardData(
            title: 'Total Students',
            value: _totalStudents.toString(),
            icon: Icons.groups_outlined,
            iconBackground: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
          ),
          _SummaryCardData(
            title: 'Present',
            value: _totalPresent.toString(),
            icon: Icons.check_circle_outline,
            iconBackground: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
          ),
          _SummaryCardData(
            title: 'Absent',
            value: _totalAbsent.toString(),
            icon: Icons.cancel_outlined,
            iconBackground: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFDC2626),
          ),
          _SummaryCardData(
            title: 'Leave',
            value: _totalLeave.toString(),
            icon: Icons.event_busy_outlined,
            iconBackground: const Color(0xFFFFFBEB),
            iconColor: const Color(0xFFD97706),
          ),
          _SummaryCardData(
            title: 'Attendance',
            value: '${_overallPercentage.toStringAsFixed(1)}%',
            icon: Icons.percent_rounded,
            iconBackground: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
          ),
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: width < 500 ? 1.7 : 2.15,
          ),
          itemBuilder: (context, index) {
            return _SummaryCard(data: cards[index]);
          },
        );
      },
    );
  }

  Widget _buildClassSection() {
    final filtered = _filteredSummaries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Class-wise Attendance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${filtered.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          _buildEmptyCard()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 950;

              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: 1.75,
                  ),
                  itemBuilder: (context, index) {
                    return _ClassAttendanceCard(
                      summary: filtered[index],
                      onViewDetails: () => _openDetails(filtered[index]),
                    );
                  },
                );
              }

              return Column(
                children: filtered
                    .map(
                      (summary) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ClassAttendanceCard(
                          summary: summary,
                          onViewDetails: () => _openDetails(summary),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No classes found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _searchQuery.isEmpty
                ? 'No classes are available for this school.'
                : 'No class matches your search.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to load attendance',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _loadClasses,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CLASS SUMMARY
// ============================================================

class _ClassAttendanceSummary {
  final SchoolClass schoolClass;
  final int totalStudents;
  final int marked;
  final int present;
  final int absent;
  final int leave;
  final double attendancePercentage;

  const _ClassAttendanceSummary({
    required this.schoolClass,
    required this.totalStudents,
    required this.marked,
    required this.present,
    required this.absent,
    required this.leave,
    required this.attendancePercentage,
  });
}

// ============================================================
// CLASS CARD
// ============================================================

class _ClassAttendanceCard extends StatelessWidget {
  final _ClassAttendanceSummary summary;
  final VoidCallback onViewDetails;

  const _ClassAttendanceCard({
    required this.summary,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = summary.attendancePercentage;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.schoolClass.name ?? 'Unnamed Class',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (summary.schoolClass.code != null)
                          summary.schoolClass.code!,
                        if (summary.schoolClass.grade != null)
                          summary.schoolClass.grade!,
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _CircularAttendance(
                percentage: percentage,
                size: 74,
                strokeWidth: 7,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Students',
                  value: summary.totalStudents.toString(),
                  icon: Icons.groups_outlined,
                  iconColor: const Color(0xFF2563EB),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Marked',
                  value: summary.marked.toString(),
                  icon: Icons.fact_check_outlined,
                  iconColor: const Color(0xFF7C3AED),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Present',
                  value: summary.present.toString(),
                  icon: Icons.check_circle_outline,
                  iconColor: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatusCount(
                  label: 'Present',
                  value: summary.present,
                  color: const Color(0xFF059669),
                ),
              ),
              Expanded(
                child: _StatusCount(
                  label: 'Absent',
                  value: summary.absent,
                  color: const Color(0xFFDC2626),
                ),
              ),
              Expanded(
                child: _StatusCount(
                  label: 'Leave',
                  value: summary.leave,
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text(
                'View Attendance Details',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CIRCULAR ATTENDANCE
// ============================================================

class _CircularAttendance extends StatelessWidget {
  final double percentage;
  final double size;
  final double strokeWidth;

  const _CircularAttendance({
    required this.percentage,
    required this.size,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final value = (percentage / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE2E8F0)),
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: strokeWidth,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(_percentageColor(percentage)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: size >= 80 ? 17 : 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
              if (size >= 80)
                const Text(
                  'Attendance',
                  style: TextStyle(fontSize: 8, color: Color(0xFF64748B)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _percentageColor(double percentage) {
    if (percentage >= 90) {
      return const Color(0xFF059669);
    }

    if (percentage >= 75) {
      return const Color(0xFF2563EB);
    }

    if (percentage >= 50) {
      return const Color(0xFFD97706);
    }

    return const Color(0xFFDC2626);
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });
}

class _SummaryCard extends StatelessWidget {
  final _SummaryCardData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: data.iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.iconColor, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: const TextStyle(
                    fontSize: 21,
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

// ============================================================
// MINI STAT
// ============================================================

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATUS COUNT
// ============================================================

class _StatusCount extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatusCount({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FILTER CONTAINER
// ============================================================

class _FilterContainer extends StatelessWidget {
  final IconData icon;
  final Widget child;

  const _FilterContainer({required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF64748B)),
          const SizedBox(width: 11),
          Expanded(child: child),
        ],
      ),
    );
  }
}
