import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:swiftcare_volunteer_app/services/auth_storage.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  // ============================================================
  // API
  // ============================================================

  static const String _apiBaseUrl =
      'https://flop-enjoyment-unexposed.ngrok-free.dev';

  // ============================================================
  // STATE
  // ============================================================

  List<VolunteerTask> _tasks = [];

  List<VolunteerDaySchedule> _scheduleDays = [];

  bool _isLoading = true;
  bool _hasError = false;

  String _errorMessage =
      'Unable to load your tasks.';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadTasks();
  }

  // ============================================================
  // LOAD TASKS
  // ============================================================

  Future<void> _loadTasks() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token =
          await AuthStorage.getToken();

      if (token == null ||
          token.isEmpty) {
        throw Exception(
          'Your login session has expired.',
        );
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
        throw Exception(
          'Your login session has expired. Please login again.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to load your tasks. '
          'Server returned ${response.statusCode}.',
        );
      }

      final dynamic decoded =
          jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response from the server.',
        );
      }

      final List<VolunteerTask> loadedTasks = [];

      final List<VolunteerDaySchedule>
          loadedDays = [];

      // ==========================================================
      // API RESPONSE
      //
      // {
      //   startDate: "...",
      //   endDate: "...",
      //   totalTasks: 3,
      //   days: [
      //      {
      //        date: "...",
      //        shift: {
      //          status: "DayOff"
      //        },
      //        tasks: [...]
      //      }
      //   ]
      // }
      // ==========================================================

      final days =
          decoded['days'];

      if (days is List) {
        for (final day in days) {
          if (day is! Map) {
            continue;
          }

          final date =
              day['date']?.toString() ?? '';

          // ========================================================
          // SHIFT
          // ========================================================

          VolunteerShift? shift;

          final shiftJson =
              day['shift'];

          if (shiftJson is Map) {
            shift =
                VolunteerShift.fromJson(
              shiftJson,
            );
          }

          // ========================================================
          // DAY TASKS
          // ========================================================

          final List<VolunteerTask>
              dayTasks = [];

          final tasks =
              day['tasks'];

          if (tasks is List) {
            for (final task in tasks) {
              if (task is! Map) {
                continue;
              }

              final parsedTask =
                  VolunteerTask.fromJson(
                task,
                fallbackDate: date,
              );

              loadedTasks.add(
                parsedTask,
              );

              dayTasks.add(
                parsedTask,
              );
            }
          }

          // ========================================================
          // SAVE COMPLETE DAY
          // ========================================================

          loadedDays.add(
            VolunteerDaySchedule(
              date: date,
              shift: shift,
              tasks: dayTasks,
            ),
          );
        }
      }

      // Sort days chronologically.
      loadedDays.sort(
        (a, b) => a.date.compareTo(
          b.date,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _tasks = loadedTasks;
        _scheduleDays = loadedDays;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _hasError = true;

        _errorMessage =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isDayOff(
    VolunteerDaySchedule day,
  ) {
    final status =
        day.shift?.status
                .toLowerCase()
                .replaceAll('_', '')
                .replaceAll('-', '')
                .trim() ??
            '';

    return status == 'dayoff' ||
        status == 'off';
  }

  bool _hasWorkingShift(
    VolunteerDaySchedule day,
  ) {
    final shift = day.shift;

    if (shift == null) {
      return false;
    }

    final status =
        shift.status
            .toLowerCase()
            .replaceAll('_', '')
            .replaceAll('-', '')
            .trim();

    return status != 'dayoff' &&
        status != 'off' &&
        status != 'cancelled';
  }

  int get _dayOffCount {
    return _scheduleDays
        .where(_isDayOff)
        .length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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
          'My Tasks',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _isLoading
                ? null
                : _loadTasks,

            icon: const Icon(
              Icons.refresh,
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),

      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(
          color:
              Color(0xFF2E7D32),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_tasks.isEmpty &&
        _dayOffCount == 0) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color:
          const Color(0xFF2E7D32),

      onRefresh: _loadTasks,

      child: ListView(
        padding:
            const EdgeInsets.all(18),

        children: [
          _buildSummaryHeader(),

          const SizedBox(height: 16),

          ..._buildScheduleContent(),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD SCHEDULE CONTENT
  // ============================================================

  List<Widget> _buildScheduleContent() {
    final List<Widget> widgets = [];

    for (final day in _scheduleDays) {
      // ----------------------------------------------------------
      // DAY OFF
      // ----------------------------------------------------------

      if (_isDayOff(day)) {
        widgets.add(
          _buildDayOffCard(day),
        );

        widgets.add(
          const SizedBox(height: 12),
        );
      }

      // ----------------------------------------------------------
      // WORKING SHIFT
      // ----------------------------------------------------------

      if (_hasWorkingShift(day) &&
          day.tasks.isEmpty) {
        widgets.add(
          _buildShiftCard(day),
        );

        widgets.add(
          const SizedBox(height: 12),
        );
      }

      // ----------------------------------------------------------
      // TASKS
      // ----------------------------------------------------------

      for (final task in day.tasks) {
        widgets.add(
          _buildTask(task),
        );
      }
    }

    return widgets;
  }

  // ============================================================
  // SUMMARY HEADER
  // ============================================================

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            const Color(0xFFDCEDC8),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              const Color(0xFFD5E7D6),
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFF1B5E20),
                  shape:
                      BoxShape.circle,
                ),

                child: const Icon(
                  Icons.task_alt,
                  color:
                      Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'My Tasks',
                      style:
                          TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF1B5E20),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '${_tasks.length} task${_tasks.length == 1 ? '' : 's'} assigned',
                      style:
                          const TextStyle(
                        fontSize: 13,
                        color:
                            Color(0xFF52705A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ------------------------------------------------------
          // DAY OFF SUMMARY
          // ------------------------------------------------------

          if (_dayOffCount > 0) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),

              decoration:
                  BoxDecoration(
                color:
                    Colors.red.shade50,

                borderRadius:
                    BorderRadius.circular(12),

                border: Border.all(
                  color:
                      Colors.red.shade100,
                ),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons
                        .free_breakfast_outlined,
                    size: 18,
                    color:
                        Colors.red.shade600,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      '${_dayOffCount} day${_dayOffCount == 1 ? '' : 's'} off this week',
                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Colors.red.shade700,
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
  // DAY OFF CARD
  // ============================================================

  Widget _buildDayOffCard(
    VolunteerDaySchedule day,
  ) {
    return GestureDetector(
      onTap: () {
        _showDayOffDetails(day);
      },

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.all(17),

        decoration: BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color:
                const Color(0xFFF1D4D4),
          ),

          boxShadow: const [
            BoxShadow(
              color:
                  Color(0x08000000),
              blurRadius: 8,
              offset:
                  Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,

          children: [
            Container(
              width: 52,
              height: 52,

              decoration:
                  BoxDecoration(
                color:
                    Colors.red.shade50,

                borderRadius:
                    BorderRadius.circular(
                  15,
                ),
              ),

              child: Icon(
                Icons
                    .free_breakfast_outlined,
                color:
                    Colors.red.shade600,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    _formatDate(
                      day.date,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 3),

                  const Text(
                    'DAY OFF',
                    style:
                        TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          Color(0xFFB71C1C),
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'You are not scheduled to work on this day.',
                    style:
                        TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade600,
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

              decoration:
                  BoxDecoration(
                color:
                    Colors.red.shade50,

                borderRadius:
                    BorderRadius.circular(
                  8,
                ),
              ),

              child: Text(
                'OFF',
                style:
                    TextStyle(
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHIFT CARD
  // ============================================================

  Widget _buildShiftCard(
    VolunteerDaySchedule day,
  ) {
    final shift = day.shift;

    if (shift == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(17),

      decoration:
          BoxDecoration(
        color:
            Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              const Color(0xFFD5E7D6),
        ),

        boxShadow: const [
          BoxShadow(
            color:
                Color(0x08000000),
            blurRadius: 8,
            offset:
                Offset(0, 3),
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

            child: const Icon(
              Icons.access_time,
              color:
                  Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  _formatDate(
                    day.date,
                  ),
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Scheduled Shift',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        Color(0xFF1B5E20),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${shift.startTime} - ${shift.endTime}',
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Color(0xFF616161),
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
  // TASK CARD
  // ============================================================

  Widget _buildTask(
    VolunteerTask task,
  ) {
    return GestureDetector(
      onTap: () {
        _showTaskDetails(task);
      },

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 14,
        ),

        padding:
            const EdgeInsets.all(17),

        decoration:
            BoxDecoration(
          color:
              Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color:
                const Color(0xFFD5E7D6),
          ),

          boxShadow: const [
            BoxShadow(
              color:
                  Color(0x08000000),
              blurRadius: 8,
              offset:
                  Offset(0, 3),
            ),
          ],
        ),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // TASK ICON
            // ==================================================

            Container(
              width: 50,
              height: 50,

              decoration:
                  BoxDecoration(
                color:
                    const Color(
                  0xFFDCEDC8,
                ),

                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),

              child: Icon(
                _getTaskIcon(
                  task.area,
                ),

                color:
                    const Color(
                  0xFF2E7D32,
                ),
              ),
            ),

            const SizedBox(width: 14),

            // ==================================================
            // TASK INFORMATION
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    task.title,

                    maxLines: 2,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF1B5E20),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 14,
                        color:
                            Colors.grey,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Expanded(
                        child: Text(
                          _formatDate(
                            task.date,
                          ),

                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .access_time_outlined,
                        size: 14,
                        color:
                            Colors.grey,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Expanded(
                        child: Text(
                          '${task.startTime} - ${task.endTime}',

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 13,
                            color:
                                Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (task.location !=
                          null &&
                      task.location!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 5,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_outlined,
                          size: 14,
                          color:
                              Colors.grey,
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Expanded(
                          child: Text(
                            task.location!,

                            maxLines: 1,

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 7,
                    runSpacing: 5,

                    children: [
                      if (task.area
                          .isNotEmpty)
                        _buildSmallBadge(
                          task.area,
                        ),

                      if (task.priority
                          .isNotEmpty)
                        _buildPriorityBadge(
                          task.priority,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // ==================================================
            // STATUS
            // ==================================================

            _buildStatusBadge(
              task.status,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SMALL BADGE
  // ============================================================

  Widget _buildSmallBadge(
    String text,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF0FDF4),

        borderRadius:
            BorderRadius.circular(8),
      ),

      child: Text(
        text,

        style:
            const TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
          color:
              Color(0xFF2E7D32),
        ),
      ),
    );
  }

  // ============================================================
  // PRIORITY BADGE
  // ============================================================

  Widget _buildPriorityBadge(
    String priority,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF5F5F5),

        borderRadius:
            BorderRadius.circular(8),
      ),

      child: Text(
        priority,

        style:
            const TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
          color:
              Color(0xFF616161),
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
    Color background =
        const Color(0xFFDCEDC8);

    Color foreground =
        const Color(0xFF2E7D32);

    final normalized =
        status
            .toLowerCase()
            .replaceAll('_', '')
            .replaceAll('-', '')
            .trim();

    if (normalized ==
            'cancelled' ||
        normalized == 'missed') {
      background =
          Colors.red.shade50;
      foreground =
          Colors.red.shade600;
    } else if (normalized ==
        'inprogress') {
      background =
          Colors.orange.shade50;
      foreground =
          Colors.orange.shade700;
    } else if (normalized ==
        'completed') {
      background =
          Colors.green.shade50;
      foreground =
          Colors.green.shade700;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration:
          BoxDecoration(
        color:
            background,

        borderRadius:
            BorderRadius.circular(8),
      ),

      child: Text(
        status.isEmpty
            ? 'Assigned'
            : status,

        style:
            TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.bold,
          color:
              foreground,
        ),
      ),
    );
  }

  // ============================================================
  // DAY OFF DETAILS
  // ============================================================

  void _showDayOffDetails(
    VolunteerDaySchedule day,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            12,
            22,
            30,
          ),

          decoration:
              const BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(28),
            ),
          ),

          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Center(
                  child: Container(
                    width: 64,
                    height: 64,

                    decoration:
                        BoxDecoration(
                      color:
                          Colors.red.shade50,
                      shape:
                          BoxShape.circle,
                    ),

                    child: Icon(
                      Icons
                          .free_breakfast_outlined,
                      size: 32,
                      color:
                          Colors.red.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Center(
                  child: Text(
                    'DAY OFF',
                    style:
                        TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          Color(0xFFB71C1C),
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Center(
                  child: Text(
                    _formatDate(
                      day.date,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 14,
                      color:
                          Colors.grey,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.red.shade50,

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    border: Border.all(
                      color:
                          Colors.red.shade100,
                    ),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .event_available_outlined,
                        color:
                            Colors.red.shade600,
                      ),

                      const SizedBox(width: 10),

                      const Expanded(
                        child: Text(
                          'You are not scheduled to work on this day.',
                          style:
                              TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color:
                                Color(0xFF616161),
                          ),
                        ),
                      ),
                    ],
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
  // TASK DETAILS
  // ============================================================

  void _showTaskDetails(
    VolunteerTask task,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor:
          Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            22,
            12,
            22,
            30,
          ),

          decoration:
              const BoxDecoration(
            color:
                Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(28),
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
                      width: 42,
                      height: 4,

                      decoration:
                          BoxDecoration(
                        color:
                            Colors.grey.shade300,
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
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
                              BorderRadius.circular(
                            15,
                          ),
                        ),

                        child: Icon(
                          _getTaskIcon(
                            task.area,
                          ),

                          color:
                              const Color(
                            0xFF2E7D32,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          task.title,

                          style:
                              const TextStyle(
                            fontSize: 21,
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

                  const SizedBox(height: 22),

                  _buildDetailRow(
                    Icons
                        .calendar_today_outlined,
                    'Date',
                    _formatDate(
                      task.date,
                    ),
                  ),

                  _buildDetailRow(
                    Icons
                        .access_time_outlined,
                    'Time',
                    '${task.startTime} - ${task.endTime}',
                  ),

                  _buildDetailRow(
                    Icons.category_outlined,
                    'Area',
                    task.area,
                  ),

                  if (task.location !=
                          null &&
                      task.location!
                          .trim()
                          .isNotEmpty)
                    _buildDetailRow(
                      Icons
                          .location_on_outlined,
                      'Location',
                      task.location!,
                    ),

                  _buildDetailRow(
                    Icons.flag_outlined,
                    'Priority',
                    task.priority.isEmpty
                        ? 'Normal'
                        : task.priority,
                  ),

                  _buildDetailRow(
                    Icons.task_alt,
                    'Status',
                    task.status,
                  ),

                  if (task.description !=
                          null &&
                      task.description!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Description',
                      style:
                          TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            Color(0xFF1B5E20),
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    Text(
                      task.description!,

                      style:
                          const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color:
                            Color(0xFF616161),
                      ),
                    ),
                  ],
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
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 12,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 19,
            color:
                const Color(0xFF2E7D32),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 75,

            child: Text(
              label,

              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color:
          const Color(0xFF2E7D32),

      onRefresh: _loadTasks,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(24),

        children: [
          const SizedBox(height: 100),

          Center(
            child: Container(
              width: 90,
              height: 90,

              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFDCEDC8),
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons.task_alt,
                size: 46,
                color:
                    Color(0xFF2E7D32),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'No Tasks Assigned',
            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'You currently have no tasks assigned for the upcoming week.',
            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
                  Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return RefreshIndicator(
      color:
          const Color(0xFF2E7D32),

      onRefresh: _loadTasks,

      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),

        padding:
            const EdgeInsets.all(24),

        children: [
          const SizedBox(height: 80),

          const Icon(
            Icons.cloud_off_outlined,
            size: 70,
            color:
                Color(0xFF78909C),
          ),

          const SizedBox(height: 22),

          const Text(
            'Unable to Load Tasks',
            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              fontSize: 21,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _errorMessage,

            textAlign:
                TextAlign.center,

            style:
                const TextStyle(
              fontSize: 14,
              height: 1.5,
              color:
                  Colors.grey,
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child:
                ElevatedButton.icon(
              onPressed:
                  _loadTasks,

              icon: const Icon(
                Icons.refresh,
              ),

              label: const Text(
                'Try Again',
              ),

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF2E7D32,
                ),

                foregroundColor:
                    Colors.white,

                elevation: 0,

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TASK ICON
  // ============================================================

  IconData _getTaskIcon(
    String area,
  ) {
    final value =
        area.toLowerCase();

    if (value.contains('food') ||
        value.contains('kitchen') ||
        value.contains('dining')) {
      return Icons.restaurant;
    }

    if (value.contains('resident') ||
        value.contains('care')) {
      return Icons.volunteer_activism;
    }

    if (value.contains('activity') ||
        value.contains('recreation')) {
      return Icons.groups;
    }

    if (value.contains('clean')) {
      return Icons.cleaning_services;
    }

    if (value.contains('admin') ||
        value.contains('office')) {
      return Icons.business_center;
    }

    return Icons.task_alt;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    String date,
  ) {
    if (date.isEmpty) {
      return 'Date unavailable';
    }

    try {
      final parsed =
          DateTime.parse(date);

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

      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return date;
    }
  }
}

// ==================================================================
// VOLUNTEER DAY SCHEDULE MODEL
// ==================================================================

class VolunteerDaySchedule {
  final String date;
  final VolunteerShift? shift;
  final List<VolunteerTask> tasks;

  VolunteerDaySchedule({
    required this.date,
    required this.shift,
    required this.tasks,
  });
}

// ==================================================================
// VOLUNTEER SHIFT MODEL
// ==================================================================

class VolunteerShift {
  final int shiftId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;

  VolunteerShift({
    required this.shiftId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.notes,
  });

  factory VolunteerShift.fromJson(
    Map json,
  ) {
    return VolunteerShift(
      shiftId:
          int.tryParse(
            json['shiftId']
                    ?.toString() ??
                '',
          ) ??
          0,

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
              'Scheduled',

      notes:
          json['notes']?.toString(),
    );
  }
}

// ==================================================================
// VOLUNTEER TASK MODEL
// ==================================================================

class VolunteerTask {
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

  VolunteerTask({
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

  // ============================================================
  // FROM JSON
  // ============================================================

  factory VolunteerTask.fromJson(
    Map json, {
    String fallbackDate = '',
  }) {
    return VolunteerTask(
      taskId:
          _parseInt(
        json['taskId'],
      ),

      title:
          json['title']
                  ?.toString() ??
              'Task',

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
                  ?.toString()
                  .isNotEmpty ==
              true
          ? json['date']
              .toString()
          : fallbackDate,

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
              'Assigned',

      priority:
          json['priority']
                  ?.toString() ??
              'Normal',
    );
  }

  static int _parseInt(
    dynamic value,
  ) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }
}
