
import 'package:flutter/material.dart';

import '../fees/models/fee_model.dart';
import 'payment_history_screen.dart';
import '../fees/services/fee_service.dart';
import 'package:flutter/material.dart';


import 'package:flutter/material.dart';

import '../fees/models/fee_model.dart';
import '../fees/services/fee_service.dart';
import 'payment_history_screen.dart';

class FeeDetailsScreen extends StatefulWidget {
  final StudentFeeModel record;

  const FeeDetailsScreen({
    super.key,
    required this.record,
  });

  @override
  State<FeeDetailsScreen> createState() =>
      _FeeDetailsScreenState();
}

class _FeeDetailsScreenState
    extends State<FeeDetailsScreen> {
  final FeeService _feeService = FeeService();

  late StudentFeeModel record;

  bool isPaymentSaving = false;

  @override
  void initState() {
    super.initState();
    record = widget.record;
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

  double get progress {
    if (record.totalAmount <= 0) {
      return 0;
    }

    return (record.paidAmount /
            record.totalAmount)
        .clamp(0.0, 1.0);
  }

  String get displayStatus {
    if (record.pendingAmount <= 0) {
      return 'PAID';
    }

    if (record.paidAmount > 0) {
      return 'PARTIAL';
    }

    return 'PENDING';
  }

  Future<void> _openPaymentHistory() async {
    if (record.studentId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentHistoryScreen(
          studentId: record.studentId!,
          studentName: record.studentName,
        ),
      ),
    );
  }

  Future<void> _collectPayment() async {
    final amountController =
        TextEditingController();

    final remarksController =
        TextEditingController();

    String paymentMethod = 'CASH';

    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 460,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Collect Payment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        record.studentName,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(
                          14,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFF8FAFC,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text(
                              'Outstanding',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Color(
                                  0xFF64748B,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency(
                                record
                                    .pendingAmount,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    Color(
                                  0xFFDC2626,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller:
                            amountController,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<
                          String>(
                        initialValue:
                            paymentMethod,
                        decoration:
                            InputDecoration(
                          labelText:
                              'Payment Method',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'CASH',
                            child:
                                Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: 'UPI',
                            child:
                                Text('UPI'),
                          ),
                          DropdownMenuItem(
                            value:
                                'BANK_TRANSFER',
                            child: Text(
                              'Bank Transfer',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'CARD',
                            child:
                                Text('Card'),
                          ),
                          DropdownMenuItem(
                            value: 'CHEQUE',
                            child:
                                Text('Cheque'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value ==
                                    null) {
                                  return;
                                }

                                setDialogState(
                                  () {
                                    paymentMethod =
                                        value;
                                  },
                                );
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller:
                            remarksController,
                        maxLines: 2,
                        decoration:
                            InputDecoration(
                          labelText: 'Remarks',
                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  final amount =
                                      double
                                          .tryParse(
                                    amountController
                                        .text
                                        .trim(),
                                  );

                                  if (amount ==
                                          null ||
                                      amount <= 0) {
                                    _showMessage(
                                      'Enter a valid amount.',
                                      isError:
                                          true,
                                    );
                                    return;
                                  }

                                  if (amount >
                                      record
                                          .pendingAmount) {
                                    _showMessage(
                                      'Amount exceeds pending fee.',
                                      isError:
                                          true,
                                    );
                                    return;
                                  }

                                  setDialogState(
                                    () {
                                      saving =
                                          true;
                                    },
                                  );

                                  try {
                                    await _feeService
                                        .recordPayment(
                                      studentFeeId:
                                          record.id!,
                                      amount:
                                          amount,
                                      paymentMethod:
                                          paymentMethod,
                                      remarks:
                                          remarksController
                                              .text
                                              .trim(),
                                    );

                                    if (!mounted) {
                                      return;
                                    }

                                    Navigator.pop(
                                      dialogContext,
                                      true,
                                    );
                                  } catch (e) {
                                    setDialogState(
                                      () {
                                        saving =
                                            false;
                                      },
                                    );

                                    _showMessage(
                                      e.toString()
                                          .replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                      isError:
                                          true,
                                    );
                                  }
                                },
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF2563EB,
                            ),
                            foregroundColor:
                                Colors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                12,
                              ),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors
                                            .white,
                                  ),
                                )
                              : const Text(
                                  'Record Payment',
                                  style:
                                      TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w700,
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
      },
    );

    amountController.dispose();
    remarksController.dispose();

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = progress * 100;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor:
            const Color(0xFF0F172A),
        title: const Text(
          'Fee Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 1050,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _studentHeader(),
                const SizedBox(height: 20),
                _paymentProgress(
                  percentage,
                ),
                const SizedBox(height: 20),
                _feeInformation(),
                const SizedBox(height: 20),
                _actionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _studentHeader() {
    final name = record.studentName.isEmpty
        ? 'Student #${record.studentId}'
        : record.studentName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF4F46E5),
                ],
              ),
              borderRadius:
                  BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                name.isEmpty
                    ? '?'
                    : name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Student ID: ${record.studentId ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  record.feeName,
                  style: const TextStyle(
                    fontSize: 12,
                    color:
                        Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _statusChip(),
        ],
      ),
    );
  }

  Widget _statusChip() {
    Color color;
    Color background;

    switch (displayStatus) {
      case 'PAID':
        color =
            const Color(0xFF15803D);
        background =
            const Color(0xFFDCFCE7);
        break;
      case 'PARTIAL':
        color =
            const Color(0xFFD97706);
        background =
            const Color(0xFFFEF3C7);
        break;
      default:
        color =
            const Color(0xFFDC2626);
        background =
            const Color(0xFFFEE2E2);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(30),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }

  Widget _paymentProgress(
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile =
              constraints.maxWidth < 650;

          final progressWidget =
              SizedBox(
            height: 108,
            width: 108,
            child: Stack(
              alignment:
                  Alignment.center,
              children: [
                SizedBox(
                  height: 108,
                  width: 108,
                  child:
                      CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor:
                        const Color(
                      0xFFE2E8F0,
                    ),
                    valueColor:
                        const AlwaysStoppedAnimation(
                      Color(0xFF2563EB),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style:
                          const TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Paid',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final amounts = Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              _amountBlock(
                'Total Fee',
                record.totalAmount,
                const Color(
                  0xFF2563EB,
                ),
              ),
              _amountBlock(
                'Paid',
                record.paidAmount,
                const Color(
                  0xFF059669,
                ),
              ),
              _amountBlock(
                'Remaining',
                record.pendingAmount,
                const Color(
                  0xFFDC2626,
                ),
              ),
            ],
          );

          if (mobile) {
            return Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: progressWidget,
                ),
                const SizedBox(height: 22),
                const Text(
                  'Payment Progress',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 17),
                amounts,
              ],
            );
          }

          return Row(
            children: [
              progressWidget,
              const SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    const Text(
                      'Payment Progress',
                      style:
                          TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height: 17,
                    ),
                    amounts,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _amountBlock(
    String title,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color:
                Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _feeInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          _infoRow(
            'Fee Name',
            record.feeName,
            Icons.receipt_long_outlined,
          ),
          _infoRow(
            'Total Amount',
            _formatCurrency(
              record.totalAmount,
            ),
            Icons.account_balance_wallet_outlined,
          ),
          _infoRow(
            'Paid Amount',
            _formatCurrency(
              record.paidAmount,
            ),
            Icons.payments_outlined,
          ),
          _infoRow(
            'Outstanding',
            _formatCurrency(
              record.pendingAmount,
            ),
            Icons.pending_actions_outlined,
          ),
          _infoRow(
            'Due Date',
            _formatDate(
              record.dueDate,
            ),
            Icons.calendar_today_outlined,
          ),
          _infoRow(
            'Status',
            displayStatus,
            Icons.verified_outlined,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 13,
      ),
      decoration:
          const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color:
                Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF8FAFC,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color:
                  const Color(
                0xFF64748B,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    Color(0xFF64748B),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile =
            constraints.maxWidth < 600;

        final history =
            OutlinedButton.icon(
          onPressed:
              _openPaymentHistory,
          icon: const Icon(
            Icons.history_rounded,
          ),
          label: const Text(
            'Payment History',
          ),
          style:
              OutlinedButton.styleFrom(
            minimumSize:
                const Size.fromHeight(
              52,
            ),
            foregroundColor:
                const Color(
              0xFF334155,
            ),
            side: const BorderSide(
              color:
                  Color(0xFFCBD5E1),
            ),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
          ),
        );

        final collect =
            ElevatedButton.icon(
          onPressed:
              record.pendingAmount > 0
                  ? _collectPayment
                  : null,
          icon: const Icon(
            Icons.add_card_rounded,
          ),
          label: const Text(
            'Collect Payment',
          ),
          style:
              ElevatedButton.styleFrom(
            minimumSize:
                const Size.fromHeight(
              52,
            ),
            backgroundColor:
                const Color(
              0xFF2563EB,
            ),
            foregroundColor:
                Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),
          ),
        );

        if (mobile) {
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: history,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: collect,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: history),
            const SizedBox(width: 14),
            Expanded(child: collect),
          ],
        );
      },
    );
  }
}
