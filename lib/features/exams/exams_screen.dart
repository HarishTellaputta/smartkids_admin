import 'package:flutter/material.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String selectedClass = 'All Classes';
  String selectedStatus = 'All';

  final List<Map<String, dynamic>> exams = [
    {
      'id': 'EX001',
      'name': 'Unit Test - 1',
      'class': 'Class 1 - A',
      'startDate': '18 Aug 2026',
      'endDate': '22 Aug 2026',
      'subjects': 5,
      'students': 28,
      'status': 'Upcoming',
    },
    {
      'id': 'EX002',
      'name': 'Unit Test - 1',
      'class': 'Class 2 - A',
      'startDate': '18 Aug 2026',
      'endDate': '22 Aug 2026',
      'subjects': 5,
      'students': 30,
      'status': 'Upcoming',
    },
    {
      'id': 'EX003',
      'name': 'Periodic Test - 1',
      'class': 'Class 3 - A',
      'startDate': '25 Aug 2026',
      'endDate': '30 Aug 2026',
      'subjects': 6,
      'students': 32,
      'status': 'Upcoming',
    },
    {
      'id': 'EX004',
      'name': 'Mid Term Examination',
      'class': 'Class 4 - A',
      'startDate': '10 Sep 2026',
      'endDate': '17 Sep 2026',
      'subjects': 7,
      'students': 35,
      'status': 'Scheduled',
    },
    {
      'id': 'EX005',
      'name': 'Annual Examination',
      'class': 'Class 5 - A',
      'startDate': '10 Mar 2027',
      'endDate': '20 Mar 2027',
      'subjects': 8,
      'students': 38,
      'status': 'Scheduled',
    },
    {
      'id': 'EX006',
      'name': 'Unit Test - 1',
      'class': 'Class 5 - A',
      'startDate': '20 Jul 2026',
      'endDate': '24 Jul 2026',
      'subjects': 5,
      'students': 38,
      'status': 'Completed',
    },
  ];

  List<Map<String, dynamic>> get filteredExams {
    return exams.where((exam) {
      final classMatch =
          selectedClass == 'All Classes' || exam['class'] == selectedClass;

      final statusMatch =
          selectedStatus == 'All' || exam['status'] == selectedStatus;

      return classMatch && statusMatch;
    }).toList();
  }

  int get totalExams => exams.length;

  int get upcomingExams =>
      exams.where((exam) => exam['status'] == 'Upcoming').length;

  int get scheduledExams =>
      exams.where((exam) => exam['status'] == 'Scheduled').length;

  int get completedExams =>
      exams.where((exam) => exam['status'] == 'Completed').length;

  void _showAddExamDialog() {
    final nameController = TextEditingController();

    String examClass = 'Class 1 - A';
    String examStatus = 'Upcoming';
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create New Examination',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: _inputDecoration(
                          'Exam Name',
                          Icons.assignment_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: examClass,
                        decoration: _inputDecoration(
                          'Class',
                          Icons.school_outlined,
                        ),
                        items:
                            const [
                              'Class 1 - A',
                              'Class 1 - B',
                              'Class 2 - A',
                              'Class 2 - B',
                              'Class 3 - A',
                              'Class 4 - A',
                              'Class 5 - A',
                            ].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              examClass = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _dateButton(
                              label: startDate == null
                                  ? 'Start Date'
                                  : _formatDate(startDate!),
                              icon: Icons.calendar_today_outlined,
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2026),
                                  lastDate: DateTime(2030),
                                  initialDate: DateTime.now(),
                                );

                                if (date != null) {
                                  setDialogState(() {
                                    startDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dateButton(
                              label: endDate == null
                                  ? 'End Date'
                                  : _formatDate(endDate!),
                              icon: Icons.event_outlined,
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(2026),
                                  lastDate: DateTime(2030),
                                  initialDate: startDate ?? DateTime.now(),
                                );

                                if (date != null) {
                                  setDialogState(() {
                                    endDate = date;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: examStatus,
                        decoration: _inputDecoration(
                          'Status',
                          Icons.flag_outlined,
                        ),
                        items: const ['Upcoming', 'Scheduled', 'Completed'].map(
                          (item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          },
                        ).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              examStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        startDate == null ||
                        endDate == null) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter exam name and dates.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      exams.add({
                        'id':
                            'EX${(exams.length + 1).toString().padLeft(3, '0')}',
                        'name': nameController.text.trim(),
                        'class': examClass,
                        'startDate': _formatDate(startDate!),
                        'endDate': _formatDate(endDate!),
                        'subjects': 0,
                        'students': 0,
                        'status': examStatus,
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Examination created successfully.'),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Exam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    );
  }

  Widget _dateButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6B7280)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: label.contains('Date')
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        '${months[date.month - 1]} ${date.year}';
  }

  void _showExamDetails(Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            exam['name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Exam ID', exam['id']),
                _detailRow('Class', exam['class']),
                _detailRow('Start Date', exam['startDate']),
                _detailRow('End Date', exam['endDate']),
                _detailRow('Subjects', '${exam['subjects']}'),
                _detailRow('Students', '${exam['students']}'),
                _detailRow('Status', exam['status']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (exam['status'] != 'Completed')
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showSnack('Exam schedule editor will be connected later.');
                },
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit'),
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _deleteExam(Map<String, dynamic> exam) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Examination?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to delete "${exam['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  exams.remove(exam);
                });

                Navigator.pop(context);

                _showSnack('Examination deleted.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
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
            _buildExamList(),
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
              _addExamButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            _addExamButton(),
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
          'Examinations',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Create and manage school examinations and schedules.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _addExamButton() {
    return ElevatedButton.icon(
      onPressed: _showAddExamDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Create Examination'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
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
          if (constraints.maxWidth < 700) {
            return Column(
              children: [
                _classDropdown(),
                const SizedBox(height: 12),
                _statusDropdown(),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 250, child: _classDropdown()),
              const SizedBox(width: 12),
              SizedBox(width: 220, child: _statusDropdown()),
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

  Widget _statusDropdown() {
    return _dropdown(
      value: selectedStatus,
      items: const ['All', 'Upcoming', 'Scheduled', 'Completed'],
      onChanged: (value) {
        setState(() {
          selectedStatus = value!;
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
              child: Text(item, style: const TextStyle(fontSize: 12)),
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
              'Total Exams',
              '$totalExams',
              Icons.assignment_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Upcoming',
              '$upcomingExams',
              Icons.event_available_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
            ),
            _summaryCard(
              'Scheduled',
              '$scheduledExams',
              Icons.schedule_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _summaryCard(
              'Completed',
              '$completedExams',
              Icons.task_alt_outlined,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
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

  Widget _buildExamList() {
    final data = filteredExams;

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
                'Examination Schedule',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${data.length} exams',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          data.isEmpty ? _emptyState() : _examTable(data),
        ],
      ),
    );
  }

  Widget _examTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 30,
        horizontalMargin: 8,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 82,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Examination')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Start Date')),
          DataColumn(label: Text('End Date')),
          DataColumn(label: Text('Subjects')),
          DataColumn(label: Text('Students')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((exam) {
          return DataRow(
            cells: [
              DataCell(_examNameCell(exam)),
              DataCell(
                Text(exam['class'], style: const TextStyle(fontSize: 12)),
              ),
              DataCell(
                Text(exam['startDate'], style: const TextStyle(fontSize: 11)),
              ),
              DataCell(
                Text(exam['endDate'], style: const TextStyle(fontSize: 11)),
              ),
              DataCell(
                Text(
                  '${exam['subjects']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  '${exam['students']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(_statusBadge(exam['status'])),
              DataCell(_actionButtons(exam)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _examNameCell(Map<String, dynamic> exam) {
    return SizedBox(
      width: 210,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam['name'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exam['id'],
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    Color background;

    switch (status) {
      case 'Upcoming':
        color = const Color(0xFF2563EB);
        background = const Color(0xFFDBEAFE);
        break;

      case 'Scheduled':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
        break;

      case 'Completed':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;

      default:
        color = const Color(0xFF6B7280);
        background = const Color(0xFFF3F4F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButtons(Map<String, dynamic> exam) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View Details',
          onPressed: () {
            _showExamDetails(exam);
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteExam(exam);
          },
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 52, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text(
              'No examinations found',
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
