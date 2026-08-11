import 'package:flutter/material.dart';

class TeachersScreen extends StatefulWidget {
  const TeachersScreen({super.key});

  @override
  State<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends State<TeachersScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<Map<String, dynamic>> teachers = [
    {
      'id': 'TCH001',
      'name': 'Srinivas Rao',
      'subject': 'Mathematics',
      'class': 'Class 5',
      'phone': '9876500001',
      'email': 'srinivas@smartkids.com',
      'status': 'Active',
    },
    {
      'id': 'TCH002',
      'name': 'Lakshmi Devi',
      'subject': 'English',
      'class': 'Class 4',
      'phone': '9876500002',
      'email': 'lakshmi@smartkids.com',
      'status': 'Active',
    },
    {
      'id': 'TCH003',
      'name': 'Ravi Kumar',
      'subject': 'Science',
      'class': 'Class 6',
      'phone': '9876500003',
      'email': 'ravi@smartkids.com',
      'status': 'Active',
    },
    {
      'id': 'TCH004',
      'name': 'Anitha Reddy',
      'subject': 'Social Studies',
      'class': 'Class 7',
      'phone': '9876500004',
      'email': 'anitha@smartkids.com',
      'status': 'Inactive',
    },
    {
      'id': 'TCH005',
      'name': 'Mahesh Babu',
      'subject': 'Telugu',
      'class': 'Class 3',
      'phone': '9876500005',
      'email': 'mahesh@smartkids.com',
      'status': 'Active',
    },
    {
      'id': 'TCH006',
      'name': 'Priya Sharma',
      'subject': 'Computer Science',
      'class': 'Class 8',
      'phone': '9876500006',
      'email': 'priya@smartkids.com',
      'status': 'Active',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredTeachers {
    if (_searchQuery.trim().isEmpty) {
      return teachers;
    }

    final query = _searchQuery.toLowerCase().trim();

    return teachers.where((teacher) {
      return teacher['name'].toString().toLowerCase().contains(query) ||
          teacher['id'].toString().toLowerCase().contains(query) ||
          teacher['subject'].toString().toLowerCase().contains(query) ||
          teacher['class'].toString().toLowerCase().contains(query) ||
          teacher['phone'].toString().contains(query);
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
            _buildTeachersTable(),
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
              _buildAddTeacherButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildHeaderText()),
            _buildAddTeacherButton(),
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
          'Teachers',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage teachers, subjects and assigned classes.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAddTeacherButton() {
    return ElevatedButton.icon(
      onPressed: _showAddTeacherDialog,
      icon: const Icon(Icons.add, size: 19),
      label: const Text('Add Teacher'),
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

        final activeCount = teachers
            .where((t) => t['status'] == 'Active')
            .length;

        final inactiveCount = teachers
            .where((t) => t['status'] == 'Inactive')
            .length;

        final subjects = teachers.map((t) => t['subject']).toSet().length;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4.0 : 2.5,
          children: [
            _summaryCard(
              title: 'Total Teachers',
              value: '28',
              icon: Icons.people_outline,
            ),
            _summaryCard(
              title: 'Active Teachers',
              value: '$activeCount',
              icon: Icons.check_circle_outline,
            ),
            _summaryCard(
              title: 'Inactive',
              value: '$inactiveCount',
              icon: Icons.person_off_outlined,
            ),
            _summaryCard(
              title: 'Subjects',
              value: '$subjects',
              icon: Icons.menu_book_outlined,
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

  Widget _buildTeachersTable() {
    final data = filteredTeachers;

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
              hintText: 'Search teachers...',
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
                    '${filteredTeachers.length} teachers',
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
              '${filteredTeachers.length} teachers',
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
          DataColumn(label: Text('Teacher')),
          DataColumn(label: Text('Subject')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: data.map((teacher) {
          return DataRow(
            cells: [
              DataCell(_teacherCell(teacher)),
              DataCell(
                Text(
                  teacher['subject'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DataCell(
                Text(
                  teacher['class'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DataCell(
                Text(
                  teacher['phone'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
              DataCell(_statusBadge(teacher['status'])),
              DataCell(
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleTeacherAction(value, teacher);
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

  Widget _teacherCell(Map<String, dynamic> teacher) {
    final name = teacher['name'].toString();

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
              teacher['id'],
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
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
            'No teachers found',
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
  // ADD TEACHER
  // ============================================================

  void _showAddTeacherDialog() {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final qualificationController = TextEditingController();
    final experienceController = TextEditingController();

    String selectedSubject = 'Mathematics';
    String selectedClass = 'Class 1';
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
                  maxWidth: 800,
                  maxHeight: 700,
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
                                    'Add New Teacher',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Enter teacher professional details',
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

                        _sectionTitle('Teacher Information'),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 600;

                            if (twoColumns) {
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _textField(
                                          controller: nameController,
                                          label: 'Full Name',
                                          hint: 'Enter teacher name',
                                          icon: Icons.person_outline,
                                          required: true,
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
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: selectedSubject,
                                          decoration: _inputDecoration(
                                            label: 'Subject',
                                            icon: Icons.menu_book_outlined,
                                          ),
                                          items:
                                              const [
                                                'Mathematics',
                                                'English',
                                                'Science',
                                                'Telugu',
                                                'Hindi',
                                                'Social Studies',
                                                'Computer Science',
                                                'General',
                                              ].map((subject) {
                                                return DropdownMenuItem(
                                                  value: subject,
                                                  child: Text(subject),
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
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: selectedClass,
                                          decoration: _inputDecoration(
                                            label: 'Assigned Class',
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
                                    ],
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _textField(
                                  controller: nameController,
                                  label: 'Full Name',
                                  hint: 'Enter teacher name',
                                  icon: Icons.person_outline,
                                  required: true,
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
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedSubject,
                                  decoration: _inputDecoration(
                                    label: 'Subject',
                                    icon: Icons.menu_book_outlined,
                                  ),
                                  items:
                                      const [
                                        'Mathematics',
                                        'English',
                                        'Science',
                                        'Telugu',
                                        'Hindi',
                                        'Social Studies',
                                        'Computer Science',
                                        'General',
                                      ].map((subject) {
                                        return DropdownMenuItem(
                                          value: subject,
                                          child: Text(subject),
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
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedClass,
                                  decoration: _inputDecoration(
                                    label: 'Assigned Class',
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
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        _sectionTitle('Contact Information'),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 600;

                            if (twoColumns) {
                              return Row(
                                children: [
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _textField(
                                      controller: emailController,
                                      label: 'Email Address',
                                      hint: 'teacher@example.com',
                                      icon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _textField(
                                  controller: phoneController,
                                  label: 'Phone Number',
                                  hint: '10-digit mobile number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                _textField(
                                  controller: emailController,
                                  label: 'Email Address',
                                  hint: 'teacher@example.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        _sectionTitle('Professional Information'),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            final twoColumns = constraints.maxWidth >= 600;

                            if (twoColumns) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _textField(
                                      controller: qualificationController,
                                      label: 'Qualification',
                                      hint: 'e.g. B.Ed, M.Ed',
                                      icon: Icons.school_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _textField(
                                      controller: experienceController,
                                      label: 'Experience',
                                      hint: 'e.g. 5 years',
                                      icon: Icons.work_outline,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                _textField(
                                  controller: qualificationController,
                                  label: 'Qualification',
                                  hint: 'e.g. B.Ed, M.Ed',
                                  icon: Icons.school_outlined,
                                ),
                                const SizedBox(height: 16),
                                _textField(
                                  controller: experienceController,
                                  label: 'Experience',
                                  hint: 'e.g. 5 years',
                                  icon: Icons.work_outline,
                                ),
                              ],
                            );
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
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 14,
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

                                final newTeacher = {
                                  'id':
                                      'TCH${(teachers.length + 1).toString().padLeft(3, '0')}',
                                  'name': nameController.text.trim(),
                                  'subject': selectedSubject,
                                  'class': selectedClass,
                                  'phone': phoneController.text.trim(),
                                  'email': emailController.text.trim(),
                                  'status': 'Active',
                                };

                                setState(() {
                                  teachers.add(newTeacher);
                                });

                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${newTeacher['name']} added successfully.',
                                    ),
                                    backgroundColor: const Color(0xFF15803D),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Save Teacher'),
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

  // ============================================================
  // VIEW / EDIT / DELETE
  // ============================================================

  void _handleTeacherAction(String action, Map<String, dynamic> teacher) {
    switch (action) {
      case 'view':
        _showTeacherDetails(teacher);
        break;

      case 'edit':
        _showEditTeacherDialog(teacher);
        break;

      case 'delete':
        _showDeleteConfirmation(teacher);
        break;
    }
  }

  void _showTeacherDetails(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(teacher['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Teacher ID', teacher['id']),
              _detailRow('Subject', teacher['subject']),
              _detailRow('Class', teacher['class']),
              _detailRow('Phone', teacher['phone']),
              _detailRow('Email', teacher['email']),
              _detailRow('Status', teacher['status']),
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

  void _showEditTeacherDialog(Map<String, dynamic> teacher) {
    final nameController = TextEditingController(text: teacher['name']);

    final phoneController = TextEditingController(text: teacher['phone']);

    final emailController = TextEditingController(text: teacher['email']);

    String selectedSubject = teacher['subject'];

    String selectedClass = teacher['class'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${teacher['name']}'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _textField(
                      controller: nameController,
                      label: 'Teacher Name',
                      hint: 'Teacher name',
                      icon: Icons.person_outline,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: _inputDecoration(
                        label: 'Subject',
                        icon: Icons.menu_book_outlined,
                      ),
                      items:
                          const [
                            'Mathematics',
                            'English',
                            'Science',
                            'Telugu',
                            'Hindi',
                            'Social Studies',
                            'Computer Science',
                            'General',
                          ].map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
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
                    const SizedBox(height: 14),
                    _textField(
                      controller: phoneController,
                      label: 'Phone Number',
                      hint: '10-digit number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),
                    const SizedBox(height: 14),
                    _textField(
                      controller: emailController,
                      label: 'Email Address',
                      hint: 'teacher@example.com',
                      icon: Icons.email_outlined,
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
                        phoneController.text.trim().length != 10) {
                      return;
                    }

                    setState(() {
                      teacher['name'] = nameController.text.trim();
                      teacher['subject'] = selectedSubject;
                      teacher['class'] = selectedClass;
                      teacher['phone'] = phoneController.text.trim();
                      teacher['email'] = emailController.text.trim();
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teacher updated successfully.'),
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

  void _showDeleteConfirmation(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Teacher?'),
          content: Text('Are you sure you want to delete ${teacher['name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  teachers.remove(teacher);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Teacher deleted successfully.'),
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

  // ============================================================
  // FILTER
  // ============================================================

  void _showFilterDialog() {
    String selectedSubject = 'All Subjects';
    String selectedStatus = 'All';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Teachers'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                            'All Subjects',
                            'Mathematics',
                            'English',
                            'Science',
                            'Telugu',
                            'Hindi',
                            'Social Studies',
                            'Computer Science',
                            'General',
                          ].map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
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
  // COMMON FORM WIDGETS
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
    );
  }
}
