import 'package:flutter/material.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String selectedClass = 'Class 1 - A';

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  final List<String> periods = [
    '09:00 - 09:40',
    '09:40 - 10:20',
    '10:20 - 11:00',
    '11:20 - 12:00',
    '12:00 - 12:40',
    '01:40 - 02:20',
    '02:20 - 03:00',
  ];

  final Map<String, List<Map<String, String>>> timetable = {
    'Monday': [
      {
        'subject': 'Mathematics',
        'teacher': 'Priya Teacher',
        'room': 'Room 101',
      },
      {'subject': 'English', 'teacher': 'Anitha Teacher', 'room': 'Room 101'},
      {'subject': 'Science', 'teacher': 'Rahul Teacher', 'room': 'Room 101'},
      {'subject': 'Telugu', 'teacher': 'Lakshmi Teacher', 'room': 'Room 101'},
      {'subject': 'Lunch Break', 'teacher': '', 'room': ''},
      {'subject': 'Drawing', 'teacher': 'Kavya Teacher', 'room': 'Art Room'},
      {'subject': 'Games', 'teacher': 'Ravi Teacher', 'room': 'Play Ground'},
    ],
    'Tuesday': [
      {'subject': 'English', 'teacher': 'Anitha Teacher', 'room': 'Room 101'},
      {
        'subject': 'Mathematics',
        'teacher': 'Priya Teacher',
        'room': 'Room 101',
      },
      {'subject': 'Telugu', 'teacher': 'Lakshmi Teacher', 'room': 'Room 101'},
      {'subject': 'Science', 'teacher': 'Rahul Teacher', 'room': 'Room 101'},
      {'subject': 'Lunch Break', 'teacher': '', 'room': ''},
      {
        'subject': 'Computer',
        'teacher': 'Suresh Teacher',
        'room': 'Computer Lab',
      },
      {
        'subject': 'Moral Science',
        'teacher': 'Priya Teacher',
        'room': 'Room 101',
      },
    ],
    'Wednesday': [
      {'subject': 'Science', 'teacher': 'Rahul Teacher', 'room': 'Room 101'},
      {'subject': 'Telugu', 'teacher': 'Lakshmi Teacher', 'room': 'Room 101'},
      {
        'subject': 'Mathematics',
        'teacher': 'Priya Teacher',
        'room': 'Room 101',
      },
      {'subject': 'English', 'teacher': 'Anitha Teacher', 'room': 'Room 101'},
      {'subject': 'Lunch Break', 'teacher': '', 'room': ''},
      {'subject': 'Games', 'teacher': 'Ravi Teacher', 'room': 'Play Ground'},
      {'subject': 'Drawing', 'teacher': 'Kavya Teacher', 'room': 'Art Room'},
    ],
    'Thursday': [
      {
        'subject': 'Mathematics',
        'teacher': 'Priya Teacher',
        'room': 'Room 101',
      },
      {'subject': 'Science', 'teacher': 'Rahul Teacher', 'room': 'Room 101'},
      {'subject': 'English', 'teacher': 'Anitha Teacher', 'room': 'Room 101'},
      {
        'subject': 'Computer',
        'teacher': 'Suresh Teacher',
        'room': 'Computer Lab',
      },
      {'subject': 'Lunch Break', 'teacher': '', 'room': ''},
      {'subject': 'Telugu', 'teacher': 'Lakshmi Teacher', 'room': 'Room 101'},
      {'subject': 'Library', 'teacher': 'Anitha Teacher', 'room': 'Library'},
    ],
    'Friday': [
      {'subject': 'English', 'teacher': 'Anitha Teacher', 'room': 'Room 101'},
      {
        'subject': 'Mathematics',
        'teacher': 'Priya Teacher',
        'room': 'Room 101',
      },
      {'subject': 'Science', 'teacher': 'Rahul Teacher', 'room': 'Room 101'},
      {'subject': 'Telugu', 'teacher': 'Lakshmi Teacher', 'room': 'Room 101'},
      {'subject': 'Lunch Break', 'teacher': '', 'room': ''},
      {'subject': 'Music', 'teacher': 'Kavya Teacher', 'room': 'Music Room'},
      {'subject': 'Games', 'teacher': 'Ravi Teacher', 'room': 'Play Ground'},
    ],
    'Saturday': [
      {
        'subject': 'Mathematics',
        'teacher': 'Priya Teacher',
        'room': 'Room 101',
      },
      {'subject': 'English', 'teacher': 'Anitha Teacher', 'room': 'Room 101'},
      {
        'subject': 'Activity',
        'teacher': 'Kavya Teacher',
        'room': 'Activity Room',
      },
      {
        'subject': 'General Knowledge',
        'teacher': 'Rahul Teacher',
        'room': 'Room 101',
      },
      {'subject': 'Lunch Break', 'teacher': '', 'room': ''},
      {
        'subject': 'Art & Craft',
        'teacher': 'Kavya Teacher',
        'room': 'Art Room',
      },
      {'subject': 'Early Dispersal', 'teacher': '', 'room': ''},
    ],
  };

  void _showAddPeriodDialog({String? day, int? periodIndex}) {
    String selectedSubject = 'Mathematics';
    String selectedTeacher = 'Priya Teacher';
    String selectedRoom = 'Room 101';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Timetable Period',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 430,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: day ?? 'Monday',
                      decoration: _inputDecoration('Day'),
                      items: days.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedSubject,
                      decoration: _inputDecoration('Subject'),
                      items:
                          const [
                            'Mathematics',
                            'English',
                            'Science',
                            'Telugu',
                            'Computer',
                            'Drawing',
                            'Games',
                            'Music',
                            'Library',
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedSubject = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedTeacher,
                      decoration: _inputDecoration('Teacher'),
                      items:
                          const [
                            'Priya Teacher',
                            'Anitha Teacher',
                            'Rahul Teacher',
                            'Lakshmi Teacher',
                            'Suresh Teacher',
                            'Kavya Teacher',
                            'Ravi Teacher',
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedTeacher = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedRoom,
                      decoration: _inputDecoration('Room'),
                      items:
                          const [
                            'Room 101',
                            'Room 102',
                            'Room 103',
                            'Computer Lab',
                            'Art Room',
                            'Music Room',
                            'Library',
                            'Play Ground',
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRoom = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Period added successfully.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Period'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  void _showPeriodDetails(String day, int index, Map<String, String> period) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            period['subject'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Day', day),
              _detailRow('Time', periods[index]),
              _detailRow(
                'Teacher',
                period['teacher']!.isEmpty ? '—' : period['teacher']!,
              ),
              _detailRow(
                'Room',
                period['room']!.isEmpty ? '—' : period['room']!,
              ),
            ],
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
            width: 75,
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
            _buildClassSelector(),
            const SizedBox(height: 24),
            _buildStats(),
            const SizedBox(height: 24),
            _buildTimetable(),
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
          'Timetable',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage class schedules, subjects and teacher periods.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _addButton() {
    return ElevatedButton.icon(
      onPressed: () => _showAddPeriodDialog(),
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Add Period'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildClassSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          const Text(
            'Select Class',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedClass,
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
                        child: Text(item, style: const TextStyle(fontSize: 12)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
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
            _statCard(
              'School Days',
              '6',
              Icons.calendar_month_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _statCard(
              'Periods / Day',
              '7',
              Icons.schedule_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
            ),
            _statCard(
              'Subjects',
              '8',
              Icons.menu_book_outlined,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _statCard(
              'Free Periods',
              '2',
              Icons.free_breakfast_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
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

  Widget _buildTimetable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_view_week_outlined,
                color: Color(0xFF2563EB),
                size: 21,
              ),
              const SizedBox(width: 9),
              Text(
                '$selectedClass — Weekly Timetable',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    const double timeWidth = 120;
    const double dayWidth = 175;

    return Column(
      children: [
        Row(
          children: [
            _headerCell('Time', timeWidth),
            ...days.map((day) => _headerCell(day, dayWidth)),
          ],
        ),
        ...List.generate(periods.length, (periodIndex) {
          return Row(
            children: [
              _timeCell(periods[periodIndex], timeWidth),
              ...days.map((day) {
                final period = timetable[day]![periodIndex];

                return _periodCell(day, periodIndex, period, dayWidth);
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _headerCell(String text, double width) {
    return Container(
      width: width,
      height: 52,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _timeCell(String time, double width) {
    return Container(
      width: width,
      height: 100,
      margin: const EdgeInsets.all(1),
      decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
      alignment: Alignment.center,
      child: Text(
        time,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _periodCell(
    String day,
    int periodIndex,
    Map<String, String> period,
    double width,
  ) {
    final subject = period['subject'] ?? '';

    final isLunch = subject == 'Lunch Break';
    final isSpecial =
        subject == 'Games' ||
        subject == 'Drawing' ||
        subject == 'Music' ||
        subject == 'Art & Craft' ||
        subject == 'Activity';

    Color background = Colors.white;
    Color accent = const Color(0xFF2563EB);

    if (isLunch) {
      background = const Color(0xFFFFFBEB);
      accent = const Color(0xFFD97706);
    } else if (isSpecial) {
      background = const Color(0xFFF5F3FF);
      accent = const Color(0xFF7C3AED);
    }

    return InkWell(
      onTap: () {
        _showPeriodDetails(day, periodIndex, period);
      },
      child: Container(
        width: width,
        height: 100,
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 28,
              width: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isLunch ? Icons.restaurant_outlined : Icons.menu_book_outlined,
                size: 15,
                color: accent,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            if (period['teacher']!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                period['teacher']!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
