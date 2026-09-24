import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../teachers/models/teacher_model.dart';
import '../teachers/services/teacher_assignment_service.dart';
import '../teachers/models/class_model.dart';
import '../teachers/models/teacher_assignment_model.dart';

import 'package:smartkids_admin/features/teachers/models/teacher_performance_model.dart';
import '../exams/services/examination_service.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final Teacher teacher;
  final TeacherAssignmentService assignmentService;
  final List<SchoolClass> classes;
  final Future<bool> Function() onAssignClass;

  const TeacherDetailsScreen({
    super.key,
    required this.teacher,
    required this.assignmentService,
    required this.classes,
    required this.onAssignClass,
  });

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  List<dynamic> _assignments = [];
  List<TeacherPerformance> _performance = [];

  bool _isLoading = true;
  bool _isPerformanceLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadAssignments(), _loadPerformance()]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPerformance() async {
    try {
      if (widget.teacher.id == null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found.');
      }

      final examinationService = ExaminationService(token);

      final performance = await examinationService.getTeacherPerformance(
        widget.teacher.id!,
      );

      if (!mounted) return;

      setState(() {
        _performance = performance;
        _isPerformanceLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading teacher performance: $e');

      if (mounted) {
        setState(() {
          _isPerformanceLoading = false;
        });
      }
    }
  }

  Future<void> _loadAssignments() async {
    try {
      final assignments = await widget.assignmentService
          .getAssignmentsByTeacher(widget.teacher.id!);

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
      });
    } catch (e) {
      debugPrint('Error loading teacher assignments: $e');
    }
  }

  
  Future<void> _deleteAssignment(dynamic assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Assignment'),
          content: Text(
            'Remove ${assignment.subjectName} from '
            '${assignment.className}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isDeleting = true;
      });

      await widget.assignmentService.deleteAssignment(assignment.id!);

      await _loadAssignments();
      await _loadPerformance();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assignment removed successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove assignment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  int get _classCount {
    return _performance.map((e) => e.classId).toSet().length;
  }

  int get _studentCount {
    final classes = <int, int>{};

    for (final item in _performance) {
      classes[item.classId] = item.studentCount;
    }

    return classes.values.fold(0, (a, b) => a + b);
  }

  double get _overallPerformance {
    if (_performance.isEmpty) return 0;

    double totalWeightedMarks = 0;
    double totalMaxMarks = 0;

    for (final item in _performance) {
      if (item.maxMarks > 0) {
        totalWeightedMarks += item.averageMarks * item.studentCount;

        totalMaxMarks += item.maxMarks * item.studentCount;
      }
    }

    if (totalMaxMarks == 0) return 0;

    return (totalWeightedMarks / totalMaxMarks) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xfff6f8fc),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff172033),
        title: const Text(
          'Teacher Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1250),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTeacherHeader(theme),

                        const SizedBox(height: 24),

                        _buildPerformanceSummary(),

                        const SizedBox(height: 28),

                        _buildSectionTitle(
                          'Class-wise Performance',
                          'Latest exam performance by assigned class & subject',
                        ),

                        const SizedBox(height: 14),

                        _buildPerformanceSection(),

                        const SizedBox(height: 30),

                        _buildSectionTitle(
                          'Assigned Classes & Subjects',
                          'Classes and subjects assigned to this teacher',
                        ),

                        const SizedBox(height: 14),

                        _buildAssignmentsSection(),

                        const SizedBox(height: 30),

                        _buildProfessionalInformation(),

                        const SizedBox(height: 24),

                        _buildContactInformation(),

                        const SizedBox(height: 24),

                        _buildPersonalInformation(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTeacherHeader(ThemeData theme) {
    final teacherName = widget.teacher.name ?? 'Teacher';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe7ebf2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xffeaf2ff),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Text(
                _initials(teacherName),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff246bfd),
                ),
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teacherName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff172033),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.teacher.email ?? 'No email available',
                  style: const TextStyle(
                    color: Color(0xff687386),
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    _statusBadge(widget.teacher.status ?? 'ACTIVE'),

                    const SizedBox(width: 10),

                    Text(
                      'Teacher ID: ${widget.teacher.id ?? '-'}',
                      style: const TextStyle(
                        color: Color(0xff7a8495),
                        fontSize: 13,
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

  Widget _buildPerformanceSummary() {
    final percentage = _overallPerformance;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final cards = [
          _summaryCard(
            title: 'Classes',
            value: '$_classCount',
            icon: Icons.class_outlined,
          ),
          _summaryCard(
            title: 'Students',
            value: '$_studentCount',
            icon: Icons.groups_outlined,
          ),
          _performanceCircleCard(percentage),
        ];

        if (isMobile) {
          return Column(
            children: [
              for (final card in cards) ...[card, const SizedBox(height: 12)],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xffeef4ff),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xff246bfd), size: 25),
          ),

          const SizedBox(width: 15),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff7b8494),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 27,
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

  Widget _performanceCircleCard(double percentage) {
    return Container(
      height: 125,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            height: 82,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 8,
                    backgroundColor: const Color(0xffedf0f5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xff246bfd),
                    ),
                  ),
                ),
                Text(
                  '${percentage.round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xff172033),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Performance',
                style: TextStyle(
                  color: Color(0xff7b8494),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Latest Exams',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xff172033),
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    if (_isPerformanceLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_performance.isEmpty) {
      return _emptyCard(
        icon: Icons.analytics_outlined,
        title: 'No performance data available',
        message:
            'Performance will appear here once exams and marks are available.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        if (isMobile) {
          return Column(
            children: _performance
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildPerformanceCard(item),
                  ),
                )
                .toList(),
          );
        }

        final rows = <Widget>[];

        for (int i = 0; i < _performance.length; i += 2) {
          final first = _performance[i];

          final second = i + 1 < _performance.length
              ? _performance[i + 1]
              : null;

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPerformanceCard(first)),

                  const SizedBox(width: 16),

                  Expanded(
                    child: second != null
                        ? _buildPerformanceCard(second)
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }

  Widget _buildPerformanceCard(TeacherPerformance item) {
    final percentage = item.performancePercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.className,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff172033),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item.subjectName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff246bfd),
                      ),
                    ),
                  ],
                ),
              ),

              _percentageCircle(percentage),
            ],
          ),

          const SizedBox(height: 18),

          Container(height: 1, color: const Color(0xffedf0f4)),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _performanceStat(
                  icon: Icons.groups_outlined,
                  label: 'Students',
                  value: '${item.studentCount}',
                ),
              ),

              Expanded(
                child: _performanceStat(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'Assessed',
                  value: '${item.assessedCount}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _performanceStat(
                  icon: Icons.score_outlined,
                  label: 'Avg Marks',
                  value:
                      '${_formatNumber(item.averageMarks)} / ${_formatNumber(item.maxMarks.toDouble())}',
                ),
              ),

              Expanded(
                child: _performanceStat(
                  icon: Icons.event_outlined,
                  label: 'Exam Date',
                  value: item.examDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xfff7f9fc),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 17,
                  color: Color(0xff667085),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Latest Exam: ${item.latestExamName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff344054),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _percentageCircle(double percentage) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xffeef4ff),
        border: Border.all(color: const Color(0xffd8e5ff), width: 2),
      ),
      child: Center(
        child: Text(
          '${percentage.round()}%',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xff246bfd),
          ),
        ),
      ),
    );
  }

  Widget _performanceStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff7a8495)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xff8a93a3)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff344054),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsSection() {
    if (_assignments.isEmpty) {
      return _emptyCard(
        icon: Icons.class_outlined,
        title: 'No classes assigned',
        message: 'Assign classes and subjects to this teacher.',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < _assignments.length; i++) ...[
            _assignmentRow(_assignments[i]),

            if (i != _assignments.length - 1)
              const Divider(height: 24, color: Color(0xffedf0f4)),
          ],
        ],
      ),
    );
  }

  Widget _assignmentRow(dynamic assignment) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xffeef4ff),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.class_outlined, color: Color(0xff246bfd)),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.className ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xff172033),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                assignment.subjectName ?? '-',
                style: const TextStyle(fontSize: 13, color: Color(0xff737d8f)),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Remove',
          onPressed: _isDeleting ? null : () => _deleteAssignment(assignment),
          icon: const Icon(Icons.delete_outline, color: Color(0xffd92d20)),
        ),
      ],
    );
  }

  Widget _buildProfessionalInformation() {
    return _informationSection(
      title: 'Professional Information',
      icon: Icons.work_outline,
      children: [
        _infoItem('Employee ID', '${widget.teacher.employeeId ?? '-'}'),
        _infoItem('Qualification', widget.teacher.qualification ?? '-'),
        _infoItem('Joining Date', widget.teacher.joiningDate ?? '-'),
      ],
    );
  }

  Widget _buildContactInformation() {
    return _informationSection(
      title: 'Contact Information',
      icon: Icons.contact_phone_outlined,
      children: [
        _infoItem('Email', widget.teacher.email ?? '-'),
        _infoItem('Phone', widget.teacher.phone ?? '-'),
        _infoItem('Address', widget.teacher.address ?? '-'),
      ],
    );
  }

  Widget _buildPersonalInformation() {
    return _informationSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        _infoItem('Date of Birth', widget.teacher.dateOfBirth ?? '-'),
        _infoItem('Gender', widget.teacher.gender ?? '-'),
      ],
    );
  }

  Widget _informationSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: const Color(0xff246bfd)),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff172033),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          LayoutBuilder(
            builder: (context, constraints) {
              final mobile = constraints.maxWidth < 600;

              if (mobile) {
                return Column(
                  children: children
                      .map(
                        (child) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: child,
                        ),
                      )
                      .toList(),
                );
              }

              return Wrap(spacing: 30, runSpacing: 20, children: children);
            },
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff8a93a3),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff344054),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xff172033),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xff7a8495)),
        ),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xff98a2b3)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xff344054),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xff7a8495), fontSize: 13),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffe7ebf2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.035),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xffecfdf3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xff027a48),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.isEmpty) return 'T';

    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}
