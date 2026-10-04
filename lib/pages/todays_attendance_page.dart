import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:swiftcare_volunteer_app/services/auth_storage.dart';

class TodaysAttendancePage extends StatefulWidget {
  const TodaysAttendancePage({
    super.key,
  });

  @override
  State<TodaysAttendancePage> createState() =>
      _TodaysAttendancePageState();
}

class _TodaysAttendancePageState
    extends State<TodaysAttendancePage> {
  // ============================================================
  // API
  // ============================================================

  static const String _baseUrl =
      'https://swiftcareapi20261002021942-bxfgbwbsf4agendr.centralindia-01.azurewebsites.net';

  // ============================================================
  // ATTENDANCE
  // ============================================================

  bool _attendanceCheckedIn = false;
  bool _attendanceAlreadyCheckedIn = false;

  String _attendanceStatus =
      'Not Checked In';

  int? _attendanceId;
  int? _volunteerRosterShiftId;

  int _lateMinutes = 0;
  int _earlyDepartureMinutes = 0;

  String? _checkInTime;
  String? _checkOutTime;

  bool _loading = true;
  bool _checkingOut = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadAttendance();
  }

  // ============================================================
  // LOAD ATTENDANCE
  // ============================================================

  Future<void> _loadAttendance() async {
    try {
      final checkedIn =
          await AuthStorage
              .getAttendanceCheckedIn();

      final alreadyCheckedIn =
          await AuthStorage
              .getAttendanceAlreadyCheckedIn();

      final status =
          await AuthStorage
              .getAttendanceStatus();

      final attendanceId =
          await AuthStorage
              .getAttendanceId();

      final rosterShiftId =
          await AuthStorage
              .getVolunteerRosterShiftId();

      final checkInTime =
          await AuthStorage
              .getAttendanceCheckInTime();

      final lateMinutes =
          await AuthStorage
              .getAttendanceLateMinutes();

      if (!mounted) {
        return;
      }

      setState(() {
        _attendanceCheckedIn =
            checkedIn;

        _attendanceAlreadyCheckedIn =
            alreadyCheckedIn;

        _attendanceStatus =
            status?.trim().isNotEmpty == true
                ? status!.trim()
                : 'Not Checked In';

        _attendanceId =
            attendanceId;

        _volunteerRosterShiftId =
            rosterShiftId;

        _checkInTime =
            checkInTime;

        _lateMinutes =
            lateMinutes;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });
    }
  }

  // ============================================================
  // CHECK OUT
  // ============================================================

  Future<void> _checkOut() async {
    // ============================================================
    // VALIDATE ATTENDANCE
    // ============================================================

    if (_attendanceId == null ||
        _attendanceId! <= 0) {
      _showMessage(
        'No attendance record was found.',
        isError: true,
      );

      return;
    }

    // ============================================================
    // PREVENT DOUBLE CLICK
    // ============================================================

    if (_checkingOut) {
      return;
    }

    // ============================================================
    // CONFIRM CHECK OUT
    // ============================================================

    final shouldCheckOut =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text(
                'Check Out',
              ),

              content: const Text(
                'Are you sure you want to check out of your shift?',
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false);
                  },
                  child: const Text(
                    'Cancel',
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
                      0xFF1B5E20,
                    ),
                    foregroundColor:
                        Colors.white,
                  ),
                  child: const Text(
                    'Check Out',
                  ),
                ),
              ],
            );
          },
        );

    if (shouldCheckOut != true) {
      return;
    }

    // ============================================================
    // START CHECKOUT
    // ============================================================

    setState(() {
      _checkingOut = true;
    });

    try {
      // ==========================================================
      // GET JWT TOKEN
      // ==========================================================

      final token =
          await AuthStorage.getToken();

      if (token == null ||
          token.trim().isEmpty) {
        _showMessage(
          'Your session has expired. Please log in again.',
          isError: true,
        );

        return;
      }

      // ==========================================================
      // API REQUEST
      // ==========================================================

      final response =
          await http.post(
        Uri.parse(
          '$_baseUrl/api/Attendance/check-out',
        ),
        headers: {
          'Content-Type':
              'application/json',

          'Authorization':
              'Bearer ${token.trim()}',
        },
        body: jsonEncode({
          'attendanceId':
              _attendanceId,
        }),
      );

      // ==========================================================
      // PARSE RESPONSE
      // ==========================================================

      Map<String, dynamic>? data;

      if (response.body
          .trim()
          .isNotEmpty) {
        try {
          data =
              jsonDecode(
                response.body,
              )
              as Map<String, dynamic>;
        } catch (_) {
          data = null;
        }
      }

      // ==========================================================
      // SUCCESS
      // ==========================================================

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data != null) {
        final attendance =
            data['attendance']
                as Map<String, dynamic>?;

        final checkedOut =
            data['checkedOut'] == true;

        final alreadyCheckedOut =
            data['alreadyCheckedOut'] == true;

        if (checkedOut ||
            alreadyCheckedOut) {
          final checkOutTime =
              attendance?['checkOutTime']
                  ?.toString();

          final earlyDepartureMinutes =
              attendance?[
                    'earlyDepartureMinutes']
                  as int? ??
              0;

          if (!mounted) {
            return;
          }

          setState(() {
            _attendanceCheckedIn =
                false;

            _attendanceAlreadyCheckedIn =
                false;

            _attendanceStatus =
                'CheckedOut';

            _checkOutTime =
                checkOutTime;

            _earlyDepartureMinutes =
                earlyDepartureMinutes;

            _checkingOut = false;
          });

          _showMessage(
            alreadyCheckedOut
                ? 'You have already checked out.'
                : data['message']?.toString() ??
                    'You have been successfully checked out.',
          );

          return;
        }
      }

      // ==========================================================
      // API ERROR
      // ==========================================================

      final message =
          data?['message']?.toString() ??
          'Unable to check out. Please try again.';

      if (!mounted) {
        return;
      }

      _showMessage(
        message,
        isError: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to connect to the attendance service.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingOut = false;
        });
      }
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refreshAttendance() async {
    setState(() {
      _loading = true;
    });

    await _loadAttendance();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          backgroundColor:
              isError
                  ? Colors.red.shade700
                  : const Color(
                      0xFF2E7D32,
                    ),
          behavior:
              SnackBarBehavior.floating,
        ),
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

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1B5E20),
        foregroundColor:
            Colors.white,
        elevation: 0,

        title: const Text(
          'Today\'s Attendance',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed:
                _refreshAttendance,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(
                color:
                    Color(0xFF2E7D32),
              ),
            )
          : RefreshIndicator(
              color:
                  const Color(
                0xFF2E7D32,
              ),
              onRefresh:
                  _refreshAttendance,
              child:
                  SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  18,
                  16,
                  30,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(
                      height: 16,
                    ),

                    _buildStatusCard(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildAttendanceDetails(),

                    const SizedBox(
                      height: 14,
                    ),

                    _buildCheckoutButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFF1B5E20),
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset:
                Offset(0, 4),
            color:
                Color(0x16000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFDCEDC8),
              shape:
                  BoxShape.circle,
            ),
            child:
                const Icon(
              Icons
                  .calendar_today_outlined,
              color:
                  Color(0xFF1B5E20),
              size: 25,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Attendance',
                  style:
                      TextStyle(
                    color:
                        Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Your attendance record for today',
                  style:
                      TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 12,
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
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard() {
    final checkedIn =
        _attendanceCheckedIn ||
            _attendanceAlreadyCheckedIn;

    final status =
        _attendanceStatus
                .trim()
                .isNotEmpty
            ? _attendanceStatus
            : checkedIn
                ? 'Checked In'
                : 'Not Checked In';

    final normalized =
        status.toLowerCase();

    final isAbsent =
        normalized.contains(
      'absent',
    );

    final isLate =
        normalized.contains(
      'late',
    );

    final isCheckedOut =
        normalized.contains(
              'checked out',
            ) ||
            normalized.contains(
              'checkout',
            );

    Color background;
    Color foreground;
    IconData icon;

    if (isAbsent) {
      background =
          const Color(0xFFC62828);
      foreground =
          Colors.white;
      icon =
          Icons.person_off;
    } else if (isCheckedOut) {
      background =
          const Color(0xFF00897B);
      foreground =
          Colors.white;
      icon =
          Icons.logout;
    } else if (isLate) {
      background =
          const Color(0xFFF9A825);
      foreground =
          Colors.white;
      icon =
          Icons.schedule;
    } else if (checkedIn) {
      background =
          const Color(0xFF2E7D32);
      foreground =
          Colors.white;
      icon =
          Icons.check_circle;
    } else {
      background =
          const Color(0xFF607D66);
      foreground =
          Colors.white;
      icon =
          Icons.event_available;
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset:
                Offset(0, 3),
            color:
                Color(0x12000000),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration:
                BoxDecoration(
              color: background,
              shape:
                  BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 36,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Attendance Status',
            style: TextStyle(
              color:
                  Color(0xFF748675),
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 9,
            ),
            decoration:
                BoxDecoration(
              color: background,
              borderRadius:
                  BorderRadius.circular(
                999,
              ),
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: foreground,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  status,
                  style:
                      TextStyle(
                    color:
                        foreground,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
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
  // ATTENDANCE DETAILS
  // ============================================================

  Widget _buildAttendanceDetails() {
    final checkedIn =
        _attendanceCheckedIn ||
            _attendanceAlreadyCheckedIn;

    final checkedOut =
        _attendanceStatus
            .toLowerCase()
            .contains('checked');

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset:
                Offset(0, 3),
            color:
                Color(0x12000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Details',
            style: TextStyle(
              color:
                  Color(0xFF124116),
              fontSize: 16,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          _buildDetailRow(
            icon:
                Icons.login_outlined,
            label: 'Check In',
            value: checkedIn ||
                    checkedOut
                ? _formatCheckInTime(
                    _checkInTime,
                  )
                : 'Not checked in',
          ),

          const SizedBox(
            height: 10,
          ),

          _buildDetailRow(
            icon:
                Icons.schedule_outlined,
            label: 'Late',
            value:
                _lateMinutes > 0
                    ? '$_lateMinutes minutes'
                    : 'On time',
          ),

          if (_checkOutTime != null) ...[
            const SizedBox(
              height: 10,
            ),

            _buildDetailRow(
              icon:
                  Icons.logout_outlined,
              label: 'Check Out',
              value:
                  _formatCheckOutTime(
                _checkOutTime,
              ),
            ),
          ],

          if (_earlyDepartureMinutes > 0) ...[
            const SizedBox(
              height: 10,
            ),

            _buildDetailRow(
              icon:
                  Icons.warning_amber_rounded,
              label:
                  'Early Departure',
              value:
                  '$_earlyDepartureMinutes minutes',
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CHECKOUT BUTTON
  // ============================================================

  Widget _buildCheckoutButton() {
    final checkedOut =
        _attendanceStatus
                .toLowerCase()
                .contains(
                  'checked out',
                ) ||
            _attendanceStatus
                .toLowerCase()
                .contains(
                  'checkout',
                );

    final canCheckOut =
        (_attendanceCheckedIn ||
            _attendanceAlreadyCheckedIn) &&
        !checkedOut &&
        _attendanceId != null &&
        !_checkingOut;

    if (checkedOut) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          vertical: 15,
        ),
        decoration:
            BoxDecoration(
          color:
              const Color(0xFFE0F2F1),
          borderRadius:
              BorderRadius.circular(15),
          border: Border.all(
            color:
                const Color(0xFF80CBC4),
          ),
        ),
        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color:
                  Color(0xFF00897B),
            ),

            SizedBox(
              width: 8,
            ),

            Text(
              'Checked Out',
              style:
                  TextStyle(
                color:
                    Color(0xFF00695C),
                fontSize: 15,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (!canCheckOut) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed:
            _checkingOut
                ? null
                : _checkOut,
        icon: _checkingOut
            ? const SizedBox(
                width: 19,
                height: 19,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.logout,
              ),
        label: Text(
          _checkingOut
              ? 'Checking Out...'
              : 'Check Out',
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF1B5E20),
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              const Color(0xFF81A985),
          disabledForegroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              15,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 13,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF6FAF7),
        borderRadius:
            BorderRadius.circular(13),
        border: Border.all(
          color:
              const Color(0xFFE1EDE3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration:
                const BoxDecoration(
              color:
                  Color(0xFFDCEDC8),
              shape:
                  BoxShape.circle,
            ),
            child:
                Icon(
              icon,
              color:
                  const Color(
                0xFF2E7D32,
              ),
              size: 19,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF748675),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Color(0xFF124116),
                    fontSize: 13,
                    fontWeight:
                        FontWeight.bold,
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
  // FORMAT CHECK-IN TIME
  // ============================================================

  String _formatCheckInTime(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Checked in';
    }

    try {
      final parsed =
          DateTime.parse(value);

      final local =
          parsed.toLocal();

      final hour =
          local.hour
              .toString()
              .padLeft(2, '0');

      final minute =
          local.minute
              .toString()
              .padLeft(2, '0');

      return '$hour:$minute';
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // FORMAT CHECK-OUT TIME
  // ============================================================

  String _formatCheckOutTime(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Checked out';
    }

    try {
      final parsed =
          DateTime.parse(value);

      final local =
          parsed.toLocal();

      final hour =
          local.hour
              .toString()
              .padLeft(2, '0');

      final minute =
          local.minute
              .toString()
              .padLeft(2, '0');

      return '$hour:$minute';
    } catch (_) {
      return value;
    }
  }
}