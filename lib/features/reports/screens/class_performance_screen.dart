import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/examination_report_model.dart';
import '../services/report_service.dart';

class ClassPerformanceScreen extends StatefulWidget {
  const ClassPerformanceScreen({super.key});

  @override
  State<ClassPerformanceScreen> createState() =>
      _ClassPerformanceScreenState();
}

class _ClassPerformanceScreenState
    extends State<ClassPerformanceScreen> {
  late final ReportService _service;

  final TextEditingController _classController =
      TextEditingController();

  List<ExaminationReportModel> _items = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ReportService(ApiClient());
  }

  @override
  void dispose() {
    _classController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final classId = int.tryParse(
      _classController.text.trim(),
    );

    if (classId == null) {
      setState(() {
        _error = 'Please enter a valid class ID.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
          await _service.getClassPerformance(
        classId: classId,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Class Performance',
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _box(),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _classController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Class ID',
                        prefixIcon: const Icon(
                          Icons.class_rounded,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _search,
                    icon: const Icon(
                      Icons.analytics_rounded,
                    ),
                    label: const Text('View Report'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: _body()),
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
      return Center(child: Text(_error!));
    }

    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'Enter a class ID to view class performance.',
        ),
      );
    }

    return Container(
      decoration: _box(),
      child: SingleChildScrollView(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Examination')),
            DataColumn(label: Text('Subject')),
            DataColumn(label: Text('Exam Date')),
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
                  Text(item.subjectName ?? '-'),
                ),
                DataCell(
                  Text(item.examDate.toString() ?? '-'),
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