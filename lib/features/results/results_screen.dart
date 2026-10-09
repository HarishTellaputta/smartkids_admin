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
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);

  static const Color pageBg = Color(0xFFF5F7FB);
  static const Color cardBg = Colors.white;

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  // ============================================================
  // LOAD
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

      if (selectedClass != 'All Classes' && test.className != selectedClass) {
        continue;
      }

      final value = attempt.sectionName;

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

      if (selectedClass != 'All Classes' && test.className != selectedClass) {
        continue;
      }

      if (selectedSection != 'All Sections' &&
          attempt.sectionName != selectedSection) {
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

    final list = values.toList()..sort((a, b) => b.compareTo(a));

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
          selectedClass == 'All Classes' || test.className == selectedClass;

      final sectionMatch =
          selectedSection == 'All Sections' ||
          attempt.sectionName == selectedSection;

      final subjectMatch =
          selectedSubject == 'All Subjects' || test.subject == selectedSubject;

      final dateMatch =
          selectedDate == 'All Dates' || _formatDate(test.date) == selectedDate;

      return classMatch && sectionMatch && subjectMatch && dateMatch;
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
      backgroundColor: pageBg,
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadResults,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 26),

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
        final compact = constraints.maxWidth < 700;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.035),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerText(),
                    const SizedBox(height: 18),
                    _refreshButton(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _headerText()),
                    _refreshButton(),
                  ],
                ),
        );
      },
    );
  }

  Widget _headerText() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primary, primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(.22),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.assessment_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MCQ Results & Performance',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Track student performance, scores and academic progress.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _refreshButton() {
    return OutlinedButton.icon(
      onPressed: _isLoading ? null : _loadResults,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text(
        'Refresh Results',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: primary.withOpacity(.25)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return _surface(
      padding: const EdgeInsets.symmetric(vertical: 90),
      child: const Center(
        child: Column(
          children: [
            SizedBox(
              height: 38,
              width: 38,
              child: CircularProgressIndicator(strokeWidth: 3, color: primary),
            ),
            SizedBox(height: 18),
            Text(
              'Loading MCQ results...',
              style: TextStyle(fontSize: 13, color: textSecondary),
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
    return _surface(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              size: 32,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Unable to load MCQ results',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            _errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: _loadResults,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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

        const SizedBox(height: 22),

        _buildSummaryCards(),

        const SizedBox(height: 22),

        _buildResultsTable(),
      ],
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters() {
    return _surface(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
            return Column(
              children: [
                _filterLabel('CLASS', _classDropdown()),
                const SizedBox(height: 13),
                _filterLabel('SECTION', _sectionDropdown()),
                const SizedBox(height: 13),
                _filterLabel('SUBJECT', _subjectDropdown()),
                const SizedBox(height: 13),
                _filterLabel('DATE', _dateDropdown()),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _filterLabel('CLASS', _classDropdown())),
              const SizedBox(width: 12),
              Expanded(child: _filterLabel('SECTION', _sectionDropdown())),
              const SizedBox(width: 12),
              Expanded(child: _filterLabel('SUBJECT', _subjectDropdown())),
              const SizedBox(width: 12),
              Expanded(child: _filterLabel('DATE', _dateDropdown())),
            ],
          );
        },
      ),
    );
  }

  Widget _filterLabel(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: textSecondary,
              letterSpacing: .8,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _classDropdown() {
    final items = classItems;

    final value = items.contains(selectedClass) ? selectedClass : 'All Classes';

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

    final value = items.contains(selectedDate) ? selectedDate : 'All Dates';

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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 19,
            color: textSecondary,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
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
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4.4 : 2.15,
          children: [
            _summaryCard(
              title: 'Total Attempts',
              value: '$totalAttempts',
              subtitle: 'Tests completed',
              icon: Icons.assignment_turned_in_rounded,
              color: primary,
              background: const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              title: 'Passed',
              value: '$passedCount',
              subtitle: '50% or above',
              icon: Icons.verified_rounded,
              color: const Color(0xFF15803D),
              background: const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              title: 'Failed',
              value: '$failedCount',
              subtitle: 'Below 50%',
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFDC2626),
              background: const Color(0xFFFEF2F2),
            ),
            _summaryCard(
              title: 'Average Score',
              value: '${averagePercentage.toStringAsFixed(0)}%',
              subtitle: 'Overall performance',
              icon: Icons.auto_graph_rounded,
              color: const Color(0xFF7C3AED),
              background: const Color(0xFFF5F3FF),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 49,
            width: 49,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ],
            ),
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

    return _surface(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.table_chart_rounded,
                  color: primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student Results',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Detailed MCQ test performance',
                      style: TextStyle(fontSize: 10, color: textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${data.length} Results',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          data.isEmpty ? _emptyState() : _resultsDataTable(data),
        ],
      ),
    );
  }

  Widget _resultsDataTable(List<McqAttemptModel> data) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 28,
          horizontalMargin: 12,
          dataRowMinHeight: 76,
          dataRowMaxHeight: 88,
          headingRowHeight: 48,
          headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
          dividerThickness: .5,
          columns: const [
            DataColumn(label: _TableHeader('Student')),
            DataColumn(label: _TableHeader('Class')),
            DataColumn(label: _TableHeader('Section')),
            DataColumn(label: _TableHeader('Subject')),
            DataColumn(label: _TableHeader('Date')),
            DataColumn(label: _TableHeader('Score')),
            DataColumn(label: _TableHeader('Result')),
            DataColumn(label: _TableHeader('Status')),
            DataColumn(label: _TableHeader('Action')),
          ],
          rows: data.map((attempt) {
            final test = attempt.test;
            final percentage = attempt.percentage ?? 0;

            return DataRow(
              cells: [
                DataCell(_studentCell(attempt)),

                DataCell(_smallText(test?.className ?? '-')),

                DataCell(_smallText(attempt.sectionName ?? '-')),

                DataCell(
                  SizedBox(
                    width: 125,
                    child: Text(
                      test?.subject ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),

                DataCell(_smallText(_formatDate(test?.date))),

                DataCell(_scoreCell(attempt)),

                DataCell(_percentageCard(percentage)),

                DataCell(_statusBadge(_statusText(attempt))),

                DataCell(_actionButtons(attempt)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // STUDENT
  // ============================================================

  Widget _studentCell(McqAttemptModel attempt) {
    final name = attempt.studentName?.trim().isNotEmpty == true
        ? attempt.studentName!.trim()
        : 'Unknown Student';

    return SizedBox(
      width: 220,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary.withOpacity(.14), const Color(0xFFDBEAFE)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _initials(name),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
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
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                if (attempt.admissionNo != null &&
                    attempt.admissionNo!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          attempt.admissionNo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCell(McqAttemptModel attempt) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${attempt.score ?? 0}/${attempt.totalQuestions ?? 0}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${attempt.correctAnswers ?? 0} correct',
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF15803D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _percentageCard(double percentage) {
    final double value = percentage.clamp(0, 100).toDouble();

    Color color;

    if (value >= 80) {
      color = const Color(0xFF15803D);
    } else if (value >= 50) {
      color = const Color(0xFFD97706);
    } else {
      color = const Color(0xFFDC2626);
    }

    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 4,
              backgroundColor: color.withOpacity(.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(McqAttemptModel attempt) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _iconAction(
          tooltip: 'View Result',
          icon: Icons.visibility_rounded,
          color: primary,
          onPressed: () => _showResultDetails(attempt),
        ),
        const SizedBox(width: 6),
        _iconAction(
          tooltip: 'Performance',
          icon: Icons.insights_rounded,
          color: const Color(0xFF7C3AED),
          onPressed: () => _showPerformance(attempt),
        ),
      ],
    );
  }

  Widget _iconAction({
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(
            height: 35,
            width: 35,
            child: Icon(icon, size: 17, color: color),
          ),
        ),
      ),
    );
  }

  Widget _smallText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: textSecondary,
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _statusText(McqAttemptModel attempt) {
    final status = attempt.status.toUpperCase();

    if (status == 'SUBMITTED') {
      return (attempt.percentage ?? 0) >= 50 ? 'Passed' : 'Failed';
    }

    if (status == 'IN_PROGRESS') {
      return 'In Progress';
    }

    if (status == 'EXPIRED') {
      return 'Expired';
    }

    return attempt.status;
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    final isPassed = normalized == 'passed';
    final isInProgress = normalized == 'in progress';
    final isExpired = normalized == 'expired';

    Color background;
    Color foreground;
    IconData icon;

    if (isPassed) {
      background = const Color(0xFFDCFCE7);
      foreground = const Color(0xFF15803D);
      icon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      background = const Color(0xFFFEF3C7);
      foreground = const Color(0xFFD97706);
      icon = Icons.schedule_rounded;
    } else if (isExpired) {
      background = const Color(0xFFF3F4F6);
      foreground = const Color(0xFF6B7280);
      icon = Icons.timer_off_rounded;
    } else {
      background = const Color(0xFFFEE2E2);
      foreground = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
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
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VIEW RESULT - PREMIUM
  // ============================================================

  void _showResultDetails(McqAttemptModel attempt) {
    final test = attempt.test;
    final double percentage = (attempt.percentage ?? 0)
        .clamp(0, 100)
        .toDouble();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.15),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student Result',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'MCQ assessment details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Student + Score
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _dialogStudentHeader(attempt)),
                              const SizedBox(width: 20),
                              _scoreCircle(percentage: percentage, size: 112),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // Quick stats
                          Row(
                            children: [
                              Expanded(
                                child: _metricCard(
                                  'Correct',
                                  '${attempt.correctAnswers ?? 0}',
                                  Icons.check_circle_rounded,
                                  const Color(0xFF15803D),
                                  const Color(0xFFF0FDF4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Wrong',
                                  '${attempt.wrongAnswers ?? 0}',
                                  Icons.cancel_rounded,
                                  const Color(0xFFDC2626),
                                  const Color(0xFFFEF2F2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Total',
                                  '${attempt.totalQuestions ?? 0}',
                                  Icons.quiz_rounded,
                                  primary,
                                  const Color(0xFFEFF6FF),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          _dialogSection(
                            title: 'Test Information',
                            icon: Icons.info_outline_rounded,
                            child: Column(
                              children: [
                                _detailRow(
                                  'Student',
                                  attempt.studentName ?? 'Unknown Student',
                                ),
                                _detailRow(
                                  'Admission No',
                                  attempt.admissionNo ?? '-',
                                ),
                                _detailRow('Class', test?.className ?? '-'),
                                _detailRow(
                                  'Section',
                                  attempt.sectionName ?? '-',
                                ),
                                _detailRow('Subject', test?.subject ?? '-'),
                                _detailRow(
                                  'Test Date',
                                  _formatDate(test?.date),
                                ),
                                _detailRow('Status', _statusText(attempt)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          _dialogSection(
                            title: 'Timing',
                            icon: Icons.schedule_rounded,
                            child: Column(
                              children: [
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
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 15,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            'Result generated from the MCQ assessment.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PERFORMANCE - PREMIUM
  // ============================================================

  void _showPerformance(McqAttemptModel attempt) {
    final double percentage =
    (attempt.percentage ?? 0).clamp(0, 100).toDouble();

    final total = attempt.totalQuestions ?? 0;
    final correct = attempt.correctAnswers ?? 0;
    final wrong = attempt.wrongAnswers ?? 0;

    final accuracy = total > 0 ? (correct / total) * 100 : 0.0;

    final level = _performanceLevel(percentage);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.15),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.insights_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${attempt.studentName ?? 'Student'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Performance Analytics',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Main score
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF5F3FF), Color(0xFFFAF5FF)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE9D5FF),
                              ),
                            ),
                            child: Row(
                              children: [
                                _scoreCircle(
                                  percentage: percentage,
                                  size: 125,
                                  purple: true,
                                ),
                                const SizedBox(width: 22),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Overall Performance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        level,
                                        style: const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        _performanceMessage(percentage),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          height: 1.45,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Analytics metrics
                          Row(
                            children: [
                              Expanded(
                                child: _metricCard(
                                  'Correct',
                                  '$correct',
                                  Icons.check_circle_rounded,
                                  const Color(0xFF15803D),
                                  const Color(0xFFF0FDF4),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Wrong',
                                  '$wrong',
                                  Icons.cancel_rounded,
                                  const Color(0xFFDC2626),
                                  const Color(0xFFFEF2F2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _metricCard(
                                  'Accuracy',
                                  '${accuracy.toStringAsFixed(0)}%',
                                  Icons.gps_fixed_rounded,
                                  const Color(0xFF2563EB),
                                  const Color(0xFFEFF6FF),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          _dialogSection(
                            title: 'Performance Breakdown',
                            icon: Icons.bar_chart_rounded,
                            child: Column(
                              children: [
                                _progressMetric(
                                  title: 'Correct Answers',
                                  value: correct,
                                  total: total,
                                  color: const Color(0xFF16A34A),
                                ),
                                const SizedBox(height: 16),
                                _progressMetric(
                                  title: 'Wrong Answers',
                                  value: wrong,
                                  total: total,
                                  color: const Color(0xFFDC2626),
                                ),
                                const SizedBox(height: 16),
                                _progressMetric(
                                  title: 'Overall Score',
                                  value: percentage.toInt(),
                                  total: 100,
                                  color: const Color(0xFF7C3AED),
                                  suffix: '%',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          _dialogSection(
                            title: 'Test Details',
                            icon: Icons.menu_book_rounded,
                            child: Column(
                              children: [
                                _detailRow(
                                  'Subject',
                                  attempt.test?.subject ?? '-',
                                ),
                                _detailRow(
                                  'Class',
                                  attempt.test?.className ?? '-',
                                ),
                                _detailRow(
                                  'Section',
                                  attempt.sectionName ?? '-',
                                ),
                                _detailRow(
                                  'Score',
                                  '${attempt.score ?? 0} / ${attempt.totalQuestions ?? 0}',
                                ),
                                _detailRow(
                                  'Date',
                                  _formatDate(attempt.test?.date),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_graph_rounded,
                          size: 15,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 7),
                        const Expanded(
                          child: Text(
                            'Performance calculated from submitted answers.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DIALOG HELPERS
  // ============================================================

  Widget _dialogStudentHeader(McqAttemptModel attempt) {
    final name = attempt.studentName?.trim().isNotEmpty == true
        ? attempt.studentName!.trim()
        : 'Unknown Student';

    return Row(
      children: [
        Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                attempt.admissionNo?.trim().isNotEmpty == true
                    ? attempt.admissionNo!
                    : 'Admission number unavailable',
                style: const TextStyle(fontSize: 10, color: textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scoreCircle({
    required double percentage,
    required double size,
    bool purple = false,
  }) {
    final color = purple ? const Color(0xFF7C3AED) : primary;

    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 9,
              backgroundColor: color.withOpacity(.10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size > 115 ? 27 : 23,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const Text(
                'Score',
                style: TextStyle(
                  fontSize: 9,
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 9),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              color: textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: primary),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _progressMetric({
    required String title,
    required int value,
    required int total,
    required Color color,
    String suffix = '',
  }) {
    final progress = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);

    final percentage = total <= 0 ? 0 : ((value / total) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
            Text(
              '$value${suffix.isEmpty ? ' / $total' : suffix}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: color.withOpacity(.10),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$percentage%',
            style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }

  String _performanceLevel(double percentage) {
    if (percentage >= 90) {
      return 'Excellent Performance';
    }

    if (percentage >= 75) {
      return 'Very Good Performance';
    }

    if (percentage >= 60) {
      return 'Good Performance';
    }

    if (percentage >= 50) {
      return 'Satisfactory Performance';
    }

    return 'Needs Improvement';
  }

  String _performanceMessage(double percentage) {
    if (percentage >= 90) {
      return 'Outstanding result. The student has demonstrated excellent understanding.';
    }

    if (percentage >= 75) {
      return 'Strong performance with a very good understanding of the subject.';
    }

    if (percentage >= 60) {
      return 'Good performance. There is still room to improve accuracy.';
    }

    if (percentage >= 50) {
      return 'The student has achieved the passing level. More practice can improve the score.';
    }

    return 'The student needs additional practice and revision in this subject.';
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70),
      child: Center(
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.quiz_outlined,
                size: 32,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'No MCQ results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Students must complete an MCQ test to see results here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _loadResults,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(foregroundColor: primary),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SURFACE
  // ============================================================

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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

// ================================================================
// TABLE HEADER
// ================================================================

class _TableHeader extends StatelessWidget {
  final String text;

  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: Color(0xFF6B7280),
        letterSpacing: .6,
      ),
    );
  }
}
