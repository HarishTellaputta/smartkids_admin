import 'package:flutter/material.dart';

import '../models/parent_feedback_model.dart';
import '../services/parent_feedback_service.dart';

class SuggestionsComplaintsScreen extends StatefulWidget {
  const SuggestionsComplaintsScreen({super.key});

  @override
  State<SuggestionsComplaintsScreen> createState() =>
      _SuggestionsComplaintsScreenState();
}

class _SuggestionsComplaintsScreenState
    extends State<SuggestionsComplaintsScreen> {
  final ParentFeedbackService _service = ParentFeedbackService();

  List<ParentFeedbackModel> _feedback = [];

  bool _loading = true;
  String? _error;
  String _filter = 'ALL';
  final Set<int> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getAllFeedback();

      if (!mounted) return;

      setState(() {
        _feedback = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<ParentFeedbackModel> get _filteredFeedback {
    if (_filter == 'COMPLAINT') {
      return _feedback.where((item) => !item.isSuggestion).toList();
    }

    if (_filter == 'SUGGESTION') {
      return _feedback.where((item) => item.isSuggestion).toList();
    }

    return _feedback;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final local = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/'
        '${twoDigits(local.month)}/'
        '${local.year} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }

  Color _typeColor(ParentFeedbackModel item) {
    return item.isSuggestion
        ? const Color(0xFF047857)
        : const Color(0xFFB45309);
  }

  Future<void> _deleteFeedback(ParentFeedbackModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete submission?'),
          content: Text(
            'Are you sure you want to delete "${item.subject}"? '
            'This action cannot be undone.',
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

    if (confirmed != true || !mounted) return;

    setState(() {
      _deletingIds.add(item.id);
    });

    try {
      await _service.deleteFeedback(item.id);

      if (!mounted) return;

      setState(() {
        _feedback.removeWhere((feedback) => feedback.id == item.id);
        _deletingIds.remove(item.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _deletingIds.remove(item.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _showDetails(ParentFeedbackModel item) {
    final isSuggestion = item.isSuggestion;
    final accentColor = isSuggestion
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x240F172A),
                  blurRadius: 35,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Premium header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF312E81), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Icon(
                          isSuggestion
                              ? Icons.lightbulb_outline_rounded
                              : Icons.report_problem_outlined,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Parent Feedback',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.subject.isEmpty
                                  ? 'Feedback Details'
                                  : item.subject,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.displayType.toUpperCase(),
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: Colors.white70,
                                  size: 15,
                                ),
                                Text(
                                  _formatDate(item.createdAt),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable details
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PARENT INFORMATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _premiumInfoCard(
                          icon: Icons.person_rounded,
                          title: 'Parent / Guardian',
                          value: item.parentName,
                          iconColor: const Color(0xFF4F46E5),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _premiumInfoCard(
                                icon: Icons.phone_rounded,
                                title: 'Phone Number',
                                value: item.parentPhone?.isNotEmpty == true
                                    ? item.parentPhone!
                                    : 'Not provided',
                                iconColor: const Color(0xFF0891B2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _premiumInfoCard(
                                icon: Icons.email_rounded,
                                title: 'Email Address',
                                value: item.parentEmail?.isNotEmpty == true
                                    ? item.parentEmail!
                                    : 'Not provided',
                                iconColor: const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'STUDENT INFORMATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.studentName?.isNotEmpty == true
                                          ? item.studentName!
                                          : 'Student not specified',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Admission No: '
                                      '${item.admissionNo?.isNotEmpty == true ? item.admissionNo! : '-'}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Color(0xFF4F46E5),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Message from Parent',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: SelectableText(
                            item.message.isEmpty
                                ? 'No message provided.'
                                : item.message,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.8,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFAFC),
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 17,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'School Admin • Parent Feedback',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _premiumInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(String value, String label) {
    final selected = _filter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filter = value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredFeedback;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadFeedback,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.feedback_rounded,
                      color: Color(0xFF7C3AED),
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suggestions & Complaints',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Review submissions received from parents.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loadFeedback,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildFilter('ALL', 'All (${_feedback.length})'),
                  _buildFilter(
                    'COMPLAINT',
                    'Complaints (${_feedback.where((e) => !e.isSuggestion).length})',
                  ),
                  _buildFilter(
                    'SUGGESTION',
                    'Suggestions (${_feedback.where((e) => e.isSuggestion).length})',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadFeedback,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (items.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'ALL'
                              ? 'No parent submissions yet'
                              : 'No ${_filter.toLowerCase()} submissions found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'New submissions will appear here.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...items.map(_buildFeedbackCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(ParentFeedbackModel item) {
    final color = _typeColor(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.displayType,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              item.subject.isEmpty ? '(No subject)' : item.subject,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              item.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(height: 1.45, color: Color(0xFF4B5563)),
            ),

            const Divider(height: 24),

            Wrap(
              spacing: 22,
              runSpacing: 10,
              children: [
                _smallInfo(Icons.person_outline, item.parentName),
                _smallInfo(
                  Icons.school_outlined,
                  item.studentName ?? 'Student not specified',
                ),
                if (item.parentPhone != null && item.parentPhone!.isNotEmpty)
                  _smallInfo(Icons.phone_outlined, item.parentPhone!),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDetails(item),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View Details'),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Delete submission',
                  onPressed: _deletingIds.contains(item.id)
                      ? null
                      : () => _deleteFeedback(item),
                  icon: _deletingIds.contains(item.id)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallInfo(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
          ),
        ),
      ],
    );
  }
}
