import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/notice_model.dart';
import 'services/notice_service.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String selectedCategory = 'All';

  List<NoticeModel> notices = [];

  NoticeService? _noticeService;

  bool isLoading = true;
  bool isSaving = false;

  String? errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Session expired. Please login again.';
      });

      return;
    }

    _noticeService = NoticeService(token);

    await _loadNotices();
  }

  // ============================================================
  // LOAD NOTICES
  // ============================================================

  Future<void> _loadNotices() async {
    if (_noticeService == null) return;

    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

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
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<NoticeModel> get filteredNotices {
    if (selectedCategory == 'All') {
      return notices;
    }

    return notices.where((notice) {
      return (notice.category ?? '').trim() == selectedCategory;
    }).toList();
  }

  // ============================================================
  // CREATE NOTICE
  // ============================================================

  void _showAddNoticeDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    String category = 'Academic';
    String audience = 'All Students';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create New Notice',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Notice Title',
                          hintText: 'Enter notice title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter notice details',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            const [
                              'Academic',
                              'Event',
                              'Fee',
                              'Holiday',
                              'MCQ',
                              'Sports',
                              'General',
                            ].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            category = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: audience,
                        decoration: InputDecoration(
                          labelText: 'Send To',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            const [
                              'All Students',
                              'Parents',
                              'Students',
                              'Students & Parents',
                              'Teachers',
                              'All',
                            ].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            audience = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                // SAVE DRAFT
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) {
                            _showMessage('Please enter notice title.');
                            return;
                          }

                          await _createNotice(
                            dialogContext: dialogContext,
                            title: titleController.text.trim(),
                            message: descriptionController.text.trim(),
                            category: category,
                            audience: audience,
                            status: 'DRAFT',
                          );
                        },
                  child: const Text('Save Draft'),
                ),

                // PUBLISH
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) {
                            _showMessage('Please enter notice title.');
                            return;
                          }

                          await _createNotice(
                            dialogContext: dialogContext,
                            title: titleController.text.trim(),
                            message: descriptionController.text.trim(),
                            category: category,
                            audience: audience,
                            status: 'PUBLISHED',
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Publish'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createNotice({
    required BuildContext dialogContext,
    required String title,
    required String message,
    required String category,
    required String audience,
    required String status,
  }) async {
    if (_noticeService == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _noticeService!.createNotice(
        title: title,
        message: message,
        category: category,
        audience: audience,
        status: status,
      );

      if (!mounted) return;

      Navigator.pop(dialogContext);

      _showMessage(
        status == 'PUBLISHED'
            ? 'Notice published successfully.'
            : 'Notice saved as draft.',
      );

      await _loadNotices();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // NOTICE DETAILS
  // ============================================================

  void _showNoticeDetails(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            notice.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailItem('Category', notice.category ?? 'General'),
                _detailItem('Audience', notice.audience ?? 'All'),
                _detailItem('Date', _formatDate(notice)),
                _detailItem('Status', _displayStatus(notice.status)),

                const SizedBox(height: 12),

                const Text(
                  'Notice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  notice.message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DELETE NOTICE
  // ============================================================

  void _deleteNotice(NoticeModel notice) {
    if (notice.id == null) {
      _showMessage('This notice does not have a valid ID.', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Notice?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to delete this notice?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                await _performDelete(notice.id!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDelete(int id) async {
    if (_noticeService == null) return;

    try {
      await _noticeService!.deleteNotice(id);

      if (!mounted) return;

      _showMessage('Notice deleted successfully.');

      await _loadNotices();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  // ============================================================
  // EDIT NOTICE
  // ============================================================

  void _editNotice(NoticeModel notice) {
    if (notice.id == null) {
      _showMessage('This notice does not have a valid ID.', isError: true);
      return;
    }

    final titleController = TextEditingController(text: notice.title);

    final descriptionController = TextEditingController(text: notice.message);

    String category = _validCategory(notice.category);
    String audience = _validAudience(notice.audience);

    final currentStatus = (notice.status ?? 'DRAFT').trim().toUpperCase();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Notice',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Notice Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            const [
                              'Academic',
                              'Event',
                              'Fee',
                              'Holiday',
                              'MCQ',
                              'Sports',
                              'General',
                            ].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            category = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        value: audience,
                        decoration: InputDecoration(
                          labelText: 'Send To',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            const [
                              'All Students',
                              'Parents',
                              'Students',
                              'Students & Parents',
                              'Teachers',
                              'All',
                            ].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            audience = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) {
                            _showMessage('Please enter notice title.');
                            return;
                          }

                          await _updateNotice(
                            dialogContext: dialogContext,
                            id: notice.id!,
                            title: titleController.text.trim(),
                            message: descriptionController.text.trim(),
                            category: category,
                            audience: audience,
                            status: currentStatus,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateNotice({
    required BuildContext dialogContext,
    required int id,
    required String title,
    required String message,
    required String category,
    required String audience,
    required String status,
  }) async {
    if (_noticeService == null) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _noticeService!.updateNotice(
        id: id,
        title: title,
        message: message,
        category: category,
        audience: audience,
        status: status,
      );

      if (!mounted) return;

      Navigator.pop(dialogContext);

      _showMessage('Notice updated successfully.');

      await _loadNotices();
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final data = filteredNotices;

    final total = notices.length;
    final published = notices
        .where((n) => (n.status ?? '').toUpperCase() == 'PUBLISHED')
        .length;
    final drafts = total - published;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),

      body: RefreshIndicator(
        onRefresh: _loadNotices,
        color: const Color(0xFF2563EB),

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(32, 30, 32, 100),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPremiumHeader(),

              const SizedBox(height: 26),

              _buildStatsCards(
                total: total,
                published: published,
                drafts: drafts,
              ),

              const SizedBox(height: 26),

              _buildCategoryFilter(),

              const SizedBox(height: 22),

              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 100),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (errorMessage != null)
                _buildErrorState()
              else
                _buildNoticeList(data),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : _showAddNoticeDialog,

        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,

        elevation: 6,

        icon: const Icon(Icons.add_rounded),

        label: const Text(
          'Create Notice',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildStatsCards({
    required int total,
    required int published,
    required int drafts,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        final cards = [
          _statCard(
            icon: Icons.campaign_outlined,
            title: 'Total Notices',
            value: total.toString(),
          ),
          _statCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Published',
            value: published.toString(),
          ),
          _statCard(
            icon: Icons.edit_note_rounded,
            title: 'Drafts',
            value: drafts.toString(),
          ),
        ];

        if (compact) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: 10),
              cards[1],
              const SizedBox(height: 10),
              cards[2],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 14),
            Expanded(child: cards[1]),
            const SizedBox(width: 14),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8EAF0)),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
          ),

          const SizedBox(width: 13),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF8A92A3),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),

          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
            ),

            borderRadius: BorderRadius.circular(22),

            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.12),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.20)),
                ),

                child: const Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Notices & Announcements',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 6),

                    Text(
                      'Keep students, parents and staff informed.',
                      style: TextStyle(fontSize: 13, color: Color(0xFFDDE9FF)),
                    ),
                  ],
                ),
              ),

              if (!compact) _headerCreateButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _headerCreateButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),

      onTap: isLoading ? null : _showAddNoticeDialog,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),

        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 19, color: Color(0xFF2563EB)),

            SizedBox(width: 7),

            Text(
              'Create Notice',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // CATEGORY FILTER
  // ============================================================

  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      'Academic',
      'Event',
      'Fee',
      'Holiday',
      'MCQ',
      'Sports',
      'General',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final selected = selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    selectedCategory = category;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF2563EB)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : const Color(0xFF6B7280),
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

  // ============================================================
  // NOTICE LIST
  // ============================================================

  Widget _buildNoticeList(List<NoticeModel> data) {
    if (data.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: data.map((notice) {
        return _noticeCard(notice);
      }).toList(),
    );
  }

  // ============================================================
  // NOTICE CARD
  // ============================================================

  Widget _noticeCard(NoticeModel notice) {
    final category = notice.category ?? 'General';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 650) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _noticeIcon(category),
                    const SizedBox(width: 16),
                    Expanded(child: _noticeContent(notice)),
                  ],
                ),

                const SizedBox(height: 15),

                _noticeActions(notice),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _noticeIcon(category),

              const SizedBox(width: 16),

              Expanded(child: _noticeContent(notice)),

              const SizedBox(width: 16),

              _noticeActions(notice),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // NOTICE ICON
  // ============================================================

  Widget _noticeIcon(String category) {
    IconData icon;

    switch (category) {
      case 'Event':
        icon = Icons.event_outlined;
        break;

      case 'Academic':
        icon = Icons.school_outlined;
        break;

      case 'Fee':
        icon = Icons.currency_rupee;
        break;

      case 'Holiday':
        icon = Icons.beach_access_outlined;
        break;

      case 'MCQ':
        icon = Icons.psychology_outlined;
        break;

      case 'Sports':
        icon = Icons.sports_soccer_outlined;
        break;

      default:
        icon = Icons.notifications_none;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: const Color(0xFF2563EB)),
    );
  }

  // ============================================================
  // NOTICE CONTENT
  // ============================================================

  Widget _noticeContent(NoticeModel notice) {
    final category = notice.category ?? 'General';
    final status = _displayStatus(notice.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              notice.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),

            _categoryBadge(category),

            _statusBadge(status),
          ],
        ),

        const SizedBox(height: 9),

        Text(
          notice.message,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF6B7280),
          ),
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 18,
          runSpacing: 7,
          children: [
            _metaItem(Icons.people_outline, notice.audience ?? 'All'),

            _metaItem(Icons.calendar_today_outlined, _formatDate(notice)),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _noticeActions(NoticeModel notice) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () {
            _showNoticeDetails(notice);
          },
          icon: const Icon(Icons.visibility_outlined, size: 19),
        ),

        IconButton(
          tooltip: 'Edit',
          onPressed: () {
            _editNotice(notice);
          },
          icon: const Icon(
            Icons.edit_outlined,
            size: 18,
            color: Color(0xFF2563EB),
          ),
        ),

        IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteNotice(notice);
          },
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // META ITEM
  // ============================================================

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),

        const SizedBox(width: 5),

        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORY BADGE
  // ============================================================

  Widget _categoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2563EB),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(String status) {
    final isPublished = status.trim().toUpperCase() == 'PUBLISHED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? const Color(0xFF15803D)
              : const Color(0xFFD97706),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none, size: 55, color: Color(0xFFD1D5DB)),

          SizedBox(height: 12),

          Text(
            'No notices found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Create a new notice to get started.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 50, color: Color(0xFFDC2626)),

          const SizedBox(height: 12),

          const Text(
            'Failed to load notices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            errorMessage ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: _loadNotices,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(NoticeModel notice) {
    final date = notice.publishedAt ?? notice.createdAt;

    if (date == null) {
      return '-';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // STATUS DISPLAY
  // ============================================================

  String _displayStatus(String? status) {
    if (status == null || status.trim().isEmpty) {
      return 'Draft';
    }

    final normalized = status.trim().toUpperCase();

    if (normalized == 'PUBLISHED') {
      return 'Published';
    }

    return 'Draft';
  }

  // ============================================================
  // VALID CATEGORY
  // ============================================================

  String _validCategory(String? value) {
    const categories = [
      'Academic',
      'Event',
      'Fee',
      'Holiday',
      'MCQ',
      'Sports',
      'General',
    ];

    if (value != null && categories.contains(value)) {
      return value;
    }

    return 'General';
  }

  // ============================================================
  // VALID AUDIENCE
  // ============================================================

  String _validAudience(String? value) {
    const audiences = [
      'All Students',
      'Parents',
      'Students',
      'Students & Parents',
      'Teachers',
      'All',
    ];

    if (value != null && audiences.contains(value)) {
      return value;
    }

    return 'All Students';
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFDC2626) : null,
      ),
    );
  }
}
