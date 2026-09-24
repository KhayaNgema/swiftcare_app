import 'package:flutter/material.dart';

import 'package:swiftcare_volunteer_app/pages/splash_screen.dart';
import 'package:swiftcare_volunteer_app/pages/home_page.dart';
import 'package:swiftcare_volunteer_app/pages/tasks_page.dart';
import 'package:swiftcare_volunteer_app/pages/profile_page.dart';
import 'package:swiftcare_volunteer_app/pages/notifications_page.dart';
import 'package:swiftcare_volunteer_app/pages/volunteer_schedule_page.dart';
import 'package:swiftcare_volunteer_app/pages/todays_attendance_page.dart';

void main() {
  runApp(
    const SwiftCareVolunteerApp(),
  );
}

class SwiftCareVolunteerApp
    extends StatelessWidget {
  const SwiftCareVolunteerApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'SwiftCare Volunteer',

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
        ),

        scaffoldBackgroundColor:
            const Color(0xFFF0FDF4),

        fontFamily: 'Roboto',
      ),

      // ============================================================
      // ROUTES
      // ============================================================

      initialRoute: '/splash',

      routes: {
        // ----------------------------------------------------------
        // SPLASH
        // ----------------------------------------------------------

        '/splash': (context) =>
            const SplashScreen(),

        // ----------------------------------------------------------
        // VOLUNTEER DASHBOARD
        // ----------------------------------------------------------

        '/home': (context) =>
            const HomePage(),

        //VOLUNTEER ATTENDANCE PAGE

        '/attendance': (context) =>
             const TodaysAttendancePage(),

        // ----------------------------------------------------------
        // TASKS
        // ----------------------------------------------------------

        '/tasks': (context) =>
            const TasksPage(),

        // ----------------------------------------------------------
        // PROFILE
        // ----------------------------------------------------------

        '/profile': (context) =>
            const ProfilePage(),

        //SCHEDULE

          '/schedule': (context) =>
      const VolunteerSchedulePage(),

        // ----------------------------------------------------------
        // NOTIFICATIONS
        // ----------------------------------------------------------

        '/notifications': (context) =>
            const NotificationsPage(),
      },
    );
  }
}
