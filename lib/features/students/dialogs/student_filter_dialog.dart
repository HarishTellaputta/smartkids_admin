import 'package:flutter/material.dart';

class StudentFilterDialog extends StatefulWidget {
  final String selectedStatus;
  final ValueChanged<String> onApply;

  const StudentFilterDialog({
    super.key,
    required this.selectedStatus,
    required this.onApply,
  });

  @override
  State<StudentFilterDialog> createState() => _StudentFilterDialogState();
}

class _StudentFilterDialogState extends State<StudentFilterDialog> {
  late String _selectedStatus;

  final List<String> _statuses = [
    'All',
    'ACTIVE',
    'INACTIVE',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
  }

  void _applyFilter() {
    widget.onApply(_selectedStatus);
    Navigator.of(context).pop();
  }

  void _resetFilter() {
    setState(() {
      _selectedStatus = 'All';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.filter_list_rounded,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Filter Students',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          Text(
            'Student Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey.shade200,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _statuses.map((status) {
                final bool isSelected = _selectedStatus == status;

                return RadioListTile<String>(
                  value: status,
                  groupValue: _selectedStatus,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  title: Row(
                    children: [
                      _buildStatusIcon(status),
                      const SizedBox(width: 10),
                      Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  activeColor: Colors.blue.shade700,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  dense: true,
                );
              }).toList(),
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: _resetFilter,
          child: const Text(
            'Reset',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(width: 4),

        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),

        const SizedBox(width: 4),

        ElevatedButton(
          onPressed: _applyFilter,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Apply',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case 'ACTIVE':
        return Icon(
          Icons.check_circle_outline,
          size: 20,
          color: Colors.green.shade600,
        );

      case 'INACTIVE':
        return Icon(
          Icons.cancel_outlined,
          size: 20,
          color: Colors.red.shade600,
        );

      default:
        return Icon(
          Icons.people_outline,
          size: 20,
          color: Colors.blue.shade600,
        );
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Active Students';

      case 'INACTIVE':
        return 'Inactive Students';

      default:
        return 'All Students';
    }
  }
}