import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

 import '../notices/services/notice_service.dart';
import '../notices/models/notice_model.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final List<String> _categories = const [
    'All',
    'Academic',
    'Event',
    'Fee',
    'Holiday',
    'MCQ',
    'Sports',
    'General',
  ];

  final List<String> _audiences = const [
    'All Students',
    'Parents',
    'Students',
    'Students & Parents',
    'Teachers',
    'All',
  ];

  String selectedCategory = 'All';

  List<NoticeModel> notices = [];

  NoticeService? _noticeService;

  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.trim().isEmpty) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          errorMessage = 'Session expired. Please login again.';
        });
        return;
      }

      _noticeService = NoticeService(token);

      await _loadNotices();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Unable to initialize notices.';
      });
    }
  }

  Future<void> _loadNotices() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _noticeService!.getNotices();

      if (!mounted) return;

      setState(() {
        notices = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception:')) {
      return message.replaceFirst('Exception:', '').trim();
    }

    return message;
  }

  List<NoticeModel> get filteredNotices {
    if (selectedCategory == 'All') {
      return notices;
    }

    return notices
        .where(
          (notice) =>
              notice.category!.toLowerCase() ==
              selectedCategory.toLowerCase(),
        )
        .toList();
  }

  int get publishedCount {
    return notices
        .where((notice) => notice.status!.toUpperCase() == 'PUBLISHED')
        .length;
  }

  int get draftCount {
    return notices
        .where((notice) => notice.status!.toUpperCase() == 'DRAFT')
        .length;
  }

  int get totalCount => notices.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildPremiumHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadNotices,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
            Color(0xFF1E40AF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerTitle(),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: _createButton(),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: _headerTitle()),
              _createButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _headerTitle() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
            ),
          ),
          child: const Icon(
            Icons.campaign_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'School Notices',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Create, manage and publish important school announcements',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _createButton() {
    return ElevatedButton.icon(
      onPressed: _showAddNoticeDialog,
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text(
        'Create Notice',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D4ED8),
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStats(),
          const SizedBox(height: 24),
          _buildCategoryFilter(),
          const SizedBox(height: 22),
          _buildNoticeList(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unable to Load Notices',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadNotices,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STATS
  // ---------------------------------------------------------------------------

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 650) {
          return Column(
            children: [
              _statCard(
                title: 'Total Notices',
                value: '$totalCount',
                icon: Icons.notifications_active_rounded,
                iconBackground: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              _statCard(
                title: 'Published',
                value: '$publishedCount',
                icon: Icons.check_circle_rounded,
                iconBackground: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
              ),
              const SizedBox(height: 12),
              _statCard(
                title: 'Drafts',
                value: '$draftCount',
                icon: Icons.edit_note_rounded,
                iconBackground: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Total Notices',
                value: '$totalCount',
                icon: Icons.notifications_active_rounded,
                iconBackground: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statCard(
                title: 'Published',
                value: '$publishedCount',
                icon: Icons.check_circle_rounded,
                iconBackground: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _statCard(
                title: 'Drafts',
                value: '$draftCount',
                icon: Icons.edit_note_rounded,
                iconBackground: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconBackground,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
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
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 24,
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

  // ---------------------------------------------------------------------------
  // CATEGORY FILTER
  // ---------------------------------------------------------------------------

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final selected = selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NOTICE LIST
  // ---------------------------------------------------------------------------

  Widget _buildNoticeList() {
    final data = filteredNotices;

    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: data.map(_buildNoticeCard).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 60,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: Color(0xFF2563EB),
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            selectedCategory == 'All'
                ? 'No Notices Yet'
                : 'No $selectedCategory Notices',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a notice to share important updates with your school community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showAddNoticeDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Notice'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    final isPublished =
        notice.status!.toUpperCase() == 'PUBLISHED';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 650;

            if (isSmall) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _noticeMainContent(notice),
                  const SizedBox(height: 16),
                  _noticeActions(notice),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _noticeMainContent(notice),
                ),
                const SizedBox(width: 20),
                _noticeActions(notice),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _noticeMainContent(NoticeModel notice) {
    final isPublished =
        notice.status!.toUpperCase() == 'PUBLISHED';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _categoryBackground(notice.category!),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _categoryIcon(notice.category!),
            color: _categoryColor(notice.category!),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _categoryBadge(notice.category!),
                  _statusBadge(
                    isPublished ? 'Published' : 'Draft',
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                notice.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                notice.message!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _metaItem(
                    Icons.people_alt_outlined,
                    _displayAudience(notice.audience!),
                  ),
                  _metaItem(
                    Icons.calendar_today_outlined,
                    _formatDate(notice.createdAt!),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noticeActions(NoticeModel notice) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionButton(
          icon: Icons.visibility_outlined,
          tooltip: 'View',
          color: const Color(0xFF2563EB),
          onTap: () => _showNoticeDetails(notice),
        ),
        const SizedBox(width: 8),
        _actionButton(
          icon: Icons.edit_outlined,
          tooltip: 'Edit',
          color: const Color(0xFF7C3AED),
          onTap: () => _editNotice(notice),
        ),
        const SizedBox(width: 8),
        _actionButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Delete',
          color: const Color(0xFFDC2626),
          onTap: () => _deleteNotice(notice),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _categoryBadge(String category) {
    final color = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isPublished = status.toUpperCase() == 'PUBLISHED';

    final color = isPublished
        ? const Color(0xFF059669)
        : const Color(0xFFEA580C);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished
                ? Icons.check_circle_rounded
                : Icons.schedule_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF9CA3AF),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE NOTICE
  // ---------------------------------------------------------------------------

  Future<void> _showAddNoticeDialog() async {
    await _showNoticeFormDialog(
      mode: _NoticeFormMode.create,
    );
  }

  // ---------------------------------------------------------------------------
  // EDIT NOTICE
  // ---------------------------------------------------------------------------

  Future<void> _editNotice(NoticeModel notice) async {
    await _showNoticeFormDialog(
      mode: _NoticeFormMode.edit,
      notice: notice,
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON CREATE / EDIT DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _showNoticeFormDialog({
    required _NoticeFormMode mode,
    NoticeModel? notice,
  }) async {
    final isEdit = mode == _NoticeFormMode.edit;

    final titleController = TextEditingController(
      text: isEdit ? notice!.title : '',
    );

    final descriptionController = TextEditingController(
      text: isEdit ? notice!.message : '',
    );

    String? selectedFormCategory =
        isEdit && notice!.category!.isNotEmpty
            ? notice.category
            : null;

    String? selectedAudience =
        isEdit && notice!.audience!.isNotEmpty
            ? _displayAudience(notice.audience!)
            : null;

    String status = isEdit
        ? notice!.status!.toUpperCase()
        : 'DRAFT';

    final formKey = GlobalKey<FormState>();

    bool dialogSaving = false;

    try {
      await showDialog(
        context: context,
        barrierDismissible: !isSaving,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submit(String requestedStatus) async {
                if (dialogSaving) return;

                final valid = formKey.currentState?.validate() ?? false;

                if (!valid) {
                  return;
                }

                setDialogState(() {
                  dialogSaving = true;
                });

                try {
                  if (isEdit) {
                    await _updateNotice(
                      notice: notice!,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      category: selectedFormCategory!,
                      audience: selectedAudience!,
                      status: requestedStatus,
                    );
                  } else {
                    await _createNotice(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      category: selectedFormCategory!,
                      audience: selectedAudience!,
                      status: requestedStatus,
                    );
                  }

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (_) {
                  if (dialogContext.mounted) {
                    setDialogState(() {
                      dialogSaving = false;
                    });
                  }
                }
              }

              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 680,
                    maxHeight: 760,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFormDialogHeader(
                        context: dialogContext,
                        isEdit: isEdit,
                        notice: notice,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            26,
                            24,
                            26,
                            12,
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _dialogSectionTitle(
                                  icon: Icons.edit_document,
                                  title: isEdit
                                      ? 'Edit Notice'
                                      : 'Notice Information',
                                  subtitle: isEdit
                                      ? 'Update the notice details below.'
                                      : 'Enter all required information to create a notice.',
                                ),
                                const SizedBox(height: 22),

                                _fieldLabel(
                                  'Notice Title',
                                  required: true,
                                ),
                                const SizedBox(height: 8),
                                _premiumTextField(
                                  controller: titleController,
                                  hint: 'Enter notice title',
                                  icon: Icons.title_rounded,
                                  maxLength: 120,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Notice title is required';
                                    }

                                    if (value.trim().length < 3) {
                                      return 'Title must contain at least 3 characters';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                _fieldLabel(
                                  'Description',
                                  required: true,
                                ),
                                const SizedBox(height: 8),
                                _premiumTextField(
                                  controller: descriptionController,
                                  hint: 'Write the complete notice message...',
                                  icon: Icons.notes_rounded,
                                  maxLines: 6,
                                  maxLength: 1000,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Description is required';
                                    }

                                    if (value.trim().length < 5) {
                                      return 'Description must contain at least 5 characters';
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 20),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    if (constraints.maxWidth < 520) {
                                      return Column(
                                        children: [
                                          _categoryDropdown(
                                            selectedFormCategory,
                                            (value) {
                                              setDialogState(() {
                                                selectedFormCategory =
                                                    value;
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 18),
                                          _audienceDropdown(
                                            selectedAudience,
                                            (value) {
                                              setDialogState(() {
                                                selectedAudience = value;
                                              });
                                            },
                                          ),
                                        ],
                                      );
                                    }

                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _categoryDropdown(
                                            selectedFormCategory,
                                            (value) {
                                              setDialogState(() {
                                                selectedFormCategory =
                                                    value;
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _audienceDropdown(
                                            selectedAudience,
                                            (value) {
                                              setDialogState(() {
                                                selectedAudience = value;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                if (isEdit) ...[
                                  const SizedBox(height: 22),
                                  _buildEditStatusInfo(
                                    notice!.status!,
                                  ),
                                ],

                                const SizedBox(height: 18),
                                _requiredHint(),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.fromLTRB(
                          22,
                          14,
                          22,
                          20,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAFBFC),
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final mobile =
                                constraints.maxWidth < 500;

                            if (mobile) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton(
                                    onPressed: dialogSaving
                                        ? null
                                        : () {
                                            Navigator.of(
                                              dialogContext,
                                            ).pop();
                                          },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(height: 10),
                                  if (!isEdit)
                                    OutlinedButton.icon(
                                      onPressed: dialogSaving
                                          ? null
                                          : () => submit('DRAFT'),
                                      icon: const Icon(
                                        Icons.save_outlined,
                                      ),
                                      label: const Text(
                                        'Save as Draft',
                                      ),
                                    ),
                                  if (!isEdit)
                                    const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: dialogSaving
                                        ? null
                                        : () {
                                            if (isEdit) {
                                              submit(status);
                                            } else {
                                              submit('PUBLISHED');
                                            }
                                          },
                                    icon: dialogSaving
                                        ? const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            isEdit
                                                ? Icons.check_rounded
                                                : Icons.publish_rounded,
                                          ),
                                    label: Text(
                                      dialogSaving
                                          ? 'Saving...'
                                          : isEdit
                                              ? 'Update Notice'
                                              : 'Publish Notice',
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: dialogSaving
                                      ? null
                                      : () {
                                          Navigator.of(
                                            dialogContext,
                                          ).pop();
                                        },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 10),
                                if (!isEdit) ...[
                                  OutlinedButton.icon(
                                    onPressed: dialogSaving
                                        ? null
                                        : () => submit('DRAFT'),
                                    icon: const Icon(
                                      Icons.save_outlined,
                                    ),
                                    label: const Text(
                                      'Save as Draft',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                ElevatedButton.icon(
                                  onPressed: dialogSaving
                                      ? null
                                      : () {
                                          if (isEdit) {
                                            submit(status);
                                          } else {
                                            submit('PUBLISHED');
                                          }
                                        },
                                  icon: dialogSaving
                                      ? const SizedBox(
                                          width: 17,
                                          height: 17,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          isEdit
                                              ? Icons.check_rounded
                                              : Icons.publish_rounded,
                                        ),
                                  label: Text(
                                    dialogSaving
                                        ? 'Saving...'
                                        : isEdit
                                            ? 'Update Notice'
                                            : 'Publish Notice',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _buildFormDialogHeader({
    required BuildContext context,
    required bool isEdit,
    NoticeModel? notice,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isEdit
                  ? Icons.edit_note_rounded
                  : Icons.campaign_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Notice' : 'Create Notice',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isEdit
                      ? 'Update notice details'
                      : 'Share an important update',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(
    String text, {
    bool required = false,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _premiumTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 13,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 10,
            top: maxLines > 1 ? 14 : 0,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: maxLines > 1 ? 48 : 48,
          minHeight: maxLines > 1 ? 48 : 48,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDC2626),
            width: 1.5,
          ),
        ),
        counterStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _categoryDropdown(
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final dropdownCategories = _categories
        .where((category) => category != 'All')
        .toList();

    final safeValue = dropdownCategories.contains(value)
        ? value
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          'Category',
          required: true,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Category is required';
            }

            return null;
          },
          decoration: _dropdownDecoration(
            icon: Icons.category_outlined,
            hint: 'Select category',
          ),
          items: dropdownCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(
                category,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _audienceDropdown(
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    final safeValue =
        _audiences.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          'Audience',
          required: true,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: safeValue,
          isExpanded: true,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Audience is required';
            }

            return null;
          },
          decoration: _dropdownDecoration(
            icon: Icons.people_alt_outlined,
            hint: 'Select audience',
          ),
          items: _audiences.map((audience) {
            return DropdownMenuItem<String>(
              value: audience,
              child: Text(
                audience,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration({
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6B7280),
        size: 20,
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _requiredHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFFD97706),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Fields marked with * are required.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditStatusInfo(String currentStatus) {
    final published =
        currentStatus.toUpperCase() == 'PUBLISHED';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: published
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: published
              ? const Color(0xFFA7F3D0)
              : const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            published
                ? Icons.check_circle_outline_rounded
                : Icons.edit_note_rounded,
            color: published
                ? const Color(0xFF059669)
                : const Color(0xFFEA580C),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              published
                  ? 'This notice is currently published. Editing it will keep it published.'
                  : 'This notice is currently a draft. You can update it before publishing.',
              style: TextStyle(
                color: published
                    ? const Color(0xFF065F46)
                    : const Color(0xFF9A3412),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE API
  // ---------------------------------------------------------------------------

  Future<void> _createNotice({
    required String title,
    required String description,
    required String category,
    required String audience,
    required String status,
  }) async {
    if (_noticeService == null) return;

    try {
      await _noticeService!.createNotice(
        title: title,
        message: description,
        category: category,
        audience: _apiAudience(audience),
        status: status,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'PUBLISHED'
                ? 'Notice published successfully.'
                : 'Notice saved as draft successfully.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF059669),
        ),
      );

      await _loadNotices();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create notice: ${_cleanError(e)}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
        ),
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE API
  // ---------------------------------------------------------------------------

  Future<void> _updateNotice({
    required NoticeModel notice,
    required String title,
    required String description,
    required String category,
    required String audience,
    required String status,
  }) async {
    if (_noticeService == null) return;

    try {
      final originalStatus = notice.status!.toUpperCase();

      // Important:
      // Published notice must remain published when edited.
      final finalStatus =
          originalStatus == 'PUBLISHED'
              ? 'PUBLISHED'
              : status;

      await _noticeService!.updateNotice(
        id: notice.id!,
        title: title,
        message: description,
        category: category,
        audience: _apiAudience(audience),
        status: finalStatus,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            originalStatus == 'PUBLISHED'
                ? 'Published notice updated successfully.'
                : 'Notice updated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF059669),
        ),
      );

      await _loadNotices();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update notice: ${_cleanError(e)}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
        ),
      );

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VIEW NOTICE
  // ---------------------------------------------------------------------------

  Future<void> _showNoticeDetails(
    NoticeModel notice,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        final isPublished =
            notice.status!.toUpperCase() == 'PUBLISHED';

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 680,
              maxHeight: 760,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    24,
                    18,
                    24,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _categoryColor(notice.category!),
                        _categoryColor(notice.category!)
                            .withValues(alpha: 0.78),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.16,
                          ),
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _categoryIcon(notice.category!),
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notice Details',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notice.title,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _categoryBadge(notice.category!),
                            _statusBadge(
                              isPublished
                                  ? 'Published'
                                  : 'Draft',
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),

                        _viewInfoGrid(notice),

                        const SizedBox(height: 24),

                        const Text(
                          'Notice Content',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius:
                                BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            notice.message!,
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 14,
                              height: 1.65,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        if (isPublished &&
                            notice.publishedAt != null) ...[
                          const SizedBox(height: 18),
                          _publishedInfo(notice),
                        ],
                      ],
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.fromLTRB(
                    22,
                    14,
                    22,
                    20,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAFBFC),
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                        label: const Text('Close'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();
                          await _editNotice(notice);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                        ),
                        label: const Text('Edit Notice'),
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

  Widget _viewInfoGrid(NoticeModel notice) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 480;

        final items = [
          _viewInfoCard(
            icon: Icons.category_outlined,
            title: 'Category',
            value: notice.category!,
          ),
          _viewInfoCard(
            icon: Icons.people_alt_outlined,
            title: 'Audience',
            value: _displayAudience(notice.audience!),
          ),
          _viewInfoCard(
            icon: Icons.calendar_today_outlined,
            title: 'Created',
            value: _formatDate(notice.createdAt),
          ),
          _viewInfoCard(
            icon: Icons.verified_outlined,
            title: 'Status',
            value: _displayStatus(notice.status!),
          ),
        ];

        if (!twoColumns) {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10),
                    child: item,
                  ),
                )
                .toList(),
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.2,
          children: items,
        );
      },
    );
  }

  Widget _viewInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
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

  Widget _publishedInfo(NoticeModel notice) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFA7F3D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.publish_rounded,
            color: Color(0xFF059669),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Published on ${_formatDate(notice.publishedAt)}',
              style: const TextStyle(
                color: Color(0xFF065F46),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  Future<void> _deleteNotice(
    NoticeModel notice,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            10,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            18,
            4,
            18,
            18,
          ),
          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Delete Notice?',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "${notice.title}"? This action cannot be undone.',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _performDelete(notice);
  }

  Future<void> _performDelete(
    NoticeModel notice,
  ) async {
    if (_noticeService == null) return;

    try {
      await _noticeService!.deleteNotice(notice.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notice deleted successfully.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF059669),
        ),
      );

      await _loadNotices();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete notice: ${_cleanError(e)}',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _apiAudience(String audience) {
    switch (audience.trim()) {
      case 'All Students':
        return 'STUDENTS';

      case 'Parents':
        return 'ALL_PARENTS';

      case 'Students':
        return 'STUDENTS';

      case 'Students & Parents':
        return 'STUDENTS_AND_PARENTS';

      case 'Teachers':
        return 'TEACHERS';

      case 'All':
        return 'ALL';

      default:
        return audience.trim().toUpperCase();
    }
  }

  String _displayAudience(String audience) {
    switch (audience.trim().toUpperCase()) {
      case 'ALL_PARENTS':
        return 'Parents';

      case 'STUDENTS':
        return 'Students';

      case 'STUDENTS_AND_PARENTS':
        return 'Students & Parents';

      case 'TEACHERS':
        return 'Teachers';

      case 'ALL':
        return 'All';

      case 'CLASS':
        return 'Class Students';

      case 'SECTION':
        return 'Section Students';

      default:
        return audience;
    }
  }

  String _displayStatus(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PUBLISHED':
        return 'Published';

      case 'DRAFT':
        return 'Draft';

      default:
        return status;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not available';
    }

    final local = date.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute = local.minute.toString().padLeft(2, '0');

    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year • $hour:$minute $period';
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Icons.school_outlined;

      case 'event':
        return Icons.event_outlined;

      case 'fee':
        return Icons.account_balance_wallet_outlined;

      case 'holiday':
        return Icons.beach_access_outlined;

      case 'mcq':
        return Icons.quiz_outlined;

      case 'sports':
        return Icons.sports_cricket_outlined;

      case 'general':
      default:
        return Icons.campaign_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return const Color(0xFF2563EB);

      case 'event':
        return const Color(0xFF7C3AED);

      case 'fee':
        return const Color(0xFF059669);

      case 'holiday':
        return const Color(0xFFEA580C);

      case 'mcq':
        return const Color(0xFF0891B2);

      case 'sports':
        return const Color(0xFF16A34A);

      case 'general':
      default:
        return const Color(0xFF475569);
    }
  }

  Color _categoryBackground(String category) {
    return _categoryColor(category).withValues(alpha: 0.09);
  }
}

enum _NoticeFormMode {
  create,
  edit,
}