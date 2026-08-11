import 'package:flutter/material.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  String selectedCategory = 'All';

  final List<Map<String, dynamic>> notices = [
    {
      'title': 'Independence Day Celebration',
      'description':
          'School will celebrate Independence Day on 15th August. Students should come in proper school uniform.',
      'category': 'Event',
      'audience': 'All Students',
      'date': '10 Aug 2026',
      'status': 'Published',
    },
    {
      'title': 'Parent-Teacher Meeting',
      'description':
          'Parent-Teacher meeting will be conducted on Saturday from 10:00 AM to 1:00 PM.',
      'category': 'Academic',
      'audience': 'Parents',
      'date': '09 Aug 2026',
      'status': 'Published',
    },
    {
      'title': 'Monthly Fee Reminder',
      'description':
          'Parents are requested to complete the monthly school fee payment before the due date.',
      'category': 'Fee',
      'audience': 'Parents',
      'date': '08 Aug 2026',
      'status': 'Published',
    },
    {
      'title': 'Unit Test Schedule',
      'description':
          'The first unit tests will begin from 20th August. Students are requested to prepare accordingly.',
      'category': 'Academic',
      'audience': 'Students & Parents',
      'date': '07 Aug 2026',
      'status': 'Published',
    },
    {
      'title': 'School Holiday Notice',
      'description':
          'The school will remain closed on Monday due to a public holiday.',
      'category': 'Holiday',
      'audience': 'All',
      'date': '06 Aug 2026',
      'status': 'Published',
    },
    {
      'title': 'New Daily MCQ Test',
      'description':
          'Daily MCQ tests will be available for students every day at 7:00 PM.',
      'category': 'MCQ',
      'audience': 'Students',
      'date': '05 Aug 2026',
      'status': 'Published',
    },
    {
      'title': 'Sports Day Registration',
      'description':
          'Students interested in participating in Sports Day events can register with their class teacher.',
      'category': 'Sports',
      'audience': 'Students',
      'date': '04 Aug 2026',
      'status': 'Draft',
    },
  ];

  List<Map<String, dynamic>> get filteredNotices {
    if (selectedCategory == 'All') {
      return notices;
    }

    return notices
        .where((notice) => notice['category'] == selectedCategory)
        .toList();
  }

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
                OutlinedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      notices.insert(0, {
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'category': category,
                        'audience': audience,
                        'date': '10 Aug 2026',
                        'status': 'Draft',
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notice saved as draft.')),
                    );
                  },
                  child: const Text('Save Draft'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      notices.insert(0, {
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'category': category,
                        'audience': audience,
                        'date': '10 Aug 2026',
                        'status': 'Published',
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notice published successfully.'),
                      ),
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

  void _showNoticeDetails(Map<String, dynamic> notice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            notice['title'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailItem('Category', notice['category']),
                _detailItem('Audience', notice['audience']),
                _detailItem('Date', notice['date']),
                _detailItem('Status', notice['status']),
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
                  notice['description'],
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

  void _deleteNotice(int index) {
    final notice = filteredNotices[index];

    final actualIndex = notices.indexOf(notice);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Notice?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Are you sure you want to delete this notice?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  notices.removeAt(actualIndex);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Notice deleted successfully.')),
                );
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

  void _editNotice(Map<String, dynamic> notice) {
    final titleController = TextEditingController(text: notice['title']);

    final descriptionController = TextEditingController(
      text: notice['description'],
    );

    String category = notice['category'];
    String audience = notice['audience'];

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
                  onPressed: () {
                    final index = notices.indexOf(notice);

                    if (index == -1) {
                      Navigator.pop(dialogContext);
                      return;
                    }

                    setState(() {
                      notices[index] = {
                        ...notices[index],
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'category': category,
                        'audience': audience,
                      };
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notice updated successfully.'),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final data = filteredNotices;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildCategoryFilter(),
            const SizedBox(height: 24),
            _buildNoticeList(data),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNoticeDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Notice'),
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notices & Announcements',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Create and manage school announcements.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      'Academic',
      'Event',
      'Fee',
      'Holiday',
      'MCQ',
      'Sports',
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

  Widget _buildNoticeList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: data.map((notice) {
        final index = notices.indexOf(notice);

        return _noticeCard(notice, index);
      }).toList(),
    );
  }

  Widget _noticeCard(Map<String, dynamic> notice, int index) {
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
                _noticeContent(notice),
                const SizedBox(height: 15),
                _noticeActions(notice, index),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _noticeIcon(notice['category']),
              const SizedBox(width: 16),
              Expanded(child: _noticeContent(notice)),
              const SizedBox(width: 16),
              _noticeActions(notice, index),
            ],
          );
        },
      ),
    );
  }

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

  Widget _noticeContent(Map<String, dynamic> notice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              notice['title'],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            _categoryBadge(notice['category']),
            _statusBadge(notice['status']),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          notice['description'],
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
            _metaItem(Icons.people_outline, notice['audience']),
            _metaItem(Icons.calendar_today_outlined, notice['date']),
          ],
        ),
      ],
    );
  }

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

  Widget _noticeActions(Map<String, dynamic> notice, int index) {
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
            _deleteNotice(index);
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

  Widget _statusBadge(String status) {
    final isPublished = status == 'Published';

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
}
