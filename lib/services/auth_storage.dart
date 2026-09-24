import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  // ============================================================
  // KEYS
  // ============================================================

  static const String tokenKey = 'swiftcare_jwt';

  static const String volunteerIdKey = 'volunteer_id';
  static const String volunteerNumberKey = 'volunteer_number';
  static const String firstNameKey = 'volunteer_first_name';
  static const String lastNameKey = 'volunteer_last_name';
  static const String emailKey = 'volunteer_email';
  static const String userNameKey = 'volunteer_username';
  static const String roleKey = 'volunteer_role';
  static const String onboardingIdKey = 'volunteer_onboarding_id';

  // ============================================================
  // ATTENDANCE KEYS
  // ============================================================

  static const String attendanceCheckedInKey =
      'attendance_checked_in';

  static const String attendanceAlreadyCheckedInKey =
      'attendance_already_checked_in';

  static const String attendanceStatusKey =
      'attendance_status';

  static const String attendanceMessageKey =
      'attendance_message';

  static const String attendanceIdKey =
      'attendance_id';

  static const String volunteerRosterShiftIdKey =
      'volunteer_roster_shift_id';

  static const String attendanceCheckInTimeKey =
      'attendance_check_in_time';

  static const String attendanceLateMinutesKey =
      'attendance_late_minutes';

  // ============================================================
  // SAVE LOGIN
  // ============================================================

  static Future<void> saveLogin({
    required String token,
    String? volunteerId,
    String? volunteerNumber,
    String? firstName,
    String? lastName,
    String? email,
    String? userName,
    String? role,
    String? onboardingId,
  }) async {
    await _storage.write(
      key: tokenKey,
      value: token,
    );

    if (volunteerId != null) {
      await _storage.write(
        key: volunteerIdKey,
        value: volunteerId,
      );
    }

    if (volunteerNumber != null) {
      await _storage.write(
        key: volunteerNumberKey,
        value: volunteerNumber,
      );
    }

    if (firstName != null) {
      await _storage.write(
        key: firstNameKey,
        value: firstName,
      );
    }

    if (lastName != null) {
      await _storage.write(
        key: lastNameKey,
        value: lastName,
      );
    }

    if (email != null) {
      await _storage.write(
        key: emailKey,
        value: email,
      );
    }

    if (userName != null) {
      await _storage.write(
        key: userNameKey,
        value: userName,
      );
    }

    if (role != null) {
      await _storage.write(
        key: roleKey,
        value: role,
      );
    }

    if (onboardingId != null) {
      await _storage.write(
        key: onboardingIdKey,
        value: onboardingId,
      );
    }
  }

  // ============================================================
  // SAVE ATTENDANCE
  // ============================================================

  static Future<void> saveAttendance({
    bool checkedIn = false,
    bool alreadyCheckedIn = false,
    String? status,
    String? message,
    int? attendanceId,
    int? volunteerRosterShiftId,
    String? checkInTime,
    int? lateMinutes,
  }) async {
    // ------------------------------------------------------------
    // Checked in
    // ------------------------------------------------------------

    await _storage.write(
      key: attendanceCheckedInKey,
      value: checkedIn.toString(),
    );

    // ------------------------------------------------------------
    // Already checked in
    // ------------------------------------------------------------

    await _storage.write(
      key: attendanceAlreadyCheckedInKey,
      value: alreadyCheckedIn.toString(),
    );

    // ------------------------------------------------------------
    // Status
    // ------------------------------------------------------------

    if (status != null) {
      await _storage.write(
        key: attendanceStatusKey,
        value: status,
      );
    } else {
      await _storage.delete(
        key: attendanceStatusKey,
      );
    }

    // ------------------------------------------------------------
    // Message
    // ------------------------------------------------------------

    if (message != null) {
      await _storage.write(
        key: attendanceMessageKey,
        value: message,
      );
    } else {
      await _storage.delete(
        key: attendanceMessageKey,
      );
    }

    // ------------------------------------------------------------
    // Attendance ID
    // ------------------------------------------------------------

    if (attendanceId != null) {
      await _storage.write(
        key: attendanceIdKey,
        value: attendanceId.toString(),
      );
    } else {
      await _storage.delete(
        key: attendanceIdKey,
      );
    }

    // ------------------------------------------------------------
    // Volunteer Roster Shift ID
    // ------------------------------------------------------------

    if (volunteerRosterShiftId != null) {
      await _storage.write(
        key: volunteerRosterShiftIdKey,
        value: volunteerRosterShiftId.toString(),
      );
    } else {
      await _storage.delete(
        key: volunteerRosterShiftIdKey,
      );
    }

    // ------------------------------------------------------------
    // Check-in time
    // ------------------------------------------------------------

    if (checkInTime != null) {
      await _storage.write(
        key: attendanceCheckInTimeKey,
        value: checkInTime,
      );
    } else {
      await _storage.delete(
        key: attendanceCheckInTimeKey,
      );
    }

    // ------------------------------------------------------------
    // Late minutes
    // ------------------------------------------------------------

    await _storage.write(
      key: attendanceLateMinutesKey,
      value: (lateMinutes ?? 0).toString(),
    );
  }

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<String?> getToken() async {
    return await _storage.read(
      key: tokenKey,
    );
  }

  // ============================================================
  // VOLUNTEER DETAILS
  // ============================================================

  static Future<String?> getVolunteerId() async {
    return await _storage.read(
      key: volunteerIdKey,
    );
  }

  static Future<String?> getVolunteerNumber() async {
    return await _storage.read(
      key: volunteerNumberKey,
    );
  }

  static Future<String?> getFirstName() async {
    return await _storage.read(
      key: firstNameKey,
    );
  }

  static Future<String?> getLastName() async {
    return await _storage.read(
      key: lastNameKey,
    );
  }

  static Future<String?> getEmail() async {
    return await _storage.read(
      key: emailKey,
    );
  }

  static Future<String?> getUserName() async {
    return await _storage.read(
      key: userNameKey,
    );
  }

  static Future<String?> getRole() async {
    return await _storage.read(
      key: roleKey,
    );
  }

  static Future<String?> getOnboardingId() async {
    return await _storage.read(
      key: onboardingIdKey,
    );
  }

  // ============================================================
  // ATTENDANCE GETTERS
  // ============================================================

  static Future<bool> getAttendanceCheckedIn() async {
    final value = await _storage.read(
      key: attendanceCheckedInKey,
    );

    return value == 'true';
  }

  static Future<bool> getAttendanceAlreadyCheckedIn() async {
    final value = await _storage.read(
      key: attendanceAlreadyCheckedInKey,
    );

    return value == 'true';
  }

  static Future<String?> getAttendanceStatus() async {
    return await _storage.read(
      key: attendanceStatusKey,
    );
  }

  static Future<String?> getAttendanceMessage() async {
    return await _storage.read(
      key: attendanceMessageKey,
    );
  }

  static Future<int?> getAttendanceId() async {
    final value = await _storage.read(
      key: attendanceIdKey,
    );

    if (value == null || value.isEmpty) {
      return null;
    }

    return int.tryParse(value);
  }

  static Future<int?> getVolunteerRosterShiftId() async {
    final value = await _storage.read(
      key: volunteerRosterShiftIdKey,
    );

    if (value == null || value.isEmpty) {
      return null;
    }

    return int.tryParse(value);
  }

  static Future<String?> getAttendanceCheckInTime() async {
    return await _storage.read(
      key: attendanceCheckInTimeKey,
    );
  }

  static Future<int> getAttendanceLateMinutes() async {
    final value = await _storage.read(
      key: attendanceLateMinutesKey,
    );

    if (value == null || value.isEmpty) {
      return 0;
    }

    return int.tryParse(value) ?? 0;
  }

  // ============================================================
  // CLEAR ATTENDANCE
  // ============================================================

  static Future<void> clearAttendance() async {
    await _storage.delete(
      key: attendanceCheckedInKey,
    );

    await _storage.delete(
      key: attendanceAlreadyCheckedInKey,
    );

    await _storage.delete(
      key: attendanceStatusKey,
    );

    await _storage.delete(
      key: attendanceMessageKey,
    );

    await _storage.delete(
      key: attendanceIdKey,
    );

    await _storage.delete(
      key: volunteerRosterShiftIdKey,
    );

    await _storage.delete(
      key: attendanceCheckInTimeKey,
    );

    await _storage.delete(
      key: attendanceLateMinutesKey,
    );
  }

  // ============================================================
  // LOGGED IN?
  // ============================================================

  static Future<bool> isLoggedIn() async {
    final token = await getToken();

    return token != null && token.isNotEmpty;
  }

  // ============================================================
  // CLEAR LOGIN
  // ============================================================

  static Future<void> clearLogin() async {
    await _storage.deleteAll();
  }
}