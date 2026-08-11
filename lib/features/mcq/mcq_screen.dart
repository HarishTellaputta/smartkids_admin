import 'package:flutter/material.dart';

class McqScreen extends StatefulWidget {
  const McqScreen({super.key});

  @override
  State<McqScreen> createState() => _McqScreenState();
}

class _McqScreenState extends State<McqScreen> {
  String selectedClass = 'All Classes';
  String selectedStatus = 'All';

  final List<Map<String, dynamic>> tests = [
    {
      'id': 'MCQ001',
      'title': 'Daily General Knowledge Test',
      'class': 'Class 1 - A',
      'date': '10 Aug 2026',
      'time': '7:00 PM',
      'duration': 15,
      'questions': 10,
      'attempts': 24,
      'status': 'Published',
    },
    {
      'id': 'MCQ002',
      'title': 'Daily Mathematics Test',
      'class': 'Class 2 - A',
      'date': '10 Aug 2026',
      'time': '7:00 PM',
      'duration': 15,
      'questions': 10,
      'attempts': 27,
      'status': 'Published',
    },
    {
      'id': 'MCQ003',
      'title': 'Science Daily Challenge',
      'class': 'Class 3 - A',
      'date': '11 Aug 2026',
      'time': '7:00 PM',
      'duration': 15,
      'questions': 15,
      'attempts': 0,
      'status': 'Scheduled',
    },
    {
      'id': 'MCQ004',
      'title': 'English Vocabulary Test',
      'class': 'Class 4 - A',
      'date': '11 Aug 2026',
      'time': '7:00 PM',
      'duration': 15,
      'questions': 15,
      'attempts': 0,
      'status': 'Draft',
    },
    {
      'id': 'MCQ005',
      'title': 'Mathematics Challenge',
      'class': 'Class 5 - A',
      'date': '09 Aug 2026',
      'time': '7:00 PM',
      'duration': 15,
      'questions': 15,
      'attempts': 31,
      'status': 'Completed',
    },
  ];

  int get totalTests => tests.length;

  int get publishedTests =>
      tests.where((test) => test['status'] == 'Published').length;

  int get scheduledTests =>
      tests.where((test) => test['status'] == 'Scheduled').length;

  int get draftTests => tests.where((test) => test['status'] == 'Draft').length;

  int get totalAttempts =>
      tests.fold(0, (sum, test) => sum + (test['attempts'] as int));

  List<Map<String, dynamic>> get filteredTests {
    return tests.where((test) {
      final classMatch =
          selectedClass == 'All Classes' || test['class'] == selectedClass;

      final statusMatch =
          selectedStatus == 'All' || test['status'] == selectedStatus;

      return classMatch && statusMatch;
    }).toList();
  }

