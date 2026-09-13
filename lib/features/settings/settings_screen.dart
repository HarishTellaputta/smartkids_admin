import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int selectedSection = 0;

  bool emailNotifications = true;
  bool pushNotifications = true;
  bool admissionNotifications = true;
  bool feeNotifications = true;
  bool attendanceNotifications = true;
  bool mcqNotifications = true;

  bool twoFactorAuthentication = false;
  bool loginAlerts = true;

  String academicYear = '2026-27';
  String medium = 'English';
  String timezone = 'Asia/Kolkata';
  String dateFormat = 'DD MMM YYYY';

  final schoolNameController = TextEditingController(
    text: 'MySchool',
  );

  final schoolCodeController = TextEditingController(text: 'SKP-001');

  final schoolPhoneController = TextEditingController(text: '9876543210');

  final schoolEmailController = TextEditingController(
    text: 'admin@myschool.com',
  );

  final schoolAddressController = TextEditingController(
    text: 'Khammam, Telangana',
  );

  final principalController = TextEditingController(text: 'School Principal');

  @override
  void dispose() {
    schoolNameController.dispose();
    schoolCodeController.dispose();
    schoolPhoneController.dispose();
    schoolEmailController.dispose();
    schoolAddressController.dispose();
    principalController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> sections = [
    {'title': 'School Profile', 'icon': Icons.school_outlined},
    {'title': 'Academic Settings', 'icon': Icons.menu_book_outlined},
    {'title': 'Notifications', 'icon': Icons.notifications_none_outlined},
    {'title': 'Security', 'icon': Icons.security_outlined},
    {'title': 'Admin Preferences', 'icon': Icons.tune_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSettingsLayout(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Manage school configuration and administrator preferences.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildSettingsLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              _buildSectionMenu(),
              const SizedBox(height: 20),
              _buildSelectedSection(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 245, child: _buildSectionMenu()),
            const SizedBox(width: 22),
            Expanded(child: _buildSelectedSection()),
          ],
        );
      },
    );
  }

  Widget _buildSectionMenu() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: List.generate(sections.length, (index) {
          final section = sections[index];
          final selected = selectedSection == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  selectedSection = index;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      section['icon'],
                      size: 19,
                      color: selected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        section['title'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.chevron_right,
                        size: 17,
                        color: Color(0xFF2563EB),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedSection() {
    switch (selectedSection) {
      case 0:
        return _schoolProfileSection();

      case 1:
        return _academicSettingsSection();

      case 2:
        return _notificationSection();

      case 3:
        return _securitySection();

      case 4:
        return _adminPreferencesSection();

      default:
        return _schoolProfileSection();
    }
  }

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _schoolProfileSection() {
    return _sectionCard(
      title: 'School Profile',
      subtitle: 'Update your school information displayed across the platform.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSchoolLogoSection(),
          const SizedBox(height: 25),
          _responsiveForm(
            children: [
              _textField(
                controller: schoolNameController,
                label: 'School Name',
                icon: Icons.school_outlined,
              ),
              _textField(
                controller: schoolCodeController,
                label: 'School Code',
                icon: Icons.badge_outlined,
              ),
              _textField(
                controller: schoolPhoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
              ),
              _textField(
                controller: schoolEmailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
              ),
              _textField(
                controller: principalController,
                label: 'Principal Name',
                icon: Icons.person_outline,
              ),
              _textField(
                controller: schoolAddressController,
                label: 'School Address',
                icon: Icons.location_on_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _saveButton(text: 'Save School Profile', onPressed: _saveSettings),
        ],
      ),
    );
  }

  Widget _buildSchoolLogoSection() {
    return Row(
      children: [
        Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Icon(Icons.school, size: 38, color: Color(0xFF2563EB)),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'School Logo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Upload your school logo.',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 9),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logo upload will be connected later.'),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_outlined, size: 17),
                label: const Text('Upload Logo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _academicSettingsSection() {
    return _sectionCard(
      title: 'Academic Settings',
      subtitle: 'Configure academic year, language and regional settings.',
      child: Column(
        children: [
          _responsiveForm(
            children: [
              _dropdownField(
                label: 'Academic Year',
                value: academicYear,
                items: const ['2025-26', '2026-27', '2027-28'],
                onChanged: (value) {
                  setState(() {
                    academicYear = value!;
                  });
                },
              ),
              _dropdownField(
                label: 'School Medium',
                value: medium,
                items: const ['English', 'Telugu', 'Hindi', 'English & Telugu'],
                onChanged: (value) {
                  setState(() {
                    medium = value!;
                  });
                },
              ),
              _dropdownField(
                label: 'Timezone',
                value: timezone,
                items: const ['Asia/Kolkata', 'Asia/Dubai', 'Asia/Singapore'],
                onChanged: (value) {
                  setState(() {
                    timezone = value!;
                  });
                },
              ),
              _dropdownField(
                label: 'Date Format',
                value: dateFormat,
                items: const [
                  'DD MMM YYYY',
                  'DD/MM/YYYY',
                  'MM/DD/YYYY',
                  'YYYY-MM-DD',
                ],
                onChanged: (value) {
                  setState(() {
                    dateFormat = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _infoBox(
            icon: Icons.info_outline,
            title: 'MCQ Test Schedule',
            message:
                'Daily MCQ tests are currently planned for 7:00 PM. The final schedule will be controlled by the backend.',
          ),
          const SizedBox(height: 22),
          _saveButton(text: 'Save Academic Settings', onPressed: _saveSettings),
        ],
      ),
    );
  }

  Widget _notificationSection() {
    return _sectionCard(
      title: 'Notifications',
      subtitle:
          'Choose which notifications the school administrator should receive.',
      child: Column(
        children: [
          _switchTile(
            icon: Icons.email_outlined,
            title: 'Email Notifications',
            subtitle: 'Receive important school updates by email.',
            value: emailNotifications,
            onChanged: (value) {
              setState(() {
                emailNotifications = value;
              });
            },
          ),
          _divider(),
          _switchTile(
            icon: Icons.notifications_active_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive notifications inside the admin portal.',
            value: pushNotifications,
            onChanged: (value) {
              setState(() {
                pushNotifications = value;
              });
            },
          ),
          _divider(),
          _switchTile(
            icon: Icons.person_add_outlined,
            title: 'Admission Notifications',
            subtitle: 'Get notified when a new admission application arrives.',
            value: admissionNotifications,
            onChanged: (value) {
              setState(() {
                admissionNotifications = value;
              });
            },
          ),
          _divider(),
          _switchTile(
            icon: Icons.currency_rupee,
            title: 'Fee Notifications',
            subtitle: 'Receive alerts for fee payments and pending fees.',
            value: feeNotifications,
            onChanged: (value) {
              setState(() {
                feeNotifications = value;
              });
            },
          ),
          _divider(),
          _switchTile(
            icon: Icons.fact_check_outlined,
            title: 'Attendance Notifications',
            subtitle: 'Receive alerts about attendance updates.',
            value: attendanceNotifications,
            onChanged: (value) {
              setState(() {
                attendanceNotifications = value;
              });
            },
          ),
          _divider(),
          _switchTile(
            icon: Icons.psychology_outlined,
            title: 'MCQ Test Notifications',
            subtitle: 'Receive alerts when daily MCQ tests are published.',
            value: mcqNotifications,
            onChanged: (value) {
              setState(() {
                mcqNotifications = value;
              });
            },
          ),
          const SizedBox(height: 22),
          _saveButton(
            text: 'Save Notification Settings',
            onPressed: _saveSettings,
          ),
        ],
      ),
    );
  }

  Widget _securitySection() {
    return _sectionCard(
      title: 'Security',
      subtitle: 'Manage administrator account security settings.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _securityInfoCard(),
          const SizedBox(height: 20),
          _switchTile(
            icon: Icons.verified_user_outlined,
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security to administrator login.',
            value: twoFactorAuthentication,
            onChanged: (value) {
              setState(() {
                twoFactorAuthentication = value;
              });
            },
          ),
          _divider(),
          _switchTile(
            icon: Icons.login_outlined,
            title: 'Login Alerts',
            subtitle: 'Notify the administrator when a new login occurs.',
            value: loginAlerts,
            onChanged: (value) {
              setState(() {
                loginAlerts = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _passwordButton(),
          const SizedBox(height: 22),
          _saveButton(text: 'Save Security Settings', onPressed: _saveSettings),
        ],
      ),
    );
  }

  Widget _securityInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.security_outlined, color: Color(0xFF2563EB)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrator Security',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Security controls will be enforced by the Spring Boot backend once authentication is connected.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordButton() {
    return OutlinedButton.icon(
      onPressed: () {
        _showChangePasswordDialog();
      },
      icon: const Icon(Icons.lock_reset_outlined, size: 18),
      label: const Text('Change Password'),
    );
  }

  Widget _adminPreferencesSection() {
    return _sectionCard(
      title: 'Admin Preferences',
      subtitle: 'Configure preferences for your administrator account.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _preferenceItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            subtitle: 'Show school statistics and recent activities on login.',
            trailing: const Text(
              'Enabled',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
          ),
          _divider(),
          _preferenceItem(
            icon: Icons.language_outlined,
            title: 'Portal Language',
            subtitle: 'Language used throughout the admin portal.',
            trailing: DropdownButton<String>(
              value: 'English',
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: 'English',
                  child: Text('English', style: TextStyle(fontSize: 12)),
                ),
                DropdownMenuItem(
                  value: 'Telugu',
                  child: Text('Telugu', style: TextStyle(fontSize: 12)),
                ),
              ],
              onChanged: (value) {},
            ),
          ),
          _divider(),
          _preferenceItem(
            icon: Icons.view_sidebar_outlined,
            title: 'Sidebar Navigation',
            subtitle: 'Keep the sidebar expanded on desktop.',
            trailing: Switch(value: true, onChanged: (value) {}),
          ),
          _divider(),
          _preferenceItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Contact MySchool support for assistance.',
            trailing: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Support section will be connected later.'),
                  ),
                );
              },
              child: const Text('Contact'),
            ),
          ),
          const SizedBox(height: 22),
          _infoBox(
            icon: Icons.cloud_outlined,
            title: 'Backend Connection',
            message:
                'The admin portal is currently running with local dummy data. API and database settings will be added when the Spring Boot backend is connected.',
          ),
        ],
      ),
    );
  }

  Widget _preferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFE5E7EB)),
    );
  }

  Widget _responsiveForm({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: child,
                  ),
                )
                .toList(),
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.8,
          children: children,
        );
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB)),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _infoBox({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton({required String text, required VoidCallback onPressed}) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_outlined, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully.')),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
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
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Password change will be connected to the backend.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Password'),
            ),
          ],
        );
      },
    );
  }
}
