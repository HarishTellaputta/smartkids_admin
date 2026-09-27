import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/mcq_performance_model.dart';
import '../services/report_service.dart';

class McqPerformanceScreen extends StatefulWidget {
  const McqPerformanceScreen({super.key});

  @override
  State<McqPerformanceScreen> createState() =>
      _McqPerformanceScreenState();
}

class _McqPerformanceScreenState
    extends State<McqPerformanceScreen> {
  late final ReportService _service;

  List<McqPerformanceModel> _items = [];

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
          await _service.getMcqPerformance();

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
          'MCQ Performance',
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
        child: Text('No MCQ attempts found.'),
      );
    }

    return Container(
      decoration: _box(),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Test')),
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Score')),
            DataColumn(label: Text('Correct')),
            DataColumn(label: Text('Wrong')),
            DataColumn(label: Text('%')),
            DataColumn(label: Text('Status')),
          ],
          rows: _items.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.testName ?? '-')),
                DataCell(Text(item.studentName ?? '-')),
                DataCell(
                  Text(
                    '${item.score ?? 0} / ${item.totalQuestions ?? 0}',
                  ),
                ),
                DataCell(
                  Text('${item.correctAnswers ?? 0}'),
                ),
                DataCell(
                  Text('${item.wrongAnswers ?? 0}'),
                ),
                DataCell(
                  Text(
                    item.percentage == null
                        ? '-'
                        : '${item.percentage!.toStringAsFixed(1)}%',
                  ),
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