  void _showCreateTestDialog() {
    final titleController = TextEditingController();

    String testClass = 'Class 1 - A';
    String testStatus = 'Draft';
    String testTime = '7:00 PM';
    int duration = 15;

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create Daily MCQ Test',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: _inputDecoration(
                          'Test Title',
                          Icons.quiz_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: testClass,
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
                              testClass = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2030),
                            initialDate: selectedDate,
                          );

                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
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
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatDate(selectedDate),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: testTime,
                              decoration: _inputDecoration(
                                'Test Time',
                                Icons.access_time_outlined,
                              ),
                              items:
                                  const [
                                    '6:00 PM',
                                    '6:30 PM',
                                    '7:00 PM',
                                    '7:30 PM',
                                    '8:00 PM',
                                  ].map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    testTime = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: duration,
                              decoration: _inputDecoration(
                                'Duration',
                                Icons.timer_outlined,
                              ),
                              items: const [10, 15, 20, 30].map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text('$item minutes'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    duration = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: testStatus,
                        decoration: _inputDecoration(
                          'Initial Status',
                          Icons.flag_outlined,
                        ),
                        items: const ['Draft', 'Scheduled', 'Published'].map((
                          item,
                        ) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              testStatus = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Questions can be added after creating the test.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a test title.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      tests.add({
                        'id':
                            'MCQ${(tests.length + 1).toString().padLeft(3, '0')}',
                        'title': titleController.text.trim(),
                        'class': testClass,
                        'date': _formatDate(selectedDate),
                        'time': testTime,
                        'duration': duration,
                        'questions': 0,
                        'attempts': 0,
                        'status': testStatus,
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('MCQ test created successfully.'),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Test'),
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

  void _showTestDetails(Map<String, dynamic> test) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            test['title'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Test ID', test['id']),
                _detailRow('Class', test['class']),
                _detailRow('Date', test['date']),
                _detailRow('Time', test['time']),
                _detailRow('Duration', '${test['duration']} minutes'),
                _detailRow('Questions', '${test['questions']}'),
                _detailRow('Attempts', '${test['attempts']}'),
                _detailRow('Status', test['status']),
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
                _openQuestionManager(test);
              },
              icon: const Icon(Icons.question_mark, size: 17),
              label: const Text('Manage Questions'),
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _openQuestionManager(Map<String, dynamic> test) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => McqQuestionManagerScreen(test: test)),
    ).then((_) {
      setState(() {});
    });
  }

  void _publishTest(Map<String, dynamic> test) {
    if (test['questions'] == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one question before publishing.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      test['status'] = 'Published';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('MCQ test published successfully.'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
  }

  void _deleteTest(Map<String, dynamic> test) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete MCQ Test?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to delete "${test['title']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  tests.remove(test);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('MCQ test deleted.')),
                );
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

  void _showResults(Map<String, dynamic> test) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Results for ${test['title']} will be connected later.'),
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
            _buildTestList(),
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
              _createButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            _createButton(),
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
          'Daily MCQ Tests',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Create, schedule and manage daily MCQ tests for students.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _createButton() {
    return ElevatedButton.icon(
      onPressed: _showCreateTestDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Create MCQ Test'),
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
      items: const ['All', 'Draft', 'Scheduled', 'Published', 'Completed'],
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
              'Total Tests',
              '$totalTests',
              Icons.quiz_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Published',
              '$publishedTests',
              Icons.public_outlined,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              'Scheduled',
              '$scheduledTests',
              Icons.schedule_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _summaryCard(
              'Total Attempts',
              '$totalAttempts',
              Icons.people_outline,
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

  Widget _buildTestList() {
    final data = filteredTests;

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
                'MCQ Test Schedule',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${data.length} tests',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          data.isEmpty ? _emptyState() : _testTable(data),
        ],
      ),
    );
  }

  Widget _testTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        horizontalMargin: 8,
        dataRowMinHeight: 76,
        dataRowMaxHeight: 86,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Test')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Duration')),
          DataColumn(label: Text('Questions')),
          DataColumn(label: Text('Attempts')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((test) {
          return DataRow(
            cells: [
              DataCell(_testNameCell(test)),
              DataCell(
                Text(test['class'], style: const TextStyle(fontSize: 12)),
              ),
              DataCell(
                Text(test['date'], style: const TextStyle(fontSize: 11)),
              ),
              DataCell(
                Text(test['time'], style: const TextStyle(fontSize: 11)),
              ),
              DataCell(
                Text(
                  '${test['duration']} min',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(
                Text(
                  '${test['questions']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  '${test['attempts']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              DataCell(_statusBadge(test['status'])),
              DataCell(_actionButtons(test)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _testNameCell(Map<String, dynamic> test) {
    return SizedBox(
      width: 235,
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              size: 21,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  test['id'],
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
      case 'Published':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;

      case 'Scheduled':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
        break;

      case 'Completed':
        color = const Color(0xFF6B7280);
        background = const Color(0xFFF3F4F6);
        break;

      default:
        color = const Color(0xFF7C3AED);
        background = const Color(0xFFF3E8FF);
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

  Widget _actionButtons(Map<String, dynamic> test) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View Details',
          onPressed: () {
            _showTestDetails(test);
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        IconButton(
          tooltip: 'Manage Questions',
          onPressed: () {
            _openQuestionManager(test);
          },
          icon: const Icon(
            Icons.list_alt_outlined,
            size: 18,
            color: Color(0xFF2563EB),
          ),
        ),
        if (test['status'] == 'Draft')
          IconButton(
            tooltip: 'Publish',
            onPressed: () {
              _publishTest(test);
            },
            icon: const Icon(
              Icons.publish_outlined,
              size: 18,
              color: Color(0xFF15803D),
            ),
          ),
        if (test['status'] == 'Published' || test['status'] == 'Completed')
          IconButton(
            tooltip: 'Results',
            onPressed: () {
              _showResults(test);
            },
            icon: const Icon(
              Icons.bar_chart_outlined,
              size: 18,
              color: Color(0xFF7C3AED),
            ),
          ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteTest(test);
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
            Icon(Icons.quiz_outlined, size: 52, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text(
              'No MCQ tests found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your filters or create a new test.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MCQ QUESTION MANAGER
// ============================================================

class McqQuestionManagerScreen extends StatefulWidget {
  final Map<String, dynamic> test;

  const McqQuestionManagerScreen({super.key, required this.test});

  @override
  State<McqQuestionManagerScreen> createState() =>
      _McqQuestionManagerScreenState();
}

class _McqQuestionManagerScreenState extends State<McqQuestionManagerScreen> {
  final List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();

    // Dummy questions for the existing test.
    if (widget.test['questions'] > 0) {
      questions.addAll([
        {
          'question': 'Which planet is known as the Red Planet?',
          'options': ['Earth', 'Mars', 'Jupiter', 'Venus'],
          'answer': 1,
          'marks': 1,
        },
        {
          'question': 'How many days are there in a week?',
          'options': ['5', '6', '7', '8'],
          'answer': 2,
          'marks': 1,
        },
      ]);
    }
  }

  void _showAddQuestionDialog() {
    final questionController = TextEditingController();

    final optionControllers = List.generate(4, (_) => TextEditingController());

    int correctAnswer = 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add MCQ Question',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: questionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Question',
                          hintText: 'Enter your question...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: index,
                                groupValue: correctAnswer,
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      correctAnswer = value;
                                    });
                                  }
                                },
                              ),
                              Expanded(
                                child: TextField(
                                  controller: optionControllers[index],
                                  decoration: InputDecoration(
                                    labelText:
                                        'Option ${String.fromCharCode(65 + index)}',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 5),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select the radio button beside the correct answer.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
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
                    if (questionController.text.trim().isEmpty) {
                      return;
                    }

                    final options = optionControllers
                        .map((controller) => controller.text.trim())
                        .toList();

                    if (options.any((option) => option.isEmpty)) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all four options.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      questions.add({
                        'question': questionController.text.trim(),
                        'options': options,
                        'answer': correctAnswer,
                        'marks': 1,
                      });

                      widget.test['questions'] = questions.length;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Question added successfully.'),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteQuestion(int index) {
    setState(() {
      questions.removeAt(index);
      widget.test['questions'] = questions.length;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Question removed.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          widget.test['title'],
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestHeader(),
            const SizedBox(height: 24),
            _buildQuestionList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddQuestionDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
      ),
    );
  }

  Widget _buildTestHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _testInfo(),
                const SizedBox(height: 16),
                _questionCount(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _testInfo()),
              _questionCount(),
            ],
          );
        },
      ),
    );
  }

  Widget _testInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.test['title'],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _infoChip(Icons.school_outlined, widget.test['class']),
            _infoChip(Icons.calendar_today_outlined, widget.test['date']),
            _infoChip(Icons.access_time_outlined, widget.test['time']),
            _infoChip(
              Icons.timer_outlined,
              '${widget.test['duration']} minutes',
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _questionCount() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            '${questions.length}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          const Text(
            'Questions',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList() {
    if (questions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          children: [
            Icon(Icons.quiz_outlined, size: 58, color: Color(0xFFD1D5DB)),
            SizedBox(height: 15),
            Text(
              'No questions added yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Click "Add Question" to create the first MCQ.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(questions.length, (index) {
        final question = questions[index];

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      question['question'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete Question',
                    onPressed: () {
                      _deleteQuestion(index);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 19,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(question['options'].length, (optionIndex) {
                final isCorrect = optionIndex == question['answer'];

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isCorrect
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 26,
                        width: 26,
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? const Color(0xFFDCFCE7)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCorrect
                                ? const Color(0xFF15803D)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + optionIndex),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCorrect
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question['options'][optionIndex],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      if (isCorrect)
                        const Text(
                          'Correct Answer',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15803D),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }),
    );
  }
}
