
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:swiftcare_volunteer_app/services/auth_storage.dart';

class UpcomingTasksPage extends StatefulWidget {
  const UpcomingTasksPage({super.key});

  @override
  State<UpcomingTasksPage> createState() => _UpcomingTasksPageState();
}

class _UpcomingTasksPageState extends State<UpcomingTasksPage> {
  // ============================================================
  // API
  // ============================================================

  static const String _apiBaseUrl =
      'https://swiftcareapi20261008091404-a5c8ade5cfaahea4.spaincentral-01.azurewebsites.net';

  bool _isLoading = true;
  String? _errorMessage;

  String _weekStartDate = '';
  String _weekEndDate = '';

  List<UpcomingDay> _days = [];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadUpcomingTasks();
  }

  // ============================================================
  // LOAD UPCOMING WEEK
  // ============================================================

  Future<void> _loadUpcomingTasks() async {
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
          '$_apiBaseUrl/api/VolunteerSchedule/upcoming-week',
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
          'Invalid schedule response from server.',
        );
      }

      // ==========================================================
      // WEEK RANGE
      // ==========================================================

      final String weekStart =
          decoded['startDate']?.toString() ?? '';

      final String weekEnd =
          decoded['endDate']?.toString() ?? '';

      // ==========================================================
      // DAYS
      // ==========================================================

      final List<UpcomingDay> loadedDays = [];

      final dynamic days = decoded['days'];

      if (days is List) {
        for (final dynamic day in days) {
          if (day is! Map<String, dynamic>) {
            continue;
          }

          loadedDays.add(
            UpcomingDay.fromJson(day),
          );
        }
      }

      // Sort days chronologically.
      loadedDays.sort(
        (a, b) => a.date.compareTo(b.date),
      );

      if (!mounted) return;

      setState(() {
        _weekStartDate = weekStart;
        _weekEndDate = weekEnd;
        _days = loadedDays;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to load your upcoming week.';
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: _loadUpcomingTasks,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildHeader(),

          const SizedBox(height: 18),

          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else
            _buildUpcomingWeek(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 3),
            color: Color(0x10000000),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.upcoming_outlined,
            size: 38,
            color: Color(0xFF2E7D32),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Week',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Plan ahead for your tasks',
                  style: TextStyle(
                    color: Color(0xFF1B5E20),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
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
  // UPCOMING WEEK
  // ============================================================

  Widget _buildUpcomingWeek() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Week',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),

        const SizedBox(height: 8),

        // ========================================================
        // WEEK DATE RANGE
        // ========================================================

        if (_weekStartDate.isNotEmpty ||
            _weekEndDate.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFD5E7D6),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_outlined,
                  color: Color(0xFF2E7D32),
                  size: 21,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upcoming week',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        _formatWeekRange(
                          _weekStartDate,
                          _weekEndDate,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        if (_days.isEmpty)
          _buildEmptyState()
        else
          ..._days.map(
            (day) => _buildDaySection(day),
          ),
      ],
    );
  }

  // ============================================================
  // DAY SECTION
  // ============================================================

  Widget _buildDaySection(UpcomingDay day) {
    final DateTime? date = _parseDate(day.date);

    final String dayName = date != null
        ? _dayName(date)
        : 'Scheduled Day';

    final String fullDate = date != null
        ? _formatFullDate(date)
        : _formatDate(day.date);

    final bool isToday =
        date != null &&
        _isSameDate(
          date,
          DateTime.now(),
        );

    final bool isDayOff = day.isDayOff;

    // ------------------------------------------------------------
    // DAY OFF COLOURS
    // ------------------------------------------------------------

    const Color dayOffBackground =
        Color(0xFFFEF2F2);

    const Color dayOffBorder =
        Color(0xFFFECACA);

    const Color dayOffIconBackground =
        Color(0xFFFEE2E2);

    const Color dayOffRed =
        Color(0xFFB91C1C);

    // ------------------------------------------------------------
    // NORMAL UPCOMING COLOURS
    // ------------------------------------------------------------

    const Color normalBackground =
        Colors.white;

    const Color normalBorder =
        Color(0xFFD5E7D6);

    const Color todayBorder =
        Color(0xFF8BC34A);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDayOff
            ? dayOffBackground
            : normalBackground,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: isDayOff
              ? dayOffBorder
              : isToday
                  ? todayBorder
                  : normalBorder,
          width: isDayOff || isToday
              ? 1.5
              : 1,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Color(0x08000000),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // DAY HEADER
          // ======================================================

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDayOff
                  ? const Color(0xFFFFF7F7)
                  : const Color(0xFFF0FDF4),
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                // ------------------------------------------------
                // DATE BOX
                // ------------------------------------------------

                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDayOff
                        ? dayOffIconBackground
                        : const Color(0xFFDCEDC8),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(
                        date != null
                            ? date.day.toString()
                            : '--',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                          color: isDayOff
                              ? dayOffRed
                              : const Color(
                                  0xFF1B5E20,
                                ),
                        ),
                      ),

                      if (date != null)
                        Text(
                          _shortMonth(date),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w700,
                            color: isDayOff
                                ? dayOffRed
                                : const Color(
                                    0xFF2E7D32,
                                  ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 13),

                // ------------------------------------------------
                // DAY NAME + FULL DATE
                // ------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.bold,
                                color: isDayOff
                                    ? dayOffRed
                                    : const Color(
                                        0xFF1B5E20,
                                      ),
                              ),
                            ),
                          ),

                          if (isToday &&
                              !isDayOff) ...[
                            const SizedBox(width: 7),

                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFF8BC34A,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  10,
                                ),
                              ),
                              child:
                                  const Text(
                                'TODAY',
                                style:
                                    TextStyle(
                                  fontSize: 8,
                                  fontWeight:
                                      FontWeight.bold,
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        fullDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // ------------------------------------------------
                // DAY OFF BADGE
                // ------------------------------------------------

                if (isDayOff)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          dayOffIconBackground,
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: dayOffBorder,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .event_busy_outlined,
                          size: 13,
                          color: dayOffRed,
                        ),

                        SizedBox(width: 4),

                        Text(
                          'DAY OFF',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight:
                                FontWeight.bold,
                            color: dayOffRed,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // ------------------------------------------------
                  // TASK COUNT
                  // ------------------------------------------------
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFFDCEDC8),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      '${day.tasks.length} '
                      '${day.tasks.length == 1 ? 'Task' : 'Tasks'}',
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF2E7D32),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ======================================================
          // DAY OFF
          // ======================================================

          if (isDayOff)
            _buildDayOff(day)

          // ======================================================
          // NORMAL SHIFT
          // ======================================================

          else if (day.shift != null)
            _buildShift(day.shift!),

          // ======================================================
          // TASKS
          // ======================================================

          if (!isDayOff && day.tasks.isEmpty)
            _buildNoTasksForDay()
          else if (!isDayOff &&
              day.tasks.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                12,
                12,
                4,
              ),
              child: Column(
                children: day.tasks
                    .map(
                      (task) =>
                          _buildUpcomingTask(
                        task,
                      ),
                    )
                    .toList(),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ============================================================
  // DAY OFF
  // ============================================================

  Widget _buildDayOff(
    UpcomingDay day,
  ) {
    final String notes =
        day.shift?.notes.trim() ?? '';

    const Color dayOffBackground =
        Color(0xFFFEF2F2);

    const Color dayOffBorder =
        Color(0xFFFECACA);

    const Color dayOffIconBackground =
        Color(0xFFFEE2E2);

    const Color dayOffRed =
        Color(0xFFB91C1C);

    return Container(
      margin: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dayOffBackground,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: dayOffBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      dayOffIconBackground,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.free_breakfast_outlined,
                  color: dayOffRed,
                  size: 26,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day Off',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color: dayOffRed,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'You are not scheduled to work on this day.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dayOffRed,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Text(
                  'OFF',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // ------------------------------------------------------
          // DATE
          // ------------------------------------------------------

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(12),
              border: Border.all(
                color: dayOffBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: dayOffRed,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    _formatDate(day.date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color: dayOffRed,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ------------------------------------------------------
          // NOTES
          // ------------------------------------------------------

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: dayOffBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.notes_outlined,
                    size: 17,
                    color: dayOffRed,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.grey,
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
  // SHIFT
  // ============================================================

  Widget _buildShift(
    UpcomingShift shift,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFD5E7D6),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            size: 19,
            color: Color(0xFF2E7D32),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shift',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _formatTimeRange(
                    shift.startTime,
                    shift.endTime,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),

          if (shift.status.isNotEmpty)
            Text(
              _formatStatus(
                shift.status,
              ),
              style: const TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // NO TASKS FOR DAY
  // ============================================================

  Widget _buildNoTasksForDay() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        4,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 20,
            color: Colors.grey,
          ),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'No tasks scheduled for this day.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPCOMING TASK
  // ============================================================

  Widget _buildUpcomingTask(
    UpcomingTask task,
  ) {
    return GestureDetector(
      onTap: () => _showTaskDetails(task),
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD5E7D6),
          ),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFDCEDC8),
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _getTaskIcon(task.area),
                    color:
                        const Color(0xFF2E7D32),
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
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xFF1B5E20),
                        ),
                      ),

                      if (task.area.isNotEmpty) ...[
                        const SizedBox(height: 4),

                        Text(
                          task.area,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                _buildStatusBadge(
                  task.status,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ----------------------------------------------------
            // DATE
            // ----------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Colors.grey,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    _formatDate(task.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            // ----------------------------------------------------
            // TIME
            // ----------------------------------------------------

            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 15,
                  color: Colors.grey,
                ),

                const SizedBox(width: 7),

                Expanded(
                  child: Text(
                    _formatTimeRange(
                      task.startTime,
                      task.endTime,
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            // ----------------------------------------------------
            // LOCATION
            // ----------------------------------------------------

            if (task.location.isNotEmpty) ...[
              const SizedBox(height: 7),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Colors.grey,
                  ),

                  const SizedBox(width: 7),

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

            // ----------------------------------------------------
            // PRIORITY
            // ----------------------------------------------------

            if (task.priority.isNotEmpty) ...[
              const SizedBox(height: 9),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color:
                          Color(0xFF2E7D32),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      'Priority: ${task.priority}',
                      style:
                          const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    if (status.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEDC8),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
        ),
      ),
    );
  }

  // ============================================================
  // TASK DETAILS
  // ============================================================

  void _showTaskDetails(
    UpcomingTask task,
  ) {
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
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(26),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFD5E7D6,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFDCEDC8,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(15),
                        ),
                        child: Icon(
                          _getTaskIcon(
                            task.area,
                          ),
                          color:
                              const Color(
                            0xFF2E7D32,
                          ),
                          size: 27,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          task.title,
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(
                              0xFF1B5E20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildDetailRow(
                    Icons.calendar_today_outlined,
                    _formatDate(task.date),
                  ),

                  const SizedBox(height: 10),

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

                  if (task.status.isNotEmpty) ...[
                    const SizedBox(height: 10),

                    _buildDetailRow(
                      Icons.info_outline,
                      _formatStatus(
                        task.status,
                      ),
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
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF1B5E20),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      task.description,
                      style:
                          const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child:
                        ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(
                        context,
                      ),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            const Color(
                          0xFF2E7D32,
                        ),
                        foregroundColor:
                            Colors.white,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
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
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF2E7D32),
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
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Container(
      margin:
          const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5E7D6),
        ),
      ),
      child: const Column(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child:
                CircularProgressIndicator(
              strokeWidth: 3,
              color:
                  Color(0xFF2E7D32),
            ),
          ),

          SizedBox(height: 14),

          Text(
            'Loading your upcoming week...',
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
      margin:
          const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5E7D6),
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
              color: Color(0xFF1B5E20),
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            onPressed:
                _loadUpcomingTasks,
            icon: const Icon(
              Icons.refresh,
              color:
                  Color(0xFF2E7D32),
            ),
            label: const Text(
              'Try Again',
              style: TextStyle(
                color:
                    Color(0xFF2E7D32),
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
      margin:
          const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5E7D6),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 48,
            color: Color(0xFF8BC34A),
          ),

          SizedBox(height: 14),

          Text(
            'No upcoming schedule',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF1B5E20),
            ),
          ),

          SizedBox(height: 6),

          Text(
            'You currently have no tasks scheduled for the upcoming week.',
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
  // ICON
  // ============================================================

  IconData _getTaskIcon(
    String area,
  ) {
    final value =
        area.toLowerCase();

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
  // DATE HELPERS
  // ============================================================

  DateTime? _parseDate(
    String value,
  ) {
    if (value.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  String _formatWeekRange(
    String start,
    String end,
  ) {
    final DateTime? startDate =
        _parseDate(start);

    final DateTime? endDate =
        _parseDate(end);

    if (startDate == null &&
        endDate == null) {
      return 'Upcoming week';
    }

    if (startDate != null &&
        endDate != null) {
      return '${_formatShortDate(startDate)}'
          ' - '
          '${_formatShortDate(endDate)}';
    }

    if (startDate != null) {
      return 'From ${_formatShortDate(startDate)}';
    }

    return 'Until ${_formatShortDate(endDate!)}';
  }

  String _formatShortDate(
    DateTime date,
  ) {
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _formatFullDate(
    DateTime date,
  ) {
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  String _formatDate(
    String value,
  ) {
    if (value.isEmpty) {
      return 'Date not specified';
    }

    final DateTime? date =
        _parseDate(value);

    if (date == null) {
      return value;
    }

    return _formatFullDate(date);
  }

  String _dayName(
    DateTime date,
  ) {
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
  }

  String _shortMonth(
    DateTime date,
  ) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return months[date.month - 1];
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  String _formatTimeRange(
    String start,
    String end,
  ) {
    if (start.isEmpty && end.isEmpty) {
      return 'Time not specified';
    }

    final formattedStart =
        _formatTime(start);

    final formattedEnd =
        _formatTime(end);

    if (formattedStart.isEmpty) {
      return formattedEnd;
    }

    if (formattedEnd.isEmpty) {
      return formattedStart;
    }

    return '$formattedStart - $formattedEnd';
  }

  String _formatTime(
    String value,
  ) {
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
          '${minute.toString().padLeft(2, '0')} '
          '$period';
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // STATUS FORMAT
  // ============================================================

  String _formatStatus(
    String status,
  ) {
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

// ==================================================================
// UPCOMING DAY MODEL
// ==================================================================

class UpcomingDay {
  final String date;
  final UpcomingShift? shift;
  final List<UpcomingTask> tasks;

  const UpcomingDay({
    required this.date,
    required this.shift,
    required this.tasks,
  });

  // ============================================================
  // DAY OFF
  // ============================================================

  bool get isDayOff {
    if (shift == null) {
      return false;
    }

    final normalizedStatus =
        shift!.status
            .toLowerCase()
            .replaceAll(
              RegExp(r'[\s_-]'),
              '',
            );

    return normalizedStatus == 'dayoff';
  }

  factory UpcomingDay.fromJson(
    Map<String, dynamic> json,
  ) {
    UpcomingShift? shift;

    final dynamic shiftJson =
        json['shift'];

    if (shiftJson
        is Map<String, dynamic>) {
      shift =
          UpcomingShift.fromJson(
        shiftJson,
      );
    }

    final List<UpcomingTask> tasks =
        [];

    final dynamic tasksJson =
        json['tasks'];

    if (tasksJson is List) {
      for (final dynamic task
          in tasksJson) {
        if (task
            is Map<String, dynamic>) {
          tasks.add(
            UpcomingTask.fromJson(
              task,
              fallbackDate:
                  json['date']
                      ?.toString(),
            ),
          );
        }
      }
    }

    return UpcomingDay(
      date:
          json['date']?.toString() ?? '',
      shift: shift,
      tasks: tasks,
    );
  }
}

// ==================================================================
// UPCOMING SHIFT MODEL
// ==================================================================

class UpcomingShift {
  final int shiftId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String notes;

  const UpcomingShift({
    required this.shiftId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.notes,
  });

  factory UpcomingShift.fromJson(
    Map<String, dynamic> json,
  ) {
    return UpcomingShift(
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

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}

// ==================================================================
// UPCOMING TASK MODEL
// ==================================================================

class UpcomingTask {
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

  const UpcomingTask({
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

  factory UpcomingTask.fromJson(
    Map<String, dynamic> json, {
    String? fallbackDate,
  }) {
    return UpcomingTask(
      taskId:
          _parseInt(json['taskId']),
      title:
          json['title']?.toString() ??
              'Untitled Task',
      description:
          json['description']
                  ?.toString() ??
              '',
      area:
          json['area']?.toString() ?? '',
      location:
          json['location']?.toString() ?? '',
      date:
          json['date']?.toString() ??
              fallbackDate ??
              '',
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

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}
