import 'package:flutter/material.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  String selectedClass = 'All Classes';
  String selectedStatus = 'All';
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> feeRecords = [
    {
      'id': 'FEE001',
      'studentId': 'STU001',
      'student': 'Aarav Kumar',
      'class': 'Class 1 - A',
      'parent': 'Rajesh Kumar',
      'totalFee': 45000.0,
      'paid': 45000.0,
      'due': 0.0,
      'status': 'Paid',
      'lastPayment': '05 Aug 2026',
    },
    {
      'id': 'FEE002',
      'studentId': 'STU002',
      'student': 'Ananya Reddy',
      'class': 'Class 1 - A',
      'parent': 'Suresh Reddy',
      'totalFee': 45000.0,
      'paid': 30000.0,
      'due': 15000.0,
      'status': 'Partial',
      'lastPayment': '01 Aug 2026',
    },
    {
      'id': 'FEE003',
      'studentId': 'STU003',
      'student': 'Vihan Rao',
      'class': 'Class 2 - A',
      'parent': 'Ravi Rao',
      'totalFee': 50000.0,
      'paid': 0.0,
      'due': 50000.0,
      'status': 'Pending',
      'lastPayment': '-',
    },
    {
      'id': 'FEE004',
      'studentId': 'STU004',
      'student': 'Diya Sharma',
      'class': 'Class 2 - A',
      'parent': 'Amit Sharma',
      'totalFee': 50000.0,
      'paid': 50000.0,
      'due': 0.0,
      'status': 'Paid',
      'lastPayment': '03 Aug 2026',
    },
    {
      'id': 'FEE005',
      'studentId': 'STU005',
      'student': 'Arjun Babu',
      'class': 'Class 3 - A',
      'parent': 'Mohan Babu',
      'totalFee': 55000.0,
      'paid': 35000.0,
      'due': 20000.0,
      'status': 'Partial',
      'lastPayment': '28 Jul 2026',
    },
    {
      'id': 'FEE006',
      'studentId': 'STU006',
      'student': 'Sai Reddy',
      'class': 'Class 3 - A',
      'parent': 'Prasad Reddy',
      'totalFee': 55000.0,
      'paid': 55000.0,
      'due': 0.0,
      'status': 'Paid',
      'lastPayment': '02 Aug 2026',
    },
    {
      'id': 'FEE007',
      'studentId': 'STU007',
      'student': 'Krishna Kumar',
      'class': 'Class 4 - A',
      'parent': 'Venkat Kumar',
      'totalFee': 60000.0,
      'paid': 25000.0,
      'due': 35000.0,
      'status': 'Overdue',
      'lastPayment': '10 Jul 2026',
    },
    {
      'id': 'FEE008',
      'studentId': 'STU008',
      'student': 'Rahul Verma',
      'class': 'Class 5 - A',
      'parent': 'Sanjay Verma',
      'totalFee': 65000.0,
      'paid': 65000.0,
      'due': 0.0,
      'status': 'Paid',
      'lastPayment': '30 Jul 2026',
    },
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredRecords {
    return feeRecords.where((record) {
      final query = searchQuery.toLowerCase().trim();

      final matchesSearch =
          query.isEmpty ||
          record['student'].toString().toLowerCase().contains(query) ||
          record['studentId'].toString().toLowerCase().contains(query) ||
          record['parent'].toString().toLowerCase().contains(query);

      final matchesClass =
          selectedClass == 'All Classes' || record['class'] == selectedClass;

      final matchesStatus =
          selectedStatus == 'All' || record['status'] == selectedStatus;

      return matchesSearch && matchesClass && matchesStatus;
    }).toList();
  }

  double get totalFees {
    return feeRecords.fold(
      0,
      (sum, record) => sum + (record['totalFee'] as double),
    );
  }

  double get totalCollected {
    return feeRecords.fold(
      0,
      (sum, record) => sum + (record['paid'] as double),
    );
  }

  double get totalDue {
    return feeRecords.fold(0, (sum, record) => sum + (record['due'] as double));
  }

  int get paidCount => feeRecords.where((e) => e['status'] == 'Paid').length;

  int get pendingCount =>
      feeRecords.where((e) => e['status'] == 'Pending').length;

  int get overdueCount =>
      feeRecords.where((e) => e['status'] == 'Overdue').length;

  double get collectionPercentage {
    if (totalFees == 0) return 0;

    return (totalCollected / totalFees) * 100;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    }

    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    }

    return '₹${amount.toStringAsFixed(0)}';
  }

  void _showAddPaymentDialog(Map<String, dynamic> record) {
    final amountController = TextEditingController();

    String paymentMode = 'Cash';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Record Fee Payment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _studentInfo(record),
                    const SizedBox(height: 18),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Payment Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: paymentMode,
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      items:
                          const [
                            'Cash',
                            'UPI',
                            'Bank Transfer',
                            'Card',
                            'Cheque',
                          ].map((item) {
                            return DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            paymentMode = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Current Due: ${_formatCurrency(record['due'])}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
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
                    final amount = double.tryParse(
                      amountController.text.trim(),
                    );

                    if (amount == null || amount <= 0) {
                      return;
                    }

                    setState(() {
                      final due = record['due'] as double;

                      final actualPayment = amount > due ? due : amount;

                      record['paid'] =
                          (record['paid'] as double) + actualPayment;

                      record['due'] = (record['due'] as double) - actualPayment;

                      if (record['due'] == 0) {
                        record['status'] = 'Paid';
                      } else {
                        record['status'] = 'Partial';
                      }

                      record['lastPayment'] = '10 Aug 2026';
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment recorded successfully.'),
                        backgroundColor: Color(0xFF15803D),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Record Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _studentInfo(Map<String, dynamic> record) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record['student'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            '${record['class']} • ${record['studentId']}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  void _showFeeDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${record['student']} - Fee Details',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Student ID', record['studentId']),
                _detailRow('Class', record['class']),
                _detailRow('Parent', record['parent']),
                _detailRow('Total Fee', _formatCurrency(record['totalFee'])),
                _detailRow('Paid', _formatCurrency(record['paid'])),
                _detailRow('Due', _formatCurrency(record['due'])),
                _detailRow('Last Payment', record['lastPayment']),
                _detailRow('Status', record['status']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (record['due'] > 0)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddPaymentDialog(record);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Collect Payment'),
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
            _buildFeeTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return _headerText();
        }

        return Row(
          children: [
            Expanded(child: _headerText()),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fee report export will be connected later.'),
                  ),
                );
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Export Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
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
          'Fees & Payments',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Track student fees, payments and outstanding balances.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
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
          hintText: 'Search student, parent or ID...',
          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 19),
          border: InputBorder.none,
        ),
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
      items: const ['All', 'Paid', 'Partial', 'Pending', 'Overdue'],
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
              'Total Fees',
              _formatCurrency(totalFees),
              Icons.account_balance_wallet_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Collected',
              _formatCurrency(totalCollected),
              Icons.payments_outlined,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              'Outstanding',
              _formatCurrency(totalDue),
              Icons.pending_actions_outlined,
              const Color(0xFFDC2626),
              const Color(0xFFFEF2F2),
            ),
            _summaryCard(
              'Collection Rate',
              '${collectionPercentage.toStringAsFixed(0)}%',
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
                  fontSize: 20,
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

  Widget _buildFeeTable() {
    final data = filteredRecords;

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
                'Fee Records',
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
          DataColumn(label: Text('Student')),
          DataColumn(label: Text('Class')),
          DataColumn(label: Text('Total Fee')),
          DataColumn(label: Text('Paid')),
          DataColumn(label: Text('Due')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Last Payment')),
          DataColumn(label: Text('Actions')),
        ],
        rows: data.map((record) {
          return DataRow(
            cells: [
              DataCell(_studentCell(record)),
              DataCell(
                Text(record['class'], style: const TextStyle(fontSize: 12)),
              ),
              DataCell(
                Text(
                  _formatCurrency(record['totalFee']),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatCurrency(record['paid']),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatCurrency(record['due']),
                  style: TextStyle(
                    fontSize: 12,
                    color: record['due'] > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(_statusBadge(record['status'])),
              DataCell(
                Text(
                  record['lastPayment'],
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(_actionButtons(record)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _studentCell(Map<String, dynamic> record) {
    final name = record['student'].toString();

    return SizedBox(
      width: 190,
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
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
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record['studentId'],
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
      case 'Paid':
        color = const Color(0xFF15803D);
        background = const Color(0xFFDCFCE7);
        break;

      case 'Partial':
        color = const Color(0xFFD97706);
        background = const Color(0xFFFEF3C7);
        break;

      case 'Overdue':
        color = const Color(0xFFDC2626);
        background = const Color(0xFFFEE2E2);
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

  Widget _actionButtons(Map<String, dynamic> record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View Details',
          onPressed: () {
            _showFeeDetails(record);
          },
          icon: const Icon(Icons.visibility_outlined, size: 18),
        ),
        if (record['due'] > 0)
          IconButton(
            tooltip: 'Collect Payment',
            onPressed: () {
              _showAddPaymentDialog(record);
            },
            icon: const Icon(
              Icons.add_card_outlined,
              size: 18,
              color: Color(0xFF2563EB),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 50,
              color: Color(0xFFD1D5DB),
            ),
            SizedBox(height: 12),
            Text(
              'No fee records found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Try changing your search or filters.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
