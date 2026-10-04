import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_storage.dart';

class VolunteerSchedulePage extends StatefulWidget {
  const VolunteerSchedulePage({super.key});

  @override
  State<VolunteerSchedulePage> createState() =>
      _VolunteerSchedulePageState();
}

class _VolunteerSchedulePageState
    extends State<VolunteerSchedulePage> {
  static const String _apiBaseUrl =
      'https://swiftcareapi20261002021942-bxfgbwbsf4agendr.centralindia-01.azurewebsites.net';

  static const Color forestGreen = Color(0xFF1B5E20);
  static const Color darkGreen = Color(0xFF124116);
  static const Color green = Color(0xFF2E7D32);
  static const Color lime = Color(0xFF8BC34A);
  static const Color lightGreen = Color(0xFFDCEDC8);
  static const Color veryLightGreen = Color(0xFFF0FDF4);
  static const Color borderGreen = Color(0xFFD5E7D6);

  bool _isLoading = true;
  String? _errorMessage;

  DateTime _displayedMonth =
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      );

  List<ScheduleDay> _days = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  // ============================================================
  // LOAD SCHEDULE
  // ============================================================

  Future<void> _loadSchedule() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Your session has expired. Please log in again.';
        });

        return;
      }

      final year = _displayedMonth.year;
      final month = _displayedMonth.month;

      final uri = Uri.parse(
        '$_apiBaseUrl/api/VolunteerSchedule/month'
        '?year=$year&month=$month',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage =
              'Your session has expired. Please log in again.';
        });

        return;
      }

      if (response.statusCode != 200) {
        String message =
            'Unable to load your schedule. Please try again.';

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            message =
                decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                message;
          }
        } catch (_) {}

        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });

        return;
      }

      final decoded = jsonDecode(response.body);

      final List<dynamic> dayJson =
          decoded is Map<String, dynamic> &&
                  decoded['days'] is List
              ? decoded['days'] as List<dynamic>
              : [];

      final loadedDays =
          dayJson
              .whereType<Map<String, dynamic>>()
              .map(ScheduleDay.fromJson)
              .toList();

      loadedDays.sort(
        (a, b) => a.date.compareTo(b.date),
      );

      if (!mounted) return;

      setState(() {
        _days = loadedDays;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not connect to SwiftCare. Please check your connection and try again.';
      });
    }
  }

  // ============================================================
  // MONTH NAVIGATION
  // ============================================================

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });

    _loadSchedule();
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });

    _loadSchedule();
  }

  void _goToToday() {
    final now = DateTime.now();

    setState(() {
      _displayedMonth = DateTime(
        now.year,
        now.month,
        1,
      );
    });

    _loadSchedule();
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  ScheduleDay? _getDay(DateTime date) {
    for (final day in _days) {
      if (_sameDate(day.date, date)) {
        return day;
      }
    }

    return null;
  }

  bool _sameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isToday(DateTime date) {
    return _sameDate(
      date,
      DateTime.now(),
    );
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  int get _workingDays {
    return _days
        .where(
          (day) =>
              day.status.toLowerCase() ==
              'working',
        )
        .length;
  }

  int get _offDays {
    return _days
        .where(
          (day) =>
              day.status.toLowerCase() ==
              'off',
        )
        .length;
  }

  int get _totalTasks {
    return _days.fold<int>(
      0,
      (total, day) =>
          total + day.tasks.length,
    );
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  String _monthName(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[date.month - 1];
  }

  String _weekdayName(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdays[date.weekday - 1];
  }

  String _shortMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[date.month - 1];
  }

  String _formatFullDate(DateTime date) {
    return '${_weekdayName(date)}, '
        '${date.day} ${_shortMonth(date)} ${date.year}';
  }

  String _formatTime(String value) {
    if (value.isEmpty) {
      return '';
    }

    try {
      final parts = value.split(':');

      if (parts.length < 2) {
        return value;
      }

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final period = hour >= 12 ? 'PM' : 'AM';

      final displayHour =
          hour % 12 == 0
              ? 12
              : hour % 12;

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return value;
    }
  }

  String _formatShiftTime(
    ScheduleShift shift,
  ) {
    final start = _formatTime(
      shift.startTime,
    );

    final end = _formatTime(
      shift.endTime,
    );

    if (start.isEmpty && end.isEmpty) {
      return 'Shift scheduled';
    }

    if (end.isEmpty) {
      return start;
    }

    return '$start – $end';
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'working':
        return green;

      case 'off':
        return Colors.red.shade600;

      case 'noschedule':
      case 'no schedule':
      default:
        return Colors.grey.shade500;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'working':
        return 'Working';

      case 'off':
        return 'Day Off';

      case 'noschedule':
      case 'no schedule':
        return 'No Schedule';

      default:
        return status.isEmpty
            ? 'No Schedule'
            : status;
    }
  }

  // ============================================================
  // CALENDAR DAYS
  // ============================================================

  List<DateTime?> _buildCalendarDays() {
    final firstDay = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;

    // Monday = 1 ... Sunday = 7.
    final leadingEmptyDays =
        firstDay.weekday - 1;

    final List<DateTime?> calendarDays =
        [];

    for (
      int i = 0;
      i < leadingEmptyDays;
      i++
    ) {
      calendarDays.add(null);
    }

    for (
      int day = 1;
      day <= daysInMonth;
      day++
    ) {
      calendarDays.add(
        DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          day,
        ),
      );
    }

    while (
      calendarDays.length % 7 != 0
    ) {
      calendarDays.add(null);
    }

    return calendarDays;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FBF7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: forestGreen,
        foregroundColor: Colors.white,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(
              Icons.calendar_month,
              size: 25,
            ),
            SizedBox(width: 10),
            Text(
              'My Schedule',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: forestGreen,
        onRefresh: _loadSchedule,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 350,
            child: Center(
              child: CircularProgressIndicator(
                color: forestGreen,
              ),
            ),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 90),
          Container(
            padding:
                const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(24),
              border: Border.all(
                color: borderGreen,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.05),
                  blurRadius: 18,
                  offset:
                      const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    color:
                        Colors.red.shade600,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Unable to Load Schedule',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color:
                        Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed:
                      _loadSchedule,
                  icon:
                      const Icon(
                    Icons.refresh,
                  ),
                  label:
                      const Text(
                    'Try Again',
                  ),
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        forestGreen,
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        32,
      ),
      children: [
        _buildMonthHeader(),
        const SizedBox(height: 16),
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildCalendarCard(),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  // ============================================================
  // MONTH HEADER
  // ============================================================

  Widget _buildMonthHeader() {
    final now = DateTime.now();

    final isCurrentMonth =
        _displayedMonth.year ==
                now.year &&
            _displayedMonth.month ==
                now.month;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color: borderGreen,
        ),
        boxShadow: [
          BoxShadow(
            color: forestGreen
                .withOpacity(0.07),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          _monthNavigationButton(
            icon: Icons.chevron_left,
            onPressed:
                _previousMonth,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Text(
                  _monthName(
                    _displayedMonth,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 21,
                    fontWeight:
                        FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
                Text(
                  '${_displayedMonth.year}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _monthNavigationButton(
            icon: Icons.chevron_right,
            onPressed:
                _nextMonth,
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 200,
            ),
            child: TextButton(
              onPressed:
                  isCurrentMonth
                      ? null
                      : _goToToday,
              style:
                  TextButton.styleFrom(
                foregroundColor:
                    forestGreen,
                backgroundColor:
                    isCurrentMonth
                        ? Colors.grey.shade100
                        : lightGreen,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(12),
                ),
              ),
              child:
                  const Text(
                'Today',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: veryLightGreen,
      borderRadius:
          BorderRadius.circular(13),
      child: InkWell(
        onTap: onPressed,
        borderRadius:
            BorderRadius.circular(13),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: borderGreen,
            ),
          ),
          child: Icon(
            icon,
            color: forestGreen,
            size: 25,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard() {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            forestGreen,
            darkGreen,
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: forestGreen
                .withOpacity(0.20),
            blurRadius: 20,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons
                    .event_available_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 9),
              Text(
                'Monthly Overview',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child:
                    _buildSummaryItem(
                  icon: Icons
                      .work_outline_rounded,
                  value:
                      _workingDays
                          .toString(),
                  label:
                      'Working Days',
                ),
              ),
              Container(
                height: 44,
                width: 1,
                color: Colors.white
                    .withOpacity(0.18),
              ),
              Expanded(
                child:
                    _buildSummaryItem(
                  icon: Icons
                      .free_breakfast_outlined,
                  value:
                      _offDays
                          .toString(),
                  label: 'Days Off',
                ),
              ),
              Container(
                height: 44,
                width: 1,
                color: Colors.white
                    .withOpacity(0.18),
              ),
              Expanded(
                child:
                    _buildSummaryItem(
                  icon: Icons
                      .task_alt_rounded,
                  value:
                      _totalTasks
                          .toString(),
                  label: 'Tasks',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color:
              Colors.white.withOpacity(
            0.85,
          ),
          size: 20,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        Text(
          label,
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                Colors.white.withOpacity(
              0.72,
            ),
            fontSize: 10.5,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CALENDAR CARD
  // ============================================================

  Widget _buildCalendarCard() {
    final calendarDays =
        _buildCalendarDays();

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        10,
        16,
        10,
        14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: borderGreen,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.045),
            blurRadius: 18,
            offset:
                const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWeekdayHeader(),
          const SizedBox(height: 9),
          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),
            itemCount:
                calendarDays.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,

              // =================================================
              // IMPORTANT:
              // Explicit height prevents RenderFlex overflow.
              // =================================================
              mainAxisExtent: 92,
            ),
            itemBuilder:
                (context, index) {
              final date =
                  calendarDays[index];

              if (date == null) {
                return const SizedBox
                    .shrink();
              }

              final day =
                  _getDay(date);

              return _buildCalendarDayCell(
                date,
                day,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WEEKDAY HEADER
  // ============================================================

  Widget _buildWeekdayHeader() {
    const weekdays = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return Row(
      children: List.generate(
        weekdays.length,
        (index) {
          final isWeekend =
              index >= 5;

          return Expanded(
            child: Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 7,
              ),
              margin:
                  const EdgeInsets
                      .symmetric(
                horizontal: 2,
              ),
              decoration:
                  BoxDecoration(
                color: isWeekend
                    ? const Color(
                        0xFFFFF4F4,
                      )
                    : veryLightGreen,
                borderRadius:
                    BorderRadius
                        .circular(9),
              ),
              child: Text(
                weekdays[index],
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing: 0.3,
                  color: isWeekend
                      ? Colors.red.shade500
                      : forestGreen,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CALENDAR DAY CELL
  // ============================================================
  //
  // Uses Stack instead of Column.
  //
  // This prevents:
  //
  // RenderFlex overflowed by XX pixels on the bottom
  //
  // because the children are positioned inside the fixed
  // calendar cell instead of competing for vertical Flex space.
  //
  // ============================================================

  Widget _buildCalendarDayCell(
    DateTime date,
    ScheduleDay? day,
  ) {
    final weekend =
        _isWeekend(date);

    final today =
        _isToday(date);

    final status =
        day?.status.isNotEmpty == true
            ? day!.status
            : 'NoSchedule';

    final statusColor =
        _statusColor(status);

    final hasShift =
        day?.shift != null;

    final taskCount =
        day?.tasks.length ?? 0;

    final isOff =
        status.toLowerCase() ==
        'off';

    final statusLower =
        status.toLowerCase();

    Color backgroundColor;

    if (today) {
      backgroundColor =
          const Color(0xFFE8F5E9);
    } else if (weekend && isOff) {
      backgroundColor =
          const Color(0xFFFFF2F2);
    } else if (weekend) {
      backgroundColor =
          const Color(0xFFFFF8F8);
    } else if (statusLower ==
        'working') {
      backgroundColor =
          const Color(0xFFF3FAF3);
    } else {
      backgroundColor =
          const Color(0xFFFAFCFA);
    }

    Color borderColor;

    if (today) {
      borderColor = forestGreen;
    } else if (weekend) {
      borderColor =
          const Color(0xFFF1D4D4);
    } else {
      borderColor =
          const Color(0xFFE4ECE4);
    }

    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(13),
      child: InkWell(
        onTap: () {
          _showDayDetails(
            date,
            day,
          );
        },
        borderRadius:
            BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: borderColor,
              width:
                  today ? 1.7 : 1,
            ),
          ),
          child: Stack(
            children: [
              // ==================================================
              // DATE NUMBER
              // ==================================================

              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment:
                      Alignment.center,
                  decoration: today
                      ? const BoxDecoration(
                          color:
                              forestGreen,
                          shape:
                              BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          FontWeight.w900,
                      color: today
                          ? Colors.white
                          : weekend
                              ? Colors
                                  .red
                                  .shade600
                              : darkGreen,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // WEEKEND MARKER
              // ==================================================

              if (weekend)
                Positioned(
                  top: 5,
                  right: 4,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 3,
                      vertical: 2,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.shade50,
                      borderRadius:
                          BorderRadius
                              .circular(5),
                    ),
                    child: Text(
                      'WK',
                      style: TextStyle(
                        fontSize: 6,
                        fontWeight:
                            FontWeight.w900,
                        color: Colors
                            .red
                            .shade500,
                      ),
                    ),
                  ),
                ),

              // ==================================================
              // STATUS DOT
              // ==================================================

              Positioned(
                top: 36,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(
                      color:
                          statusColor,
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // SHIFT / OFF / WEEKEND
              // ==================================================

              Positioned(
                left: 3,
                right: 3,
                top: 47,
                child: Center(
                  child:
                      _buildCalendarStatusText(
                    date: date,
                    day: day,
                    hasShift:
                        hasShift,
                    isOff: isOff,
                    weekend:
                        weekend,
                  ),
                ),
              ),

              // ==================================================
              // TASK COUNT
              // ==================================================

              if (taskCount > 0)
                Positioned(
                  left: 3,
                  right: 3,
                  bottom: 5,
                  child: Center(
                    child: Container(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 52,
                      ),
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color: lime,
                        borderRadius:
                            BorderRadius
                                .circular(7),
                      ),
                      child: Text(
                        '$taskCount task${taskCount == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 6.5,
                          fontWeight:
                              FontWeight
                                  .w900,
                          color:
                              darkGreen,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR STATUS TEXT
  // ============================================================

  Widget _buildCalendarStatusText({
    required DateTime date,
    required ScheduleDay? day,
    required bool hasShift,
    required bool isOff,
    required bool weekend,
  }) {
    if (hasShift &&
        day?.shift != null) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 2,
          vertical: 3,
        ),
        decoration:
            BoxDecoration(
          color:
              green.withOpacity(0.10),
          borderRadius:
              BorderRadius.circular(6),
        ),
        child: Text(
          _formatTime(
            day!.shift!.startTime,
          ),
          textAlign:
              TextAlign.center,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style:
              const TextStyle(
            fontSize: 8,
            fontWeight:
                FontWeight.w800,
            color: forestGreen,
          ),
        ),
      );
    }

    if (isOff) {
      return Text(
        'OFF',
        maxLines: 1,
        overflow:
            TextOverflow.clip,
        style: TextStyle(
          fontSize: 7.5,
          fontWeight:
              FontWeight.w900,
          color:
              Colors.red.shade500,
        ),
      );
    }

    if (weekend) {
      return Text(
        'WEEKEND',
        maxLines: 1,
        overflow:
            TextOverflow.clip,
        style: TextStyle(
          fontSize: 6,
          fontWeight:
              FontWeight.w900,
          color:
              Colors.red.shade300,
        ),
      );
    }

    return Text(
      '—',
      style: TextStyle(
        fontSize: 9,
        fontWeight:
            FontWeight.w700,
        color:
            Colors.grey.shade400,
      ),
    );
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegend() {
    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: borderGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendar Guide',
            style: TextStyle(
              color: darkGreen,
              fontSize: 15,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              _legendItem(
                color: green,
                label: 'Working',
              ),
              _legendItem(
                color:
                    Colors.red.shade600,
                label: 'Day Off',
              ),
              _legendItem(
                color:
                    Colors.grey.shade500,
                label: 'No Schedule',
              ),
              _legendWeekendItem(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Icon(
                Icons
                    .touch_app_outlined,
                size: 17,
                color:
                    Colors.grey.shade500,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Tap any date to view its shift and assigned tasks.',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration:
              BoxDecoration(
            color: color,
            shape:
                BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w600,
            color:
                Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _legendWeekendItem() {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFFFF4F4,
            ),
            borderRadius:
                BorderRadius.circular(5),
            border: Border.all(
              color:
                  const Color(
                0xFFF1D4D4,
              ),
            ),
          ),
          child: Icon(
            Icons
                .weekend_outlined,
            size: 11,
            color:
                Colors.red.shade500,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Weekend',
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                FontWeight.w600,
            color:
                Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DAY DETAILS
  // ============================================================

  void _showDayDetails(
    DateTime date,
    ScheduleDay? day,
  ) {
    final weekend =
        _isWeekend(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints:
                const BoxConstraints(
              maxHeight: 650,
            ),
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                20,
                12,
                20,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey
                                .shade300,
                        borderRadius:
                            BorderRadius
                                .circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color: weekend
                              ? Colors.red
                                  .shade50
                              : veryLightGreen,
                          borderRadius:
                              BorderRadius
                                  .circular(16),
                        ),
                        child: Icon(
                          weekend
                              ? Icons
                                  .weekend_outlined
                              : Icons
                                  .calendar_today_rounded,
                          color: weekend
                              ? Colors.red
                                  .shade500
                              : forestGreen,
                          size: 25,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              _formatFullDate(
                                date,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight
                                        .w900,
                                color:
                                    darkGreen,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        _statusColor(
                                      day?.status ??
                                          'NoSchedule',
                                    ),
                                    shape:
                                        BoxShape
                                            .circle,
                                  ),
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Flexible(
                                  child: Text(
                                    _statusLabel(
                                      day?.status ??
                                          'NoSchedule',
                                    ),
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey.shade700,
                                      fontSize:
                                          12,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ),
                                if (weekend) ...[
                                  const SizedBox(
                                    width: 9,
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal:
                                          8,
                                      vertical:
                                          4,
                                    ),
                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .red
                                          .shade50,
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        8,
                                      ),
                                    ),
                                    child: Text(
                                      'WEEKEND',
                                      style:
                                          TextStyle(
                                        color: Colors
                                            .red
                                            .shade600,
                                        fontSize:
                                            8,
                                        fontWeight:
                                            FontWeight
                                                .w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 22,
                  ),
                  if (day?.shift != null)
                    _buildBottomSheetShift(
                      day!.shift!,
                    )
                  else
                    _buildNoShiftCard(
                      weekend:
                          weekend,
                    ),
                  const SizedBox(
                    height: 18,
                  ),
                  _buildTasksSection(
                    day?.tasks ?? [],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM SHEET SHIFT
  // ============================================================

  Widget _buildBottomSheetShift(
    ScheduleShift shift,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: veryLightGreen,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: borderGreen,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                      BorderRadius
                          .circular(12),
                ),
                child: const Icon(
                  Icons
                      .access_time_rounded,
                  color: forestGreen,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              const Expanded(
                child: Text(
                  'Scheduled Shift',
                  style:
                      TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
              ),
              _smallStatusBadge(
                shift.status,
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              const Icon(
                Icons
                    .schedule_rounded,
                size: 18,
                color: forestGreen,
              ),
              const SizedBox(
                width: 8,
              ),
              Flexible(
                child: Text(
                  _formatShiftTime(
                    shift,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w900,
                    color: forestGreen,
                  ),
                ),
              ),
            ],
          ),
          if (shift.notes != null &&
              shift.notes!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(
                12,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(12),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Icon(
                    Icons.notes_rounded,
                    size: 17,
                    color: Colors
                        .grey.shade600,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      shift.notes!,
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // NO SHIFT CARD
  // ============================================================

  Widget _buildNoShiftCard({
    required bool weekend,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: weekend
            ? const Color(0xFFFFF8F8)
            : Colors.grey.shade50,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: weekend
              ? const Color(
                  0xFFF1D4D4,
                )
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color: weekend
                  ? Colors.red.shade50
                  : Colors.grey.shade100,
              borderRadius:
                  BorderRadius
                      .circular(12),
            ),
            child: Icon(
              weekend
                  ? Icons
                      .weekend_outlined
                  : Icons
                      .event_busy_outlined,
              color: weekend
                  ? Colors.red.shade500
                  : Colors.grey.shade500,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  weekend
                      ? 'Weekend'
                      : 'No Shift Scheduled',
                  style:
                      const TextStyle(
                    color: darkGreen,
                    fontWeight:
                        FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  weekend
                      ? 'No shift information has been scheduled for this weekend.'
                      : 'There is no shift assigned to you on this date.',
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 11.5,
                    height: 1.35,
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
  // STATUS BADGE
  // ============================================================

  Widget _smallStatusBadge(
    String status,
  ) {
    Color color;

    switch (status.toLowerCase()) {
      case 'completed':
        color = green;
        break;

      case 'cancelled':
        color =
            Colors.red.shade600;
        break;

      case 'dayoff':
      case 'day off':
        color =
            Colors.red.shade500;
        break;

      default:
        color = forestGreen;
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color:
            color.withOpacity(0.10),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Text(
        status.isEmpty
            ? 'Scheduled'
            : status,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // TASKS SECTION
  // ============================================================

  Widget _buildTasksSection(
    List<ScheduleTask> tasks,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.task_alt_rounded,
              color: forestGreen,
              size: 21,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              'Tasks (${tasks.length})',
              style:
                  const TextStyle(
                color: darkGreen,
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(
              17,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.grey.shade50,
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color:
                    Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons
                      .task_alt_outlined,
                  color:
                      Colors.grey.shade500,
                  size: 22,
                ),
                const SizedBox(
                  width: 11,
                ),
                Expanded(
                  child: Text(
                    'No tasks assigned for this day.',
                    style: TextStyle(
                      color: Colors
                          .grey
                          .shade600,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map(
            (task) =>
                _buildTaskCard(task),
          ),
      ],
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _buildTaskCard(
    ScheduleTask task,
  ) {
    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: borderGreen,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.035),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                      BorderRadius
                          .circular(12),
                ),
                child: Icon(
                  _taskIcon(task),
                  color: forestGreen,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow:
                          TextOverflow
                              .ellipsis,
                      style:
                          const TextStyle(
                        color: darkGreen,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    if (task.area
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        task.area,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize: 11,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(
                width: 5,
              ),
              _priorityBadge(
                task.priority,
              ),
            ],
          ),
          if (task.description !=
                  null &&
              task.description!
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(
              height: 12,
            ),
            Text(
              task.description!,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    Colors.grey.shade700,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(
            height: 12,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            children: [
              if (task.startTime
                  .isNotEmpty)
                _taskInfoChip(
                  Icons
                      .access_time_rounded,
                  _formatTime(
                    task.startTime,
                  ),
                ),
              if (task.endTime
                  .isNotEmpty)
                _taskInfoChip(
                  Icons
                      .arrow_forward_rounded,
                  _formatTime(
                    task.endTime,
                  ),
                ),
              if (task.location !=
                      null &&
                  task.location!
                      .trim()
                      .isNotEmpty)
                _taskInfoChip(
                  Icons
                      .location_on_outlined,
                  task.location!,
                ),
              if (task.status
                  .isNotEmpty)
                _taskInfoChip(
                  Icons.flag_outlined,
                  task.status,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TASK INFO CHIP
  // ============================================================

  Widget _taskInfoChip(
    IconData icon,
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
          BoxDecoration(
        color: veryLightGreen,
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: forestGreen,
          ),
          const SizedBox(
            width: 5,
          ),
          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 130,
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: forestGreen,
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIORITY BADGE
  // ============================================================

  Widget _priorityBadge(
    String priority,
  ) {
    if (priority.isEmpty) {
      return const SizedBox.shrink();
    }

    Color color;

    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        color =
            Colors.red.shade600;
        break;

      case 'low':
        color =
            Colors.blueGrey.shade500;
        break;

      default:
        color = forestGreen;
        break;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            color.withOpacity(0.09),
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  // ============================================================
  // TASK ICON
  // ============================================================

  IconData _taskIcon(
    ScheduleTask task,
  ) {
    final value =
        '${task.title} ${task.area}'
            .toLowerCase();

    if (value.contains('resident')) {
      return Icons.elderly_rounded;
    }

    if (value.contains('clean')) {
      return Icons
          .cleaning_services_outlined;
    }

    if (value.contains('food') ||
        value.contains('meal') ||
        value.contains('kitchen')) {
      return Icons
          .restaurant_outlined;
    }

    if (value.contains('garden')) {
      return Icons.yard_outlined;
    }

    if (value.contains('activity')) {
      return Icons.groups_outlined;
    }

    if (value.contains('medic')) {
      return Icons
          .medical_services_outlined;
    }

    return Icons.task_alt_rounded;
  }
}

// ============================================================
// MODELS
// ============================================================

class ScheduleDay {
  final DateTime date;
  final String status;
  final ScheduleShift? shift;
  final List<ScheduleTask> tasks;

  ScheduleDay({
    required this.date,
    required this.status,
    this.shift,
    required this.tasks,
  });

  factory ScheduleDay.fromJson(
    Map<String, dynamic> json,
  ) {
    DateTime parsedDate;

    try {
      parsedDate = DateTime.parse(
        json['date']?.toString() ?? '',
      );
    } catch (_) {
      parsedDate = DateTime.now();
    }

    ScheduleShift? parsedShift;

    final shiftJson =
        json['shift'];

    if (shiftJson
        is Map<String, dynamic>) {
      parsedShift =
          ScheduleShift.fromJson(
        shiftJson,
      );
    }

    final List<ScheduleTask>
        parsedTasks = [];

    final tasksJson =
        json['tasks'];

    if (tasksJson is List) {
      for (final item in tasksJson) {
        if (item
            is Map<String, dynamic>) {
          parsedTasks.add(
            ScheduleTask.fromJson(
              item,
            ),
          );
        }
      }
    }

    return ScheduleDay(
      date: parsedDate,
      status:
          json['status']
              ?.toString() ??
          'NoSchedule',
      shift: parsedShift,
      tasks: parsedTasks,
    );
  }
}

// ============================================================
// SHIFT MODEL
// ============================================================

class ScheduleShift {
  final int shiftId;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;

  ScheduleShift({
    required this.shiftId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
  });

  factory ScheduleShift.fromJson(
    Map<String, dynamic> json,
  ) {
    DateTime parsedDate;

    try {
      parsedDate = DateTime.parse(
        json['date']?.toString() ?? '',
      );
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return ScheduleShift(
      shiftId:
          int.tryParse(
            json['shiftId']
                    ?.toString() ??
                '',
          ) ??
          0,
      date: parsedDate,
      startTime:
          json['startTime']
                  ?.toString() ??
              '',
      endTime:
          json['endTime']
                  ?.toString() ??
              '',
      status:
          json['status']
                  ?.toString() ??
              '',
      notes:
          json['notes']?.toString(),
    );
  }
}

// ============================================================
// TASK MODEL
// ============================================================

class ScheduleTask {
  final int taskId;
  final String title;
  final String? description;
  final String area;
  final String? location;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String priority;

  ScheduleTask({
    required this.taskId,
    required this.title,
    this.description,
    required this.area,
    this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.priority,
  });

  factory ScheduleTask.fromJson(
    Map<String, dynamic> json,
  ) {
    return ScheduleTask(
      taskId:
          int.tryParse(
            json['taskId']
                    ?.toString() ??
                '',
          ) ??
          0,
      title:
          json['title']
                  ?.toString() ??
              '',
      description:
          json['description']
              ?.toString(),
      area:
          json['area']
                  ?.toString() ??
              '',
      location:
          json['location']
              ?.toString(),
      date:
          json['date']
                  ?.toString() ??
              '',
      startTime:
          json['startTime']
                  ?.toString() ??
              '',
      endTime:
          json['endTime']
                  ?.toString() ??
              '',
      status:
          json['status']
                  ?.toString() ??
              '',
      priority:
          json['priority']
                  ?.toString() ??
              '',
    );
  }
}