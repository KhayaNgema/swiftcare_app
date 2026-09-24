import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),

        children: [
          _buildNotification(
            icon: Icons.task_alt,
            title: 'New task assigned',
            message:
                'You have a new resident support task scheduled for today.',
            time: '10 minutes ago',
          ),

          _buildNotification(
            icon: Icons.event_available,
            title: 'Upcoming task',
            message:
                'You have a recreation activity scheduled tomorrow.',
            time: '2 hours ago',
          ),

          _buildNotification(
            icon: Icons.check_circle_outline,
            title: 'Profile verified',
            message:
                'Your SwiftCare volunteer identity has been verified.',
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }

  Widget _buildNotification({
    required IconData icon,
    required String title,
    required String message,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: const Color(0xFFD5E7D6),
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 46,
            height: 46,

            decoration: const BoxDecoration(
              color: Color(0xFFDCEDC8),
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}