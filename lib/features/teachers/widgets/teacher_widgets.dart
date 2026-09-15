import 'package:flutter/material.dart';

import '../models/teacher_model.dart';

class TeacherWidgets {
  TeacherWidgets._();

  // ============================================================
  // PREMIUM INPUT
  // ============================================================

  static InputDecoration premiumInputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hint,
    bool alignLabelWithHint = false,
  }) {
    final color = Theme.of(context).colorScheme.primary;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: color, width: 1.5),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  static Widget sectionTitle(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  static Widget datePickerField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String? value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != null && value.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: InputDecorator(
        decoration: premiumInputDecoration(context, label: label, icon: icon),
        child: Text(
          hasValue ? value! : 'Select date',
          style: TextStyle(
            fontSize: 14,
            color: hasValue
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  static Widget header(BuildContext context, {required VoidCallback onAdd}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Teachers',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                'Manage teachers and their professional information.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add Teacher'),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  static Widget summaryCards(BuildContext context, List<Teacher> teachers) {
    final total = teachers.length;

    final active = teachers
        .where((teacher) => (teacher.status ?? '').toUpperCase() == 'ACTIVE')
        .length;

    final inactive = teachers
        .where((teacher) => (teacher.status ?? '').toUpperCase() == 'INACTIVE')
        .length;

    final designations = teachers
        .map((teacher) => teacher.designation?.trim())
        .where((designation) => designation != null && designation.isNotEmpty)
        .toSet()
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            summaryCard(
              width: cardWidth,
              title: 'Total Teachers',
              value: total.toString(),
              icon: Icons.people_outline,
            ),
            summaryCard(
              width: cardWidth,
              title: 'Active Teachers',
              value: active.toString(),
              icon: Icons.check_circle_outline,
            ),
            summaryCard(
              width: cardWidth,
              title: 'Inactive',
              value: inactive.toString(),
              icon: Icons.pause_circle_outline,
            ),
            summaryCard(
              width: cardWidth,
              title: 'Designations',
              value: designations.toString(),
              icon: Icons.work_outline,
            ),
          ],
        );
      },
    );
  }

  static Widget summaryCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  static Widget toolbar(
    BuildContext context, {
    required TextEditingController searchController,
    required String selectedStatus,
    required ValueChanged<String> onSearch,
    required VoidCallback onClearSearch,
    required VoidCallback onFilter,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: 'Search teachers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onFilter,
            icon: const Icon(Icons.filter_list),
            label: Text(selectedStatus == 'All' ? 'Filter' : selectedStatus),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEACHER TABLE
  // ============================================================

  static Widget teacherTable(
    BuildContext context, {
    required bool isLoading,
    required List<Teacher> filteredTeachers,
    required VoidCallback onRefresh,
    required Function(Teacher) onView,
    required Function(Teacher) onEdit,
    required Function(Teacher) onAssign,
    required Function(Teacher) onDelete,
  }) {
    if (isLoading) {
      return const SizedBox(
        height: 350,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (filteredTeachers.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No teachers found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Try changing your search or filter.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 52,
            dataRowMinHeight: 65,
            dataRowMaxHeight: 75,
            columnSpacing: 28,
            headingRowColor: const WidgetStatePropertyAll(Color(0xFFF8FAFC)),
            columns: const [
              DataColumn(
                label: Text(
                  'Teacher',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Employee ID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Designation',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Qualification',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Phone',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Action',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: filteredTeachers.map((teacher) {
              return DataRow(
                cells: [
                  DataCell(teacherCell(teacher)),
                  DataCell(Text(teacher.employeeId ?? '-')),
                  DataCell(Text(teacher.designation ?? '-')),
                  DataCell(Text(teacher.qualification ?? '-')),
                  DataCell(Text(teacher.phone ?? '-')),
                  DataCell(statusBadge(teacher.status)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'View',
                          icon: const Icon(Icons.visibility_outlined),
                          onPressed: () => onView(teacher),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => onEdit(teacher),
                        ),
                        IconButton(
                          tooltip: 'Assign Class',
                          icon: const Icon(
                            Icons.assignment_outlined,
                            color: Colors.blue,
                          ),
                          onPressed: () => onAssign(teacher),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => onDelete(teacher),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TEACHER CELL
  // ============================================================

  static Widget teacherCell(Teacher teacher) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.withOpacity(.10),
            child: Text(
              initial(teacher.name),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teacher.name ?? '-',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  static Widget statusBadge(String? status) {
    final active = (status ?? '').toUpperCase() == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(.10)
            : Colors.red.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status ?? '-',
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  static Widget textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }

        if (label == 'Phone' && value != null && value.trim().isNotEmpty) {
          if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
            return 'Enter valid 10 digit phone';
          }
        }

        if (label == 'Email' && value != null && value.trim().isNotEmpty) {
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
            return 'Enter valid email';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  static Widget dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      isExpanded: true,
      menuMaxHeight: 280,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  static Widget dateField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: const OutlineInputBorder(),
      ),
      onTap: () async {
        DateTime initialDate = DateTime.now();

        if (controller.text.isNotEmpty) {
          final parsed = DateTime.tryParse(controller.text);

          if (parsed != null) {
            initialDate = parsed;
          }
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          controller.text =
              '${picked.year.toString().padLeft(4, '0')}-'
              '${picked.month.toString().padLeft(2, '0')}-'
              '${picked.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  // ============================================================
  // DETAIL SECTION
  // ============================================================

  static Widget detailSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  static Widget detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value == null || value.trim().isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  static Widget filterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        onSelected();
      },
    );
  }

  // ============================================================
  // INITIAL
  // ============================================================

  static String initial(String? name) {
    if (name == null || name.trim().isEmpty) {
      return '?';
    }

    return name.trim()[0].toUpperCase();
  }
}
