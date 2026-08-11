import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String selectedCategory = 'All';

  final List<Map<String, dynamic>> events = [
    {
      'title': 'Independence Day Celebration',
      'description':
          'Flag hoisting, cultural programs, patriotic songs and student performances.',
      'category': 'Celebration',
      'date': '15 Aug 2026',
      'time': '8:00 AM - 12:00 PM',
      'venue': 'School Ground',
      'audience': 'All Students',
      'status': 'Upcoming',
    },
    {
      'title': 'Parent-Teacher Meeting',
      'description':
          'Parents can meet class teachers to discuss student academic progress and activities.',
      'category': 'Meeting',
      'date': '22 Aug 2026',
      'time': '10:00 AM - 1:00 PM',
      'venue': 'School Campus',
      'audience': 'Parents',
      'status': 'Upcoming',
    },
    {
      'title': 'Sports Day',
      'description':
          'Annual sports day with running, relay, team games and other activities.',
      'category': 'Sports',
      'date': '05 Sep 2026',
      'time': '8:00 AM - 3:00 PM',
      'venue': 'School Playground',
      'audience': 'Students',
      'status': 'Upcoming',
    },
    {
      'title': 'Science Exhibition',
      'description':
          'Students will present science projects and innovative working models.',
      'category': 'Academic',
      'date': '18 Sep 2026',
      'time': '9:00 AM - 2:00 PM',
      'venue': 'School Hall',
      'audience': 'Students & Parents',
      'status': 'Upcoming',
    },
    {
      'title': 'Teachers Day Celebration',
      'description':
          'Special celebration organized by students to appreciate teachers.',
      'category': 'Celebration',
      'date': '05 Sep 2026',
      'time': '10:00 AM - 12:00 PM',
      'venue': 'Auditorium',
      'audience': 'Teachers & Students',
      'status': 'Upcoming',
    },
    {
      'title': 'Annual Day 2026',
      'description':
          'Annual school celebration with cultural programs, awards and student performances.',
      'category': 'Celebration',
      'date': '20 Dec 2025',
      'time': '5:00 PM - 9:00 PM',
      'venue': 'School Auditorium',
      'audience': 'All',
      'status': 'Completed',
    },
    {
      'title': 'Math Quiz Competition',
      'description': 'Inter-class mathematics quiz competition for students.',
      'category': 'Competition',
      'date': '01 Aug 2026',
      'time': '10:00 AM - 12:00 PM',
      'venue': 'Classroom Block',
      'audience': 'Students',
      'status': 'Completed',
    },
  ];

  List<Map<String, dynamic>> get filteredEvents {
    if (selectedCategory == 'All') {
      return events;
    }

    return events
        .where((event) => event['category'] == selectedCategory)
        .toList();
  }

  int get upcomingCount =>
      events.where((event) => event['status'] == 'Upcoming').length;

  int get completedCount =>
      events.where((event) => event['status'] == 'Completed').length;

  void _showAddEventDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();
    final venueController = TextEditingController();

    String category = 'Celebration';
    String audience = 'All Students';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create New Event',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Event Name',
                          hintText: 'Enter event name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter event details',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateController,
                              decoration: InputDecoration(
                                labelText: 'Date',
                                hintText: '15 Aug 2026',
                                prefixIcon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: timeController,
                              decoration: InputDecoration(
                                labelText: 'Time',
                                hintText: '10:00 AM - 1:00 PM',
                                prefixIcon: const Icon(
                                  Icons.access_time_outlined,
                                  size: 18,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: venueController,
                        decoration: InputDecoration(
                          labelText: 'Venue',
                          hintText: 'School Auditorium',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                              'Celebration',
                              'Academic',
                              'Sports',
                              'Competition',
                              'Meeting',
                              'Workshop',
                              'Other',
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
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: audience,
                        decoration: InputDecoration(
                          labelText: 'Audience',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            const [
                              'All Students',
                              'Students',
                              'Parents',
                              'Students & Parents',
                              'Teachers & Students',
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
                    if (titleController.text.trim().isEmpty) {
                      return;
                    }

                    setState(() {
                      events.insert(0, {
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'category': category,
                        'date': dateController.text.trim().isEmpty
                            ? 'Date not set'
                            : dateController.text.trim(),
                        'time': timeController.text.trim().isEmpty
                            ? 'Time not set'
                            : timeController.text.trim(),
                        'venue': venueController.text.trim().isEmpty
                            ? 'Venue not set'
                            : venueController.text.trim(),
                        'audience': audience,
                        'status': 'Upcoming',
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event created successfully.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Event'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            event['title'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  Icons.category_outlined,
                  'Category',
                  event['category'],
                ),
                _detailRow(
                  Icons.calendar_today_outlined,
                  'Date',
                  event['date'],
                ),
                _detailRow(Icons.access_time_outlined, 'Time', event['time']),
                _detailRow(Icons.location_on_outlined, 'Venue', event['venue']),
                _detailRow(Icons.people_outline, 'Audience', event['audience']),
                _detailRow(Icons.info_outline, 'Status', event['status']),
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event['description'],
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Color(0xFF6B7280),
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

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF2563EB)),
          const SizedBox(width: 10),
          SizedBox(
            width: 75,
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

  void _deleteEvent(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Event?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to delete "${event['title']}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  events.remove(event);
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Event deleted successfully.')),
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

  void _editEvent(Map<String, dynamic> event) {
    final titleController = TextEditingController(text: event['title']);

    final descriptionController = TextEditingController(
      text: event['description'],
    );

    final dateController = TextEditingController(text: event['date']);

    final timeController = TextEditingController(text: event['time']);

    final venueController = TextEditingController(text: event['venue']);

    String category = event['category'];
    String audience = event['audience'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Event',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Event Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: dateController,
                              decoration: InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: timeController,
                              decoration: InputDecoration(
                                labelText: 'Time',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: venueController,
                        decoration: InputDecoration(
                          labelText: 'Venue',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
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
                              'Celebration',
                              'Academic',
                              'Sports',
                              'Competition',
                              'Meeting',
                              'Workshop',
                              'Other',
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
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: audience,
                        decoration: InputDecoration(
                          labelText: 'Audience',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items:
                            const [
                              'All Students',
                              'Students',
                              'Parents',
                              'Students & Parents',
                              'Teachers & Students',
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
                    final index = events.indexOf(event);

                    if (index == -1) {
                      Navigator.pop(dialogContext);
                      return;
                    }

                    setState(() {
                      events[index] = {
                        ...events[index],
                        'title': titleController.text.trim(),
                        'description': descriptionController.text.trim(),
                        'date': dateController.text.trim(),
                        'time': timeController.text.trim(),
                        'venue': venueController.text.trim(),
                        'category': category,
                        'audience': audience,
                      };
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event updated successfully.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update Event'),
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
    final data = filteredEvents;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSummary(),
            const SizedBox(height: 24),
            _buildCategoryFilter(),
            const SizedBox(height: 24),
            _buildEventList(data),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventDialog,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'School Events',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Create and manage school events and activities.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 3;

        if (constraints.maxWidth < 750) {
          columns = 1;
        }

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: columns == 1 ? 4 : 2.7,
          children: [
            _summaryCard(
              'Total Events',
              '${events.length}',
              Icons.event_note_outlined,
              const Color(0xFF2563EB),
              const Color(0xFFEFF6FF),
            ),
            _summaryCard(
              'Upcoming',
              '$upcomingCount',
              Icons.event_available_outlined,
              const Color(0xFF15803D),
              const Color(0xFFF0FDF4),
            ),
            _summaryCard(
              'Completed',
              '$completedCount',
              Icons.event_available_outlined,
              const Color(0xFF7C3AED),
              const Color(0xFFF5F3FF),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = [
      'All',
      'Celebration',
      'Academic',
      'Sports',
      'Competition',
      'Meeting',
      'Workshop',
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
                    horizontal: 15,
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

  Widget _buildEventList(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return _emptyState();
    }

    return Column(
      children: data.map((event) {
        return _eventCard(event);
      }).toList(),
    );
  }

  Widget _eventCard(Map<String, dynamic> event) {
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
          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _eventDateBox(event['date']),
                    const SizedBox(width: 15),
                    Expanded(child: _eventMainContent(event)),
                  ],
                ),
                const SizedBox(height: 15),
                _eventActions(event),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eventDateBox(event['date']),
              const SizedBox(width: 18),
              Expanded(child: _eventMainContent(event)),
              const SizedBox(width: 15),
              _eventActions(event),
            ],
          );
        },
      ),
    );
  }

  Widget _eventDateBox(String date) {
    final parts = date.split(' ');

    String day = parts.isNotEmpty ? parts.first : '--';

    String month = parts.length > 1 ? parts[1] : '';

    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB),
            ),
          ),
          Text(
            month.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventMainContent(Map<String, dynamic> event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              event['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            _categoryBadge(event['category']),
            _statusBadge(event['status']),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          event['description'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 13),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _metaItem(Icons.access_time_outlined, event['time']),
            _metaItem(Icons.location_on_outlined, event['venue']),
            _metaItem(Icons.people_outline, event['audience']),
          ],
        ),
      ],
    );
  }

  Widget _eventActions(Map<String, dynamic> event) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'View',
          onPressed: () {
            _showEventDetails(event);
          },
          icon: const Icon(Icons.visibility_outlined, size: 19),
        ),
        IconButton(
          tooltip: 'Edit',
          onPressed: () {
            _editEvent(event);
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
            _deleteEvent(event);
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

  Widget _metaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
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
    final upcoming = status == 'Upcoming';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: upcoming ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: upcoming ? const Color(0xFF15803D) : const Color(0xFF6B7280),
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
          Icon(Icons.event_busy_outlined, size: 55, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Create a new event to get started.',
            style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
