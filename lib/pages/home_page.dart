import 'package:flutter/material.dart';

import 'package:swiftcare_volunteer_app/pages/daily_tasks_page.dart';
import 'package:swiftcare_volunteer_app/pages/weekly_tasks_page.dart';
import 'package:swiftcare_volunteer_app/pages/upcoming_tasks_page.dart';
import 'package:swiftcare_volunteer_app/services/auth_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _selectedDrawerIndex = 0;

  // ============================================================
  // VOLUNTEER DETAILS
  // ============================================================

  String _volunteerName = 'Volunteer';
  String _volunteerRole = 'Volunteer';
  String _volunteerNumber = '';
  String _volunteerEmail = '';
  String _volunteerId = '';
  String _volunteerInitials = 'V';

  bool _loadingVolunteer = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    _loadVolunteerDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD SAVED VOLUNTEER DETAILS
  // ============================================================

  Future<void> _loadVolunteerDetails() async {
    try {
      final firstName =
          await AuthStorage.getFirstName();

      final lastName =
          await AuthStorage.getLastName();

      final role =
          await AuthStorage.getRole();

      final volunteerNumber =
          await AuthStorage.getVolunteerNumber();

      final email =
          await AuthStorage.getEmail();

      final volunteerId =
          await AuthStorage.getVolunteerId();

      final safeFirstName =
          firstName?.trim() ?? '';

      final safeLastName =
          lastName?.trim() ?? '';

      // ==========================================================
      // BUILD FULL VOLUNTEER NAME
      // ==========================================================

      String fullName;

      if (safeFirstName.isNotEmpty &&
          safeLastName.isNotEmpty) {
        fullName =
            '$safeFirstName $safeLastName';
      } else if (safeFirstName.isNotEmpty) {
        fullName = safeFirstName;
      } else if (safeLastName.isNotEmpty) {
        fullName = safeLastName;
      } else {
        fullName = 'Volunteer';
      }

      // ==========================================================
      // BUILD INITIALS
      // ==========================================================

      final initials = _buildInitials(
        safeFirstName,
        safeLastName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _volunteerName = fullName;

        _volunteerRole =
            role?.trim().isNotEmpty == true
                ? role!.trim()
                : 'Volunteer';

        _volunteerNumber =
            volunteerNumber?.trim() ?? '';

        _volunteerEmail =
            email?.trim() ?? '';

        _volunteerId =
            volunteerId?.trim() ?? '';

        _volunteerInitials =
            initials;

        _loadingVolunteer = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingVolunteer = false;
      });
    }
  }

  // ============================================================
  // BUILD INITIALS
  // ============================================================

  String _buildInitials(
    String firstName,
    String lastName,
  ) {
    final first =
        firstName.trim();

    final last =
        lastName.trim();

    if (first.isNotEmpty &&
        last.isNotEmpty) {
      return '${first[0]}${last[0]}'
          .toUpperCase();
    }

    if (first.isNotEmpty) {
      return first[0].toUpperCase();
    }

    if (last.isNotEmpty) {
      return last[0].toUpperCase();
    }

    return 'V';
  }

  // ============================================================
  // DRAWER NAVIGATION
  // ============================================================

  void _selectDrawerItem(
    int index,
  ) {
    setState(() {
      _selectedDrawerIndex =
          index;
    });

    Navigator.of(context).pop();

    switch (index) {
      case 0:
        break;

      case 1:
        Navigator.of(context)
            .pushNamed('/attendance');
        break;

      case 2:
        Navigator.of(context)
            .pushNamed('/schedule');
        break;

      case 3:
        Navigator.of(context)
            .pushNamed('/profile');
        break;

    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    Navigator.of(context).pop();

    final shouldLogout =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              18,
            ),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF1B5E20),
            ),
          ),
          content: const Text(
            'Are you sure you want to logout of SwiftCare?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color:
                      Color(0xFF2E7D32),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pop(true);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF2E7D32,
                ),
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    // ==========================================================
    // DELETE JWT + VOLUNTEER DETAILS
    // ==========================================================

    await AuthStorage.clearLogin();

    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF0FDF4),

      drawer: _buildDrawer(),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1B5E20),
        foregroundColor:
            Colors.white,
        elevation: 0,

        title: const Text(
          'SwiftCare',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

       
      ),

      body: SafeArea(
        child: Column(
          children: [
            _buildWelcomeHeader(),

            _buildDashboardTabs(),

            Expanded(
              child: TabBarView(
                controller:
                    _tabController,
                children: const [
                  DailyTasksPage(),
                  WeeklyTasksPage(),
                  UpcomingTasksPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME HEADER
  // ============================================================

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        22,
      ),
      decoration:
          const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(26),
          bottomRight:
              Radius.circular(26),
        ),
      ),
      child: Row(
        children: [
          _buildInitialAvatar(
            size: 58,
            fontSize: 21,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back,',
                  style: TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _loadingVolunteer
                      ? 'Loading...'
                      : _volunteerName,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 14,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _volunteerRole,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFFDCEDC8),
                    fontSize: 13,
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
  // INITIAL AVATAR
  // ============================================================

  Widget _buildInitialAvatar({
    required double size,
    required double fontSize,
  }) {
    return Container(
      width: size,
      height: size,
      decoration:
          const BoxDecoration(
        color: Color(0xFFDCEDC8),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _volunteerInitials,
        style: TextStyle(
          color:
              const Color(0xFF1B5E20),
          fontSize: fontSize,
          fontWeight:
              FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD TABS
  // ============================================================

  Widget _buildDashboardTabs() {
    return Container(
      margin:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      padding:
          const EdgeInsets.all(5),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset:
                Offset(0, 3),
            color:
                Color(0x10000000),
          ),
        ],
      ),
      child: TabBar(
        controller:
            _tabController,
        indicator:
            BoxDecoration(
          color:
              const Color(0xFF2E7D32),
          borderRadius:
              BorderRadius.circular(
            11,
          ),
        ),
        indicatorSize:
            TabBarIndicatorSize.tab,
        dividerColor:
            Colors.transparent,
        labelColor:
            Colors.white,
        unselectedLabelColor:
            const Color(0xFF1B5E20),
        labelStyle:
            const TextStyle(
          fontSize: 13,
          fontWeight:
              FontWeight.bold,
        ),
        tabs: const [
          Tab(
            text: 'Today',
          ),
          Tab(
            text: 'This Week',
          ),
          Tab(
            text: 'Upcoming',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor:
          const Color(0xFFF0FDF4),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),

            const SizedBox(height: 10),

            _buildDrawerItem(
              icon:
                  Icons.dashboard_outlined,
              activeIcon:
                  Icons.dashboard,
              title: 'Dashboard',
              index: 0,
            ),

            _buildDrawerItem(
              icon:
                  Icons.fact_check_outlined,
              activeIcon:
                  Icons.fact_check,
              title: 'Today\'s Attendance',
              index: 1,
            ),

            _buildDrawerItem(
              icon:
                  Icons.calendar_month_outlined,
              activeIcon:
                  Icons.calendar_month,
              title: 'My Schedule',
              index: 2,
            ),

            _buildDrawerItem(
              icon:
                  Icons.person_outline,
              activeIcon:
                  Icons.person,
              title: 'My Profile',
              index: 3,
            ),

            const Spacer(),

            const Divider(
              indent: 20,
              endIndent: 20,
            ),

            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 22,
              ),
              leading:
                  const Icon(
                Icons.logout,
                color:
                    Color(0xFFB71C1C),
              ),
              title:
                  const Text(
                'Logout',
                style:
                    TextStyle(
                  color:
                      Color(0xFFB71C1C),
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              onTap: _logout,
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER HEADER
  // ============================================================

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        22,
        28,
        22,
        26,
      ),
      decoration:
          const BoxDecoration(
        color: Color(0xFF1B5E20),
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(28),
          bottomRight:
              Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _buildInitialAvatar(
            size: 68,
            fontSize: 25,
          ),

          const SizedBox(height: 16),

          Text(
            _loadingVolunteer
                ? 'Loading...'
                : _volunteerName,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _volunteerRole,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  Color(0xFFDCEDC8),
              fontSize: 14,
              fontWeight:
                  FontWeight.w500,
            ),
          ),

          if (_volunteerNumber
              .isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Volunteer No. '
              '$_volunteerNumber',
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget _buildDrawerItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required int index,
  }) {
    final isSelected =
        _selectedDrawerIndex ==
            index;

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 3,
      ),
      decoration:
          BoxDecoration(
        color: isSelected
            ? const Color(
                0xFFDCEDC8,
              )
            : Colors.transparent,
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(
          isSelected
              ? activeIcon
              : icon,
          color: isSelected
              ? const Color(
                  0xFF1B5E20,
                )
              : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(
                    0xFF1B5E20,
                  )
                : Colors.grey.shade800,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
        onTap: () {
          _selectDrawerItem(index);
        },
      ),
    );
  }
}