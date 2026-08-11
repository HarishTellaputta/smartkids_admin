import 'package:flutter/material.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final List<Map<String, dynamic>> parents = [
    {
      'id': 'PAR001',
      'name': 'Rajesh Kumar',
      'student': 'Aarav Kumar',
      'class': 'Class 1 - A',
      'relation': 'Father',
      'phone': '9876543210',
      'email': 'rajesh@gmail.com',
      'status': 'Active',
    },
    {
      'id': 'PAR002',
      'name': 'Lakshmi Devi',
      'student': 'Ananya Reddy',
      'class': 'Class 2 - A',
      'relation': 'Mother',
      'phone': '9876543211',
      'email': 'lakshmi@gmail.com',
      'status': 'Active',
    },
    {
      'id': 'PAR003',
      'name': 'Srinivas Rao',
      'student': 'Vihan Rao',
      'class': 'Class 3 - A',
      'relation': 'Father',
      'phone': '9876543212',
      'email': 'srinivas@gmail.com',
      'status': 'Active',
    },
    {
      'id': 'PAR004',
      'name': 'Priya Sharma',
      'student': 'Diya Sharma',
      'class': 'Class 4 - A',
      'relation': 'Mother',
      'phone': '9876543213',
      'email': 'priya@gmail.com',
      'status': 'Active',
    },
    {
      'id': 'PAR005',
      'name': 'Mahesh Babu',
      'student': 'Arjun Babu',
      'class': 'Class 5 - A',
      'relation': 'Father',
      'phone': '9876543214',
      'email': 'mahesh@gmail.com',
      'status': 'Active',
    },
    {
      'id': 'PAR006',
      'name': 'Anitha Reddy',
      'student': 'Sai Reddy',
      'class': 'Class 6 - A',
      'relation': 'Mother',
      'phone': '9876543215',
      'email': 'anitha@gmail.com',
      'status': 'Active',
    },
    {
      'id': 'PAR007',
      'name': 'Ramesh Kumar',
      'student': 'Krishna Kumar',
      'class': 'Class 7 - A',
      'relation': 'Father',
      'phone': '9876543216',
      'email': 'ramesh@gmail.com',
      'status': 'Inactive',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredParents {
    if (_searchQuery.trim().isEmpty) {
      return parents;
    }

    final query = _searchQuery.toLowerCase().trim();

    return parents.where((parent) {
      return parent['name'].toString().toLowerCase().contains(query) ||
          parent['student'].toString().toLowerCase().contains(query) ||
          parent['class'].toString().toLowerCase().contains(query) ||
          parent['phone'].toString().contains(query) ||
          parent['email'].toString().toLowerCase().contains(query) ||
          parent['id'].toString().toLowerCase().contains(query);
    }).toList();
  }

  int get activeParents {
    return parents.where((p) => p['status'] == 'Active').length;
  }

  int get inactiveParents {
    return parents.where((p) => p['status'] == 'Inactive').length;
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
            _buildParentsTable(),
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
        if (constraints.maxWidth < 650) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderText(),
              const SizedBox(height: 16),
              _buildAddParentButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildHeaderText()),
            _buildAddParentButton(),
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
          'Parents',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage parents and their student relationships.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAddParentButton() {
    return ElevatedButton.icon(
      onPressed: _showAddParentDialog,
      icon: const Icon(Icons.person_add_alt_1, size: 19),
      label: const Text('Add Parent'),
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

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4.0 : 2.5,
          children: [
            _summaryCard(
              title: 'Total Parents',
              value: '${parents.length}',
              icon: Icons.groups_outlined,
            ),
            _summaryCard(
              title: 'Active Parents',
              value: '$activeParents',
              icon: Icons.verified_user_outlined,
            ),
            _summaryCard(
              title: 'Father',
              value: '${_relationCount('Father')}',
              icon: Icons.person_outline,
            ),
            _summaryCard(
              title: 'Mother',
              value: '${_relationCount('Mother')}',
              icon: Icons.person_2_outlined,
            ),
          ],
        );
      },
    );
  }

  int _relationCount(String relation) {
    return parents.where((parent) => parent['relation'] == relation).length;
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
  // PARENTS TABLE
  // ============================================================

  Widget _buildParentsTable() {
    final data = filteredParents;

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
          width: isSmall ? double.infinity : 310,
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
              hintText: 'Search parents...',
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
                    '${filteredParents.length} parents',
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
              '${filteredParents.length} parents',
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
        dataRowMinHeight: 70,
        dataRowMaxHeight: 78,
        columnSpacing: 26,
        horizontalMargin: 12,
        columns: const [
          DataColumn(label: Text('Parent')),
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Relation')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: data.map((parent) {
          return DataRow(
            cells: [
              DataCell(_parentCell(parent)),
              DataCell(_studentCell(parent)),
              DataCell(_relationBadge(parent['relation'])),
              DataCell(_phoneCell(parent['phone'])),
              DataCell(
                Text(
                  parent['email'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              DataCell(_statusBadge(parent['status'])),
              DataCell(
                PopupMenuButton<String>(
                  onSelected: (value) {
                    _handleParentAction(value, parent);
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

  Widget _parentCell(Map<String, dynamic> parent) {
    final name = parent['name'].toString();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
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
              parent['id'],
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _studentCell(Map<String, dynamic> parent) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parent['student'],
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          parent['class'],
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _relationBadge(String relation) {
    final isFather = relation == 'Father';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isFather ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        relation,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isFather ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
        ),
      ),
    );
  }

  Widget _phoneCell(String phone) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          phone,
          style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
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
          Icon(
            Icons.person_search_outlined,
            size: 50,
            color: Color(0xFFD1D5DB),
          ),
          SizedBox(height: 12),
          Text(
            'No parents found',
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
  // ADD PARENT
  // ============================================================

  void _showAddParentDialog() {
    final formKey = GlobalKey<FormState>();

    String selectedRelation = 'Father';
    String selectedStudent = 'Aarav Kumar';
    String selectedStatus = 'Active';

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

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
                                Icons.person_add_alt_1,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add New Parent',
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Add parent details and link them to a student.',
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

                        _sectionTitle('Parent Information'),

                        const SizedBox(height: 16),

                        _textField(
                          controller: nameController,
                          label: 'Parent Name',
                          hint: 'Enter full name',
                          icon: Icons.person_outline,
                          required: true,
                        ),

                        const SizedBox(height: 16),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 500) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: _textField(
                                      controller: phoneController,
                                      label: 'Phone Number',
                                      hint: '10 digit number',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      required: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _textField(
                                      controller: emailController,
                                      label: 'Email',
                                      hint: 'parent@email.com',
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
                                  hint: '10 digit number',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                _textField(
                                  controller: emailController,
                                  label: 'Email',
                                  hint: 'parent@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedRelation,
                          decoration: _inputDecoration(
                            label: 'Relation',
                            icon: Icons.family_restroom_outlined,
                          ),
                          items: const ['Father', 'Mother', 'Guardian'].map((
                            value,
                          ) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedRelation = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedStudent,
                          decoration: _inputDecoration(
                            label: 'Student',
                            icon: Icons.school_outlined,
                          ),
                          items:
                              const [
                                'Aarav Kumar',
                                'Ananya Reddy',
                                'Vihan Rao',
                                'Diya Sharma',
                                'Arjun Babu',
                                'Sai Reddy',
                                'Krishna Kumar',
                              ].map((value) {
                                return DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedStudent = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          initialValue: selectedStatus,
                          decoration: _inputDecoration(
                            label: 'Status',
                            icon: Icons.toggle_on_outlined,
                          ),
                          items: const ['Active', 'Inactive'].map((value) {
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

                                final newParent = {
                                  'id':
                                      'PAR${(parents.length + 1).toString().padLeft(3, '0')}',
                                  'name': nameController.text.trim(),
                                  'student': selectedStudent,
                                  'class': 'Class 1 - A',
                                  'relation': selectedRelation,
                                  'phone': phoneController.text.trim(),
                                  'email': emailController.text.trim(),
                                  'status': selectedStatus,
                                };

                                setState(() {
                                  parents.add(newParent);
                                });

                                Navigator.pop(dialogContext);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Parent added successfully.'),
                                    backgroundColor: Color(0xFF15803D),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Save Parent'),
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
  // ACTIONS
  // ============================================================

  void _handleParentAction(String action, Map<String, dynamic> parent) {
    switch (action) {
      case 'view':
        _showParentDetails(parent);
        break;
      case 'edit':
        _showEditParentDialog(parent);
        break;
      case 'delete':
        _showDeleteConfirmation(parent);
        break;
    }
  }

  void _showParentDetails(Map<String, dynamic> parent) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(parent['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Parent ID', parent['id']),
              _detailRow('Student', parent['student']),
              _detailRow('Class', parent['class']),
              _detailRow('Relation', parent['relation']),
              _detailRow('Phone', parent['phone']),
              _detailRow('Email', parent['email']),
              _detailRow('Status', parent['status']),
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
            width: 85,
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

  // ============================================================
  // EDIT PARENT
  // ============================================================

  void _showEditParentDialog(Map<String, dynamic> parent) {
    String selectedRelation = parent['relation'];

    String selectedStatus = parent['status'];

    final nameController = TextEditingController(text: parent['name']);

    final phoneController = TextEditingController(text: parent['phone']);

    final emailController = TextEditingController(text: parent['email']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${parent['name']}'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _textField(
                        controller: nameController,
                        label: 'Parent Name',
                        hint: 'Enter full name',
                        icon: Icons.person_outline,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: phoneController,
                        label: 'Phone Number',
                        hint: '10 digit number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _textField(
                        controller: emailController,
                        label: 'Email',
                        hint: 'parent@email.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRelation,
                        decoration: _inputDecoration(
                          label: 'Relation',
                          icon: Icons.family_restroom_outlined,
                        ),
                        items: const ['Father', 'Mother', 'Guardian'].map((
                          value,
                        ) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedRelation = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: _inputDecoration(
                          label: 'Status',
                          icon: Icons.toggle_on_outlined,
                        ),
                        items: const ['Active', 'Inactive'].map((value) {
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        phoneController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      parent['name'] = nameController.text.trim();
                      parent['phone'] = phoneController.text.trim();
                      parent['email'] = emailController.text.trim();
                      parent['relation'] = selectedRelation;
                      parent['status'] = selectedStatus;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Parent updated successfully.'),
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

  // ============================================================
  // DELETE
  // ============================================================

  void _showDeleteConfirmation(Map<String, dynamic> parent) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Parent?'),
          content: Text('Are you sure you want to delete ${parent['name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  parents.remove(parent);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Parent deleted successfully.')),
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
    String selectedRelation = 'All';
    String selectedStatus = 'All';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Parents'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedRelation,
                      decoration: const InputDecoration(
                        labelText: 'Relation',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['All', 'Father', 'Mother', 'Guardian'].map((
                        value,
                      ) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRelation = value;
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
