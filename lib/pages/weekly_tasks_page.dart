import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:swiftcare_volunteer_app/services/auth_storage.dart';

class WeeklyTasksPage extends StatefulWidget {
  const WeeklyTasksPage({super.key});

  @override
  State<WeeklyTasksPage> createState() => _WeeklyTasksPageState();
}

class _WeeklyTasksPageState extends State<WeeklyTasksPage> {
  // ============================================================
  // API
  // ============================================================

  static const String _apiBaseUrl =
      'https://flop-enjoyment-unexposed.ngrok-free.dev';

  bool _isLoading = true;
  String? _errorMessage;

  String _startDate = '';
  String _endDate = '';

  List<WeeklyDay> _days = [];

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _forestGreen = Color(0xFF1B5E20);
  static const Color _mainGreen = Color(0xFF2E7D32);
  static const Color _limeGreen = Color(0xFF8BC34A);
  static const Color _lightGreen = Color(0xFFDCEDC8);
  static const Color _softGreen = Color(0xFFF0FDF4);
  static const Color _borderGreen = Color(0xFFD5E7D6);

  // Soft red / grey for day off
  static const Color _dayOffRed = Color(0xFFB85C5C);
  static const Color _dayOffSoftRed = Color(0xFFFFF3F3);
  static const Color _dayOffLightRed = Color(0xFFFDE2E2);
  static const Color _dayOffBorder = Color(0xFFE8B7B7);

