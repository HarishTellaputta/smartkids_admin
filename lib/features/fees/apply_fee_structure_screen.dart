import 'package:flutter/material.dart';

import 'package:smartkids_admin/features/fees/services/fee_service.dart';

class ApplyFeeStructureScreen extends StatefulWidget {
  const ApplyFeeStructureScreen({super.key});

  @override
  State<ApplyFeeStructureScreen> createState() =>
      _ApplyFeeStructureScreenState();
}

class _ApplyFeeStructureScreenState extends State<ApplyFeeStructureScreen> {
  final FeeService _feeService = FeeService();

  List<dynamic> feeStructures = [];

  bool isLoading = true;
  int? applyingId;
  int? enablingId;

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeeStructures();
  }

  Future<void> _loadFeeStructures() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _feeService.getFeeStructures();

      if (!mounted) return;

      setState(() {
        feeStructures = result;
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

  String _formatCurrency(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '') ?? 0;

    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(dynamic value) {
    final date = value?.toString() ?? '';

    if (date.isEmpty || date == '-') {
      return '-';
    }

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

  Future<void> _confirmEnable(int structureId, String structureName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_open_rounded, color: Color(0xFF059669)),
              SizedBox(width: 10),
              Text('Enable Fee Structure'),
            ],
          ),
          content: Text(
            'Enable "$structureName" for editing and applying again?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.lock_open_rounded, size: 17),
              label: const Text('Enable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      enablingId = structureId;
    });

    try {
      await _feeService.enableFeeStructure(structureId);

      if (!mounted) return;

      _showMessage('$structureName enabled successfully.');

      await _loadFeeStructures();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          enablingId = null;
        });
      }
    }
  }

  Future<void> _confirmApply(Map<String, dynamic> structure) async {
    final structureId = int.tryParse(structure['id']?.toString() ?? '');

    if (structureId == null) {
      _showMessage('Fee structure ID not found.', isError: true);
      return;
    }

    final name = structure['name']?.toString() ?? 'Fee Structure';

    final amount = _formatCurrency(structure['amount']);

    final className =
        structure['className']?.toString() ??
        structure['class_name']?.toString() ??
        structure['classId']?.toString() ??
        '-';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.play_circle_outline_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Apply Fee Structure'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),

              _infoRow('Class', className),

              const SizedBox(height: 8),

              _infoRow('Amount', amount),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFFEA580C),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will create fee records for all eligible students in this class.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Apply'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _applyFeeStructure(structureId, name);
  }

  Future<void> _applyFeeStructure(int structureId, String structureName) async {
    setState(() {
      applyingId = structureId;
    });

    try {
      await _feeService.applyFeeStructure(structureId);

      if (!mounted) return;

      _showMessage('$structureName applied successfully.');

      await _loadFeeStructures();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          applyingId = null;
        });
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF059669),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: const Text(
          'Apply Fee Structures',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _loadFeeStructures,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1250),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [Expanded(child: _buildContent())]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return _buildError();
    }

    if (feeStructures.isEmpty) {
      return _buildEmpty();
    }

    return _buildTable();
  }

  Widget _buildTable() {
    return Container(
      width: double.infinity,
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
          // ==========================================================
          // HEADER
          // ==========================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fee Structures',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Apply configured fee structures to eligible students',
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
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${feeStructures.length} structures',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ==========================================================
          // TABLE
          // ==========================================================
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          headingRowHeight: 50,
                          dataRowMinHeight: 64,
                          dataRowMaxHeight: 76,
                          columnSpacing: 32,
                          horizontalMargin: 22,

                          headingTextStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                          ),

                          dataTextStyle: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                          ),

                          columns: const [
                            DataColumn(label: Text('FEE')),
                            DataColumn(label: Text('CLASS')),
                            DataColumn(label: Text('AMOUNT')),
                            DataColumn(label: Text('DUE DATE')),
                            DataColumn(label: Text('STATUS')),
                            DataColumn(label: Text('ACTION')),
                          ],

                          rows: feeStructures.map((item) {
                            final structure = Map<String, dynamic>.from(item);

                            final id = int.tryParse(
                              structure['id']?.toString() ?? '',
                            );

                            final name = structure['name']?.toString() ?? '-';

                            final className =
                                structure['className']?.toString() ??
                                structure['class_name']?.toString() ??
                                structure['classId']?.toString() ??
                                '-';

                            final amount = _formatCurrency(structure['amount']);

                            final dueDate = _formatDate(structure['dueDate']);

                            final status =
                                structure['status']?.toString() ?? 'ACTIVE';

                            final applied = structure['applied'] == true;

                            final isApplying = applyingId == id;

                            final isEnabling = enablingId == id;

                            return DataRow(
                              cells: [
                                // ==================================================
                                // FEE
                                // ==================================================

                                DataCell(
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 190,
                                    ),
                                    child: Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),

                                // ==================================================
                                // CLASS
                                // ==================================================
                                DataCell(
                                  Text(
                                    className,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // ==================================================
                                // AMOUNT
                                // ==================================================
                                DataCell(
                                  Text(
                                    amount,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),

                                // ==================================================
                                // DUE DATE
                                // ==================================================
                                DataCell(
                                  Text(
                                    dueDate,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),

                                // ==================================================
                                // STATUS
                                // ==================================================
                                DataCell(_statusChip(status)),

                                // ==================================================
                                // ACTION
                                // ==================================================
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // ==========================================
                                      // APPLIED
                                      // ==========================================

                                      if (applied)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                size: 17,
                                                color: Color(0xFF15803D),
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Applied',
                                                style: TextStyle(
                                                  color: Color(0xFF15803D),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      // ==========================================
                                      // NOT APPLIED
                                      // ==========================================
                                      else
                                        ElevatedButton.icon(
                                          onPressed: id == null || isApplying
                                              ? null
                                              : () {
                                                  _confirmApply(structure);
                                                },
                                          icon: isApplying
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.play_arrow_rounded,
                                                  size: 17,
                                                ),
                                          label: Text(
                                            isApplying
                                                ? 'Applying...'
                                                : 'Apply',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF2563EB,
                                            ),
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor:
                                                const Color(0xFF93C5FD),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 13,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),

                                      // ==========================================
                                      // ENABLE
                                      // ==========================================
                                      if (applied) ...[
                                        const SizedBox(width: 8),

                                        OutlinedButton.icon(
                                          onPressed: id == null || isEnabling
                                              ? null
                                              : () {
                                                  _confirmEnable(id, name);
                                                },
                                          icon: isEnabling
                                              ? const SizedBox(
                                                  width: 15,
                                                  height: 15,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.lock_open_rounded,
                                                  size: 16,
                                                ),
                                          label: Text(
                                            isEnabling
                                                ? 'Enabling...'
                                                : 'Enable',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF059669,
                                            ),
                                            disabledForegroundColor:
                                                const Color(0xFF86EFAC),
                                            side: const BorderSide(
                                              color: Color(0xFF86EFAC),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();

    final active = normalized == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        normalized,
        style: TextStyle(
          color: active ? const Color(0xFF15803D) : const Color(0xFF64748B),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 50,
              color: Color(0xFFCBD5E1),
            ),
            SizedBox(height: 14),
            Text(
              'No fee structures found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Create or import fee structures first.',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(35),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: _loadFeeStructures,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
