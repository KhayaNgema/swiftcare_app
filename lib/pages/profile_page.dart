import 'package:flutter/material.dart';

import 'package:swiftcare_volunteer_app/services/auth_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ============================================================
  // SAVED PROFILE DATA
  // ============================================================

  String _volunteerNumber = '';
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _userName = '';
  String _role = '';

  bool _isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();
  }

  // ============================================================
  // LOAD SAVED PROFILE
  // ============================================================

  Future<void> _loadSavedProfile() async {
    try {
      final volunteerNumber =
          await AuthStorage.getVolunteerNumber();

      final firstName =
          await AuthStorage.getFirstName();

      final lastName =
          await AuthStorage.getLastName();

      final email =
          await AuthStorage.getEmail();

      final userName =
          await AuthStorage.getUserName();

      final role =
          await AuthStorage.getRole();

      if (!mounted) return;

      setState(() {
        _volunteerNumber = volunteerNumber ?? '';
        _firstName = firstName ?? '';
        _lastName = lastName ?? '';
        _email = email ?? '';
        _userName = userName ?? '';
        _role = role ?? '';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: _loadSavedProfile,
              child: ListView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  20,
                  18,
                  30,
                ),
                children: [
                  _buildProfileHeader(),

                  const SizedBox(height: 24),

                  _buildSectionTitle(
                    'Volunteer Details',
                  ),

                  const SizedBox(height: 10),

                  _buildInfoCard(
                    icon: Icons.badge_outlined,
                    title: 'Volunteer Number',
                    value: _displayValue(
                      _volunteerNumber,
                    ),
                  ),

                  _buildInfoCard(
                    icon: Icons.person_outline,
                    title: 'Full Name',
                    value: _fullName(),
                  ),

                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    title: 'Email Address',
                    value: _displayValue(
                      _email,
                    ),
                  ),

                  _buildInfoCard(
                    icon: Icons.account_circle_outlined,
                    title: 'Username',
                    value: _displayValue(
                      _userName,
                    ),
                  ),

                  _buildInfoCard(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Role',
                    value: _formatRole(_role),
                  ),

                  const SizedBox(height: 12),

                  _buildSecurityCard(),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    final String name = _fullName();

    final String displayName =
        name.isNotEmpty ? name : 'Volunteer';

    final String role =
        _formatRole(_role).isNotEmpty
            ? _formatRole(_role)
            : 'Volunteer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B5E20),
            Color(0xFF2E7D32),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 5),
            color: Color(0x18000000),
          ),
        ],
      ),
      child: Column(
        children: [
          // ------------------------------------------------------
          // PROFILE PICTURE / INITIALS
          // ------------------------------------------------------

          _buildProfileAvatar(),

          const SizedBox(height: 15),

          // ------------------------------------------------------
          // NAME
          // ------------------------------------------------------

          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ------------------------------------------------------
          // USERNAME
          // ------------------------------------------------------

          if (_userName.trim().isNotEmpty) ...[
            const SizedBox(height: 4),

            Text(
              '@${_userName.trim()}',
              style: const TextStyle(
                color: Color(0xFFD5E7D6),
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 11),

          // ------------------------------------------------------
          // ROLE
          // ------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0x338BC34A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x668BC34A),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.volunteer_activism_outlined,
                  size: 15,
                  color: Color(0xFFDCEDC8),
                ),

                const SizedBox(width: 6),

                Text(
                  role,
                  style: const TextStyle(
                    color: Color(0xFFDCEDC8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // VOLUNTEER NUMBER
          // ------------------------------------------------------

          if (_volunteerNumber.trim().isNotEmpty) ...[
            const SizedBox(height: 14),

            Text(
              'Volunteer No. ${_volunteerNumber.trim()}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================

  Widget _buildProfileAvatar() {
    final initials = _profileInitials();

    return Container(
      width: 94,
      height: 94,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFDCEDC8),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Color(0xFF1B5E20),
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE INITIALS
  // ============================================================

  String _profileInitials() {
    final first = _firstName.trim();
    final last = _lastName.trim();

    // ----------------------------------------------------------
    // First name + last name
    // Example:
    // Khayalethu Ngema -> KN
    // ----------------------------------------------------------

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }

    // ----------------------------------------------------------
    // Only first name
    // Example:
    // Khayalethu -> KH
    // ----------------------------------------------------------

    if (first.isNotEmpty) {
      if (first.length >= 2) {
        return first.substring(0, 2).toUpperCase();
      }

      return first.toUpperCase();
    }

    // ----------------------------------------------------------
    // Only last name
    // Example:
    // Ngema -> NG
    // ----------------------------------------------------------

    if (last.isNotEmpty) {
      if (last.length >= 2) {
        return last.substring(0, 2).toUpperCase();
      }

      return last.toUpperCase();
    }

    // ----------------------------------------------------------
    // Username fallback
    // ----------------------------------------------------------

    final username = _userName.trim();

    if (username.isNotEmpty) {
      if (username.length >= 2) {
        return username.substring(0, 2).toUpperCase();
      }

      return username.toUpperCase();
    }

    // ----------------------------------------------------------
    // Final fallback
    // ----------------------------------------------------------

    return 'V';
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 3,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF8BC34A),
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          const SizedBox(width: 8),

          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFD5E7D6),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Color(0x08000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEDC8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 22,
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
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
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
  // SECURITY CARD
  // ============================================================

  Widget _buildSecurityCard() {
    return Container(
      margin: const EdgeInsets.only(
        top: 4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5E7D6),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEDC8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF2E7D32),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Your SwiftCare account information is securely stored on this device.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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

  // ============================================================
  // FULL NAME
  // ============================================================

  String _fullName() {
    final first = _firstName.trim();
    final last = _lastName.trim();

    if (first.isNotEmpty && last.isNotEmpty) {
      return '$first $last';
    }

    if (first.isNotEmpty) {
      return first;
    }

    if (last.isNotEmpty) {
      return last;
    }

    if (_userName.trim().isNotEmpty) {
      return _userName.trim();
    }

    return '';
  }

  // ============================================================
  // DISPLAY VALUE
  // ============================================================

  String _displayValue(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Not available';
    }

    return trimmed;
  }

  // ============================================================
  // ROLE FORMAT
  // ============================================================

  String _formatRole(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    final words = trimmed
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ');

    return words
        .where(
          (word) => word.isNotEmpty,
        )
        .map(
          (word) =>
              '${word[0].toUpperCase()}'
              '${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}