import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  String selectedClass = 'Class 1 - A';
  String selectedStatusFilter = 'All';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> students = [
    {
      'id': 'STU001',
      'name': 'Aarav Kumar',
      'rollNo': '01',
      'status': 'Present',
    },
    {
      'id': 'STU002',
      'name': 'Ananya Reddy',
      'rollNo': '02',
      'status': 'Present',
    },
    {'id': 'STU003', 'name': 'Vihan Rao', 'rollNo': '03', 'status': 'Absent'},
    {
      'id': 'STU004',
      'name': 'Diya Sharma',
      'rollNo': '04',
      'status': 'Present',
    },
    {'id': 'STU005', 'name': 'Arjun Babu', 'rollNo': '05', 'status': 'Late'},
    {'id': 'STU006', 'name': 'Sai Reddy', 'rollNo': '06', 'status': 'Present'},
    {
      'id': 'STU007',
      'name': 'Krishna Kumar',
      'rollNo': '07',
      'status': 'Present',
    },
    {'id': 'STU008', 'name': 'Rahul Verma', 'rollNo': '08', 'status': 'Absent'},
    {
      'id': 'STU009',
      'name': 'Saanvi Patel',
      'rollNo': '09',
      'status': 'Present',
    },
    {'id': 'STU010', 'name': 'Rohan Singh', 'rollNo': '10', 'status': 'Late'},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredStudents {
    return students.where((student) {
      final query = searchQuery.toLowerCase().trim();

      final matchesSearch =
          query.isEmpty ||
          student['name'].toString().toLowerCase().contains(query) ||
          student['rollNo'].toString().contains(query) ||
          student['id'].toString().toLowerCase().contains(query);

      final matchesStatus =
          selectedStatusFilter == 'All' ||
          student['status'] == selectedStatusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get presentCount =>
      students.where((student) => student['status'] == 'Present').length;

  int get absentCount =>
      students.where((student) => student['status'] == 'Absent').length;

  int get lateCount =>
      students.where((student) => student['status'] == 'Late').length;

  double get attendancePercentage {
    if (students.isEmpty) return 0;

    final attended = presentCount + lateCount;

    return (attended / students.length) * 100;
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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _changeAttendance(Map<String, dynamic> student, String status) {
    setState(() {
      student['status'] = status;
    });
  }

  void _markAll(String status) {
    setState(() {
      for (final student in students) {
        student['status'] = status;
      }
    });
  }

  void _saveAttendance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance saved successfully.'),
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
            _buildControls(),
            const SizedBox(height: 24),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildAttendanceTable(),
          ],
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
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderText(),
              const SizedBox(height: 16),
              _buildSaveButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildHeaderText()),
            _buildSaveButton(),
          ],
        );
      },
    );
  }

  Widget _buildHeaderText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage daily student attendance.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveAttendance,
      icon: const Icon(Icons.save_outlined, size: 18),
      label: const Text('Save Attendance'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // CONTROLS
  // ============================================================

  Widget _buildControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final small = constraints.maxWidth < 750;

          if (small) {
            return Column(
              children: [
                _dateSelector(),
                const SizedBox(height: 14),
                _classSelector(),
                const SizedBox(height: 14),
                _searchBox(),
              ],
            );
          }

          return Row(
            children: [
              _dateSelector(),
              const SizedBox(width: 14),
              _classSelector(),
              const SizedBox(width: 14),
              Expanded(child: _searchBox()),
            ],
          );
        },
      ),
    );
  }

  Widget _dateSelector() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 9),
            Text(
              _formatDate(selectedDate),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classSelector() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedClass,
          icon: const Icon(Icons.keyboard_arrow_down, size: 19),
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
                  child: Text(value, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedClass = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
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
          hintText: 'Search student by name or roll number...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF6B7280)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns;

        if (constraints.maxWidth >= 1000) {
          columns = 4;
        } else if (constraints.maxWidth >= 600) {
          columns = 2;
        } else {
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
              title: 'Present',
              value: '$presentCount',
              icon: Icons.check_circle_outline,
              color: const Color(0xFF16A34A),
              background: const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              title: 'Absent',
              value: '$absentCount',
              icon: Icons.cancel_outlined,
              color: const Color(0xFFDC2626),
              background: const Color(0xFFFEF2F2),
            ),
            _summaryCard(
              title: 'Late',
              value: '$lateCount',
              icon: Icons.access_time_outlined,
              color: const Color(0xFFD97706),
              background: const Color(0xFFFFFBEB),
            ),
            _summaryCard(
              title: 'Attendance',
              value: '${attendancePercentage.toStringAsFixed(0)}%',
              icon: Icons.bar_chart_outlined,
              color: const Color(0xFF2563EB),
              background: const Color(0xFFEFF6FF),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
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
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
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
  // ATTENDANCE TABLE
  // ============================================================

  Widget _buildAttendanceTable() {
    final data = filteredStudents;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTableHeader(),
          const SizedBox(height: 16),
          data.isEmpty ? _buildEmptyState() : _buildTable(data),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Attendance',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              _filterDropdown(),
            ],
          );
        }

        return Row(
          children: [
            const Text(
              'Student Attendance',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const Spacer(),
            const Text(
              'Filter:',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 8),
            _filterDropdown(),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _markAll('Present'),
              icon: const Icon(Icons.done_all, size: 17),
              label: const Text('Mark All Present'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF15803D),
                side: const BorderSide(color: Color(0xFFBBF7D0)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatusFilter,
          items: const ['All', 'Present', 'Absent', 'Late'].map((value) {
            return DropdownMenuItem(
              value: value,
              child: Text(value, style: const TextStyle(fontSize: 12)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                selectedStatusFilter = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        dataRowMinHeight: 70,
        dataRowMaxHeight: 78,
        columnSpacing: 30,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('Roll No.')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Mark Attendance')),
        ],
        rows: data.map((student) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  student['rollNo'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(_studentCell(student)),
              DataCell(_statusBadge(student['status'])),
              DataCell(_attendanceButtons(student)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _studentCell(Map<String, dynamic> student) {
    final name = student['name'].toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              name[0],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              student['id'],
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    Color background;

    switch (status) {
      case 'Present':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;

      case 'Absent':
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEE2E2);
        break;

      default:
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _attendanceButtons(Map<String, dynamic> student) {
    final currentStatus = student['status'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _attendanceButton(
          label: 'Present',
          shortLabel: 'P',
          status: 'Present',
          currentStatus: currentStatus,
          color: const Color(0xFF15803D),
          background: const Color(0xFFDCFCE7),
        ),
        const SizedBox(width: 6),
        _attendanceButton(
          label: 'Absent',
          shortLabel: 'A',
          status: 'Absent',
          currentStatus: currentStatus,
          color: const Color(0xFFDC2626),
          background: const Color(0xFFFEE2E2),
        ),
        const SizedBox(width: 6),
        _attendanceButton(
          label: 'Late',
          shortLabel: 'L',
          status: 'Late',
          currentStatus: currentStatus,
          color: const Color(0xFFD97706),
          background: const Color(0xFFFEF3C7),
        ),
      ],
    );
  }

  Widget _attendanceButton({
    required String label,
    required String shortLabel,
    required String status,
    required String currentStatus,
    required Color color,
    required Color background,
  }) {
    final selected = currentStatus == status;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () {
          final student = students.firstWhere(
            (student) => student['status'] == currentStatus,
            orElse: () => students.first,
          );

          // This button is replaced by the actual
          // student-specific handler in the table.
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: selected ? background : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? color : const Color(0xFFE5E7EB),
            ),
          ),
          child: Center(
            child: Text(
              shortLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: selected ? color : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.event_busy_outlined, size: 50, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing your search or filter.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
