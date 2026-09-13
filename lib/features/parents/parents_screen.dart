import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smartkids_admin/models/parent_model.dart';
import 'package:smartkids_admin/services/parent_service.dart';
import 'package:smartkids_admin/services/student_service.dart';

class ParentsScreen extends StatefulWidget {
  const ParentsScreen({super.key});

  @override
  State<ParentsScreen> createState() => _ParentsScreenState();
}

class _ParentsScreenState extends State<ParentsScreen> {
  ParentService? _parentService;

  final TextEditingController _searchController = TextEditingController();

  List<Parent> _parents = [];
  List<Parent> _filteredParents = [];

  bool _isLoading = true;
  bool _isSaving = false;

  String _selectedRelationship = 'All';

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Login session not found. Please login again.';
      });

      return;
    }

    _parentService = ParentService(token);

    await _loadParents();
  }

  // ============================================================
  // LOAD PARENTS
  // ============================================================

  Future<void> _loadParents() async {
    if (_parentService == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parents = await _parentService!.getParents();

      if (!mounted) return;

      setState(() {
        _parents = parents;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // SEARCH + FILTER
  // ============================================================

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    final result = _parents.where((parent) {
      final matchesSearch =
          query.isEmpty ||
          parent.displayName.toLowerCase().contains(query) ||
          (parent.fatherName ?? '').toLowerCase().contains(query) ||
          (parent.motherName ?? '').toLowerCase().contains(query) ||
          (parent.guardianName ?? '').toLowerCase().contains(query) ||
          (parent.contactPhone ?? '').toLowerCase().contains(query) ||
          (parent.contactEmail ?? '').toLowerCase().contains(query) ||
          (parent.address ?? '').toLowerCase().contains(query) ||
          (parent.id?.toString() ?? '').contains(query);

      final matchesRelationship =
          _selectedRelationship == 'All' ||
          (parent.relationship ?? '').toLowerCase() ==
              _selectedRelationship.toLowerCase();

      return matchesSearch && matchesRelationship;
    }).toList();

    setState(() {
      _filteredParents = result;
    });
  }

  // ============================================================
  // ADD PARENT
  // ============================================================

  Future<void> _showAddParentDialog() async {
    if (_parentService == null) return;

    final formKey = GlobalKey<FormState>();

    final fatherController = TextEditingController();
    final motherController = TextEditingController();
    final guardianController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

    String relationship = 'Father';

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return _parentFormDialog(
                title: 'Add Parent',
                subtitle: 'Create a new parent record',
                formKey: formKey,
                fatherController: fatherController,
                motherController: motherController,
                guardianController: guardianController,
                phoneController: phoneController,
                emailController: emailController,
                addressController: addressController,
                relationship: relationship,
                isEdit: false,
                isSaving: _isSaving,
                onRelationshipChanged: (value) {
                  setDialogState(() {
                    relationship = value;
                  });
                },
                onSave: () async {
                  if (!formKey.currentState!.validate()) return;

                  setState(() {
                    _isSaving = true;
                  });

                  try {
                    await _parentService!.createParent(
                      fatherName: fatherController.text.trim(),
                      motherName: motherController.text.trim(),
                      guardianName: guardianController.text.trim(),
                      contactPhone: phoneController.text.trim(),
                      contactEmail: emailController.text.trim(),
                      relationship: relationship,
                      address: addressController.text.trim(),
                    );

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    _showSuccess('Parent created successfully');

                    await _loadParents();
                  } catch (e) {
                    _showError(_cleanError(e));
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  }
                },
              );
            },
          );
        },
      );
    } finally {
      fatherController.dispose();
      motherController.dispose();
      guardianController.dispose();
      phoneController.dispose();
      emailController.dispose();
      addressController.dispose();
    }
  }

  // ============================================================
  // EDIT PARENT
  // ============================================================

  Future<void> _showEditParentDialog(Parent parent) async {
    if (_parentService == null || parent.id == null) return;

    final formKey = GlobalKey<FormState>();

    final fatherController = TextEditingController(
      text: parent.fatherName ?? '',
    );

    final motherController = TextEditingController(
      text: parent.motherName ?? '',
    );

    final guardianController = TextEditingController(
      text: parent.guardianName ?? '',
    );

    final phoneController = TextEditingController(
      text: parent.contactPhone ?? '',
    );

    final emailController = TextEditingController(
      text: parent.contactEmail ?? '',
    );

    final addressController = TextEditingController(text: parent.address ?? '');

    String relationship = parent.relationship?.isNotEmpty == true
        ? parent.relationship!
        : 'Father';

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return _parentFormDialog(
                title: 'Edit Parent',
                subtitle: 'Update parent information',
                formKey: formKey,
                fatherController: fatherController,
                motherController: motherController,
                guardianController: guardianController,
                phoneController: phoneController,
                emailController: emailController,
                addressController: addressController,
                relationship: relationship,
                isEdit: true,
                isSaving: _isSaving,
                onRelationshipChanged: (value) {
                  setDialogState(() {
                    relationship = value;
                  });
                },
                onSave: () async {
                  if (!formKey.currentState!.validate()) return;

                  setState(() {
                    _isSaving = true;
                  });

                  try {
                    await _parentService!.updateParent(
                      id: parent.id!,
                      fatherName: fatherController.text.trim(),
                      motherName: motherController.text.trim(),
                      guardianName: guardianController.text.trim(),
                      contactPhone: phoneController.text.trim(),
                      contactEmail: emailController.text.trim(),
                      relationship: relationship,
                      address: addressController.text.trim(),
                    );

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    _showSuccess('Parent updated successfully');

                    await _loadParents();
                  } catch (e) {
                    _showError(_cleanError(e));
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  }
                },
              );
            },
          );
        },
      );
    } finally {
      fatherController.dispose();
      motherController.dispose();
      guardianController.dispose();
      phoneController.dispose();
      emailController.dispose();
      addressController.dispose();
    }
  }

  // ============================================================
  // DELETE PARENT
  // ============================================================

  Future<void> _deleteParent(Parent parent) async {
    if (_parentService == null || parent.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Parent?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Are you sure you want to delete ${parent.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _parentService!.deleteParent(parent.id!);

      if (!mounted) return;

      _showSuccess('Parent deleted successfully');

      await _loadParents();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // VIEW DETAILS
  // ============================================================

  Future<void> _showParentDetails(Parent parent) async {
    Parent selectedParent = parent;

    if (_parentService != null && parent.id != null) {
      try {
        selectedParent = await _parentService!.getParent(parent.id!);
      } catch (_) {
        // If detail API fails, show existing object.
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return _parentDetailsDialog(selectedParent);
      },
    );
  }

  // ============================================================
  // LINK STUDENT
  // ============================================================

  Future<void> _showLinkStudentDialog(Parent parent) async {
    if (_parentService == null || parent.id == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      _showError('Login session expired.');
      return;
    }

    try {
      final studentService = StudentService(token);

      final studentPage = await studentService.getStudents(page: 0, size: 100);

      final students = studentPage.content;

      if (!mounted) return;

      if (students.isEmpty) {
        _showError('No students available.');
        return;
      }

      int? selectedStudentId;

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final availableStudents = students
                  .where(
                    (student) => student.id != null && student.parentId == null,
                  )
                  .toList();

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text(
                  'Link Student',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                content: SizedBox(
                  width: 450,
                  child: availableStudents.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'All available students are already linked.',
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          initialValue: selectedStudentId,
                          decoration: InputDecoration(
                            labelText: 'Select Student',
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: availableStudents.map((student) {
                            return DropdownMenuItem<int>(
                              value: student.id,
                              child: Text(student.name ?? 'Unnamed Student'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedStudentId = value;
                            });
                          },
                        ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton.icon(
                    onPressed: selectedStudentId == null
                        ? null
                        : () async {
                            try {
                              await _parentService!.linkStudent(
                                parentId: parent.id!,
                                studentId: selectedStudentId!,
                              );

                              if (!mounted) return;

                              Navigator.pop(dialogContext);

                              _showSuccess('Student linked successfully');

                              await _loadParents();
                            } catch (e) {
                              _showError(_cleanError(e));
                            }
                          },
                    icon: const Icon(Icons.link),
                    label: const Text('Link Student'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // UNLINK STUDENT
  // ============================================================

  Future<void> _unlinkStudent(Parent parent, ParentStudent student) async {
    if (_parentService == null || parent.id == null || student.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Unlink Student?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Remove ${student.name ?? 'this student'} '
            'from ${parent.displayName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Unlink'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _parentService!.unlinkStudent(
        parentId: parent.id!,
        studentId: student.id!,
      );

      if (!mounted) return;

      _showSuccess('Student unlinked successfully');

      await _loadParents();
    } catch (e) {
      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // FILTER DIALOG
  // ============================================================

  Future<void> _showFilterDialog() async {
    String tempRelationship = _selectedRelationship;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.filter_alt_outlined,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Filter Parents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    const Text(
                      'Relationship',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip(
                          label: 'All',
                          icon: Icons.people_outline,
                          selected: tempRelationship == 'All',
                          onSelected: () {
                            setDialogState(() {
                              tempRelationship = 'All';
                            });
                          },
                        ),

                        _filterChip(
                          label: 'Father',
                          icon: Icons.man_outlined,
                          selected: tempRelationship == 'Father',
                          onSelected: () {
                            setDialogState(() {
                              tempRelationship = 'Father';
                            });
                          },
                        ),

                        _filterChip(
                          label: 'Mother',
                          icon: Icons.woman_outlined,
                          selected: tempRelationship == 'Mother',
                          onSelected: () {
                            setDialogState(() {
                              tempRelationship = 'Mother';
                            });
                          },
                        ),

                        _filterChip(
                          label: 'Guardian',
                          icon: Icons.family_restroom_outlined,
                          selected: tempRelationship == 'Guardian',
                          onSelected: () {
                            setDialogState(() {
                              tempRelationship = 'Guardian';
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tempRelationship == 'All'
                                  ? 'Showing parents from all relationships'
                                  : 'Showing $tempRelationship parents only',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempRelationship = 'All';
                    });
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(width: 8),

                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedRelationship = tempRelationship;
                      _applyFilters();
                    });

                    Navigator.pop(dialogContext);
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Apply Filter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _filterChip({
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onSelected,
}) {
  return ChoiceChip(
    selected: selected,
    onSelected: (_) => onSelected(),
    avatar: Icon(
      icon,
      size: 18,
      color: selected
          ? Colors.white
          : const Color(0xFF64748B),
    ),
    label: Text(label),
    labelStyle: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: selected
          ? Colors.white
          : const Color(0xFF334155),
    ),
    selectedColor: const Color(0xFF2563EB),
    backgroundColor: Colors.white,
    side: BorderSide(
      color: selected
          ? const Color(0xFF2563EB)
          : const Color(0xFFE2E8F0),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 8,
    ),
  );
}
  // ============================================================
  // FORM DIALOG
  // ============================================================

  Widget _parentFormDialog({
    required String title,
    required String subtitle,
    required GlobalKey<FormState> formKey,
    required TextEditingController fatherController,
    required TextEditingController motherController,
    required TextEditingController guardianController,
    required TextEditingController phoneController,
    required TextEditingController emailController,
    required TextEditingController addressController,
    required String relationship,
    required bool isEdit,
    required bool isSaving,
    required ValueChanged<String> onRelationshipChanged,
    required VoidCallback onSave,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.family_restroom,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _sectionTitle('Parent Information'),

                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 600;

                      if (!twoColumns) {
                        return Column(
                          children: [
                            _textField(
                              controller: fatherController,
                              label: 'Father Name',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: motherController,
                              label: 'Mother Name',
                              icon: Icons.person_outline,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: fatherController,
                              label: 'Father Name',
                              icon: Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _textField(
                              controller: motherController,
                              label: 'Mother Name',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller: guardianController,
                    label: 'Guardian Name',
                    icon: Icons.supervisor_account_outlined,
                  ),

                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 600;

                      if (!twoColumns) {
                        return Column(
                          children: [
                            _textField(
                              controller: phoneController,
                              label: 'Contact Phone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: _phoneValidator,
                            ),
                            const SizedBox(height: 14),
                            _textField(
                              controller: emailController,
                              label: 'Contact Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _textField(
                              controller: phoneController,
                              label: 'Contact Phone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: _phoneValidator,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _textField(
                              controller: emailController,
                              label: 'Contact Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: relationship,
                    decoration: InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: const Icon(Icons.family_restroom_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Father', child: Text('Father')),
                      DropdownMenuItem(value: 'Mother', child: Text('Mother')),
                      DropdownMenuItem(
                        value: 'Guardian',
                        child: Text('Guardian'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onRelationshipChanged(value);
                      }
                    },
                  ),

                  const SizedBox(height: 14),

                  _textField(
                    controller: addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: isSaving ? null : onSave,
                        icon: isSaving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(isEdit ? Icons.save_outlined : Icons.add),
                        label: Text(
                          isSaving
                              ? 'Saving...'
                              : isEdit
                              ? 'Update Parent'
                              : 'Add Parent',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DETAILS DIALOG
  // ============================================================

  Widget _parentDetailsDialog(Parent parent) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        parent.initials,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parent.displayName,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            parent.id != null
                                ? 'Parent ID: ${parent.id}'
                                : 'Parent',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                _sectionTitle('Contact Information'),

                const SizedBox(height: 12),

                _detailTile(
                  Icons.phone_outlined,
                  'Phone',
                  parent.contactPhone ?? 'Not provided',
                ),

                _detailTile(
                  Icons.email_outlined,
                  'Email',
                  parent.contactEmail ?? 'Not provided',
                ),

                _detailTile(
                  Icons.location_on_outlined,
                  'Address',
                  parent.address ?? 'Not provided',
                ),

                _detailTile(
                  Icons.family_restroom_outlined,
                  'Relationship',
                  parent.relationship ?? 'Not provided',
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _infoCard(
                        title: 'Father',
                        value: parent.fatherName ?? 'Not provided',
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoCard(
                        title: 'Mother',
                        value: parent.motherName ?? 'Not provided',
                        icon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _sectionTitle('Linked Students'),
                    const Spacer(),
                    if (parent.id != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showLinkStudentDialog(parent);
                        },
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Link Student'),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                if (parent.students.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 34,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No students linked',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...parent.students.map(
                    (student) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student.name ?? 'Unnamed Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (student.admissionNo != null)
                                  Text(
                                    'Admission: ${student.admissionNo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Unlink',
                            onPressed: () {
                              Navigator.pop(context);
                              _unlinkStudent(parent, student);
                            },
                            icon: const Icon(
                              Icons.link_off,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(),

              const SizedBox(height: 22),

              _buildSummaryCards(),

              const SizedBox(height: 22),

              Expanded(child: _buildMainContent()),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerTitle(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _showAddParentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Parent'),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _headerTitle()),
            FilledButton.icon(
              onPressed: _isLoading ? null : _showAddParentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Parent'),
            ),
          ],
        );
      },
    );
  }

  Widget _headerTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Parents',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Manage parents, guardians and student relationships.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget _buildSummaryCards() {
    final total = _parents.length;

    final fathers = _parents
        .where((p) => (p.relationship ?? '').toLowerCase() == 'father')
        .length;

    final mothers = _parents
        .where((p) => (p.relationship ?? '').toLowerCase() == 'mother')
        .length;

    final guardians = _parents
        .where((p) => (p.relationship ?? '').toLowerCase() == 'guardian')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 650) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: 'Total Parents',
                      value: '$total',
                      icon: Icons.groups_outlined,
                      iconColor: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      title: 'Fathers',
                      value: '$fathers',
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: 'Mothers',
                      value: '$mothers',
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFFDB2777),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      title: 'Guardians',
                      value: '$guardians',
                      icon: Icons.supervisor_account_outlined,
                      iconColor: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Parents',
                value: '$total',
                icon: Icons.groups_outlined,
                iconColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _summaryCard(
                title: 'Fathers',
                value: '$fathers',
                icon: Icons.person_outline,
                iconColor: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _summaryCard(
                title: 'Mothers',
                value: '$mothers',
                icon: Icons.person_outline,
                iconColor: const Color(0xFFDB2777),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _summaryCard(
                title: 'Guardians',
                value: '$guardians',
                icon: Icons.supervisor_account_outlined,
                iconColor: const Color(0xFF059669),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
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
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildToolbar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ============================================================
  // TOOLBAR
  // ============================================================

  Widget _buildToolbar() {
    final filterActive = _selectedRelationship != 'All';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            return Column(
              children: [
                _searchBox(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _filterButton(filterActive)),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isLoading ? null : _loadParents,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                      ),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _searchBox()),
              const SizedBox(width: 12),
              _filterButton(filterActive),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _isLoading ? null : _loadParents,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                ),
                icon: const Icon(Icons.refresh),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _applyFilters(),
      decoration: InputDecoration(
        hintText: 'Search parent, phone, email or address...',
        prefixIcon: const Icon(Icons.search, size: 21),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  _applyFilters();
                },
                icon: const Icon(Icons.clear),
              ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filterButton(bool active) {
    return OutlinedButton.icon(
      onPressed: _showFilterDialog,
      icon: Icon(
        Icons.filter_list,
        color: active ? const Color(0xFF2563EB) : Colors.grey.shade700,
      ),
      label: Text(active ? 'Filter: $_selectedRelationship' : 'Filter'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 50),
        side: BorderSide(
          color: active ? const Color(0xFF2563EB) : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _errorState();
    }

    if (_filteredParents.isEmpty) {
      return _emptyState();
    }

    return _parentsTable();
  }

  // ============================================================
  // TABLE
  // ============================================================

  Widget _parentsTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowHeight: 52,
                  dataRowMinHeight: 72,
                  dataRowMaxHeight: 82,
                  horizontalMargin: 20,
                  columnSpacing: 28,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                    fontSize: 13,
                  ),
                  columns: const [
                    DataColumn(label: Text('PARENT')),
                    DataColumn(label: Text('RELATIONSHIP')),
                    DataColumn(label: Text('PHONE')),
                    DataColumn(label: Text('EMAIL')),
                    DataColumn(label: Text('STUDENTS')),
                    DataColumn(label: Text('ACTION')),
                  ],
                  rows: _filteredParents.map((parent) {
                    return DataRow(
                      cells: [
                        DataCell(_parentCell(parent)),
                        DataCell(
                          _relationshipBadge(parent.relationship ?? 'Unknown'),
                        ),
                        DataCell(Text(parent.contactPhone ?? 'Not provided')),
                        DataCell(
                          SizedBox(
                            width: 190,
                            child: Text(
                              parent.contactEmail ?? 'Not provided',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(_studentCell(parent)),
                        DataCell(_actionMenu(parent)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _parentCell(Parent parent) {
    return SizedBox(
      width: 220,
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              parent.initials,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parent.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  parent.id != null ? 'ID: ${parent.id}' : 'Parent',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCell(Parent parent) {
    if (parent.students.isEmpty) {
      return Text(
        'Not linked',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
      );
    }

    if (parent.students.length == 1) {
      return SizedBox(
        width: 160,
        child: Text(
          parent.students.first.name ?? 'Unnamed Student',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${parent.students.length} students',
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _relationshipBadge(String relationship) {
    Color background;
    Color foreground;

    switch (relationship.toLowerCase()) {
      case 'mother':
        background = const Color(0xFFFCE7F3);
        foreground = const Color(0xFFBE185D);
        break;

      case 'guardian':
        background = const Color(0xFFD1FAE5);
        foreground = const Color(0xFF047857);
        break;

      default:
        background = const Color(0xFFEDE9FE);
        foreground = const Color(0xFF6D28D9);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        relationship,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // ACTION MENU
  // ============================================================

  Widget _actionMenu(Parent parent) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      onSelected: (value) {
        switch (value) {
          case 'view':
            _showParentDetails(parent);
            break;

          case 'edit':
            _showEditParentDialog(parent);
            break;

          case 'link':
            _showLinkStudentDialog(parent);
            break;

          case 'delete':
            _deleteParent(parent);
            break;
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 'view',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.visibility_outlined),
              title: Text('View Details'),
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
            ),
          ),
          PopupMenuItem(
            value: 'link',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.link),
              title: Text('Link Student'),
            ),
          ),
          PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ];
      },
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    final hasFilters =
        _searchController.text.trim().isNotEmpty ||
        _selectedRelationship != 'All';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.groups_outlined,
                size: 40,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasFilters ? 'No parents found' : 'No parents available',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text(
              hasFilters
                  ? 'Try changing your search or filter.'
                  : 'Add your first parent to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _selectedRelationship = 'All';
                  });

                  _applyFilters();
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              )
            else
              FilledButton.icon(
                onPressed: _showAddParentDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Parent'),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load parents',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadParents,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMMON WIDGETS
  // ============================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _detailTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final phone = value.trim();

    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      return 'Enter valid 10-digit phone';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final email = value.trim();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter valid email';
    }

    return null;
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF16A34A),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }
}
