
import 'package:flutter/material.dart';

import 'package:smartkids_admin/features/exams/models/examination_model.dart';
import 'package:smartkids_admin/features/exams/services/examination_service.dart';

class ExamDetailsScreen extends StatefulWidget {
  final ExaminationModel exam;
  final ExaminationService service;
  final VoidCallback? onEdit;

  const ExamDetailsScreen({
    super.key,
    required this.exam,
    required this.service,
    this.onEdit,
  });

  @override
  State<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends State<ExamDetailsScreen> {
  List<ExamScheduleModel> schedules = [];

  bool isLoadingSchedules = true;
  String? errorMessage;

  ExaminationModel get exam => widget.exam;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    if (exam.id == null) {
      setState(() {
        isLoadingSchedules = false;
      });
      return;
    }

    try {
      final result =
          await widget.service.getSchedulesByExamination(exam.id!);

      if (!mounted) return;

      setState(() {
        schedules = result;
        isLoadingSchedules = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingSchedules = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      isLoadingSchedules = true;
      errorMessage = null;
    });

    await _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF0F172A),
          ),
        ),
        title: const Text(
          'Examination Details',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoadingSchedules ? null : _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(),
                const SizedBox(height: 20),
                _buildDetailHeaderCard(),
                const SizedBox(height: 20),
                _buildScheduleSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exam.name ?? 'Examination',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'View examination information and complete schedule',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey.shade500,
                ),
              ),
            ],
          ),
        ),
        if (widget.onEdit != null)
          ElevatedButton.icon(
            onPressed: widget.onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
            ),
            label: const Text('Edit Examination'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Examination Information',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _statusBadge(exam.status),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              _detailMetric(
                icon: Icons.tag_rounded,
                label: 'Exam ID',
                value: exam.id?.toString() ?? '-',
              ),
              _detailMetric(
                icon: Icons.calendar_today_outlined,
                label: 'Year',
                value: exam.year?.toString() ?? '-',
              ),
              _detailMetric(
                icon: Icons.school_outlined,
                label: 'Academic Year',
                value: exam.academicYearId?.toString() ?? '-',
              ),
              _detailMetric(
                icon: Icons.category_outlined,
                label: 'Exam Type',
                value: _prettyEnum(exam.examType),
              ),
            ],
          ),
          if (exam.description != null &&
              exam.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    exam.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return SizedBox(
      width: 210,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) {
    final normalized = status?.toUpperCase() ?? '';

    Color background;
    Color foreground;

    switch (normalized) {
      case 'PUBLISHED':
      case 'ACTIVE':
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF15803D);
        break;

      case 'COMPLETED':
        background = const Color(0xFFE0E7FF);
        foreground = const Color(0xFF4338CA);
        break;

      case 'CANCELLED':
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFFDC2626);
        break;

      case 'DRAFT':
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFFB45309);
        break;

      default:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _prettyEnum(status),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              22,
              20,
              22,
              18,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.schedule_outlined,
                    color: Color(0xFF16A34A),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Examination Schedule',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Subjects, dates, timings and marks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${schedules.length} Schedule${schedules.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
          _buildScheduleContent(),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    if (isLoadingSchedules) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load examination schedule',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (schedules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 12),
              Text(
                'No schedules found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              SizedBox(height: 5),
              Text(
                'No subject schedules have been added for this examination.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _scheduleTable();
  }

  Widget _scheduleTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 48,
        dataRowMinHeight: 58,
        dataRowMaxHeight: 70,
        horizontalMargin: 22,
        columnSpacing: 30,
        headingTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
        ),
        columns: const [
          DataColumn(label: Text('SUBJECT')),
          DataColumn(label: Text('CLASS')),
          DataColumn(label: Text('SECTION')),
          DataColumn(label: Text('DATE')),
          DataColumn(label: Text('TIME')),
          DataColumn(label: Text('MARKS')),
          DataColumn(label: Text('ROOM')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: schedules.map((schedule) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  schedule.subject?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              DataCell(
                Text(
                  schedule.classId?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              DataCell(
                Text(
                  schedule.sectionId?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatApiDate(schedule.examDate),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatTime(schedule.startTime),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              DataCell(
                Text(
                  schedule.maxMarks?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              DataCell(
                Text(
                  schedule.roomNumber?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              DataCell(
                _scheduleStatus(schedule.status),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _scheduleStatus(String? status) {
    final normalized = status?.toUpperCase() ?? '';

    Color background;
    Color foreground;

    switch (normalized) {
      case 'ACTIVE':
      case 'PUBLISHED':
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF15803D);
        break;

      case 'COMPLETED':
        background = const Color(0xFFE0E7FF);
        foreground = const Color(0xFF4338CA);
        break;

      case 'CANCELLED':
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFFDC2626);
        break;

      default:
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        _prettyEnum(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  String _prettyEnum(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value
        .trim()
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _formatApiDate(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    try {
      final date = DateTime.parse(text);

      const months = [
        '',
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
          '${months[date.month]} '
          '${date.year}';
    } catch (_) {
      return text;
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    try {
      final parts = text.split(':');

      if (parts.length < 2) {
        return text;
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return text;
    }
  }
}

