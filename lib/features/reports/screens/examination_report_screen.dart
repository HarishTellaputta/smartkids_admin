import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/examination_report_model.dart';
import '../services/report_service.dart';

class ExaminationReportScreen extends StatefulWidget {
  const ExaminationReportScreen({super.key});

  @override
  State<ExaminationReportScreen> createState() =>
      _ExaminationReportScreenState();
}

class _ExaminationReportScreenState
    extends State<ExaminationReportScreen> {
  late final ReportService _service;

  List<ExaminationReportModel> _items = [];

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
      final result = await _service.getExaminationReport(
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Examination Report',
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
            _filters(),
            const SizedBox(height: 20),
            Expanded(child: _content()),
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
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _dateButton(
    String label,
    DateTime value,
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
          '$label: ${_date(value)}',
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text('No examination records found.'),
      );
    }

    return Container(
      decoration: _box(),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Exam')),
            DataColumn(label: Text('Class')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Exam Date')),
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Max Marks')),
            DataColumn(label: Text('Status')),
          ],
          rows: _items.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(item.examinationName ?? '-'),
                ),
                DataCell(
                  Text(item.className ?? '-'),
                ),
                DataCell(
                  Text(item.subjectName ?? '-'),
                ),
                DataCell(
                  Text(item.examDate.toString() ?? '-'),
                ),
                DataCell(
                  Text(item.startTime ?? '-'),
                ),
                DataCell(
                  Text('${item.maxMarks ?? '-'}'),
                ),
                DataCell(
                  Text(item.status ?? '-'),
                ),
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