import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/attendance_report_model.dart';
import '../services/report_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() =>
      _AttendanceReportScreenState();
}

class _AttendanceReportScreenState
    extends State<AttendanceReportScreen> {
  late final ReportService _service;

  List<AttendanceReportModel> _items = [];

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getAttendanceReport(
        from: _date(_from),
        to: _date(_to),
      );

      if (!mounted) return;

      setState(() {
        _items = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _date(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate(bool from) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: from ? _from : _to,
    );

    if (selected == null) return;

    setState(() {
      if (from) {
        _from = selected;
      } else {
        _to = selected;
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
          'Attendance Report',
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
            _filterCard(),
            const SizedBox(height: 20),
            Expanded(
              child: _body(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Row(
        children: [
          _dateButton(
            'From',
            _from,
            () => _pickDate(true),
          ),
          const SizedBox(width: 14),
          _dateButton(
            'To',
            _to,
            () => _pickDate(false),
          ),
          const Spacer(),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: Color(0xFF4F46E5),
            ),
            const SizedBox(width: 9),
            Text(
              '$label: ${_date(date)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _errorWidget();
    }

    if (_items.isEmpty) {
      return _emptyWidget('No attendance records found.');
    }

    return Container(
      decoration: _box(),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              WidgetStateProperty.all(
            const Color(0xFFF9FAFB),
          ),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Class')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Remarks')),
          ],
          rows: _items.map((item) {
            return DataRow(
              cells: [
                DataCell(
                  Text(item.attendanceDate ?? '-'),
                ),
                DataCell(
                  Text(item.studentName ?? '-'),
                ),
                DataCell(
                  Text(item.className ?? '-'),
                ),
                DataCell(
                  _status(item.status),
                ),
                DataCell(
                  Text(item.remarks ?? '-'),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _status(String? value) {
    final present = value?.toUpperCase() == 'PRESENT';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: present
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value ?? '-',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: present
              ? const Color(0xFF15803D)
              : const Color(0xFFB91C1C),
        ),
      ),
    );
  }

  Widget _emptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 55,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 50,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
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