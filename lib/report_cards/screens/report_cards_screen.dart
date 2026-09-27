import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../services/report_card_service.dart';
import 'report_card_view_screen.dart';

class ReportCardsScreen extends StatefulWidget {
  const ReportCardsScreen({super.key});

  @override
  State<ReportCardsScreen> createState() =>
      _ReportCardsScreenState();
}

class _ReportCardsScreenState
    extends State<ReportCardsScreen> {
  final TextEditingController _studentController =
      TextEditingController();

  final TextEditingController _examController =
      TextEditingController();

  late final ReportCardService _service;

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ReportCardService(ApiClient());
  }

  @override
  void dispose() {
    _studentController.dispose();
    _examController.dispose();
    super.dispose();
  }

  Future<void> _openReportCard() async {
    final studentId = int.tryParse(
      _studentController.text.trim(),
    );

    final examinationId = int.tryParse(
      _examController.text.trim(),
    );

    if (studentId == null || examinationId == null) {
      setState(() {
        _error =
            'Please enter valid Student ID and Examination ID.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final report = await _service.getReportCard(
        studentId: studentId,
        examinationId: examinationId,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReportCardViewScreen(
            reportCard: report,
            service: _service,
          ),
        ),
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Cards',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'View and download student examination report cards.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),

            Container(
              constraints: const BoxConstraints(
                maxWidth: 800,
              ),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: Color(0xFF4F46E5),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Generate Report Card',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: _studentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Student ID',
                      hintText: 'Enter student ID',
                      prefixIcon: const Icon(
                        Icons.person_rounded,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _examController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Examination ID',
                      hintText: 'Enter examination ID',
                      prefixIcon: const Icon(
                        Icons.school_rounded,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _loading ? null : _openReportCard,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.visibility_rounded,
                            ),
                      label: Text(
                        _loading
                            ? 'Loading...'
                            : 'View Report Card',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 17,
                        ),
                        backgroundColor:
                            const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}