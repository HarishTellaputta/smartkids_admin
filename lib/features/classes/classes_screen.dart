import 'package:flutter/material.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<Map<String, dynamic>> classes = [
    {
      'id': 'CLS001',
      'className': 'Class 1',
      'section': 'A',
      'classTeacher': 'Lakshmi Devi',
      'room': '101',
      'students': 28,
      'capacity': 35,
      'status': 'Active',
    },
    {
      'id': 'CLS002',
      'className': 'Class 1',
      'section': 'B',
      'classTeacher': 'Ravi Kumar',
      'room': '102',
      'students': 30,
      'capacity': 35,
      'status': 'Active',
    },
    {
      'id': 'CLS003',
      'className': 'Class 2',
      'section': 'A',
      'classTeacher': 'Anitha Reddy',
      'room': '201',
      'students': 32,
      'capacity': 35,
      'status': 'Active',
    },
    {
      'id': 'CLS004',
      'className': 'Class 3',
      'section': 'A',
      'classTeacher': 'Mahesh Babu',
      'room': '301',
      'students': 29,
      'capacity': 35,
      'status': 'Active',
    },
    {
      'id': 'CLS005',
      'className': 'Class 4',
      'section': 'A',
      'classTeacher': 'Priya Sharma',
      'room': '401',
      'students': 31,
      'capacity': 35,
      'status': 'Active',
    },
    {
      'id': 'CLS006',
      'className': 'Class 5',
      'section': 'A',
      'classTeacher': 'Srinivas Rao',
      'room': '501',
      'students': 34,
      'capacity': 35,
      'status': 'Active',
    },
    {
      'id': 'CLS007',
      'className': 'Class 6',
      'section': 'A',
      'classTeacher': 'Ravi Kumar',
      'room': '601',
      'students': 27,
      'capacity': 35,
      'status': 'Active',
    },
    {
      'id': 'CLS008',
      'className': 'Class 7',
      'section': 'A',
      'classTeacher': 'Anitha Reddy',
      'room': '701',
      'students': 26,
      'capacity': 35,
      'status': 'Active',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredClasses {
    if (_searchQuery.trim().isEmpty) {
      return classes;
    }

    final query = _searchQuery.toLowerCase().trim();

    return classes.where((item) {
      return item['className'].toString().toLowerCase().contains(query) ||
          item['section'].toString().toLowerCase().contains(query) ||
          item['classTeacher'].toString().toLowerCase().contains(query) ||
          item['room'].toString().toLowerCase().contains(query) ||
          item['id'].toString().toLowerCase().contains(query);
    }).toList();
  }

  int get totalStudents {
    return classes.fold(0, (sum, item) => sum + (item['students'] as int));
  }

  int get totalCapacity {
    return classes.fold(0, (sum, item) => sum + (item['capacity'] as int));
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
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildClassesTable(),
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
        final isSmall = constraints.maxWidth < 650;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderText(),
              const SizedBox(height: 16),
              _buildAddClassButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildHeaderText()),
            _buildAddClassButton(),
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
          'Classes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage classes, sections, classrooms and class teachers.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAddClassButton() {
    return ElevatedButton.icon(
      onPressed: _showAddClassDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Add Class'),
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
  // SUMMARY CARDS
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

        final availableSeats = totalCapacity - totalStudents;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4.0 : 2.5,
          children: [
            _summaryCard(
              title: 'Total Classes',
              value: '${classes.length}',
              icon: Icons.class_outlined,
            ),
            _summaryCard(
              title: 'Total Students',
              value: '$totalStudents',
              icon: Icons.people_outline,
            ),
            _summaryCard(
              title: 'Classrooms',
              value: '${classes.length}',
              icon: Icons.meeting_room_outlined,
            ),
            _summaryCard(
              title: 'Available Seats',
              value: '$availableSeats',
              icon: Icons.event_seat_outlined,
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _buildClassesTable() {
    final data = filteredClasses;

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
          _buildTableToolbar(),
          const SizedBox(height: 20),
          data.isEmpty ? _buildEmptyState() : _buildTable(data),
        ],
      ),
    );
  }

  Widget _buildTableToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        final searchBox = Container(
          height: 44,
          width: isSmall ? double.infinity : 300,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: const InputDecoration(
              hintText: 'Search classes...',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Color(0xFF6B7280),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

        final filterButton = OutlinedButton.icon(
          onPressed: _showFilterDialog,
          icon: const Icon(Icons.filter_list, size: 18),
          label: const Text('Filter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        );

        if (isSmall) {
          return Column(
            children: [
              searchBox,
              const SizedBox(height: 12),
              Row(
                children: [
                  filterButton,
                  const Spacer(),
                  Text(
                    '${filteredClasses.length} classes',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            searchBox,
            const SizedBox(width: 12),
            filterButton,
            const Spacer(),
            Text(
              '${filteredClasses.length} classes',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FAFB)),
        dataRowMinHeight: 65,
        dataRowMaxHeight: 75,
        columnSpacing: 28,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Section')),
          DataColumn(label: Text('Class Teacher')),
          DataColumn(label: Text('Room')),
          DataColumn(label: Text('Students')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: data.map((item) {
          return DataRow(
            cells: [
              DataCell(_classCell(item)),
              DataCell(_sectionBadge(item['section'])),
              DataCell(
                Text(
                  item['classTeacher'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 17,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['room'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(_studentCountCell(item)),
              DataCell(_statusBadge(item['status'])),
              DataCell(
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleClassAction(value, item);
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(value: 'view', child: Text('View')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ];
                  },
                  child: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _classCell(Map<String, dynamic> item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Color(0xFF2563EB),
            size: 21,
          ),
        ),
        const SizedBox(width: 11),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['className'],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item['id'],
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionBadge(String section) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Section $section',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7E22CE),
        ),
      ),
    );
  }

  Widget _studentCountCell(Map<String, dynamic> item) {
    final students = item['students'] as int;
    final capacity = item['capacity'] as int;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$students',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          ' / $capacity',
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final active = status == 'Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF15803D) : const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 50, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text(
            'No classes found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing your search.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADD CLASS
  // ============================================================

  void _showAddClassDialog() {
    final formKey = GlobalKey<FormState>();

    String selectedClass = 'Class 1';
    String selectedSection = 'A';
    String selectedTeacher = 'Lakshmi Devi';
    String selectedStatus = 'Active';

    final roomController = TextEditingController();
    final capacityController = TextEditingController(text: '35');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 600,
                  maxHeight: 650,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add_business_outlined,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add New Class',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Create a class and assign its teacher.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        _sectionTitle('Class Information'),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedClass,
                          decoration: _inputDecoration(
                            label: 'Class',
                            icon: Icons.school_outlined,
                          ),
                          items: List.generate(
                            10,
                            (index) => DropdownMenuItem(
                              value: 'Class ${index + 1}',
                              child: Text('Class ${index + 1}'),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedClass = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 500) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedSection,
                                      decoration: _inputDecoration(
                                        label: 'Section',
                                        icon: Icons.segment_outlined,
                                      ),
                                      items: const ['A', 'B', 'C', 'D'].map((
                                        value,
                                      ) {
                                        return DropdownMenuItem(
                                          value: value,
                                          child: Text('Section $value'),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setDialogState(() {
                                            selectedSection = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _textField(
                                      controller: roomController,
                                      label: 'Room Number',
                                      hint: 'e.g. 201',
                                      icon: Icons.meeting_room_outlined,
                                      required: true,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  initialValue: selectedSection,
                                  decoration: _inputDecoration(
                                    label: 'Section',
                                    icon: Icons.segment_outlined,
                                  ),
                                  items: const ['A', 'B', 'C', 'D'].map((
                                    value,
                                  ) {
                                    return DropdownMenuItem(
                                      value: value,
                                      child: Text('Section $value'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        selectedSection = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                _textField(
                                  controller: roomController,
                                  label: 'Room Number',
                                  hint: 'e.g. 201',
                                  icon: Icons.meeting_room_outlined,
                                  required: true,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedTeacher,
                          decoration: _inputDecoration(
                            label: 'Class Teacher',
                            icon: Icons.person_outline,
                          ),
                          items:
                              [
                                'Lakshmi Devi',
                                'Ravi Kumar',
                                'Anitha Reddy',
                                'Mahesh Babu',
                                'Priya Sharma',
                                'Srinivas Rao',
                              ].map((value) {
                                return DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
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

                        const SizedBox(height: 16),

                        _textField(
                          controller: capacityController,
                          label: 'Student Capacity',
                          hint: 'e.g. 35',
                          icon: Icons.people_outline,
                          keyboardType: TextInputType.number,
                          required: true,
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: _inputDecoration(
                            label: 'Status',
                            icon: Icons.toggle_on_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Active',
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: 'Inactive',
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedStatus = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 30),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final capacity =
                                    int.tryParse(
                                      capacityController.text.trim(),
                                    ) ??
                                    35;

                                final newClass = {
                                  'id':
                                      'CLS${(classes.length + 1).toString().padLeft(3, '0')}',
                                  'className': selectedClass,
                                  'section': selectedSection,
                                  'classTeacher': selectedTeacher,
                                  'room': roomController.text.trim(),
                                  'students': 0,
                                  'capacity': capacity,
                                  'status': selectedStatus,
                                };

                                setState(() {
                                  classes.add(newClass);
                                });

                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${newClass['className']} - Section ${newClass['section']} created successfully.',
                                    ),
                                    backgroundColor: const Color(0xFF15803D),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Save Class'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // VIEW / EDIT / DELETE
  // ============================================================

  void _handleClassAction(String action, Map<String, dynamic> item) {
    switch (action) {
      case 'view':
        _showClassDetails(item);
        break;
      case 'edit':
        _showEditClassDialog(item);
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _showClassDetails(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${item['className']} - Section ${item['section']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Class ID', item['id']),
              _detailRow('Class Teacher', item['classTeacher']),
              _detailRow('Room', item['room']),
              _detailRow('Students', '${item['students']}'),
              _detailRow('Capacity', '${item['capacity']}'),
              _detailRow('Available', '${item['capacity'] - item['students']}'),
              _detailRow('Status', item['status']),
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

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditClassDialog(Map<String, dynamic> item) {
    String selectedTeacher = item['classTeacher'];

    String selectedStatus = item['status'];

    final roomController = TextEditingController(text: item['room']);

    final capacityController = TextEditingController(
      text: '${item['capacity']}',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Edit ${item['className']} - Section ${item['section']}',
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _textField(
                      controller: roomController,
                      label: 'Room Number',
                      hint: 'e.g. 201',
                      icon: Icons.meeting_room_outlined,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedTeacher,
                      decoration: _inputDecoration(
                        label: 'Class Teacher',
                        icon: Icons.person_outline,
                      ),
                      items:
                          [
                            'Lakshmi Devi',
                            'Ravi Kumar',
                            'Anitha Reddy',
                            'Mahesh Babu',
                            'Priya Sharma',
                            'Srinivas Rao',
                          ].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
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
                    _textField(
                      controller: capacityController,
                      label: 'Student Capacity',
                      hint: 'e.g. 35',
                      icon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: _inputDecoration(
                        label: 'Status',
                        icon: Icons.toggle_on_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final capacity = int.tryParse(
                      capacityController.text.trim(),
                    );

                    if (roomController.text.trim().isEmpty ||
                        capacity == null) {
                      return;
                    }

                    setState(() {
                      item['room'] = roomController.text.trim();
                      item['capacity'] = capacity;
                      item['classTeacher'] = selectedTeacher;
                      item['status'] = selectedStatus;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Class updated successfully.'),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Class?'),
          content: Text(
            'Are you sure you want to delete ${item['className']} - Section ${item['section']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  classes.remove(item);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class deleted successfully.')),
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

  // ============================================================
  // FILTER
  // ============================================================

  void _showFilterDialog() {
    String selectedClass = 'All Classes';
    String selectedSection = 'All Sections';
    String selectedStatus = 'All';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Classes'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedClass,
                      decoration: const InputDecoration(
                        labelText: 'Class',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                            'All Classes',
                            ...List.generate(
                              10,
                              (index) => 'Class ${index + 1}',
                            ),
                          ].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedClass = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSection,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['All Sections', 'A', 'B', 'C', 'D'].map((
                        value,
                      ) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == 'All Sections' ? value : 'Section $value',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedSection = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['All', 'Active', 'Inactive'].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 5,
          width: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF2563EB),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
