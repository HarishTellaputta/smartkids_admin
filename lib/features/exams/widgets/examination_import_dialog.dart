
import 'package:flutter/material.dart';

import '../models/examination_import_response_model.dart';
import 'import_summary_card.dart';

class ExaminationImportDialog extends StatelessWidget {
  final ExaminationImportResponseModel result;

  const ExaminationImportDialog({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Color(0xFF16A34A),
          ),
          SizedBox(width: 10),
          Text('Excel Import Result'),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: ImportSummaryCard(
                    title: 'Total Rows',
                    value: result.totalRows.toString(),
                    icon: Icons.table_rows_outlined,
                    color: const Color(0xFF2563EB),
                    background: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ImportSummaryCard(
                    title: 'Created',
                    value: result.created.toString(),
                    icon: Icons.add_circle_outline,
                    color: const Color(0xFF16A34A),
                    background: const Color(0xFFF0FDF4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ImportSummaryCard(
                    title: 'Updated',
                    value: result.updated.toString(),
                    icon: Icons.edit_outlined,
                    color: const Color(0xFFCA8A04),
                    background: const Color(0xFFFEFCE8),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ImportSummaryCard(
                    title: 'Errors',
                    value: result.errors.toString(),
                    icon: Icons.error_outline,
                    color: const Color(0xFFDC2626),
                    background: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
            if (result.errorDetails.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Error Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 220,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: result.errorDetails.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final error = result.errorDetails[index];

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Row ${error.row}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              error.message,
                              style: const TextStyle(
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
