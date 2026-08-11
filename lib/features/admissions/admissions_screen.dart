import 'package:flutter/material.dart';

class AdmissionsScreen extends StatefulWidget {
  const AdmissionsScreen({super.key});

  @override
  State<AdmissionsScreen> createState() => _AdmissionsScreenState();
}

class _AdmissionsScreenState extends State<AdmissionsScreen> {
  String selectedStatus = 'All';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> admissions = [
    {
      'applicationId': 'ADM-2026-001',
      'studentName': 'Aarav Kumar',
      'parentName': 'Ramesh Kumar',
      'className': 'UKG',
      'phone': '9876543210',
      'email': 'ramesh@example.com',
      'date': '10 Aug 2026',
      'status': 'Pending',
      'address': 'Khammam, Telangana',
    },
    {
      'applicationId': 'ADM-2026-002',
      'studentName': 'Ananya Reddy',
      'parentName': 'Suresh Reddy',
      'className': '1st Class',
      'phone': '9988776655',
      'email': 'suresh@example.com',
      'date': '09 Aug 2026',
      'status': 'Approved',
      'address': 'Khammam, Telangana',
    },
    {
      'applicationId': 'ADM-2026-003',
      'studentName': 'Vihaan Sharma',
      'parentName': 'Rajesh Sharma',
      'className': 'LKG',
      'phone': '9123456789',
      'email': 'rajesh@example.com',
      'date': '08 Aug 2026',
      'status': 'Pending',
      'address': 'Wyra, Telangana',
    },
    {
      'applicationId': 'ADM-2026-004',
      'studentName': 'Sai Lakshmi',
      'parentName': 'Prakash Rao',
      'className': '2nd Class',
      'phone': '9012345678',
      'email': 'prakash@example.com',
      'date': '07 Aug 2026',
      'status': 'Rejected',
      'address': 'Madhira, Telangana',
    },
    {
      'applicationId': 'ADM-2026-005',
      'studentName': 'Aditya Verma',
      'parentName': 'Mahesh Verma',
      'className': 'UKG',
      'phone': '9345678901',
      'email': 'mahesh@example.com',
      'date': '06 Aug 2026',
      'status': 'Approved',
      'address': 'Khammam, Telangana',
    },
    {
      'applicationId': 'ADM-2026-006',
      'studentName': 'Ishita Rao',
      'parentName': 'Venkatesh Rao',
      'className': '3rd Class',
      'phone': '9567890123',
      'email': 'venkatesh@example.com',
      'date': '05 Aug 2026',
      'status': 'Pending',
      'address': 'Kusumanchi, Telangana',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredAdmissions {
    return admissions.where((admission) {
      final matchesStatus =
          selectedStatus == 'All' || admission['status'] == selectedStatus;

      final query = searchQuery.toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          admission['studentName'].toString().toLowerCase().contains(query) ||
          admission['parentName'].toString().toLowerCase().contains(query) ||
          admission['applicationId'].toString().toLowerCase().contains(query) ||
          admission['className'].toString().toLowerCase().contains(query) ||
          admission['phone'].toString().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  int get totalAdmissions => admissions.length;

  int get pendingAdmissions =>
      admissions.where((item) => item['status'] == 'Pending').length;

  int get approvedAdmissions =>
      admissions.where((item) => item['status'] == 'Approved').length;

  int get rejectedAdmissions =>
      admissions.where((item) => item['status'] == 'Rejected').length;

  void _showAddAdmissionDialog() {
    final studentController = TextEditingController();
    final parentController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    String className = 'LKG';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'New Admission Application',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: studentController,
                        decoration: InputDecoration(
                          labelText: 'Student Name',
                          hintText: 'Enter student name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: parentController,
                        decoration: InputDecoration(
                          labelText: 'Parent / Guardian Name',
                          hintText: 'Enter parent name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: className,
                        decoration: InputDecoration(
                          labelText: 'Applying For',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            const [
                              'LKG',
                              'UKG',
                              '1st Class',
                              '2nd Class',
                              '3rd Class',
                              '4th Class',
                              '5th Class',
                              '6th Class',
                              '7th Class',
                              '8th Class',
                              '9th Class',
                              '10th Class',
                            ].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            className = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone',
                                prefixIcon: const Icon(
                                  Icons.phone_outlined,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Enter residential address',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (studentController.text.trim().isEmpty ||
                        parentController.text.trim().isEmpty) {
                      return;
                    }

                    final newId =
                        'ADM-2026-${(admissions.length + 1).toString().padLeft(3, '0')}';

                    setState(() {
                      admissions.insert(0, {
                        'applicationId': newId,
                        'studentName': studentController.text.trim(),
                        'parentName': parentController.text.trim(),
                        'className': className,
                        'phone': phoneController.text.trim(),
                        'email': emailController.text.trim(),
                        'date': '10 Aug 2026',
                        'status': 'Pending',
                        'address': addressController.text.trim(),
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Admission application created.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Application'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdmissionDetails(Map<String, dynamic> admission) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            admission['studentName'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  Icons.badge_outlined,
                  'Application ID',
                  admission['applicationId'],
                ),
                _detailRow(
                  Icons.person_outline,
                  'Parent',
                  admission['parentName'],
                ),
                _detailRow(
                  Icons.school_outlined,
                  'Class',
                  admission['className'],
                ),
                _detailRow(Icons.phone_outlined, 'Phone', admission['phone']),
                _detailRow(Icons.email_outlined, 'Email', admission['email']),
                _detailRow(
                  Icons.calendar_today_outlined,
                  'Applied On',
                  admission['date'],
                ),
                _detailRow(Icons.info_outline, 'Status', admission['status']),
                const SizedBox(height: 8),
                const Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  admission['address'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          SizedBox(
            width: 95,
            child: Text(
              title,
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

  void _updateStatus(Map<String, dynamic> admission, String status) {
    setState(() {
      admission['status'] = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Application ${status.toLowerCase()}.')),
    );
  }

  void _confirmReject(Map<String, dynamic> admission) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Reject Application?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to reject the admission application for ${admission['studentName']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _updateStatus(admission, 'Rejected');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  void _approveAdmission(Map<String, dynamic> admission) {
    _updateStatus(admission, 'Approved');
  }

  @override
  Widget build(BuildContext context) {
    final data = filteredAdmissions;

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
            _buildSearchAndFilter(),
            const SizedBox(height: 20),
            _buildAdmissionsTable(data),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdmissionDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('New Admission'),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admissions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage student admission applications.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
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
          childAspectRatio: columns == 1 ? 4.2 : 2.5,
          children: [
            _summaryCard(
              'Total Applications',
              '$totalAdmissions',
              Icons.assignment_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Pending',
              '$pendingAdmissions',
              Icons.pending_actions_outlined,
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            _summaryCard(
              'Approved',
              '$approvedAdmissions',
              Icons.check_circle_outline,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              'Rejected',
              '$rejectedAdmissions',
              Icons.cancel_outlined,
              const Color(0xFFDC2626),
              const Color(0xFFFEF2F2),
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
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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

  Widget _buildSearchAndFilter() {
    final statuses = ['All', 'Pending', 'Approved', 'Rejected'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              children: [
                _searchField(),
                const SizedBox(height: 14),
                _statusFilters(statuses),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _searchField()),
              const SizedBox(width: 18),
              _statusFilters(statuses),
            ],
          );
        },
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: searchController,
      onChanged: (value) {
        setState(() {
          searchQuery = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search student, parent, application ID...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  setState(() {
                    searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear, size: 18),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _statusFilters(List<String> statuses) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((status) {
          final selected = selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  selectedStatus = status;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdmissionsTable(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return _emptyState();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 52,
          dataRowMinHeight: 70,
          dataRowMaxHeight: 78,
          columnSpacing: 28,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          columns: const [
            DataColumn(
              label: Text(
                'Application',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Student',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Parent',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Class',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Applied On',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
          rows: data.map((admission) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    admission['applicationId'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    admission['studentName'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    admission['parentName'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                DataCell(_classBadge(admission['className'])),
                DataCell(
                  Text(
                    admission['date'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                DataCell(_statusBadge(admission['status'])),
                DataCell(_actionButtons(admission)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _classBadge(String className) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        className,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color background;
    Color foreground;

    switch (status) {
      case 'Approved':
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF15803D);
        break;

      case 'Rejected':
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFFDC2626);
        break;

      default:
        background = const Color(0xFFFEF3C7);
        foreground = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _actionButtons(Map<String, dynamic> admission) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () {
            _showAdmissionDetails(admission);
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        if (admission['status'] == 'Pending') ...[
          IconButton(
            tooltip: 'Approve',
            onPressed: () {
              _approveAdmission(admission);
            },
            icon: const Icon(
              Icons.check_circle_outline,
              size: 18,
              color: Color(0xFF15803D),
            ),
          ),
          IconButton(
            tooltip: 'Reject',
            onPressed: () {
              _confirmReject(admission);
            },
            icon: const Icon(
              Icons.cancel_outlined,
              size: 18,
              color: Color(0xFFDC2626),
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 55,
            color: Color(0xFFD1D5DB),
          ),
          SizedBox(height: 12),
          Text(
            'No admission applications found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Try changing your search or filter.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
