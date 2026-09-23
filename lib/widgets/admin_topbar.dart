import 'package:flutter/material.dart';

class AdminTopbar extends StatelessWidget {
  final VoidCallback? onMenuPressed;

  const AdminTopbar({
    super.key,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.10),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // =====================================================
          // MOBILE MENU
          // =====================================================

          if (onMenuPressed != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.08),
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onMenuPressed,
                icon: const Icon(
                  Icons.menu_rounded,
                  size: 21,
                ),
                color: const Color(0xFF374151),
              ),
            ),

            const SizedBox(width: 14),
          ],

          // =====================================================
          // PAGE TITLE
          // =====================================================

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Color(0xFF111827),
                  ),
                ),

                SizedBox(height: 3),

                Text(
                  'Manage your school with ease',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // =====================================================
          // SEARCH
          // =====================================================

          Container(
            width: 230,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.10),
              ),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search anything...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: Color(0xFF6B7280),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 11,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // =====================================================
          // NOTIFICATION
          // =====================================================

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.08),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                    ),
                    color: const Color(0xFF4B5563),
                  ),
                ),

                Positioned(
                  right: 9,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // =====================================================
          // DIVIDER
          // =====================================================

          Container(
            height: 38,
            width: 1,
            color: const Color(0xFFE5E7EB),
          ),

          const SizedBox(width: 14),

          // =====================================================
          // ADMIN PROFILE
          // =====================================================

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.withOpacity(0.07),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo.shade600,
                        Colors.blue.shade500,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 9),

                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Admin',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Administrator',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}