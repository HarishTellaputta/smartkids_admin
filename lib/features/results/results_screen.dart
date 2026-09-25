
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mcq/services/mcq_test_service.dart';


class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  // ============================================================
  // SERVICE
  // ============================================================

  McqTestService? _mcqTestService;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  String? _errorMessage;

  List<McqAttemptModel> _attempts = [];

  // ============================================================
  // FILTERS
  // ============================================================

  String selectedClass = 'All Classes';
  String selectedSection = 'All Sections';
  String selectedSubject = 'All Subjects';
  String selectedDate = 'All Dates';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  // ============================================================
  // LOAD RESULTS
  // ============================================================

  Future<void> _loadResults() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        throw Exception('Session expired. Please login again.');
      }

      _mcqTestService = McqTestService(token);

      final data = await _mcqTestService!.getOverallPerformance();

      if (!mounted) return;

      setState(() {
        _attempts = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // ============================================================
  // FILTER OPTIONS
  // ============================================================

  List<String> get classItems {
    final values = <String>{};

    for (final attempt in _attempts) {
      final value = attempt.test?.className;

      if (value != null && value.trim().isNotEmpty) {
        values.add(value.trim());
      }
    }

    final list = values.toList()..sort();

    return ['All Classes', ...list];
  }

  List<String> get sectionItems {
    final values = <String>{};

    for (final attempt in _attempts) {
      final test = attempt.test;

      if (test == null) continue;

      if (selectedClass != 'All Classes' &&
          test.className != selectedClass) {
        continue;
      }

      final value = test.sectionName;

      if (value != null && value.trim().isNotEmpty) {
        values.add(value.trim());
      }
    }

    final list = values.toList()..sort();

    return ['All Sections', ...list];
  }

  List<String> get subjectItems {
    final values = <String>{};

    for (final attempt in _attempts) {
      final test = attempt.test;

      if (test == null) continue;

      if (selectedClass != 'All Classes' &&
          test.className != selectedClass) {
        continue;
      }

      if (selectedSection != 'All Sections' &&
          test.sectionName != selectedSection) {
        continue;
      }

      final value = test.subject;

      if (value != null && value.trim().isNotEmpty) {
        values.add(value.trim());
      }
    }

    final list = values.toList()..sort();

    return ['All Subjects', ...list];
  }

  List<String> get dateItems {
    final values = <String>{};

    for (final attempt in _attempts) {
      final date = _formatDate(attempt.test?.date);

      if (date != '-') {
        values.add(date);
      }
    }

    final list = values.toList()
      ..sort((a, b) => b.compareTo(a));

    return ['All Dates', ...list];
  }

  // ============================================================
  // FILTERED RESULTS
  // ============================================================

  List<McqAttemptModel> get filteredAttempts {
    return _attempts.where((attempt) {
      final test = attempt.test;

      if (test == null) {
        return false;
      }

      final classMatch =
          selectedClass == 'All Classes' ||
          test.className == selectedClass;

      final sectionMatch =
          selectedSection == 'All Sections' ||
          test.sectionName == selectedSection;

      final subjectMatch =
          selectedSubject == 'All Subjects' ||
          test.subject == selectedSubject;

      final dateMatch =
          selectedDate == 'All Dates' ||
          _formatDate(test.date) == selectedDate;

      return classMatch &&
          sectionMatch &&
          subjectMatch &&
          dateMatch;
    }).toList();
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get totalAttempts => filteredAttempts.length;

  int get passedCount {
    return filteredAttempts.where((attempt) {
      return (attempt.percentage ?? 0) >= 50;
    }).length;
  }

  int get failedCount {
    return filteredAttempts.where((attempt) {
      return (attempt.percentage ?? 0) < 50;
    }).length;
  }

  double get averagePercentage {
    if (filteredAttempts.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final attempt in filteredAttempts) {
      total += attempt.percentage ?? 0;
    }

    return total / filteredAttempts.length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadResults,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              if (_isLoading)
                _buildLoading()
              else if (_errorMessage != null)
                _buildError()
              else
                _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerText(),
              const SizedBox(height: 16),
              _refreshButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _headerText(),
            ),
            _refreshButton(),
          ],
        );
      },
    );
  }

  Widget _headerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MCQ Results & Performance',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'View student MCQ test results and academic performance.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _refreshButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _loadResults,
      icon: const Icon(
        Icons.refresh,
        size: 18,
      ),
      label: const Text('Refresh'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 14,
        ),
        side: const BorderSide(
          color: Color(0xFFD1D5DB),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 90,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2563EB),
            ),
            SizedBox(height: 16),
            Text(
              'Loading MCQ results...',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 52,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to load MCQ results',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadResults,
            icon: const Icon(
              Icons.refresh,
              size: 18,
            ),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilters(),

        const SizedBox(height: 24),

        _buildSummaryCards(),

        const SizedBox(height: 24),

        _buildResultsTable(),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
            return Column(
              children: [
                _classDropdown(),
                const SizedBox(height: 12),
                _sectionDropdown(),
                const SizedBox(height: 12),
                _subjectDropdown(),
                const SizedBox(height: 12),
                _dateDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _classDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sectionDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _subjectDropdown(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dateDropdown(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _classDropdown() {
    final items = classItems;

    final value = items.contains(selectedClass)
        ? selectedClass
        : 'All Classes';

    return _dropdown(
      value: value,
      items: items,
      onChanged: (value) {
        setState(() {
          selectedClass = value ?? 'All Classes';

          selectedSection = 'All Sections';
          selectedSubject = 'All Subjects';
        });
      },
    );
  }

  Widget _sectionDropdown() {
    final items = sectionItems;

    final value = items.contains(selectedSection)
        ? selectedSection
        : 'All Sections';

    return _dropdown(
      value: value,
      items: items,
      onChanged: (value) {
        setState(() {
          selectedSection = value ?? 'All Sections';

          selectedSubject = 'All Subjects';
        });
      },
    );
  }

  Widget _subjectDropdown() {
    final items = subjectItems;

    final value = items.contains(selectedSubject)
        ? selectedSubject
        : 'All Subjects';

    return _dropdown(
      value: value,
      items: items,
      onChanged: (value) {
        setState(() {
          selectedSubject = value ?? 'All Subjects';
        });
      },
    );
  }

  Widget _dateDropdown() {
    final items = dateItems;

    final value = items.contains(selectedDate)
        ? selectedDate
        : 'All Dates';

    return _dropdown(
      value: value,
      items: items,
      onChanged: (value) {
        setState(() {
          selectedDate = value ?? 'All Dates';
        });
      },
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value)
              ? value
              : items.first,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 19,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 4;

        if (constraints.maxWidth < 900) {
          columns = 2;
        }

        if (constraints.maxWidth < 550) {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4 : 2.5,
          children: [
            _summaryCard(
              'Total Attempts',
              '$totalAttempts',
              Icons.assignment_turned_in_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Passed',
              '$passedCount',
              Icons.check_circle_outline,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              'Failed',
              '$failedCount',
              Icons.cancel_outlined,
              const Color(0xFFDC2626),
              const Color(0xFFFEF2F2),
            ),
            _summaryCard(
              'Average Score',
              '${averagePercentage.toStringAsFixed(0)}%',
              Icons.analytics_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTS TABLE
  // ============================================================

  Widget _buildResultsTable() {
    final data = filteredAttempts;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'MCQ Student Results',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${data.length} results',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          data.isEmpty
              ? _emptyState()
              : _resultsDataTable(data),
        ],
      ),
    );
  }

  Widget _resultsDataTable(
    List<McqAttemptModel> data,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 25,
        horizontalMargin: 8,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 88,
        headingRowColor: const WidgetStatePropertyAll(
          Color(0xFFF9FAFB),
        ),
        columns: const [
          DataColumn(
            label: Text('Student'),
          ),
          DataColumn(
            label: Text('Class'),
          ),
          DataColumn(
            label: Text('Section'),
          ),
          DataColumn(
            label: Text('Subject'),
          ),
          DataColumn(
            label: Text('Date'),
          ),
          DataColumn(
            label: Text('Score'),
          ),
          DataColumn(
            label: Text('Percentage'),
          ),
          DataColumn(
            label: Text('Status'),
          ),
          DataColumn(
            label: Text('Action'),
          ),
        ],
        rows: data.map((attempt) {
          final test = attempt.test;

          final percentage = attempt.percentage ?? 0;

          return DataRow(
            cells: [
              DataCell(
                _studentCell(attempt),
              ),
              DataCell(
                Text(
                  test?.className ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(
                Text(
                  test?.sectionName ?? '-',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 130,
                  child: Text(
                    test?.subject ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatDate(test?.date),
                  style: const TextStyle(
                    fontSize: 11,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${attempt.score ?? 0}/${attempt.totalQuestions ?? 0}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                _percentageBadge(
                  percentage.toInt(),
                ),
              ),
              DataCell(
                _statusBadge(
                  _statusText(attempt),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View Result',
                      onPressed: () {
                        _showResultDetails(attempt);
                      },
                      icon: const Icon(
                        Icons.visibility_outlined,
                        size: 18,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Performance',
                      onPressed: () {
                        _showPerformance(attempt);
                      },
                      icon: const Icon(
                        Icons.analytics_outlined,
                        size: 18,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // STUDENT CELL
  // ============================================================

  Widget _studentCell(
    McqAttemptModel attempt,
  ) {
    final name = attempt.studentName?.trim().isNotEmpty == true
        ? attempt.studentName!
        : 'Unknown Student';

    return SizedBox(
      width: 210,
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (attempt.admissionNo != null &&
                    attempt.admissionNo!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    attempt.admissionNo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(
    McqAttemptModel attempt,
  ) {
    final status = attempt.status.toUpperCase();

    if (status == 'SUBMITTED') {
      return (attempt.percentage ?? 0) >= 50
          ? 'Passed'
          : 'Failed';
    }

    if (status == 'IN_PROGRESS') {
      return 'In Progress';
    }

    if (status == 'EXPIRED') {
      return 'Expired';
    }

    return attempt.status;
  }

  // ============================================================
  // RESULT DETAILS
  // ============================================================

  void _showResultDetails(
    McqAttemptModel attempt,
  ) {
    final test = attempt.test;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'MCQ Student Result',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow(
                    'Student',
                    attempt.studentName ?? 'Unknown Student',
                  ),
                  _detailRow(
                    'Admission No',
                    attempt.admissionNo ?? '-',
                  ),
                  _detailRow(
                    'Class',
                    test?.className ?? '-',
                  ),
                  _detailRow(
                    'Section',
                    test?.sectionName ?? '-',
                  ),
                  _detailRow(
                    'Subject',
                    test?.subject ?? '-',
                  ),
                  _detailRow(
                    'Date',
                    _formatDate(test?.date),
                  ),
                  _detailRow(
                    'Score',
                    '${attempt.score ?? 0} / ${attempt.totalQuestions ?? 0}',
                  ),
                  _detailRow(
                    'Correct Answers',
                    '${attempt.correctAnswers ?? 0}',
                  ),
                  _detailRow(
                    'Wrong Answers',
                    '${attempt.wrongAnswers ?? 0}',
                  ),
                  _detailRow(
                    'Percentage',
                    '${(attempt.percentage ?? 0).toStringAsFixed(1)}%',
                  ),
                  _detailRow(
                    'Status',
                    _statusText(attempt),
                  ),
                  _detailRow(
                    'Started At',
                    _formatDateTime(attempt.startedAt),
                  ),
                  _detailRow(
                    'Submitted At',
                    _formatDateTime(attempt.submittedAt),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Answer review will be connected next.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.fact_check_outlined,
                size: 17,
              ),
              label: const Text('View Answers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  void _showPerformance(
    McqAttemptModel attempt,
  ) {
    final percentage = attempt.percentage ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '${attempt.studentName ?? 'Student'} - Performance',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'MCQ Score',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _performanceRow(
                  'Correct Answers',
                  '${attempt.correctAnswers ?? 0}',
                  const Color(0xFF15803D),
                ),
                _performanceRow(
                  'Wrong Answers',
                  '${attempt.wrongAnswers ?? 0}',
                  const Color(0xFFDC2626),
                ),
                _performanceRow(
                  'Total Questions',
                  '${attempt.totalQuestions ?? 0}',
                  const Color(0xFF2563EB),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFORMANCE ROW
  // ============================================================

  Widget _performanceRow(
    String title,
    String value,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BADGES
  // ============================================================

  Widget _percentageBadge(
    int percentage,
  ) {
    Color color;

    if (percentage >= 80) {
      color = const Color(0xFF15803D);
    } else if (percentage >= 50) {
      color = const Color(0xFFD97706);
    } else {
      color = const Color(0xFFDC2626);
    }

    return Text(
      '$percentage%',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _statusBadge(
    String status,
  ) {
    final normalized = status.toLowerCase();

    final isPassed = normalized == 'passed';
    final isInProgress = normalized == 'in progress';
    final isExpired = normalized == 'expired';

    Color background;
    Color foreground;

    if (isPassed) {
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF15803D);
    } else if (isInProgress) {
      background = const Color(0xFFFEF3C7);
      foreground = const Color(0xFFD97706);
    } else if (isExpired) {
      background = const Color(0xFFF3F4F6);
      foreground = const Color(0xFF6B7280);
    } else {
      background = const Color(0xFFFEE2E2);
      foreground = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 60,
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.quiz_outlined,
              size: 52,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 12),
            const Text(
              'No MCQ results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Students must complete an MCQ test to see results here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _loadResults,
              icon: const Icon(
                Icons.refresh,
                size: 17,
              ),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _initials(String name) {
    final cleaned = name.trim();

    if (cleaned.isEmpty) {
      return '?';
    }

    final parts = cleaned.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _formatDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value);

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
    } catch (_) {
      return value;
    }
  }

  String _formatDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value);

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

      final hour = date.hour == 0
          ? 12
          : date.hour > 12
              ? date.hour - 12
              : date.hour;

      final minute = date.minute.toString().padLeft(2, '0');

      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '${date.day.toString().padLeft(2, '0')} '
          '${months[date.month - 1]} '
          '${date.year}, '
          '$hour:$minute $period';
    } catch (_) {
      return value;
    }
  }
}

