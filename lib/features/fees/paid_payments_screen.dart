import 'package:flutter/material.dart';

import 'models/fee_model.dart';
import 'services/fee_service.dart';

class PaidPaymentsScreen extends StatefulWidget {
  const PaidPaymentsScreen({super.key});

  @override
  State<PaidPaymentsScreen> createState() => _PaidPaymentsScreenState();
}

class _PaidPaymentsScreenState extends State<PaidPaymentsScreen> {
  final FeeService _feeService = FeeService();
  final TextEditingController _searchController = TextEditingController();

  List<FeePaymentModel> payments = [];

  bool isLoading = true;
  String? errorMessage;

  String searchQuery = '';
  String selectedMethod = 'All';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _feeService.getPayments();

      if (!mounted) return;

      setState(() {
        payments = result;
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

  List<FeePaymentModel> get filteredPayments {
    return payments.where((payment) {
      final matchesSearch =
          searchQuery.isEmpty ||
          payment.studentName.toLowerCase().contains(searchQuery) ||
          payment.receiptNumber.toLowerCase().contains(searchQuery) ||
          payment.paymentMethod.toLowerCase().contains(searchQuery) ||
          payment.remarks.toLowerCase().contains(searchQuery);

      final matchesMethod =
          selectedMethod == 'All' || payment.paymentMethod == selectedMethod;

      return matchesSearch && matchesMethod;
    }).toList();
  }

  double get totalCollected {
    return payments.fold(0, (sum, payment) => sum + payment.amount);
  }

  String _formatCurrency(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);

      String month;

      switch (parsed.month) {
        case 1:
          month = 'Jan';
          break;
        case 2:
          month = 'Feb';
          break;
        case 3:
          month = 'Mar';
          break;
        case 4:
          month = 'Apr';
          break;
        case 5:
          month = 'May';
          break;
        case 6:
          month = 'Jun';
          break;
        case 7:
          month = 'Jul';
          break;
        case 8:
          month = 'Aug';
          break;
        case 9:
          month = 'Sep';
          break;
        case 10:
          month = 'Oct';
          break;
        case 11:
          month = 'Nov';
          break;
        case 12:
          month = 'Dec';
          break;
        default:
          month = '';
      }

      return '${parsed.day} $month ${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'CASH':
        return 'Cash';
      case 'UPI':
        return 'UPI';
      case 'BANK_TRANSFER':
        return 'Bank Transfer';
      case 'CARD':
        return 'Card';
      case 'CHEQUE':
        return 'Cheque';
      default:
        return method;
    }
  }

