import 'package:flutter/material.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<Map<String, dynamic>> students = [
    {
      'id': 'STU001',
      'name': 'Rahul Kumar',
      'class': 'Class 5',
      'section': 'A',
      'parent': 'Ramesh Kumar',
      'phone': '9876543210',
      'status': 'Active',
    },
    {
      'id': 'STU002',
      'name': 'Ananya Reddy',
      'class': 'Class 4',
      'section': 'B',
      'parent': 'Suresh Reddy',
      'phone': '9876543211',
      'status': 'Active',
    },
    {
      'id': 'STU003',
      'name': 'Arjun Sharma',
      'class': 'Class 6',
      'section': 'A',
      'parent': 'Rajesh Sharma',
      'phone': '9876543212',
      'status': 'Active',
    },
    {
      'id': 'STU004',
      'name': 'Sneha Patel',
      'class': 'Class 3',
      'section': 'A',
      'parent': 'Mahesh Patel',
      'phone': '9876543213',
      'status': 'Inactive',
    },
    {
      'id': 'STU005',
      'name': 'Vikram Singh',
      'class': 'Class 5',
      'section': 'B',
      'parent': 'Amit Singh',
      'phone': '9876543214',
      'status': 'Active',
    },
    {
      'id': 'STU006',
      'name': 'Pooja Devi',
      'class': 'Class 2',
      'section': 'A',
      'parent': 'Ravi Kumar',
      'phone': '9876543215',
      'status': 'Active',
    },
    {
      'id': 'STU007',
      'name': 'Karthik Rao',
      'class': 'Class 7',
      'section': 'A',
      'parent': 'Prasad Rao',
      'phone': '9876543216',
      'status': 'Active',
    },
    {
      'id': 'STU008',
      'name': 'Meghana Das',
      'class': 'Class 4',
      'section': 'A',
      'parent': 'Srinivas Das',
      'phone': '9876543217',
      'status': 'Active',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredStudents {
    if (_searchQuery.trim().isEmpty) {
      return students;
    }

    final query = _searchQuery.toLowerCase().trim();

    return students.where((student) {
      return student['name'].toString().toLowerCase().contains(query) ||
          student['id'].toString().toLowerCase().contains(query) ||
          student['class'].toString().toLowerCase().contains(query) ||
          student['parent'].toString().toLowerCase().contains(query) ||
          student['phone'].toString().contains(query);
    }).toList();
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
            _buildStudentsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 650;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderText(),
              const SizedBox(height: 16),
              _buildAddStudentButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildHeaderText()),
            _buildAddStudentButton(),
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
          'Students',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage students, classes and parent information.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAddStudentButton() {
    return ElevatedButton.icon(
      onPressed: _showAddStudentDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Add Student'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

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

        final activeCount = students
            .where((s) => s['status'] == 'Active')
            .length;

        final inactiveCount = students
            .where((s) => s['status'] == 'Inactive')
            .length;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4.0 : 2.5,
          children: [
            _summaryCard(
              title: 'Total Students',
              value: '350',
              icon: Icons.school_outlined,
            ),
            _summaryCard(
              title: 'Active Students',
              value: '$activeCount',
              icon: Icons.check_circle_outline,
            ),
            _summaryCard(
              title: 'Inactive',
              value: '$inactiveCount',
              icon: Icons.person_off_outlined,
            ),
            _summaryCard(
              title: 'New This Month',
              value: '12',
              icon: Icons.person_add_outlined,
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

  Widget _buildStudentsTable() {
    final data = filteredStudents;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTableToolbar(),
            const SizedBox(height: 20),
            if (data.isEmpty) _buildEmptyState() else _buildTable(data),
          ],
        ),
      ),
    );
  }

  Widget _buildTableToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 700;

        final search = Container(
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
              hintText: 'Search students...',
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
              search,
              const SizedBox(height: 12),
              Row(
                children: [
                  filterButton,
                  const Spacer(),
                  Text(
                    '${filteredStudents.length} students',
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
            search,
            const SizedBox(width: 12),
            filterButton,
            const Spacer(),
            Text(
              '${filteredStudents.length} students',
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
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Parent')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: data.map((student) {
          return DataRow(
            cells: [
              DataCell(_studentCell(student)),
              DataCell(
                Text(
                  '${student['class']} - ${student['section']}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DataCell(
                Text(
                  student['parent'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DataCell(
                Text(
                  student['phone'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DataCell(_statusBadge(student['status'])),
              DataCell(
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleStudentAction(value, student);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'view', child: Text('View')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  child: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _studentCell(Map<String, dynamic> student) {
    final String name = student['name'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFDBEAFE),
          child: Text(
            name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
        const SizedBox(width: 11),
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
    final bool active = status == 'Active';

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
            'No students found',
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
  // ADD STUDENT FORM
  // ============================================================

  void _showAddStudentDialog() {
    final formKey = GlobalKey<FormState>();

    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final parentController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final dobController = TextEditingController();
    final addressController = TextEditingController();

    String selectedClass = 'Class 1';
    String selectedSection = 'A';
    String selectedGender = 'Male';

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
                  maxWidth: 850,
                  maxHeight: 720,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
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
                                Icons.person_add_outlined,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add New Student',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Enter student and parent details',
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

                        _formSectionTitle('Student Information'),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool twoColumns = constraints.maxWidth >= 600;

                            if (twoColumns) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _textField(
                                          controller: firstNameController,
                                          label: 'First Name',
                                          hint: 'Enter first name',
                                          icon: Icons.person_outline,
                                          required: true,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _textField(
                                          controller: lastNameController,
                                          label: 'Last Name',
                                          hint: 'Enter last name',
                                          icon: Icons.person_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
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
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: selectedSection,
                                          decoration: _inputDecoration(
                                            label: 'Section',
                                            icon: Icons.groups_outlined,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'A',
                                              child: Text('Section A'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'B',
                                              child: Text('Section B'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'C',
                                              child: Text('Section C'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              setDialogState(() {
                                                selectedSection = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _dateField(
                                          controller: dobController,
                                          label: 'Date of Birth',
                                          context: context,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: selectedGender,
                                          decoration: _inputDecoration(
                                            label: 'Gender',
                                            icon: Icons.wc_outlined,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Male',
                                              child: Text('Male'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Female',
                                              child: Text('Female'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Other',
                                              child: Text('Other'),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              setDialogState(() {
                                                selectedGender = value;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _textField(
                                  controller: firstNameController,
                                  label: 'First Name',
                                  hint: 'Enter first name',
                                  icon: Icons.person_outline,
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                _textField(
                                  controller: lastNameController,
                                  label: 'Last Name',
                                  hint: 'Enter last name',
                                  icon: Icons.person_outline,
                                ),
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
                                DropdownButtonFormField<String>(
                                  initialValue: selectedSection,
                                  decoration: _inputDecoration(
                                    label: 'Section',
                                    icon: Icons.groups_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'A',
                                      child: Text('Section A'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'B',
                                      child: Text('Section B'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'C',
                                      child: Text('Section C'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        selectedSection = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                _dateField(
                                  controller: dobController,
                                  label: 'Date of Birth',
                                  context: context,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedGender,
                                  decoration: _inputDecoration(
                                    label: 'Gender',
                                    icon: Icons.wc_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setDialogState(() {
                                        selectedGender = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        _formSectionTitle('Parent / Guardian Information'),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final bool twoColumns = constraints.maxWidth >= 600;

                            if (twoColumns) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _textField(
                                      controller: parentController,
                                      label: 'Parent Name',
                                      hint: 'Enter parent name',
                                      icon: Icons.person_outline,
                                      required: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _textField(
                                      controller: phoneController,
                                      label: 'Phone Number',
                                      hint: '10-digit mobile number',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      required: true,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _textField(
                                  controller: parentController,
                                  label: 'Parent Name',
                                  hint: 'Enter parent name',
                                  icon: Icons.person_outline,
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                _textField(
                                  controller: phoneController,
                                  label: 'Phone Number',
                                  hint: '10-digit mobile number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  required: true,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        _textField(
                          controller: emailController,
                          label: 'Email Address',
                          hint: 'parent@example.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 16),

                        _textField(
                          controller: addressController,
                          label: 'Address',
                          hint: 'Enter residential address',
                          icon: Icons.location_on_outlined,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 28),

                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }

                                final firstName = firstNameController.text
                                    .trim();
                                final lastName = lastNameController.text.trim();

                                final newStudent = {
                                  'id':
                                      'STU${(students.length + 1).toString().padLeft(3, '0')}',
                                  'name': '$firstName $lastName'.trim(),
                                  'class': selectedClass,
                                  'section': selectedSection,
                                  'parent': parentController.text.trim(),
                                  'phone': phoneController.text.trim(),
                                  'status': 'Active',
                                };

                                setState(() {
                                  students.add(newStudent);
                                });

                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${newStudent['name']} added successfully.',
                                    ),
                                    backgroundColor: const Color(0xFF15803D),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Save Student'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
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

  Widget _formSectionTitle(String title) {
    return Row(
      children: [
        Container(
          height: 4,
          width: 4,
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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }

              if (label == 'Phone Number' && value.trim().length != 10) {
                return 'Enter a valid 10-digit number';
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
    );
  }

  Widget _dateField({
    required TextEditingController controller,
    required String label,
    required BuildContext context,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          initialDate: DateTime(2016),
        );

        if (date != null) {
          controller.text =
              '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year}';
        }
      },
      decoration: _inputDecoration(
        label: label,
        hint: 'Select date',
        icon: Icons.calendar_today_outlined,
      ),
    );
  }

  // ============================================================
  // VIEW / EDIT / DELETE
  // ============================================================

  void _handleStudentAction(String action, Map<String, dynamic> student) {
    if (action == 'view') {
      _showStudentDetails(student);
    } else if (action == 'edit') {
      _showEditStudentDialog(student);
    } else if (action == 'delete') {
      _showDeleteConfirmation(student);
    }
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(student['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Student ID', student['id']),
              _detailRow(
                'Class',
                '${student['class']} - ${student['section']}',
              ),
              _detailRow('Parent', student['parent']),
              _detailRow('Phone', student['phone']),
              _detailRow('Status', student['status']),
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
            width: 90,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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

  void _showEditStudentDialog(Map<String, dynamic> student) {
    final nameController = TextEditingController(text: student['name']);

    final parentController = TextEditingController(text: student['parent']);

    final phoneController = TextEditingController(text: student['phone']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit ${student['name']}'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _textField(
                  controller: nameController,
                  label: 'Student Name',
                  hint: 'Student name',
                  icon: Icons.person_outline,
                  required: true,
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: parentController,
                  label: 'Parent Name',
                  hint: 'Parent name',
                  icon: Icons.family_restroom_outlined,
                  required: true,
                ),
                const SizedBox(height: 14),
                _textField(
                  controller: phoneController,
                  label: 'Phone Number',
                  hint: '10-digit number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  required: true,
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
                if (nameController.text.trim().isEmpty ||
                    parentController.text.trim().isEmpty ||
                    phoneController.text.trim().length != 10) {
                  return;
                }

                setState(() {
                  student['name'] = nameController.text.trim();
                  student['parent'] = parentController.text.trim();
                  student['phone'] = phoneController.text.trim();
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student updated successfully.'),
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
  }

  void _showDeleteConfirmation(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Student?'),
          content: Text('Are you sure you want to delete ${student['name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  students.remove(student);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student deleted successfully.'),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedClass = 'All Classes';
        String selectedStatus = 'All';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Students'),
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All')),
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
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
