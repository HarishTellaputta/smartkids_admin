import 'package:flutter/material.dart';

class TeacherFilterDialog extends StatefulWidget {
  final String selectedStatus;

  const TeacherFilterDialog({
    super.key,
    required this.selectedStatus,
  });

  @override
  State<TeacherFilterDialog> createState() =>
      _TeacherFilterDialogState();
}

class _TeacherFilterDialogState
    extends State<TeacherFilterDialog> {
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.filter_list,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Filter Teachers',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teacher Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  label: 'All',
                  value: 'All',
                ),
                _filterChip(
                  label: 'Active',
                  value: 'ACTIVE',
                ),
                _filterChip(
                  label: 'Inactive',
                  value: 'INACTIVE',
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_selectedStatus);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
  }) {
    final selected = _selectedStatus == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedStatus = value;
        });
      },
      selectedColor: const Color(0xFFEFF4FF),
      backgroundColor: const Color(0xFFF8FAFC),
      side: BorderSide(
        color: selected
            ? const Color(0xFF2563EB)
            : const Color(0xFFD0D5DD),
      ),
      labelStyle: TextStyle(
        color: selected
            ? const Color(0xFF2563EB)
            : const Color(0xFF344054),
        fontWeight: selected
            ? FontWeight.w700
            : FontWeight.w500,
      ),
      showCheckmark: false,
    );
  }
}