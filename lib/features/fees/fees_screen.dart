import 'package:flutter/material.dart';
import 'package:smartkids_admin/features/fees/models/fee_model.dart';
import 'package:smartkids_admin/features/fees/services/fee_service.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final FeeService _feeService = FeeService();

  final TextEditingController searchController = TextEditingController();

  List<StudentFeeModel> feeRecords = [];

  String selectedStatus = 'All';
  String searchQuery = '';

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFees() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _feeService.getPendingFees();

      if (!mounted) return;

      setState(() {
        feeRecords = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<StudentFeeModel> get filteredRecords {
    final query = searchQuery.toLowerCase().trim();

    return feeRecords.where((record) {
      final matchesSearch =
          query.isEmpty ||
          record.studentName.toLowerCase().contains(query) ||
          record.studentId.toString().contains(query) ||
          record.feeName.toLowerCase().contains(query);

      final normalizedStatus = _displayStatus(record);

      final matchesStatus =
          selectedStatus == 'All' || normalizedStatus == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  double get totalFees {
    return feeRecords.fold(
      0,
      (sum, record) => sum + record.totalAmount,
    );
  }

  double get totalCollected {
    return feeRecords.fold(
      0,
      (sum, record) => sum + record.paidAmount,
    );
  }

  double get totalDue {
    return feeRecords.fold(
      0,
      (sum, record) => sum + record.pendingAmount,
    );
  }

  double get collectionPercentage {
    if (totalFees == 0) return 0;

    return (totalCollected / totalFees) * 100;
  }

  String _displayStatus(StudentFeeModel record) {
    final status = record.status.trim().toUpperCase();

    if (record.pendingAmount <= 0) {
      return 'Paid';
    }

    if (status == 'OVERDUE') {
      return 'Overdue';
    }

    if (record.paidAmount > 0) {
      return 'Partial';
    }

    if (status == 'PENDING') {
      return 'Pending';
    }

    return record.status.isEmpty ? 'Pending' : record.status;
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

  String _formatDate(String date) {
    if (date.isEmpty) return '-';

    try {
      final parsed = DateTime.parse(date);

      return '${parsed.day.toString().padLeft(2, '0')} '
          '${_monthName(parsed.month)} '
          '${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  String _monthName(int month) {
    const months = [
      '',
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

    return months[month];
  }

  void _showAddPaymentDialog(StudentFeeModel record) {
    final amountController = TextEditingController();

    String paymentMode = 'Cash';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Record Fee Payment',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      items: const [
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
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  paymentMode = value;
                                });
                              }
                            },
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Remarks',
                        hintText: 'Optional',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      onChanged: (value) {},
                    ),

                    const SizedBox(height: 14),

                    Text(
                      'Current Due: ${_formatCurrency(record.pendingAmount)}',
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
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final amount = double.tryParse(
                            amountController.text.trim(),
                          );

                          if (amount == null || amount <= 0) {
                            _showMessage(
                              'Enter a valid payment amount.',
                              isError: true,
                            );
                            return;
                          }

                          if (amount > record.pendingAmount) {
                            _showMessage(
                              'Payment cannot be greater than current due.',
                              isError: true,
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await _feeService.recordPayment(
                              studentFeeId: record.id!,
                              amount: amount,
                              paymentMethod: paymentMode,
                              remarks: '',
                            );

                            if (!mounted) return;

                            Navigator.pop(dialogContext);

                            _showMessage(
                              'Payment recorded successfully.',
                            );

                            await _loadFees();
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });

                            _showMessage(
                              e.toString().replaceFirst('Exception: ', ''),
                              isError: true,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Record Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _studentInfo(StudentFeeModel record) {
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
            record.studentName.isEmpty
                ? 'Student #${record.studentId}'
                : record.studentName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Student ID: ${record.studentId ?? '-'}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            record.feeName,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeeDetails(StudentFeeModel record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${record.studentName} - Fee Details',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(
                  'Student ID',
                  record.studentId?.toString() ?? '-',
                ),
                _detailRow(
                  'Fee',
                  record.feeName,
                ),
                _detailRow(
                  'Total Fee',
                  _formatCurrency(record.totalAmount),
                ),
                _detailRow(
                  'Paid',
                  _formatCurrency(record.paidAmount),
                ),
                _detailRow(
                  'Due',
                  _formatCurrency(record.pendingAmount),
                ),
                _detailRow(
                  'Due Date',
                  _formatDate(record.dueDate),
                ),
                _detailRow(
                  'Status',
                  _displayStatus(record),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            if (record.pendingAmount > 0)
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
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? const Color(0xFFDC2626) : const Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadFees,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            Expanded(
              child: _headerText(),
            ),
            OutlinedButton.icon(
              onPressed: _loadFees,
              icon: const Icon(
                Icons.refresh,
                size: 18,
              ),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(
                  color: Color(0xFFD1D5DB),
                ),
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
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
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
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                _statusDropdown(),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 2,
                child: _searchBox(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statusDropdown(),
              ),
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
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: const InputDecoration(
          hintText: 'Search student, fee name or ID...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 19,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _statusDropdown() {
    return _dropdown(
      value: selectedStatus,
      items: const [
        'All',
        'Paid',
        'Partial',
        'Pending',
        'Overdue',
      ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 19,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
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
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
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
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
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
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 60,
              ),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            _errorState()
          else if (data.isEmpty)
            _emptyState()
          else
            _table(data),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 50,
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFees,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table(List<StudentFeeModel> data) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 28,
        horizontalMargin: 10,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 82,
        headingRowColor: const WidgetStatePropertyAll(
          Color(0xFFF9FAFB),
        ),
        columns: const [
          DataColumn(
            label: Text('Student'),
          ),
          DataColumn(
            label: Text('Fee'),
          ),
          DataColumn(
            label: Text('Total Fee'),
          ),
          DataColumn(
            label: Text('Paid'),
          ),
          DataColumn(
            label: Text('Due'),
          ),
          DataColumn(
            label: Text('Due Date'),
          ),
          DataColumn(
            label: Text('Status'),
          ),
          DataColumn(
            label: Text('Actions'),
          ),
        ],
        rows: data.map((record) {
          return DataRow(
            cells: [
              DataCell(
                _studentCell(record),
              ),
              DataCell(
                Text(
                  record.feeName,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatCurrency(record.totalAmount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatCurrency(record.paidAmount),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatCurrency(record.pendingAmount),
                  style: TextStyle(
                    fontSize: 12,
                    color: record.pendingAmount > 0
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatDate(record.dueDate),
                  style: const TextStyle(
                    fontSize: 11,
                  ),
                ),
              ),
              DataCell(
                _statusBadge(
                  _displayStatus(record),
                ),
              ),
              DataCell(
                _actionButtons(record),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _studentCell(StudentFeeModel record) {
    final name = record.studentName.isEmpty
        ? 'Student #${record.studentId}'
        : record.studentName;

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
                name.isEmpty ? '?' : name[0].toUpperCase(),
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
                  'ID: ${record.studentId ?? '-'}',
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
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
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

  Widget _actionButtons(StudentFeeModel record) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View Details',
          onPressed: () {
            _showFeeDetails(record);
          },
          icon: const Icon(
            Icons.visibility_outlined,
            size: 18,
          ),
        ),
        if (record.pendingAmount > 0)
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
      padding: EdgeInsets.symmetric(
        vertical: 60,
      ),
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
              'No pending fee records are available.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}