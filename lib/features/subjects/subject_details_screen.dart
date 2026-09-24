
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/features/teachers/models/subject_model.dart';
import 'package:smartkids_admin/features/teachers/models/teacher_assignment_model.dart';
import 'package:smartkids_admin/features/teachers/models/teacher_model.dart';
import 'package:smartkids_admin/features/teachers/services/subject_service.dart';
import 'package:smartkids_admin/features/teachers/services/teacher_assignment_service.dart';
import 'package:smartkids_admin/features/teachers/services/teacher_service.dart';

import '../teachers/services/class_service.dart';
import '../teachers/models/class_model.dart';
import '../../features/teachers/subject_performance_model.dart';
import '../../features/teachers/teacher_details_screen.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final SubjectModel subject;

  const SubjectDetailsScreen({
    super.key,
    required this.subject,
  });

  @override
  State<SubjectDetailsScreen> createState() =>
      _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState
    extends State<SubjectDetailsScreen> {

  SubjectService? _subjectService;
  TeacherAssignmentService? _assignmentService;
  TeacherService? _teacherService;
  ClassService? _classService;

  bool _isLoading = true;
  String? _errorMessage;

  List<SchoolClass> _classes = [];
  List<TeacherAssignment> _assignments = [];
  List<SubjectPerformanceModel> _performance = [];

  final Set<int> _expandedClasses = {};

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

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Authentication token not found. Please login again.';
        });

        return;
      }

      _subjectService = SubjectService(token);
      _assignmentService =
          TeacherAssignmentService(token);
      _teacherService = TeacherService(token);
      _classService = ClassService(token);

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    if (_subjectService == null ||
        _assignmentService == null ||
        _classService == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // --------------------------------------------------------
      // LOAD CLASSES
      // --------------------------------------------------------

      final classesFuture =
          _classService!.getClasses();

      // --------------------------------------------------------
      // LOAD PERFORMANCE
      // --------------------------------------------------------

      final performanceFuture =
          _subjectService!.getSubjectPerformance(
        widget.subject.id,
      );

      final results = await Future.wait([
        classesFuture,
        performanceFuture,
      ]);

      final classes =
          results[0] as List<SchoolClass>;

      final performance =
          results[1] as List<SubjectPerformanceModel>;

      // --------------------------------------------------------
      // FIND ASSIGNMENTS FOR THIS SUBJECT
      // --------------------------------------------------------

      final List<TeacherAssignment> assignments = [];

      /*
       * TeacherAssignmentService currently exposes
       * assignments by class, not directly by subject.
       *
       * Therefore we load assignments for each class
       * and filter by this subject ID.
       */

      final assignmentResults =
          await Future.wait(
        classes.map(
          (schoolClass) async {
            if (schoolClass.id == null) {
              return <TeacherAssignment>[];
            }

            try {
              final classAssignments =
                  await _assignmentService!
                      .getAssignmentsByClass(
                schoolClass.id!,
              );

              return classAssignments
                  .where(
                    (assignment) =>
                        assignment.subjectId ==
                        widget.subject.id,
                  )
                  .toList();
            } catch (_) {
              return <TeacherAssignment>[];
            }
          },
        ),
      );

      for (final list in assignmentResults) {
        assignments.addAll(list);
      }

      if (!mounted) return;

      setState(() {
        _classes = classes;
        _assignments = assignments;
        _performance = performance;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // OPEN TEACHER DETAILS
  // ============================================================

  Future<void> _openTeacherDetails(
    int teacherId,
  ) async {
    if (_teacherService == null ||
        _assignmentService == null ||
        _classService == null) {
      return;
    }

    try {
      _showLoadingDialog();

      final results = await Future.wait([
        _teacherService!.getTeacherById(teacherId),
        _classService!.getClasses(),
      ]);

      if (!mounted) return;

      Navigator.pop(context);

      final teacher =
          results[0] as Teacher;

      final classes =
          results[1] as List<SchoolClass>;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeacherDetailsScreen(
            teacher: teacher,
            assignmentService:
                _assignmentService!,
            classes: classes,
            onAssignClass: () async {
              return false;
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open teacher details: $e',
          ),
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<TeacherAssignment> _teachersForClass(
    int classId,
  ) {
    return _assignments
        .where(
          (assignment) =>
              assignment.classId == classId &&
              assignment.subjectId ==
                  widget.subject.id,
        )
        .toList();
  }

  List<SubjectPerformanceModel> _performanceForClass(
    int classId,
  ) {
    return _performance
        .where(
          (item) => item.classId == classId,
        )
        .toList();
  }

  SubjectPerformanceModel? _latestPerformance(
    int classId,
  ) {
    final records =
        _performanceForClass(classId);

    if (records.isEmpty) {
      return null;
    }

    final sorted = [...records];

    sorted.sort(
      (a, b) {
        final aDate =
            a.examDate ?? DateTime(1900);

        final bDate =
            b.examDate ?? DateTime(1900);

        return bDate.compareTo(aDate);
      },
    );

    return sorted.first;
  }

  List<SubjectPerformanceModel> _previousPerformance(
    int classId,
  ) {
    final records =
        _performanceForClass(classId);

    if (records.length <= 1) {
      return [];
    }

    final sorted = [...records];

    sorted.sort(
      (a, b) {
        final aDate =
            a.examDate ?? DateTime(1900);

        final bDate =
            b.examDate ?? DateTime(1900);

        return bDate.compareTo(aDate);
      },
    );

    return sorted.skip(1).toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _performanceColor(double percentage) {
    if (percentage >= 75) {
      return Colors.green;
    }

    if (percentage >= 50) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.subject.name,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load subject details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile =
              constraints.maxWidth < 700;

          return SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(
              isMobile ? 16 : 24,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildSubjectHeader(isMobile),
                const SizedBox(height: 20),
                _buildSummaryCards(isMobile),
                const SizedBox(height: 28),
                _buildAssignedClassesSection(
                  isMobile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SUBJECT HEADER
  // ============================================================

  Widget _buildSubjectHeader(
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 20 : 28,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.indigo.shade600,
          ],
        ),
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _subjectIcon(),
                const SizedBox(height: 16),
                _subjectHeaderText(),
              ],
            )
          : Row(
              children: [
                _subjectIcon(),
                const SizedBox(width: 20),
                Expanded(
                  child: _subjectHeaderText(),
                ),
              ],
            ),
    );
  }

  Widget _subjectIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        color: Colors.white,
        size: 38,
      ),
    );
  }

  Widget _subjectHeaderText() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          widget.subject.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Subject Code: ${widget.subject.code}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.88),
            fontSize: 15,
          ),
        ),
        if (widget.subject.description != null &&
            widget.subject.description!
                .trim()
                .isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            widget.subject.description!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards(
    bool isMobile,
  ) {
    final classIds =
        _assignments
            .map((e) => e.classId)
            .whereType<int>()
            .toSet();

    final teacherIds =
        _assignments
            .map((e) => e.teacherId)
            .whereType<int>()
            .toSet();

    final examCount =
        _performance.length;

    final cards = [
      _summaryCard(
        icon: Icons.school_outlined,
        title: 'Assigned Classes',
        value: '${classIds.length}',
      ),
      _summaryCard(
        icon: Icons.person_outline,
        title: 'Teachers',
        value: '${teacherIds.length}',
      ),
      _summaryCard(
        icon: Icons.assignment_outlined,
        title: 'Examinations',
        value: '$examCount',
      ),
      _summaryCard(
        icon: Icons.analytics_outlined,
        title: 'Performance Records',
        value: '${_performance.length}',
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding:
                    const EdgeInsets.only(bottom: 12),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return Row(
      children: cards
          .map(
            (card) => Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(right: 12),
                child: card,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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
  // ASSIGNED CLASSES
  // ============================================================

  Widget _buildAssignedClassesSection(
    bool isMobile,
  ) {
    final assignedClassIds =
        _assignments
            .map((e) => e.classId)
            .whereType<int>()
            .toSet();

    final performanceClassIds =
        _performance
            .map((e) => e.classId)
            .toSet();

    final allClassIds = {
      ...assignedClassIds,
      ...performanceClassIds,
    };

    if (allClassIds.isEmpty) {
      return _emptyCard(
        icon: Icons.school_outlined,
        title: 'No class assignments found',
        message:
            'This subject has not been assigned to any class yet.',
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Assigned Classes & Performance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Classes, assigned teachers and examination performance',
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        ...allClassIds.map(
          (classId) {
            final schoolClass =
                _findClass(classId);

            final className =
                schoolClass?.name ??
                    _performanceForClass(classId)
                        .firstOrNull
                        ?.className ??
                    'Class $classId';

            return Padding(
              padding:
                  const EdgeInsets.only(bottom: 16),
              child: _buildClassCard(
                classId: classId,
                className: className,
                isMobile: isMobile,
              ),
            );
          },
        ),
      ],
    );
  }

  SchoolClass? _findClass(
    int classId,
  ) {
    for (final schoolClass in _classes) {
      if (schoolClass.id == classId) {
        return schoolClass;
      }
    }

    return null;
  }

  // ============================================================
  // CLASS CARD
  // ============================================================

  Widget _buildClassCard({
    required int classId,
    required String className,
    required bool isMobile,
  }) {
    final teachers =
        _teachersForClass(classId);

    final latest =
        _latestPerformance(classId);

    final previous =
        _previousPerformance(classId);

    final isExpanded =
        _expandedClasses.contains(classId);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? 16 : 20,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // CLASS HEADER
            // --------------------------------------------------

            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.class_outlined,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Subject: ${widget.subject.name}',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (latest != null)
                  _percentageBadge(
                    latest.performancePercentage,
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // TEACHERS
            // --------------------------------------------------

            _sectionTitle(
              icon: Icons.people_outline,
              title: 'Assigned Teacher',
            ),

            const SizedBox(height: 10),

            if (teachers.isEmpty)
              _noTeacherAssigned()
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: teachers
                    .map(
                      (assignment) =>
                          _teacherChip(
                        assignment,
                      ),
                    )
                    .toList(),
              ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // LATEST PERFORMANCE
            // --------------------------------------------------

            _sectionTitle(
              icon: Icons.analytics_outlined,
              title: 'Latest Examination Performance',
            ),

            const SizedBox(height: 12),

            if (latest == null)
              _noPerformance()
            else
              _buildLatestPerformance(
                latest,
                isMobile,
              ),

            // --------------------------------------------------
            // MORE
            // --------------------------------------------------

            if (previous.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 4),

              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedClasses
                          .remove(classId);
                    } else {
                      _expandedClasses
                          .add(classId);
                    }
                  });
                },
                borderRadius:
                    BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons
                                .keyboard_arrow_up
                            : Icons
                                .keyboard_arrow_down,
                        color:
                            Colors.blue.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExpanded
                            ? 'Hide Previous Performance'
                            : 'More • Previous Performance',
                        style: TextStyle(
                          color:
                              Colors.blue.shade700,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.blue.shade50,
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Text(
                          '${previous.length}',
                          style: TextStyle(
                            color:
                                Colors.blue.shade700,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isExpanded)
                _buildPreviousPerformance(
                  previous,
                  isMobile,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TEACHER CHIP
  // ============================================================

  Widget _teacherChip(
    TeacherAssignment assignment,
  ) {
    final teacherId =
        assignment.teacherId;

    final teacherName =
        assignment.teacherName ??
            'Teacher';

    return InkWell(
      onTap: teacherId == null
          ? null
          : () => _openTeacherDetails(
                teacherId,
              ),
      borderRadius:
          BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: Colors.blue.shade100,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 18,
                color:
                    Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              teacherName,
              style: TextStyle(
                color:
                    Colors.blue.shade800,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
            if (teacherId != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color:
                    Colors.blue.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LATEST PERFORMANCE
  // ============================================================

  Widget _buildLatestPerformance(
    SubjectPerformanceModel performance,
    bool isMobile,
  ) {
    final percentage =
        performance.performancePercentage;

    final color =
        _performanceColor(percentage);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      performance.examName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${performance.sectionName} • '
                      '${_formatDate(performance.examDate)}',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _percentageBadge(
                percentage,
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (isMobile)
            Column(
              children: [
                _performanceStat(
                  'Average',
                  '${performance.averageMarks}'
                      ' / ${performance.maxMarks}',
                  Icons.bar_chart,
                ),
                const SizedBox(height: 10),
                _performanceStat(
                  'Students',
                  '${performance.studentCount}',
                  Icons.people_outline,
                ),
                const SizedBox(height: 10),
                _performanceStat(
                  'Assessed',
                  '${performance.assessedCount}'
                      ' / ${performance.studentCount}',
                  Icons.fact_check_outlined,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _performanceStat(
                    'Average',
                    '${performance.averageMarks}'
                        ' / ${performance.maxMarks}',
                    Icons.bar_chart,
                  ),
                ),
                Expanded(
                  child: _performanceStat(
                    'Students',
                    '${performance.studentCount}',
                    Icons.people_outline,
                  ),
                ),
                Expanded(
                  child: _performanceStat(
                    'Assessed',
                    '${performance.assessedCount}'
                        ' / ${performance.studentCount}',
                    Icons.fact_check_outlined,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius:
                BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
                  (percentage / 100)
                      .clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor:
                  Colors.grey.shade200,
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PREVIOUS PERFORMANCE
  // ============================================================

  Widget _buildPreviousPerformance(
    List<SubjectPerformanceModel> records,
    bool isMobile,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 12),
      child: Column(
        children: records.map(
          (record) {
            final color =
                _performanceColor(
              record.performancePercentage,
            );

            return Container(
              margin:
                  const EdgeInsets.only(
                bottom: 10,
              ),
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color:
                      Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration:
                        BoxDecoration(
                      color:
                          color.withOpacity(
                        0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.examName,
                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${record.sectionName} • '
                          '${_formatDate(record.examDate)}',
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.performancePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${record.averageMarks} / '
                        '${record.maxMarks}',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // SMALL COMPONENTS
  // ============================================================

  Widget _percentageBadge(
    double percentage,
  ) {
    final color =
        _performanceColor(percentage);

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: Colors.blue.shade700,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _performanceStat(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noTeacherAssigned() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color:
                Colors.orange.shade700,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No teacher has been assigned to this subject for this class.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _noPerformance() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No examination performance is available yet.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding:
            const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                icon,
                size: 60,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EXTENSION
// ============================================================

extension FirstOrNullExtension<T>
    on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }

    return first;
  }
}

