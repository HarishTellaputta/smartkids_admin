import 'package:flutter/material.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String selectedClass = 'All Classes';
  String selectedTest = 'All Tests';
  String selectedDate = 'All Dates';

  final List<Map<String, dynamic>> results = [
    {
      'student': 'Aarav Kumar',
      'class': 'Class 1 - A',
      'test': 'Daily General Knowledge Test',
      'date': '10 Aug 2026',
      'score': 9,
      'total': 10,
      'percentage': 90,
      'time': '08:42',
      'status': 'Passed',
    },
    {
      'student': 'Ananya Reddy',
      'class': 'Class 1 - A',
      'test': 'Daily General Knowledge Test',
      'date': '10 Aug 2026',
      'score': 10,
      'total': 10,
      'percentage': 100,
      'time': '06:15',
      'status': 'Passed',
    },
    {
      'student': 'Vihaan Sharma',
      'class': 'Class 2 - A',
      'test': 'Daily Mathematics Test',
      'date': '10 Aug 2026',
      'score': 8,
      'total': 10,
      'percentage': 80,
      'time': '11:20',
      'status': 'Passed',
    },
    {
      'student': 'Diya Sai',
      'class': 'Class 2 - A',
      'test': 'Daily Mathematics Test',
      'date': '10 Aug 2026',
      'score': 6,
      'total': 10,
      'percentage': 60,
      'time': '14:03',
      'status': 'Passed',
    },
    {
      'student': 'Arjun Raju',
      'class': 'Class 3 - A',
      'test': 'Science Daily Challenge',
      'date': '09 Aug 2026',
      'score': 4,
      'total': 10,
      'percentage': 40,
      'time': '15:00',
      'status': 'Failed',
    },
    {
      'student': 'Saanvi Patel',
      'class': 'Class 3 - A',
      'test': 'Science Daily Challenge',
      'date': '09 Aug 2026',
      'score': 9,
      'total': 10,
      'percentage': 90,
      'time': '09:31',
      'status': 'Passed',
    },
    {
      'student': 'Rohan Kumar',
      'class': 'Class 4 - A',
      'test': 'English Vocabulary Test',
      'date': '08 Aug 2026',
      'score': 7,
      'total': 10,
      'percentage': 70,
      'time': '12:44',
      'status': 'Passed',
    },
    {
      'student': 'Ishita Rao',
      'class': 'Class 5 - A',
      'test': 'Mathematics Challenge',
      'date': '08 Aug 2026',
      'score': 10,
      'total': 10,
      'percentage': 100,
      'time': '07:21',
      'status': 'Passed',
    },
  ];

  List<Map<String, dynamic>> get filteredResults {
    return results.where((result) {
      final classMatch =
          selectedClass == 'All Classes' || result['class'] == selectedClass;

      final testMatch =
          selectedTest == 'All Tests' || result['test'] == selectedTest;

      final dateMatch =
          selectedDate == 'All Dates' || result['date'] == selectedDate;

      return classMatch && testMatch && dateMatch;
    }).toList();
  }

  int get totalAttempts => filteredResults.length;

  int get passedCount =>
      filteredResults.where((result) => result['status'] == 'Passed').length;

  int get failedCount =>
      filteredResults.where((result) => result['status'] == 'Failed').length;

  double get averagePercentage {
    if (filteredResults.isEmpty) {
      return 0;
    }

    final total = filteredResults.fold<int>(
      0,
      (sum, result) => sum + (result['percentage'] as int),
    );

    return total / filteredResults.length;
  }

  int get highestScore {
    if (filteredResults.isEmpty) {
      return 0;
    }

    return filteredResults
        .map<int>((result) => result['percentage'] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  void _showResultDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Student Result',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 470,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Student', result['student']),
                _detailRow('Class', result['class']),
                _detailRow('Test', result['test']),
                _detailRow('Date', result['date']),
                _detailRow('Score', '${result['score']} / ${result['total']}'),
                _detailRow('Percentage', '${result['percentage']}%'),
                _detailRow('Time Taken', result['time']),
                _detailRow('Status', result['status']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Detailed answer review will be connected later.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fact_check_outlined, size: 17),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Excel/PDF export will be connected with backend later.'),
      ),
    );
  }

  void _showStudentPerformance(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${result['student']} - Performance',
            style: const TextStyle(fontWeight: FontWeight.bold),
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
                        '${result['percentage']}%',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Test Score',
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
                  '${result['score']}',
                  const Color(0xFF15803D),
                ),
                _performanceRow(
                  'Wrong Answers',
                  '${result['total'] - result['score']}',
                  const Color(0xFFDC2626),
                ),
                _performanceRow(
                  'Time Taken',
                  result['time'],
                  const Color(0xFFD97706),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _performanceRow(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildFilters(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildResultsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerText(),
              const SizedBox(height: 16),
              _exportButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            _exportButton(),
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
          'Results & Performance',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'View student test results and academic performance.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _exportButton() {
    return OutlinedButton.icon(
      onPressed: _exportResults,
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('Export Results'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return Column(
              children: [
                _classDropdown(),
                const SizedBox(height: 12),
                _testDropdown(),
                const SizedBox(height: 12),
                _dateDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _classDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _testDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _dateDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _classDropdown() {
    return _dropdown(
      value: selectedClass,
      items: const [
        'All Classes',
        'Class 1 - A',
        'Class 1 - B',
        'Class 2 - A',
        'Class 2 - B',
        'Class 3 - A',
        'Class 4 - A',
        'Class 5 - A',
      ],
      onChanged: (value) {
        setState(() {
          selectedClass = value!;
        });
      },
    );
  }

  Widget _testDropdown() {
    return _dropdown(
      value: selectedTest,
      items: const [
        'All Tests',
        'Daily General Knowledge Test',
        'Daily Mathematics Test',
        'Science Daily Challenge',
        'English Vocabulary Test',
        'Mathematics Challenge',
      ],
      onChanged: (value) {
        setState(() {
          selectedTest = value!;
        });
      },
    );
  }

  Widget _dateDropdown() {
    return _dropdown(
      value: selectedDate,
      items: const ['All Dates', '10 Aug 2026', '09 Aug 2026', '08 Aug 2026'],
      onChanged: (value) {
        setState(() {
          selectedDate = value!;
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
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 19),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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

  Widget _buildResultsTable() {
    final data = filteredResults;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Student Results',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${data.length} results',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          data.isEmpty ? _emptyState() : _resultsTable(data),
        ],
      ),
    );
  }

  Widget _resultsTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        horizontalMargin: 8,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 82,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Test')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Score')),
          DataColumn(label: Text('Percentage')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: data.map((result) {
          return DataRow(
            cells: [
              DataCell(_studentCell(result)),
              DataCell(
                Text(result['class'], style: const TextStyle(fontSize: 12)),
              ),
              DataCell(
                SizedBox(
                  width: 210,
                  child: Text(
                    result['test'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              DataCell(
                Text(result['date'], style: const TextStyle(fontSize: 11)),
              ),
              DataCell(
                Text(
                  '${result['score']}/${result['total']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(_percentageBadge(result['percentage'])),
              DataCell(
                Text(result['time'], style: const TextStyle(fontSize: 11)),
              ),
              DataCell(_statusBadge(result['status'])),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'View Result',
                      onPressed: () {
                        _showResultDetails(result);
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                    ),
                    IconButton(
                      tooltip: 'Performance',
                      onPressed: () {
                        _showStudentPerformance(result);
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

  Widget _studentCell(Map<String, dynamic> result) {
    return SizedBox(
      width: 180,
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              _initials(result['student']),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              result['student'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
            '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Widget _percentageBadge(int percentage) {
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
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _statusBadge(String status) {
    final isPassed = status == 'Passed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isPassed ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPassed ? const Color(0xFF15803D) : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 52, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your filters.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
