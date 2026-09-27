import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/academic_performance_model.dart';
import '../services/report_service.dart';

class AcademicPerformanceScreen extends StatefulWidget {
  const AcademicPerformanceScreen({super.key});

  @override
  State<AcademicPerformanceScreen> createState() =>
      _AcademicPerformanceScreenState();
}

class _AcademicPerformanceScreenState
    extends State<AcademicPerformanceScreen> {
  late final ReportService _service;

  List<AcademicPerformanceModel> _items = [];

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
      final result =
          await _service.getAcademicPerformance();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Academic Performance',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _body(),
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
        child: Text('No academic performance data found.'),
      );
    }

    return Container(
      decoration: _box(),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Examination')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Marks')),
            DataColumn(label: Text('%')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Rank')),
            DataColumn(label: Text('Status')),
          ],
          rows: _items.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.studentName ?? '-')),
                DataCell(Text(item.examinationName ?? '-')),
                DataCell(Text(item.subjectName ?? '-')),
                DataCell(
                  Text(
                    '${item.marksObtained ?? '-'} / ${item.maxMarks ?? '-'}',
                  ),
                ),
                DataCell(
                  Text(
                    item.percentage == null
                        ? '-'
                        : '${item.percentage!.toStringAsFixed(1)}%',
                  ),
                ),
                DataCell(Text(item.grade ?? '-')),
                DataCell(
                  Text('${item.classRank ?? '-'}'),
                ),
                DataCell(Text(item.status ?? '-')),
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