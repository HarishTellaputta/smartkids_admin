import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/examination_report_model.dart';
import '../services/report_service.dart';

class ExaminationReportScreen extends StatefulWidget {
  const ExaminationReportScreen({super.key});

  @override
  State<ExaminationReportScreen> createState() =>
      _ExaminationReportScreenState();
}

class _ExaminationReportScreenState extends State<ExaminationReportScreen> {
  late final ReportService _service;

  List<ExaminationReportModel> _items = [];

  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  bool _loading = false;
  String? _error;
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    _service = ReportService(ApiClient());
    _load();
  }

  String _date(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _displayDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')} '
        '${_monthName(d.month)} '
        '${d.year}';
  }

  String _monthName(int month) {
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

    return months[month - 1];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getExaminationReport(
        from: _date(_from),
        to: _date(_to),
      );

      if (mounted) {
        setState(() {
          _items = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _pick(bool isFrom) async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: isFrom ? _from : _to,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (result == null) return;

    if (isFrom && result.isAfter(_to)) {
      _showMessage('From date cannot be after To date.', isError: true);
      return;
    }

    if (!isFrom && result.isBefore(_from)) {
      _showMessage('To date cannot be before From date.', isError: true);
      return;
    }

    setState(() {
      if (isFrom) {
        _from = result;
      } else {
        _to = result;
      }
    });

    _load();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }

  int get _totalExams => _filteredItems.length;

  int get _scheduledExams {
    return _items.where((item) {
      final status = item.status?.toLowerCase();
      return status == 'scheduled' || status == 'upcoming';
    }).length;
  }

  List<ExaminationReportModel> get _filteredItems {
    if (_selectedClass == null || _selectedClass!.isEmpty) {
      return _items;
    }

    return _items.where((item) {
      return item.className?.toLowerCase() == _selectedClass!.toLowerCase();
    }).toList();
  }

  List<String> get _classes {
    final classes = _items
        .map((item) => item.className)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();

    classes.sort();
    return classes;
  }

  int get _completedExams {
    return _items.where((item) {
      final status = item.status?.toLowerCase();
      return status == 'completed' || status == 'complete';
    }).length;
  }

  int get _cancelledExams {
    return _items.where((item) {
      final status = item.status?.toLowerCase();
      return status == 'cancelled' || status == 'canceled';
    }).length;
  }

  Widget _classSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedClass,
          hint: const Text(
            'All Classes',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All Classes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            ..._classes.map(
              (className) => DropdownMenuItem<String?>(
                value: className,
                child: Text(
                  className,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedClass = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDateFilters(bool mobile) {
    final classFilter = _classSelector();

    final widgets = [
      classFilter,
      _dateSelector(label: 'From Date', value: _from, onTap: () => _pick(true)),
      _dateSelector(label: 'To Date', value: _to, onTap: () => _pick(false)),
    ];

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widgets[0],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: widgets[1]),
              const SizedBox(width: 10),
              Expanded(child: widgets[2]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        widgets[0],
        const SizedBox(width: 10),
        widgets[1],
        const SizedBox(width: 10),
        widgets[2],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        surfaceTintColor: Colors.white,
        titleSpacing: 24,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                color: Color(0xFF4F46E5),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examination Report',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Monitor and review examination schedules',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: _loading ? null : _load,
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF3F4F6),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 21),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isMobile),
                const SizedBox(height: 20),
                _buildSummaryCards(isMobile),
                const SizedBox(height: 20),
                _buildReportTable(isMobile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: _cardDecoration(),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterTitle(),
                const SizedBox(height: 18),
                _buildDateFilters(true),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildFilterTitle()),
                _buildDateFilters(false),
              ],
            ),
    );
  }

  Widget _buildFilterTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Filters',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Select a date range to view examination records.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _dateSelector({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 17,
              color: Color(0xFF4F46E5),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displayDate(value),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isMobile) {
    final cards = [
      _summaryCard(
        title: 'Total Examinations',
        value: _totalExams.toString(),
        icon: Icons.assignment_rounded,
        iconBackground: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4F46E5),
      ),
      _summaryCard(
        title: 'Scheduled',
        value: _scheduledExams.toString(),
        icon: Icons.event_available_rounded,
        iconBackground: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
      ),
      _summaryCard(
        title: 'Completed',
        value: _completedExams.toString(),
        icon: Icons.task_alt_rounded,
        iconBackground: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _summaryCard(
        title: 'Cancelled',
        value: _cancelledExams.toString(),
        icon: Icons.event_busy_rounded,
        iconBackground: const Color(0xFFFEF2F2),
        iconColor: const Color(0xFFDC2626),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable(bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Examination Records',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Detailed examination schedule and status',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _recordCount(),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _content(isMobile),
        ],
      ),
    );
  }

  Widget _recordCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_filteredItems.length} Records',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _content(bool isMobile) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 90),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFF4F46E5),
          ),
        ),
      );
    }

    if (_error != null) {
      return _errorState();
    }

    if (_items.isEmpty) {
      return _emptyState();
    }

    return isMobile ? _mobileRecords() : _desktopTable();
  }

  Widget _desktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 52,
        dataRowMinHeight: 62,
        dataRowMaxHeight: 68,
        columnSpacing: 30,
        horizontalMargin: 20,
        dividerThickness: 0.6,
        headingTextStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6B7280),
        ),
        columns: const [
          DataColumn(label: Text('EXAMINATION')),
          DataColumn(label: Text('CLASS')),
          DataColumn(label: Text('SUBJECT')),
          DataColumn(label: Text('EXAM DATE')),
          DataColumn(label: Text('TIME')),
          DataColumn(label: Text('MAX MARKS')),
          DataColumn(label: Text('STATUS')),
        ],
        rows: _filteredItems.map((item) {
          return DataRow(
            cells: [
              DataCell(_examName(item.examinationName)),
              DataCell(_normalText(item.className)),
              DataCell(_normalText(item.subjectName)),
              DataCell(_examDate(item.examDate)),
              DataCell(_normalText(item.startTime)),
              DataCell(_marks(item.maxMarks)),
              DataCell(_statusChip(item.status)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _mobileRecords() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(14),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _examName(item.examinationName)),
                  _statusChip(item.status),
                ],
              ),
              const SizedBox(height: 14),
              _mobileInfoRow(Icons.school_rounded, 'Class', item.className),
              _mobileInfoRow(
                Icons.menu_book_rounded,
                'Subject',
                item.subjectName,
              ),
              _mobileInfoRow(
                Icons.calendar_today_rounded,
                'Exam Date',
                _formatExamDate(item.examDate),
              ),
              _mobileInfoRow(Icons.access_time_rounded, 'Time', item.startTime),
              _mobileInfoRow(
                Icons.stars_rounded,
                'Max Marks',
                item.maxMarks?.toString(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mobileInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 9),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _examName(String? value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.assignment_rounded,
            size: 17,
            color: Color(0xFF4F46E5),
          ),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: Text(
            value ?? '-',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _normalText(String? value) {
    return Text(
      value ?? '-',
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF374151),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _examDate(dynamic value) {
    return Text(
      _formatExamDate(value),
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF374151),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _formatExamDate(dynamic value) {
    if (value == null) return '-';

    if (value is DateTime) {
      return _displayDate(value);
    }

    final parsed = DateTime.tryParse(value.toString());

    if (parsed != null) {
      return _displayDate(parsed);
    }

    return value.toString();
  }

  Widget _marks(dynamic value) {
    return Text(
      value?.toString() ?? '-',
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF111827),
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _statusChip(String? status) {
    final normalized = status?.toLowerCase() ?? '';

    Color background;
    Color foreground;
    IconData icon;

    if (normalized == 'completed' || normalized == 'complete') {
      background = const Color(0xFFECFDF5);
      foreground = const Color(0xFF047857);
      icon = Icons.check_circle_rounded;
    } else if (normalized == 'scheduled' || normalized == 'upcoming') {
      background = const Color(0xFFEFF6FF);
      foreground = const Color(0xFF2563EB);
      icon = Icons.schedule_rounded;
    } else if (normalized == 'cancelled' || normalized == 'canceled') {
      background = const Color(0xFFFEF2F2);
      foreground = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
    } else {
      background = const Color(0xFFF3F4F6);
      foreground = const Color(0xFF4B5563);
      icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Text(
            status?.isNotEmpty == true ? _capitalize(status!) : 'Unknown',
            style: TextStyle(
              fontSize: 10,
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;

    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 75),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 30,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No examination records',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No examinations were found for the selected date range.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 65),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 30,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load report',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
}
