import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/fee_report_model.dart';
import '../services/report_service.dart';

class FeeReportScreen extends StatefulWidget {
  const FeeReportScreen({super.key});

  @override
  State<FeeReportScreen> createState() => _FeeReportScreenState();
}

class _FeeReportScreenState extends State<FeeReportScreen> {
  late final ReportService _service;

  List<FeeReportModel> _items = [];

  DateTime _from = DateTime.now().subtract(
    const Duration(days: 30),
  );
  DateTime _to = DateTime.now();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ReportService(ApiClient());
    _load();
  }

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getFeeReport(
        from: _date(_from),
        to: _date(_to),
      );

      if (mounted) {
        setState(() => _items = result);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pick(bool isFrom) async {
    final result = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: isFrom ? _from : _to,
    );

    if (result == null) return;

    setState(() {
      if (isFrom) {
        _from = result;
      } else {
        _to = result;
      }
    });

    _load();
  }

  @override
  Widget build(BuildContext context) {
    double total = _items.fold(
      0,
      (sum, item) => sum + (item.amount ?? 0),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Fee Report',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                _summaryCard(
                  'Payments',
                  '${_items.length}',
                  Icons.receipt_long_rounded,
                ),
                const SizedBox(width: 16),
                _summaryCard(
                  'Collected',
                  '₹${total.toStringAsFixed(2)}',
                  Icons.currency_rupee_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _filters(),
            const SizedBox(height: 18),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _box(),
        child: Row(
          children: [
            Icon(
              icon,
              size: 30,
              color: const Color(0xFF059669),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Row(
        children: [
          _dateButton('From', _from, () => _pick(true)),
          const SizedBox(width: 12),
          _dateButton('To', _to, () => _pick(false)),
          const Spacer(),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(
    String label,
    DateTime date,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$label: ${_date(date)}',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('No fee payments found.'),
      );
    }

    return Container(
      decoration: _box(),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Receipt')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Remarks')),
          ],
          rows: _items.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.paymentDate ?? '-')),
                DataCell(Text(item.studentName ?? '-')),
                DataCell(Text(item.receiptNumber ?? '-')),
                DataCell(
                  Text(
                    '₹${(item.amount ?? 0).toStringAsFixed(2)}',
                  ),
                ),
                DataCell(Text(item.paymentMethod ?? '-')),
                DataCell(Text(item.remarks ?? '-')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
      ),
    );
  }
}