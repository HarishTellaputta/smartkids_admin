import 'package:flutter/material.dart';

class StudentEmptyState extends StatelessWidget {
  final String searchQuery;
  final VoidCallback onAddStudent;
  final VoidCallback onClearSearch;

  const StudentEmptyState({
    super.key,
    required this.searchQuery,
    required this.onAddStudent,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearching = searchQuery.isNotEmpty;

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ICON
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .primaryColor
                    .withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.school_outlined,
                size: 42,
                color: Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 22),

            // TITLE
            Text(
              isSearching
                  ? 'No students found'
                  : 'No students yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            // DESCRIPTION
            Text(
              isSearching
                  ? 'We couldn’t find any student matching your search.'
                  : 'Start adding students to your school management system.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),

            const SizedBox(height: 24),

            // BUTTON
            if (isSearching)
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(
                  Icons.clear_rounded,
                  size: 18,
                ),
                label: const Text('Clear Search'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onAddStudent,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 19,
                ),
                label: const Text('Add Student'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
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
      ),
    );
  }
}