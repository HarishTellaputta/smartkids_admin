
import 'package:flutter/material.dart';

import '../fees/models/fee_model.dart';
import '../fees/services/fee_service.dart';

import 'package:flutter/material.dart';

import '../fees/models/fee_model.dart';
import '../fees/services/fee_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final int studentId;
  final String studentName;

  const PaymentHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState
    extends State<PaymentHistoryScreen> {
  final FeeService _feeService = FeeService();

  List<FeePaymentModel> payments = [];

  bool isLoading = true;
  String? errorMessage;

  int currentPage = 0;
  int pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentPage = 0;
    });

    try {
      final data = await _feeService.getPayments(
        studentId: widget.studentId,
      );

      if (!mounted) return;

      setState(() {
        payments = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst(
              'Exception: ',
              '',
            );
      });
    }
  }

  String _formatCurrency(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '-';

    try {
      final d = DateTime.parse(date);

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

      return '${d.day.toString().padLeft(2, '0')} '
          '${months[d.month]} ${d.year}';
    } catch (_) {
      return date;
    }
  }

  double get totalPaid {
    return payments.fold(
      0,
      (sum, item) => sum + item.amount,
    );
  }

  int get totalPages {
    if (payments.isEmpty) return 1;
    return (payments.length / pageSize).ceil();
  }

  List<FeePaymentModel> get paginatedPayments {
    final start = currentPage * pageSize;

    if (start >= payments.length) {
      return [];
    }

    final end =
        (start + pageSize).clamp(0, payments.length);

    return payments.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Payment History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                isLoading ? null : _loadPayments,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _studentHeader(),
                  const SizedBox(height: 20),
                  _summaryCard(),
                  const SizedBox(height: 20),
                  _paymentList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentHeader() {
    final name = widget.studentName.isEmpty
        ? 'Student #${widget.studentId}'
        : widget.studentName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Center(
              child: Text(
                name.isEmpty
                    ? '?'
                    : name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Student ID: ${widget.studentId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Text(
              'PAYMENTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;

        final collected = _metricCard(
          'Total Collected',
          _formatCurrency(totalPaid),
          'All recorded payments',
          Icons.payments_outlined,
          const Color(0xFF059669),
          const Color(0xFFECFDF5),
        );

        final transactions = _metricCard(
          'Transactions',
          '${payments.length}',
          'Payment records',
          Icons.receipt_long_outlined,
          const Color(0xFF2563EB),
          const Color(0xFFEFF6FF),
        );

        if (mobile) {
          return Column(
            children: [
              collected,
              const SizedBox(height: 12),
              transactions,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: collected),
            const SizedBox(width: 14),
            Expanded(child: transactions),
          ],
        );
      },
    );
  }

  Widget _metricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color iconBackground,
  ) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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

  Widget _paymentList() {
    final visiblePayments = paginatedPayments;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete payment history for this student',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLoading && payments.isNotEmpty)
                _pageSizeDropdown(),
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
          else if (payments.isEmpty)
            _emptyState()
          else ...[
            ...visiblePayments.map(_paymentCard),
            const SizedBox(height: 8),
            _pagination(),
          ],
        ],
      ),
    );
  }

  Widget _pageSizeDropdown() {
    return SizedBox(
      width: 125,
      child: DropdownButtonFormField<int>(
        initialValue: pageSize,
        decoration: InputDecoration(
          labelText: 'Per page',
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 5,
            child: Text('5'),
          ),
          DropdownMenuItem(
            value: 10,
            child: Text('10'),
          ),
          DropdownMenuItem(
            value: 20,
            child: Text('20'),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            pageSize = value;
            currentPage = 0;
          });
        },
      ),
    );
  }

  Widget _paymentCard(
    FeePaymentModel payment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  payment.receiptNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 7,
                  runSpacing: 3,
                  children: [
                    Text(
                      _formatDate(
                        payment.paymentDate,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Text(
                      '•',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    Text(
                      payment.paymentMethod,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
                if (payment.remarks.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    payment.remarks,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(payment.amount),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    final start = currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize)
        .clamp(0, payments.length);

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$start–$end of ${payments.length} payments',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Previous',
            onPressed: currentPage == 0
                ? null
                : () {
                    setState(() {
                      currentPage--;
                    });
                  },
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Text(
              '${currentPage + 1} / $totalPages',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next',
            onPressed:
                currentPage >= totalPages - 1
                    ? null
                    : () {
                        setState(() {
                          currentPage++;
                        });
                      },
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
        ],
      ),
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
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 12),
            Text(
              'No payments yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Payment transactions will appear here.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
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
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _loadPayments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
