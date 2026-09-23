
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/models/student_model.dart';
import 'package:smartkids_admin/models/parent_model.dart';
import 'package:smartkids_admin/services/parent_service.dart';

import 'package:smartkids_admin/features/attendance/services/attendance_service.dart';
import 'package:smartkids_admin/features/attendance/models/attendance_response_model.dart';

import 'package:smartkids_admin/features/exams/models/examination_model.dart';
import 'package:smartkids_admin/features/exams/models/exam_result_model.dart';
import 'package:smartkids_admin/features/exams/services/examination_service.dart';

import 'package:smartkids_admin/features/fees/models/fee_model.dart';
import 'package:smartkids_admin/features/fees/services/fee_service.dart';

class StudentDetailsScreen extends StatefulWidget {
  final Student student;

  const StudentDetailsScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentDetailsScreen> createState() =>
      _StudentDetailsScreenState();
}

class _StudentDetailsScreenState
    extends State<StudentDetailsScreen> {
  // ============================================================
  // PARENT
  // ============================================================

  Parent? parent;
  bool isParentLoading = false;
  String? parentError;

  // ============================================================
  // FEES
  // ============================================================

  List<StudentFeeModel> pendingFees = [];
  bool isFeeLoading = false;
  String? feeError;

  // ============================================================
  // ATTENDANCE
  // ============================================================

  List<AttendanceResponseModel> attendanceRecords = [];

  bool isAttendanceLoading = false;
  String? attendanceError;

  // ============================================================
  // EXAMS
  // ============================================================

  List<ExamResultResponseModel> examResults = [];
  List<ExamScheduleModel> examSchedules = [];
  List<ExaminationModel> examinations = [];

  bool isExamLoading = false;
  String? examError;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadParentDetails();
    _loadPendingFees();
    _loadAttendance();
    _loadExamResults();
  }

  // ============================================================
  // PARENT
  // ============================================================

  Future<void> _loadParentDetails() async {
    final parentId = widget.student.parentId;

    if (parentId == null) {
      return;
    }

    setState(() {
      isParentLoading = true;
      parentError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final service = ParentService(token);

      final result = await service.getParent(parentId);

      if (!mounted) return;

      setState(() {
        parent = result;
        isParentLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isParentLoading = false;
        parentError = 'Unable to load parent details';
      });
    }
  }

  // ============================================================
  // FEES
  // ============================================================

  Future<void> _loadPendingFees() async {
    final studentId = widget.student.id;

    if (studentId == null) {
      return;
    }

    setState(() {
      isFeeLoading = true;
      feeError = null;
    });

    try {
      final service = FeeService();

      final result = await service.getStudentFees(
        studentId,
        pending: true,
      );

      if (!mounted) return;

      setState(() {
        pendingFees = result;
        isFeeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isFeeLoading = false;
        feeError = 'Unable to load fee details';
      });
    }
  }

  // ============================================================
  // ATTENDANCE
  //
  // We use the student attendance records API because the
  // Student model does not contain classId.
  //
  // Current year: January 1 -> today.
  // ============================================================

  Future<void> _loadAttendance() async {
    final studentId = widget.student.id;

    if (studentId == null) {
      return;
    }

    setState(() {
      isAttendanceLoading = true;
      attendanceError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final service = AttendanceService(token);

      final now = DateTime.now();

      final startDate = DateTime(now.year, 1, 1);

      final result = await service.getStudentAttendance(
        studentId: studentId,
        startDate: startDate,
        endDate: now,
      );

      if (!mounted) return;

      setState(() {
        attendanceRecords = result;
        isAttendanceLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isAttendanceLoading = false;
        attendanceError = 'Unable to load attendance';
      });
    }
  }

  // ============================================================
  // EXAMS
  // ============================================================

  Future<void> _loadExamResults() async {
    final studentId = widget.student.id;

    if (studentId == null) {
      return;
    }

    setState(() {
      isExamLoading = true;
      examError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final service = ExaminationService(token);

      // Actual student results.
      final results = await service.getResultsByStudent(
        studentId,
      );

      // Schedules are required to resolve subject.
      final schedules = await service.getSchedules();

      // Examinations are required to resolve exam name.
      final exams = await service.getExaminations();

      if (!mounted) return;

      setState(() {
        examResults = results;
        examSchedules = schedules;
        examinations = exams;
        isExamLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isExamLoading = false;
        examError = 'Unable to load exam results';
      });
    }
  }

  // ============================================================
  // ATTENDANCE CALCULATIONS
  // ============================================================

  int get _presentDays {
    return attendanceRecords.where((record) {
      final status = record.status.toUpperCase().trim();

      return status == 'PRESENT' ||
          status == 'P' ||
          status == 'PRESENTED';
    }).length;
  }

  int get _absentDays {
    return attendanceRecords.where((record) {
      final status = record.status.toUpperCase().trim();

      return status == 'ABSENT' || status == 'A';
    }).length;
  }

  int get _leaveDays {
    return attendanceRecords.where((record) {
      final status = record.status.toUpperCase().trim();

      return status == 'LEAVE' ||
          status == 'L' ||
          status == 'ON_LEAVE';
    }).length;
  }

  int get _attendanceTotalDays {
    return attendanceRecords.length;
  }

  double get _attendancePercentage {
    final total = _attendanceTotalDays;

    if (total == 0) {
      return 0;
    }

    return (_presentDays / total) * 100;
  }

  // ============================================================
  // EXAM HELPERS
  // ============================================================

  ExamScheduleModel? _findSchedule(int scheduleId) {
    for (final schedule in examSchedules) {
      if (schedule.id == scheduleId) {
        return schedule;
      }
    }

    return null;
  }

  ExaminationModel? _findExamination(int examinationId) {
    for (final examination in examinations) {
      if (examination.id == examinationId) {
        return examination;
      }
    }

    return null;
  }

  String _examName(ExamResultResponseModel result) {
    final schedule = _findSchedule(result.examScheduleId);

    if (schedule == null || schedule.examinationId == null) {
      return 'Exam';
    }

    final examination =
        _findExamination(schedule.examinationId!);

    return examination?.name.isNotEmpty == true
        ? examination!.name
        : 'Exam';
  }

  String _subjectName(ExamResultResponseModel result) {
    final schedule = _findSchedule(result.examScheduleId);

    if (schedule == null || schedule.subject.isEmpty) {
      return 'Subject';
    }

    return schedule.subject;
  }

  List<ExamResultResponseModel> get _latestExamResults {
    final sorted = [...examResults];

    sorted.sort((a, b) {
      final aDate = a.markedAt ?? a.createdAt;
      final bDate = b.markedAt ?? b.createdAt;

      if (aDate == null && bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return sorted.take(4).toList();
  }

  double get _overallExamPercentage {
    if (examResults.isEmpty) {
      return 0;
    }

    int totalMarks = 0;
    int totalMaxMarks = 0;

    for (final result in examResults) {
      totalMarks += result.marksObtained;
      totalMaxMarks += result.maxMarks;
    }

    if (totalMaxMarks == 0) {
      return 0;
    }

    return (totalMarks / totalMaxMarks) * 100;
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get _isActive =>
      widget.student.status?.toUpperCase() == 'ACTIVE';

  String get _statusText {
    final status = widget.student.status;

    if (status == null || status.trim().isEmpty) {
      return 'UNKNOWN';
    }

    return status.toUpperCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Student Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF172033),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF172033),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 760;

            return SingleChildScrollView(
              padding: EdgeInsets.all(
                isMobile ? 16 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1250,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(isMobile),

                      const SizedBox(height: 20),

                      if (isMobile)
                        _buildMobileLayout()
                      else
                        _buildDesktopGrid(),

                      const SizedBox(height: 24),

                      _buildFooterInfo(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 20 : 26,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF172554),
            Color(0xFF1E3A8A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF172554)
                .withOpacity(.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 64 : 76,
            height: isMobile ? 64 : 76,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(.25),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _initials(widget.student.name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 21 : 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.student.name ?? 'Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 21 : 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _headerChip(
                      Icons.badge_outlined,
                      widget.student.admissionNo ??
                          'No Admission No',
                    ),
                    _headerChip(
                      Icons.school_outlined,
                      widget.student.sectionName ??
                          'Section',
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!isMobile) _statusBadge(),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _isActive
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isActive
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            _statusText,
            style: TextStyle(
              color: _isActive
                  ? const Color(0xFF166534)
                  : const Color(0xFF991B1B),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPersonalInformation(),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildParentInformation(),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildAcademicInformation(),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildAttendanceCard(),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildExamResultsCard(),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildFeeInformation(),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildContactInformation(),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: _buildRecordInformation(),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildPersonalInformation(),
        const SizedBox(height: 16),

        _buildParentInformation(),
        const SizedBox(height: 16),

        _buildAcademicInformation(),
        const SizedBox(height: 16),

        _buildAttendanceCard(),
        const SizedBox(height: 16),

        _buildExamResultsCard(),
        const SizedBox(height: 16),

        _buildFeeInformation(),
        const SizedBox(height: 16),

        _buildContactInformation(),
        const SizedBox(height: 16),

        _buildRecordInformation(),
      ],
    );
  }

  // ============================================================
  // PERSONAL
  // ============================================================

  Widget _buildPersonalInformation() {
    return _sectionCard(
      icon: Icons.person_outline_rounded,
      iconBackground: const Color(0xFFEFF6FF),
      iconColor: const Color(0xFF2563EB),
      title: 'Personal Information',
      subtitle: 'Basic student details',
      child: Column(
        children: [
          _infoRow(
            Icons.cake_outlined,
            'Date of Birth',
            _formatDate(widget.student.dateOfBirth),
          ),
          _divider(),
          _infoRow(
            Icons.wc_outlined,
            'Gender',
            _displayValue(widget.student.gender),
          ),
          _divider(),
          _infoRow(
            Icons.bloodtype_outlined,
            'Blood Group',
            _displayValue(widget.student.bloodGroup),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACADEMIC
  // ============================================================

  Widget _buildAcademicInformation() {
    return _sectionCard(
      icon: Icons.school_outlined,
      iconBackground: const Color(0xFFF0FDF4),
      iconColor: const Color(0xFF16A34A),
      title: 'Academic Information',
      subtitle: 'Current academic details',
      child: Column(
        children: [
          _infoRow(
            Icons.class_outlined,
            'Class / Section',
            _displayValue(widget.student.sectionName),
          ),
          _divider(),
          _infoRow(
            Icons.calendar_month_outlined,
            'Academic Year',
            _displayValue(
              widget.student.academicYearName,
            ),
          ),
          _divider(),
          _infoRow(
            Icons.event_available_outlined,
            'Admission Date',
            _formatDate(widget.student.admissionDate),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PARENT
  // ============================================================

  Widget _buildParentInformation() {
    return _clickableSectionCard(
      icon: Icons.family_restroom_rounded,
      iconBackground: const Color(0xFFFDF4FF),
      iconColor: const Color(0xFFA21CAF),
      title: 'Parent Information',
      subtitle: parent == null
          ? 'Parent information'
          : 'Click to view complete details',
      onTap: parent == null
          ? null
          : _showParentDetails,
      child: _buildParentContent(),
    );
  }

  Widget _buildParentContent() {
    if (isParentLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (parentError != null) {
      return Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parentError!,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ),
          IconButton(
            onPressed: _loadParentDetails,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    if (parent == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Parent information not available',
          style: TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFFA21CAF),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    parent!.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    parent!.relationship ?? 'Parent',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (parent!.contactPhone != null)
          _contactMiniChip(
            Icons.phone_outlined,
            parent!.contactPhone!,
          ),
      ],
    );
  }

  // ============================================================
  // PARENT DETAILS DIALOG
  // ============================================================

  Future<void> _showParentDetails() async {
    if (parent == null) return;

    Parent selectedParent = parent!;

    // Refresh parent so linked students are latest.
    if (parent!.id != null) {
      try {
        final prefs =
            await SharedPreferences.getInstance();

        final token = prefs.getString('jwt_token');

        if (token != null && token.isNotEmpty) {
          final service = ParentService(token);

          selectedParent =
              await service.getParent(parent!.id!);
        }
      } catch (_) {
        // Existing parent object remains available.
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 680,
              maxHeight: 720,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _parentDetailsContent(
                selectedParent,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _parentDetailsContent(Parent parent) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    const Color(0xFFF3E8FF),
                child: Text(
                  parent.initials,
                  style: const TextStyle(
                    color: Color(0xFFA21CAF),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
                      parent.displayName,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      parent.relationship ?? 'Parent',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () =>
                    Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _dialogSectionTitle(
            'Contact Information',
          ),

          const SizedBox(height: 12),

          _detailTile(
            Icons.phone_outlined,
            'Phone',
            parent.contactPhone ??
                'Not provided',
          ),

          _detailTile(
            Icons.email_outlined,
            'Email',
            parent.contactEmail ??
                'Not provided',
          ),

          _detailTile(
            Icons.location_on_outlined,
            'Address',
            parent.address ??
                'Not provided',
          ),

          _detailTile(
            Icons.family_restroom_outlined,
            'Relationship',
            parent.relationship ??
                'Not provided',
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _infoCard(
                  title: 'Father',
                  value: parent.fatherName ??
                      'Not provided',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  title: 'Mother',
                  value: parent.motherName ??
                      'Not provided',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _dialogSectionTitle(
            'Linked Students',
          ),

          const SizedBox(height: 12),

          if (parent.students.isEmpty)
            _emptyLinkedStudents()
          else
            ...parent.students.map(
              _linkedStudentTile,
            ),
        ],
      ),
    );
  }

  Widget _linkedStudentTile(
    ParentStudent student,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE7EBF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Color(0xFF2563EB),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  student.name ??
                      'Unnamed Student',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 4),
                if (student.admissionNo != null)
                  Text(
                    'Admission: ${student.admissionNo}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                if (student.sectionName != null)
                  Text(
                    student.sectionName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyLinkedStudents() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE7EBF2),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.school_outlined,
            size: 34,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          const Text(
            'No students linked',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ATTENDANCE CARD
  // ============================================================

  Widget _buildAttendanceCard() {
    return _sectionCard(
      icon: Icons.bar_chart_rounded,
      iconBackground: const Color(0xFFECFDF5),
      iconColor: const Color(0xFF059669),
      title: 'Attendance',
      subtitle: 'Current year to date',
      child: _buildAttendanceContent(),
    );
  }

  Widget _buildAttendanceContent() {
    if (isAttendanceLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (attendanceError != null) {
      return Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attendanceError!,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ),
          IconButton(
            onPressed: _loadAttendance,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    final percentage =
        _attendancePercentage;

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 82,
              height: 82,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percentage / 100,
                    strokeWidth: 8,
                    backgroundColor:
                        const Color(0xFFE2E8F0),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      percentage >= 75
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF172033),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _metric(
                      'Present',
                      '$_presentDays',
                      const Color(0xFF16A34A),
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      'Absent',
                      '$_absentDays',
                      const Color(0xFFDC2626),
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      'Leave',
                      '$_leaveDays',
                      const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            const Icon(
              Icons.event_note_outlined,
              size: 15,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              'Total recorded days: $_attendanceTotalDays',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _actionButton(
          label: 'View Total Year Attendance',
          icon: Icons.calendar_view_month_rounded,
          onTap: _showAttendanceDetails,
        ),
      ],
    );
  }

  Future<void> _showAttendanceDetails() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Year Attendance',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 520,
            child: attendanceRecords.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No attendance records available.',
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _attendanceSummaryTile(
                        'Present',
                        _presentDays,
                        const Color(0xFF16A34A),
                      ),
                      _attendanceSummaryTile(
                        'Absent',
                        _absentDays,
                        const Color(0xFFDC2626),
                      ),
                      _attendanceSummaryTile(
                        'Leave',
                        _leaveDays,
                        const Color(0xFFD97706),
                      ),
                      _attendanceSummaryTile(
                        'Total Records',
                        _attendanceTotalDays,
                        const Color(0xFF2563EB),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _attendanceSummaryTile(
    String title,
    int value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXAM CARD
  // ============================================================

  Widget _buildExamResultsCard() {
    return _sectionCard(
      icon: Icons.assignment_outlined,
      iconBackground: const Color(0xFFFFF7ED),
      iconColor: const Color(0xFFEA580C),
      title: 'Exam Results',
      subtitle: 'Latest published academic results',
      child: _buildExamContent(),
    );
  }

  Widget _buildExamContent() {
    if (isExamLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (examError != null) {
      return Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              examError!,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ),
          IconButton(
            onPressed: _loadExamResults,
            icon: const Icon(Icons.refresh),
          ),
        ],
      );
    }

    if (examResults.isEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Text(
              'No exam results available.',
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _actionButton(
            label: 'View Exam Performance',
            icon: Icons.insights_rounded,
            onTap: _showExamDetails,
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Overall Performance',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _smallBadge(
              '${_overallExamPercentage.toStringAsFixed(1)}%',
              const Color(0xFFDCFCE7),
              const Color(0xFF166534),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ..._latestExamResults.map(
          _examResultRow,
        ),

        const SizedBox(height: 8),

        _actionButton(
          label: 'View Exam Performance',
          icon: Icons.insights_rounded,
          onTap: _showExamDetails,
        ),
      ],
    );
  }

  Widget _examResultRow(
    ExamResultResponseModel result,
  ) {
    final percentage =
        result.percentage ??
        (result.maxMarks > 0
            ? (result.marksObtained /
                    result.maxMarks) *
                100
            : 0);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              size: 17,
              color: Color(0xFFEA580C),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _subjectName(result),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _examName(result),
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '${result.marksObtained}/${result.maxMarks}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF172033),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEA580C),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExamDetails() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Exam Performance',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 650,
            child: examResults.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No exam results available.',
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: examResults
                          .map(
                            (result) =>
                                _examDetailTile(
                              result,
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _examDetailTile(
    ExamResultResponseModel result,
  ) {
    final percentage =
        result.percentage ??
        (result.maxMarks > 0
            ? (result.marksObtained /
                    result.maxMarks) *
                100
            : 0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE7EBF2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _subjectName(result),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _examName(result),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${result.marksObtained}/${result.maxMarks}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          _smallBadge(
            '${percentage.toStringAsFixed(1)}%',
            const Color(0xFFFFEDD5),
            const Color(0xFFC2410C),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEES
  // ============================================================

  Widget _buildFeeInformation() {
    double pendingAmount = 0;

    for (final fee in pendingFees) {
      pendingAmount +=
          fee.pendingAmount ?? 0;
    }

    return _sectionCard(
      icon: Icons.account_balance_wallet_outlined,
      iconBackground: const Color(0xFFFFF7ED),
      iconColor: const Color(0xFFD97706),
      title: 'Fee Information',
      subtitle: 'Current pending fees',
      child: Column(
        children: [
          if (isFeeLoading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 20,
              ),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (feeError != null)
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feeError!,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadPendingFees,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _amountMetric(
                    'Pending',
                    '₹${pendingAmount.toStringAsFixed(0)}',
                    const Color(0xFFDC2626),
                  ),
                ),
                Expanded(
                  child: _amountMetric(
                    'Pending Items',
                    pendingFees.length
                        .toString(),
                    const Color(0xFFD97706),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _actionButton(
              label: 'View Fee Details',
              icon: Icons.receipt_long_outlined,
              onTap: _showFeeDetails,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showFeeDetails() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Pending Fee Details',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 620,
            child: pendingFees.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No pending fees.',
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: pendingFees
                          .map(
                            (fee) => Container(
                              width:
                                  double.infinity,
                              margin:
                                  const EdgeInsets.only(
                                bottom: 9,
                              ),
                              padding:
                                  const EdgeInsets.all(
                                14,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFFF8FAFC,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  13,
                                ),
                                border: Border.all(
                                  color:
                                      const Color(
                                    0xFFE7EBF2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .receipt_long_outlined,
                                    color:
                                        Color(
                                      0xFFD97706,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Pending Fee',
                                      style:
                                          const TextStyle(
                                        fontWeight:
                                            FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${(fee.pendingAmount ?? 0).toStringAsFixed(0)}',
                                    style:
                                        const TextStyle(
                                      color:
                                          Color(
                                        0xFFDC2626,
                                      ),
                                      fontWeight:
                                          FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CONTACT
  // ============================================================

  Widget _buildContactInformation() {
    return _sectionCard(
      icon: Icons.contact_phone_outlined,
      iconBackground: const Color(0xFFF0F9FF),
      iconColor: const Color(0xFF0284C7),
      title: 'Contact Information',
      subtitle: 'Student contact details',
      child: Column(
        children: [
          _infoRow(
            Icons.phone_outlined,
            'Phone',
            _displayValue(widget.student.phone),
          ),
          _divider(),
          _infoRow(
            Icons.email_outlined,
            'Email',
            _displayValue(widget.student.email),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECORD
  // ============================================================

  Widget _buildRecordInformation() {
    return _sectionCard(
      icon: Icons.history_rounded,
      iconBackground: const Color(0xFFF1F5F9),
      iconColor: const Color(0xFF475569),
      title: 'Record Information',
      subtitle: 'System record details',
      child: Column(
        children: [
          _infoRow(
            Icons.add_circle_outline,
            'Created At',
            _formatDateTime(
              widget.student.createdAt,
            ),
          ),
          _divider(),
          _infoRow(
            Icons.update_rounded,
            'Updated At',
            _formatDateTime(
              widget.student.updatedAt,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _sectionCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE7EBF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
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
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // CLICKABLE CARD
  // ============================================================

  Widget _clickableSectionCard({
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE7EBF2),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(.035),
                blurRadius: 18,
                offset: const Offset(0, 7),
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
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius:
                          BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 21,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color:
                                Color(0xFF172033),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color:
                                Color(0xFF94A3B8),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (onTap != null)
                    const Icon(
                      Icons
                          .arrow_forward_ios_rounded,
                      size: 15,
                      color: Color(0xFFCBD5E1),
                    ),
                ],
              ),

              const SizedBox(height: 18),

              child,
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF94A3B8),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF172033),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // METRICS
  // ============================================================

  Widget _metric(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _amountMetric(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTION
  // ============================================================

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 16,
        ),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFF334155),
          side: const BorderSide(
            color: Color(0xFFE2E8F0),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SMALL BADGE
  // ============================================================

  Widget _smallBadge(
    String text,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // CONTACT CHIP
  // ============================================================

  Widget _contactMiniChip(
    IconData icon,
    String text,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DIVIDER
  // ============================================================

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: 12,
      ),
      child: Divider(
        height: 1,
        color: Color(0xFFF1F5F9),
      ),
    );
  }

  // ============================================================
  // PARENT DIALOG HELPERS
  // ============================================================

  Widget _dialogSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: Color(0xFF172033),
      ),
    );
  }

  Widget _detailTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
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
  // FOOTER
  // ============================================================

  Widget _buildFooterInfo() {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          size: 15,
          color: Color(0xFF94A3B8),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Student information is based on the latest available school records.',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String _displayValue(String? value) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Not available';
    }

    return value;
  }

  String _formatDate(dynamic date) {
    if (date == null) {
      return 'Not available';
    }

    try {
      final parsed = date is DateTime
          ? date
          : DateTime.parse(
              date.toString(),
            );

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return date.toString();
    }
  }

  String _formatDateTime(dynamic date) {
    if (date == null) {
      return 'Not available';
    }

    try {
      final parsed = date is DateTime
          ? date
          : DateTime.parse(
              date.toString(),
            );

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year} '
          '${parsed.hour.toString().padLeft(2, '0')}:'
          '${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date.toString();
    }
  }

  String _initials(String? name) {
    if (name == null ||
        name.trim().isEmpty) {
      return 'S';
    }

    final parts =
        name.trim().split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
        '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
