import 'package:flutter/material.dart';

class StudentToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedStatus;
  final VoidCallback onFilterPressed;
  final VoidCallback onRefresh;
  final VoidCallback onAddStudent;

  const StudentToolbar({
    super.key,
    required this.searchController,
    required this.selectedStatus,
    required this.onFilterPressed,
    required this.onRefresh,
    required this.onAddStudent,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          // SEARCH
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText:
                    'Search by name, admission no, phone, parent...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 21,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          size: 19,
                        ),
                        onPressed: () {
                          searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // FILTER
          OutlinedButton.icon(
            onPressed: onFilterPressed,
            icon: const Icon(
              Icons.filter_list_rounded,
              size: 19,
            ),
            label: Text(
              selectedStatus == 'All'
                  ? 'Filter'
                  : selectedStatus,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              side: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // REFRESH
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 21,
            ),
          ),

          const SizedBox(width: 8),

          // ADD STUDENT
          ElevatedButton.icon(
            onPressed: onAddStudent,
            icon: const Icon(
              Icons.add_rounded,
              size: 19,
            ),
            label: const Text(
              'Add Student',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}