  Color _methodColor(String method) {
    switch (method) {
      case 'CASH':
        return const Color(0xFF059669);
      case 'UPI':
        return const Color(0xFF2563EB);
      case 'BANK_TRANSFER':
        return const Color(0xFF7C3AED);
      case 'CARD':
        return const Color(0xFFD97706);
      case 'CHEQUE':
        return const Color(0xFF475569);
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _showPaymentDetails(FeePaymentModel payment) async {
    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 46,
                        width: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _detailRow(
                    'Student',
                    payment.studentName.isEmpty
                        ? 'Student #${payment.studentId ?? '-'}'
                        : payment.studentName,
                  ),
                  _detailRow('Receipt Number', payment.receiptNumber),
                  _detailRow(
                    'Amount Paid',
                    _formatCurrency(payment.amount),
                    valueColor: const Color(0xFF059669),
                  ),
                  _detailRow(
                    'Payment Method',
                    _methodLabel(payment.paymentMethod),
                  ),
                  _detailRow('Payment Date', _formatDate(payment.paymentDate)),
                  if (payment.remarks.isNotEmpty)
                    _detailRow('Remarks', payment.remarks),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showMessage('Receipt download can be connected here.');
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('View / Download Receipt'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final records = filteredPayments;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildSummary(),
                  const SizedBox(height: 22),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  _buildPaymentTable(records),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paid Payments',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'View collected fees and payment history',
                style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade500),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: isLoading ? null : _loadPayments,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 720;

        final cards = [
          _summaryCard(
            title: 'Total Payments',
            value: '${payments.length}',
            subtitle: 'Recorded transactions',
            icon: Icons.receipt_long_outlined,
            background: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
          ),
          _summaryCard(
            title: 'Total Collected',
            value: _formatCurrency(totalCollected),
            subtitle: 'Amount received',
            icon: Icons.payments_outlined,
            background: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
          ),
          _summaryCard(
            title: 'UPI Payments',
            value: '${payments.where((p) => p.paymentMethod == 'UPI').length}',
            subtitle: 'Digital transactions',
            icon: Icons.qr_code_rounded,
            background: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF7C3AED),
          ),
          _summaryCard(
            title: 'Cash Payments',
            value: '${payments.where((p) => p.paymentMethod == 'CASH').length}',
            subtitle: 'Cash transactions',
            icon: Icons.account_balance_wallet_outlined,
            background: const Color(0xFFFFF7ED),
            iconColor: const Color(0xFFD97706),
          ),
        ];

        if (mobile) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
            const SizedBox(width: 14),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color background,
    required Color iconColor,
  }) {
    return Container(
      height: 142,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 750;

          final search = TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search student or receipt...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );

          final methodDropdown = DropdownButtonFormField<String>(
            initialValue: selectedMethod,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Payment Method',
              prefixIcon: const Icon(Icons.payments_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All Methods')),
              DropdownMenuItem(value: 'CASH', child: Text('Cash')),
              DropdownMenuItem(value: 'UPI', child: Text('UPI')),
              DropdownMenuItem(
                value: 'BANK_TRANSFER',
                child: Text('Bank Transfer'),
              ),
              DropdownMenuItem(value: 'CARD', child: Text('Card')),
              DropdownMenuItem(value: 'CHEQUE', child: Text('Cheque')),
            ],
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedMethod = value;
              });
            },
          );

          if (mobile) {
            return Column(
              children: [search, const SizedBox(height: 12), methodDropdown],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 12),
              SizedBox(width: 260, child: methodDropdown),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentTable(List<FeePaymentModel> records) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Click a payment to view full details',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${records.length} payments',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            _errorState()
          else if (records.isEmpty)
            _emptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowHeight: 48,
                      dataRowMinHeight: 68,
                      dataRowMaxHeight: 76,
                      columnSpacing: 30,
                      horizontalMargin: 20,
                      showCheckboxColumn: false,
                      headingTextStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                      columns: const [
                        DataColumn(label: Text('STUDENT')),
                        DataColumn(label: Text('RECEIPT')),
                        DataColumn(label: Text('AMOUNT')),
                        DataColumn(label: Text('METHOD')),
                        DataColumn(label: Text('DATE')),
                        DataColumn(label: Text('ACTION')),
                      ],
                      rows: records.map((payment) {
                        return DataRow(
                          onSelectChanged: (_) {
                            _showPaymentDetails(payment);
                          },
                          cells: [
                            DataCell(
                              _studentCell(payment),
                              onTap: () => _showPaymentDetails(payment),
                            ),
                            DataCell(
                              Text(
                                payment.receiptNumber.isEmpty
                                    ? '-'
                                    : payment.receiptNumber,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              onTap: () => _showPaymentDetails(payment),
                            ),
                            DataCell(
                              Text(
                                _formatCurrency(payment.amount),
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onTap: () => _showPaymentDetails(payment),
                            ),
                            DataCell(
                              _methodChip(payment.paymentMethod),
                              onTap: () => _showPaymentDetails(payment),
                            ),
                            DataCell(
                              Text(_formatDate(payment.paymentDate)),
                              onTap: () => _showPaymentDetails(payment),
                            ),
                            DataCell(
                              IconButton(
                                tooltip: 'Payment Details',
                                onPressed: () => _showPaymentDetails(payment),
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 20,
                                ),
                                color: const Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _studentCell(FeePaymentModel payment) {
    final name = payment.studentName.isEmpty
        ? 'Student #${payment.studentId ?? '-'}'
        : payment.studentName;

    return SizedBox(
      width: 185,
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ID: ${payment.studentId ?? '-'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodChip(String method) {
    final color = _methodColor(method);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _methodLabel(method),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 65),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 12),
            Text(
              'No payments found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              'Recorded payments will appear here.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 55),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _loadPayments,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
