import 'package:flutter/material.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  String selectedClass = 'All Classes';
  String selectedSubject = 'All Subjects';
  String selectedStatus = 'All';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> homeworkList = [
    {
      'id': 'HW001',
      'title': 'Addition and Subtraction',
      'subject': 'Mathematics',
      'class': 'Class 1 - A',
      'teacher': 'Priya Teacher',
      'assignedDate': '10 Aug 2026',
      'dueDate': '12 Aug 2026',
      'status': 'Published',
      'submissions': 24,
      'totalStudents': 30,
    },
    {
      'id': 'HW002',
      'title': 'Read Chapter 3',
      'subject': 'English',
      'class': 'Class 2 - A',
      'teacher': 'Anitha Teacher',
      'assignedDate': '10 Aug 2026',
      'dueDate': '13 Aug 2026',
      'status': 'Published',
      'submissions': 28,
      'totalStudents': 32,
    },
    {
      'id': 'HW003',
      'title': 'Parts of a Plant',
      'subject': 'Science',
      'class': 'Class 3 - A',
      'teacher': 'Rahul Teacher',
      'assignedDate': '09 Aug 2026',
      'dueDate': '11 Aug 2026',
      'status': 'Published',
      'submissions': 19,
      'totalStudents': 28,
    },
    {
      'id': 'HW004',
      'title': 'Telugu Guninthalu',
      'subject': 'Telugu',
      'class': 'Class 1 - B',
      'teacher': 'Lakshmi Teacher',
      'assignedDate': '08 Aug 2026',
      'dueDate': '12 Aug 2026',
      'status': 'Draft',
      'submissions': 0,
      'totalStudents': 29,
    },
    {
      'id': 'HW005',
      'title': 'Shapes Around Us',
      'subject': 'Mathematics',
      'class': 'Class 2 - B',
      'teacher': 'Suresh Teacher',
      'assignedDate': '07 Aug 2026',
      'dueDate': '10 Aug 2026',
      'status': 'Closed',
      'submissions': 30,
      'totalStudents': 30,
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredHomework {
    return homeworkList.where((homework) {
      final query = searchQuery.toLowerCase().trim();

      final matchesSearch =
          query.isEmpty ||
          homework['title'].toString().toLowerCase().contains(query) ||
          homework['subject'].toString().toLowerCase().contains(query) ||
          homework['class'].toString().toLowerCase().contains(query);

      final matchesClass =
          selectedClass == 'All Classes' || homework['class'] == selectedClass;

      final matchesSubject =
          selectedSubject == 'All Subjects' ||
          homework['subject'] == selectedSubject;

      final matchesStatus =
          selectedStatus == 'All' || homework['status'] == selectedStatus;

      return matchesSearch && matchesClass && matchesSubject && matchesStatus;
    }).toList();
  }

  int get totalHomework => homeworkList.length;

  int get publishedCount =>
      homeworkList.where((item) => item['status'] == 'Published').length;

  int get draftCount =>
      homeworkList.where((item) => item['status'] == 'Draft').length;

  int get closedCount =>
      homeworkList.where((item) => item['status'] == 'Closed').length;

  double get submissionPercentage {
    int submitted = 0;
    int total = 0;

    for (final homework in homeworkList) {
      submitted += homework['submissions'] as int;
      total += homework['totalStudents'] as int;
    }

    if (total == 0) return 0;

    return (submitted / total) * 100;
  }

  void _showAddHomeworkDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    String dialogClass = 'Class 1 - A';
    String dialogSubject = 'Mathematics';
    String dialogDueDate = '15 Aug 2026';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create Homework',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dialogTextField(
                        controller: titleController,
                        label: 'Homework Title',
                        hint: 'Enter homework title',
                      ),
                      const SizedBox(height: 14),
                      _dialogTextField(
                        controller: descriptionController,
                        label: 'Description',
                        hint: 'Enter homework instructions',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: dialogClass,
                        decoration: _dialogDecoration('Class'),
                        items:
                            const [
                              'Class 1 - A',
                              'Class 1 - B',
                              'Class 2 - A',
                              'Class 2 - B',
                              'Class 3 - A',
                              'Class 4 - A',
                              'Class 5 - A',
                            ].map((value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              dialogClass = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: dialogSubject,
                        decoration: _dialogDecoration('Subject'),
                        items:
                            const [
                              'Mathematics',
                              'English',
                              'Science',
                              'Telugu',
                              'Social Studies',
                            ].map((value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              dialogSubject = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        readOnly: true,
                        initialValue: dialogDueDate,
                        decoration: _dialogDecoration('Due Date').copyWith(
                          suffixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                          ),
                        ),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime(2026, 8, 15),
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              dialogDueDate =
                                  '${picked.day} Aug ${picked.year}';
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      homeworkList.insert(0, {
                        'id': 'HW${homeworkList.length + 1}'.padLeft(3, '0'),
                        'title': titleController.text.trim(),
                        'subject': dialogSubject,
                        'class': dialogClass,
                        'teacher': 'Admin',
                        'assignedDate': '10 Aug 2026',
                        'dueDate': dialogDueDate,
                        'status': 'Draft',
                        'submissions': 0,
                        'totalStudents': 30,
                      });
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Homework created as draft.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Homework'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      ),
    );
  }

  void _deleteHomework(Map<String, dynamic> homework) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Homework?'),
          content: Text(
            'Are you sure you want to delete '
            '"${homework['title']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  homeworkList.remove(homework);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Homework deleted successfully.'),
                  ),
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

  void _publishHomework(Map<String, dynamic> homework) {
    setState(() {
      homework['status'] = 'Published';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Homework published successfully.'),
        backgroundColor: Color(0xFF15803D),
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
            _buildHomeworkTable(),
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
            children: [_headerText(), const SizedBox(height: 16), _addButton()],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            _addButton(),
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
          'Homework',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Create, publish and manage student homework.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _addButton() {
    return ElevatedButton.icon(
      onPressed: _showAddHomeworkDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Create Homework'),
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
          if (constraints.maxWidth < 750) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _classDropdown(),
                const SizedBox(height: 12),
                _subjectDropdown(),
                const SizedBox(height: 12),
                _statusDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: _searchBox()),
              const SizedBox(width: 12),
              Expanded(child: _classDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _subjectDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _statusDropdown()),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search homework...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 19),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _classDropdown() {
    return _dropdownContainer(
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

  Widget _subjectDropdown() {
    return _dropdownContainer(
      value: selectedSubject,
      items: const [
        'All Subjects',
        'Mathematics',
        'English',
        'Science',
        'Telugu',
        'Social Studies',
      ],
      onChanged: (value) {
        setState(() {
          selectedSubject = value!;
        });
      },
    );
  }

  Widget _statusDropdown() {
    return _dropdownContainer(
      value: selectedStatus,
      items: const ['All', 'Published', 'Draft', 'Closed'],
      onChanged: (value) {
        setState(() {
          selectedStatus = value!;
        });
      },
    );
  }

  Widget _dropdownContainer({
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
          isExpanded: true,
          value: value,
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

        if (constraints.maxWidth < 1000) {
          columns = 2;
        }

        if (constraints.maxWidth < 600) {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4 : 2.4,
          children: [
            _summaryCard(
              'Total Homework',
              '$totalHomework',
              Icons.menu_book_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Published',
              '$publishedCount',
              Icons.publish_outlined,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              'Drafts',
              '$draftCount',
              Icons.edit_note_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _summaryCard(
              'Submission Rate',
              '${submissionPercentage.toStringAsFixed(0)}%',
              Icons.bar_chart_outlined,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
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

  Widget _buildHomeworkTable() {
    final data = filteredHomework;

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
                'Homework List',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Text(
                '${data.length} records',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          data.isEmpty ? _emptyState() : _table(data),
        ],
      ),
    );
  }

  Widget _table(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        horizontalMargin: 10,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 82,
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        columns: const [
          DataColumn(label: Text('Homework')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Subject')),
          DataColumn(label: Text('Due Date')),
          DataColumn(label: Text('Submissions')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((homework) {
          return DataRow(
            cells: [
              DataCell(_homeworkCell(homework)),
              DataCell(
                Text(homework['class'], style: const TextStyle(fontSize: 12)),
              ),
              DataCell(_subjectBadge(homework['subject'])),
              DataCell(
                Text(homework['dueDate'], style: const TextStyle(fontSize: 12)),
              ),
              DataCell(_submissionCell(homework)),
              DataCell(_statusBadge(homework['status'])),
              DataCell(_actionButtons(homework)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _homeworkCell(Map<String, dynamic> homework) {
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
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homework['title'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  homework['teacher'],
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

  Widget _subjectBadge(String subject) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        subject,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _submissionCell(Map<String, dynamic> homework) {
    final submitted = homework['submissions'] as int;
    final total = homework['totalStudents'] as int;

    final percentage = total == 0 ? 0 : (submitted / total * 100);

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$submitted / $total',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 5,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
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

      case 'Draft':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
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

  Widget _actionButtons(Map<String, dynamic> homework) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () {
            _showHomeworkDetails(homework);
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        if (homework['status'] == 'Draft')
          IconButton(
            tooltip: 'Publish',
            onPressed: () {
              _publishHomework(homework);
            },
            icon: const Icon(
              Icons.publish_outlined,
              size: 18,
              color: Color(0xFF15803D),
            ),
          ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteHomework(homework);
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

  void _showHomeworkDetails(Map<String, dynamic> homework) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            homework['title'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Class', homework['class']),
                _detailRow('Subject', homework['subject']),
                _detailRow('Teacher', homework['teacher']),
                _detailRow('Assigned Date', homework['assignedDate']),
                _detailRow('Due Date', homework['dueDate']),
                _detailRow(
                  'Submissions',
                  '${homework['submissions']} / '
                      '${homework['totalStudents']}',
                ),
                _detailRow('Status', homework['status']),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 110,
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

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 50, color: Color(0xFFD1D5DB)),
            SizedBox(height: 12),
            Text(
              'No homework found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your filters or create new homework.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