  // Past days
  static const Color _pastBackground = Color(0xFFF5F5F5);
  static const Color _pastBorder = Color(0xFFE2E2E2);
  static const Color _pastIconBackground = Color(0xFFEAEAEA);
  static const Color _pastText = Color(0xFF8A8A8A);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadWeeklyTasks();
  }

  // ============================================================
  // LOAD WEEKLY TASKS
  // ============================================================

  Future<void> _loadWeeklyTasks() async {
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

      final response = await http.get(
        Uri.parse(
          '$_apiBaseUrl/api/VolunteerSchedule/week',
        ),
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
        throw Exception(
          'Server returned ${response.statusCode}.',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid weekly schedule response.',
        );
      }

      final dynamic daysJson = decoded['days'];

      final List<WeeklyDay> loadedDays = [];

      if (daysJson is List) {
        for (final dynamic day in daysJson) {
          if (day is! Map<String, dynamic>) {
            continue;
          }

          loadedDays.add(
            WeeklyDay.fromJson(day),
          );
        }
      }

      // ----------------------------------------------------------
      // SORT DAYS CHRONOLOGICALLY
      // ----------------------------------------------------------

      loadedDays.sort(
        (a, b) => a.date.compareTo(b.date),
      );

      if (!mounted) return;

      setState(() {
        _startDate =
            decoded['startDate']?.toString() ?? '';

        _endDate =
            decoded['endDate']?.toString() ?? '';

        _days = loadedDays;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load your weekly schedule.';
      });
    }
  }

  // ============================================================
  // TOTAL TASKS
  // ============================================================

  int get _totalTasks {
    return _days.fold(
      0,
      (total, day) => total + day.tasks.length,
    );
  }

  // ============================================================
  // TOTAL DAYS OFF
  // ============================================================

  int get _totalDaysOff {
    return _days.where(
      (day) => day.isDayOff,
    ).length;
  }

  // ============================================================
  // TODAY
  // ============================================================

  DateTime _todayOnly() {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  DateTime? _parseDateOnly(String value) {
    try {
      final date = DateTime.parse(value);

      return DateTime(
        date.year,
        date.month,
        date.day,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isToday(WeeklyDay day) {
    final date = _parseDateOnly(day.date);

    if (date == null) {
      return false;
    }

    return date == _todayOnly();
  }

  bool _isPast(WeeklyDay day) {
    final date = _parseDateOnly(day.date);

    if (date == null) {
      return false;
    }

    return date.isBefore(_todayOnly());
  }

  bool _isUpcoming(WeeklyDay day) {
    final date = _parseDateOnly(day.date);

    if (date == null) {
      return false;
    }

    return date.isAfter(_todayOnly());
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _mainGreen,
      onRefresh: _loadWeeklyTasks,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildWeeklySummary(),

          const SizedBox(height: 18),

          const Text(
            'This Week',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _forestGreen,
            ),
          ),

          const SizedBox(height: 10),

          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_days.isEmpty)
            _buildEmptyState()
          else
            ..._days.map(
              (day) => _buildDayCard(day),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // WEEKLY SUMMARY
  // ============================================================

  Widget _buildWeeklySummary() {
    String summaryText;

    if (_isLoading) {
      summaryText = 'Loading schedule...';
    } else {
      final taskText =
          '$_totalTasks '
          '${_totalTasks == 1 ? 'task' : 'tasks'}';

      final dayOffText =
          '$_totalDaysOff '
          '${_totalDaysOff == 1 ? 'day off' : 'days off'}';

      summaryText =
          '$taskText • $dayOffText';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _mainGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month,
            color: Colors.white,
            size: 38,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Schedule',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  summaryText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (!_isLoading &&
                    _startDate.isNotEmpty &&
                    _endDate.isNotEmpty) ...[
                  const SizedBox(height: 5),

                  Text(
                    '${_formatShortDate(_startDate)}'
                    ' - '
                    '${_formatShortDate(_endDate)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAY CARD
  // ============================================================

  Widget _buildDayCard(WeeklyDay day) {
    final bool isDayOff = day.isDayOff;
    final bool hasTasks = day.tasks.isNotEmpty;
    final bool isToday = _isToday(day);
    final bool isPast = _isPast(day);
    final bool isUpcoming = _isUpcoming(day);

    // ----------------------------------------------------------
    // DAY OFF
    // ----------------------------------------------------------

    if (isDayOff) {
      return _buildDayOffCard(
        day,
        isToday: isToday,
        isPast: isPast,
        isUpcoming: isUpcoming,
      );
    }

    // ----------------------------------------------------------
    // PAST DAY
    // ----------------------------------------------------------

    if (isPast) {
      return _buildPastDayCard(day);
    }

    // ----------------------------------------------------------
    // NORMAL / UPCOMING / TODAY
    // ----------------------------------------------------------

    return GestureDetector(
      onTap: hasTasks
          ? () => _showDayTasks(day)
          : null,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: isToday
              ? _softGreen
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isToday
                ? _limeGreen
                : _borderGreen,
            width: isToday ? 2 : 1,
          ),
          boxShadow: isToday
              ? const [
                  BoxShadow(
                    blurRadius: 8,
                    offset: Offset(0, 2),
                    color: Color(0x12000000),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // --------------------------------------------------
            // ICON
            // --------------------------------------------------

            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasTasks
                    ? _lightGreen
                    : Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                hasTasks
                    ? Icons.event_available
                    : Icons.event_busy,
                color: hasTasks
                    ? _mainGreen
                    : Colors.grey,
              ),
            ),

            const SizedBox(width: 14),

            // --------------------------------------------------
            // DAY INFORMATION
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getDayName(day.date),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? _mainGreen
                              : _forestGreen,
                        ),
                      ),

                      if (isToday) ...[
                        const SizedBox(width: 7),
                        _buildTodayBadge(),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _formatShortDate(day.date),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  if (day.shift != null) ...[
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            _formatTimeRange(
                              day.shift!.startTime,
                              day.shift!.endTime,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // --------------------------------------------------
            // TASK COUNT
            // --------------------------------------------------

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '${day.tasks.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: hasTasks
                        ? _mainGreen
                        : Colors.grey,
                  ),
                ),

                Text(
                  day.tasks.length == 1
                      ? 'task'
                      : 'tasks',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasTasks
                        ? _mainGreen
                        : Colors.grey,
                  ),
                ),
              ],
            ),

            if (hasTasks) ...[
              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right,
                color: _limeGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAST DAY CARD
  // ============================================================

  Widget _buildPastDayCard(WeeklyDay day) {
    final bool hasTasks = day.tasks.isNotEmpty;

    return GestureDetector(
      onTap: hasTasks
          ? () => _showDayTasks(day)
          : null,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: _pastBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pastBorder,
          ),
        ),
        child: Row(
          children: [
            // --------------------------------------------------
            // PAST ICON
            // --------------------------------------------------

            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _pastIconBackground,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                hasTasks
                    ? Icons.event_available
                    : Icons.event_busy,
                color: _pastText,
              ),
            ),

            const SizedBox(width: 14),

            // --------------------------------------------------
            // DAY INFORMATION
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDayName(day.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _pastText,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    _formatShortDate(day.date),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),

                  if (day.shift != null) ...[
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 4),

                        Flexible(
                          child: Text(
                            _formatTimeRange(
                              day.shift!.startTime,
                              day.shift!.endTime,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 5),

                  const Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 13,
                        color: Colors.grey,
                      ),

                      SizedBox(width: 4),

                      Text(
                        'Past',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // TASK COUNT
            // --------------------------------------------------

            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '${day.tasks.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _pastText,
                  ),
                ),

                Text(
                  day.tasks.length == 1
                      ? 'task'
                      : 'tasks',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _pastText,
                  ),
                ),
              ],
            ),

            if (hasTasks) ...[
              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TODAY BADGE
  // ============================================================

  Widget _buildTodayBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _mainGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'TODAY',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ============================================================
  // DAY OFF CARD
  // ============================================================

  Widget _buildDayOffCard(
    WeeklyDay day, {
    required bool isToday,
    required bool isPast,
    required bool isUpcoming,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _dayOffSoftRed,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday
              ? _dayOffRed
              : _dayOffBorder,
          width: isToday ? 2 : 1.3,
        ),
        boxShadow: isToday
            ? const [
                BoxShadow(
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  color: Color(0x12000000),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // DAY OFF ICON
          // ----------------------------------------------------

          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _dayOffLightRed,
              borderRadius:
                  BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.event_busy_outlined,
              color: _dayOffRed,
              size: 29,
            ),
          ),

          const SizedBox(width: 14),

          // ----------------------------------------------------
          // DAY OFF INFORMATION
          // ----------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------
                // DAY + TODAY + DAY OFF
                // ----------------------------------------------

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        crossAxisAlignment:
                            WrapCrossAlignment.center,
                        children: [
                          Text(
                            _getDayName(day.date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                              color: isToday
                                  ? _dayOffRed
                                  : const Color(
                                      0xFF6F4A4A,
                                    ),
                            ),
                          ),

                          if (isToday)
                            _buildTodayBadgeForDayOff(),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    _buildDayOffBadge(),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  _formatShortDate(day.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 9),

                // ----------------------------------------------
                // DAY OFF MESSAGE
                // ----------------------------------------------

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(11),
                    border: Border.all(
                      color: _dayOffBorder,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 16,
                        color: _dayOffRed,
                      ),

                      SizedBox(width: 7),

                      Expanded(
                        child: Text(
                          'No volunteer tasks scheduled',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w600,
                            color: _dayOffRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ----------------------------------------------
                // DAY OFF NOTES
                // ----------------------------------------------

                if (day.shift != null &&
                    day.shift!.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: _dayOffBorder,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notes_outlined,
                          size: 15,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 7),

                        Expanded(
                          child: Text(
                            day.shift!.notes,
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAY OFF BADGE
  // ============================================================

  Widget _buildDayOffBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _dayOffLightRed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _dayOffBorder,
        ),
      ),
      child: const Text(
        'DAY OFF',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _dayOffRed,
        ),
      ),
    );
  }

  // ============================================================
  // TODAY BADGE FOR DAY OFF
  // ============================================================

  Widget _buildTodayBadgeForDayOff() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _dayOffRed,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'TODAY',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderGreen,
        ),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: _mainGreen,
            ),
          ),

          SizedBox(height: 14),

          Text(
            'Loading your weekly schedule...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderGreen,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 42,
            color: Colors.grey,
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage ??
                'Unable to load your schedule.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _forestGreen,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed: _loadWeeklyTasks,
            icon: const Icon(
              Icons.refresh,
              color: _mainGreen,
            ),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color: _mainGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderGreen,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: _limeGreen,
          ),

          SizedBox(height: 14),

          Text(
            'No schedule this week',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: _forestGreen,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'You currently have no tasks or days off scheduled for this week.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAY TASKS
  // ============================================================

  void _showDayTasks(WeeklyDay day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _borderGreen,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  _getDayName(day.date),
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _forestGreen,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatShortDate(day.date),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.builder(
                    itemCount: day.tasks.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final task =
                          day.tasks[index];

                      return _buildTaskItem(task);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TASK ITEM
  // ============================================================

  Widget _buildTaskItem(WeeklyTask task) {
    return GestureDetector(
      onTap: () => _showTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _softGreen,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _borderGreen,
          ),
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: Icon(
                _getTaskIcon(task.area),
                color: _mainGreen,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _forestGreen,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          _formatTimeRange(
                            task.startTime,
                            task.endTime,
                          ),
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (task.location.isNotEmpty) ...[
                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            task.location,
                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            _buildStatusBadge(task.status),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TASK DETAILS
  // ============================================================

  void _showTaskDetails(WeeklyTask task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            30,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _borderGreen,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _lightGreen,
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                      child: Icon(
                        _getTaskIcon(task.area),
                        color: _mainGreen,
                        size: 27,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _forestGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _buildDetailRow(
                  Icons.access_time,
                  _formatTimeRange(
                    task.startTime,
                    task.endTime,
                  ),
                ),

                if (task.location.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    task.location,
                  ),
                ],

                if (task.area.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.category_outlined,
                    task.area,
                  ),
                ],

                if (task.priority.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(
                    Icons.flag_outlined,
                    'Priority: ${task.priority}',
                  ),
                ],

                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  const Text(
                    'Task Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _forestGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: _mainGreen,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(
    IconData icon,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 0),

        Icon(
          icon,
          size: 18,
          color: _mainGreen,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatusBadge(String status) {
    if (status.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: _mainGreen,
        ),
      ),
    );
  }

  // ============================================================
  // TASK ICON
  // ============================================================

  IconData _getTaskIcon(String area) {
    final value = area.toLowerCase();

    if (value.contains('food') ||
        value.contains('kitchen') ||
        value.contains('dining')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('resident') ||
        value.contains('care')) {
      return Icons.volunteer_activism_outlined;
    }

    if (value.contains('activity') ||
        value.contains('recreation')) {
      return Icons.groups_outlined;
    }

    if (value.contains('clean')) {
      return Icons.cleaning_services_outlined;
    }

    if (value.contains('admin') ||
        value.contains('office')) {
      return Icons.business_center_outlined;
    }

    if (value.contains('garden')) {
      return Icons.local_florist_outlined;
    }

    return Icons.task_alt_outlined;
  }

  // ============================================================
  // DAY NAME
  // ============================================================

  String _getDayName(String value) {
    try {
      final date = DateTime.parse(value);

      const days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      return days[date.weekday - 1];
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // SHORT DATE
  // ============================================================

  String _formatShortDate(String value) {
    if (value.isEmpty) {
      return 'Date not specified';
    }

    try {
      final date = DateTime.parse(value);

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

      return '${date.day} ${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTimeRange(
    String start,
    String end,
  ) {
    if (start.isEmpty && end.isEmpty) {
      return 'Time not specified';
    }

    final formattedStart = _formatTime(start);
    final formattedEnd = _formatTime(end);

    if (formattedStart.isEmpty) {
      return formattedEnd;
    }

    if (formattedEnd.isEmpty) {
      return formattedStart;
    }

    return '$formattedStart - $formattedEnd';
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

      final hour =
          int.tryParse(parts[0]) ?? 0;

      final minute =
          int.tryParse(parts[1]) ?? 0;

      final period =
          hour >= 12 ? 'PM' : 'AM';

      final displayHour =
          hour % 12 == 0
              ? 12
              : hour % 12;

      return '${displayHour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // STATUS FORMAT
  // ============================================================

  String _formatStatus(String status) {
    if (status.isEmpty) {
      return '';
    }

    final words = status
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

// ================================================================
// WEEKLY DAY MODEL
// ================================================================

class WeeklyDay {
  final String date;
  final WeeklyShift? shift;
  final List<WeeklyTask> tasks;

  const WeeklyDay({
    required this.date,
    required this.shift,
    required this.tasks,
  });

  // ============================================================
  // DAY OFF CHECK
  // ============================================================

  bool get isDayOff {
    if (shift == null) {
      return false;
    }

    final status = shift!.status
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    return status == 'dayoff';
  }

  factory WeeklyDay.fromJson(
    Map<String, dynamic> json,
  ) {
    WeeklyShift? shift;

    final dynamic shiftJson =
        json['shift'];

    if (shiftJson
        is Map<String, dynamic>) {
      shift = WeeklyShift.fromJson(
        shiftJson,
      );
    }

    final List<WeeklyTask> tasks = [];

    final dynamic tasksJson =
        json['tasks'];

    if (tasksJson is List) {
      for (final dynamic task
          in tasksJson) {
        if (task
            is Map<String, dynamic>) {
          tasks.add(
            WeeklyTask.fromJson(
              task,
            ),
          );
        }
      }
    }

    return WeeklyDay(
      date:
          json['date']?.toString() ?? '',
      shift: shift,
      tasks: tasks,
    );
  }
}

// ================================================================
// WEEKLY SHIFT MODEL
// ================================================================

class WeeklyShift {
  final int shiftId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String notes;

  const WeeklyShift({
    required this.shiftId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.notes,
  });

  factory WeeklyShift.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeeklyShift(
      shiftId:
          _parseInt(json['shiftId']),
      date:
          json['date']?.toString() ?? '',
      startTime:
          json['startTime']?.toString() ?? '',
      endTime:
          json['endTime']?.toString() ?? '',
      status:
          json['status']?.toString() ?? '',
      notes:
          json['notes']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

// ================================================================
// WEEKLY TASK MODEL
// ================================================================

class WeeklyTask {
  final int taskId;
  final String title;
  final String description;
  final String area;
  final String location;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String priority;

  const WeeklyTask({
    required this.taskId,
    required this.title,
    required this.description,
    required this.area,
    required this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.priority,
  });

  factory WeeklyTask.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeeklyTask(
      taskId:
          _parseInt(json['taskId']),
      title:
          json['title']?.toString() ??
          'Untitled Task',
      description:
          json['description']?.toString() ??
          '',
      area:
          json['area']?.toString() ?? '',
      location:
          json['location']?.toString() ?? '',
      date:
          json['date']?.toString() ?? '',
      startTime:
          json['startTime']?.toString() ?? '',
      endTime:
          json['endTime']?.toString() ?? '',
      status:
          json['status']?.toString() ?? '',
      priority:
          json['priority']?.toString() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}