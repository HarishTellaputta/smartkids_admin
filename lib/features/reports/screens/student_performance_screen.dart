import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../reports/models/academic_performance_model.dart';
import '../services/report_service.dart';

class StudentPerformanceScreen extends StatefulWidget {
  const StudentPerformanceScreen({super.key});

  @override
  State<StudentPerformanceScreen> createState() =>
      _StudentPerformanceScreenState();
}

class _StudentPerformanceScreenState
    extends State<StudentPerformanceScreen> {
  late final ReportService _service;

  final TextEditingController _studentController =
      TextEditingController();

  List<AcademicPerformanceModel> _items = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ReportService(ApiClient());
  }

  @override
  void dispose() {
    _studentController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final studentId = int.tryParse(
      _studentController.text.trim(),
    );

    if (studentId == null) {
      setState(() {
        _error = 'Please enter a valid student ID.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
          await _service.getStudentPerformance(
        studentId: studentId,
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
          'Student Performance',
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
            _searchCard(),
            const SizedBox(height: 20),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _box(),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _studentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Student ID',
                hintText: 'Enter student ID',
                prefixIcon: const Icon(
                  Icons.person_search_rounded,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton.icon(
            onPressed: _loading ? null : _search,
            icon: const Icon(Icons.search_rounded),
            label: const Text('View Performance'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18,
              ),
            ),
          ),
        ],
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
          'Enter a student ID to view performance.',
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
            DataColumn(label: Text('Marks')),
            DataColumn(label: Text('%')),
            DataColumn(label: Text('Grade')),
            DataColumn(label: Text('Rank')),
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