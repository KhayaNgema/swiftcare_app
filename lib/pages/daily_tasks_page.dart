import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:swiftcare_volunteer_app/services/auth_storage.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  // ============================================================
  // API
  // ============================================================

  static const String _baseUrl =
      'https://flop-enjoyment-unexposed.ngrok-free.dev';

  // ============================================================
  // STATE
  // ============================================================

  List<DailyTask> _tasks = [];

  DailyShift? _shift;

  String? _date;

  bool _isLoading = true;
  bool _isRefreshing = false;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    super.dispose();
  }

  // ============================================================
  // LOAD TODAY
  // ============================================================

  Future<void> _loadToday({
    bool refresh = false,
  }) async {
    if (refresh) {
      setState(() {
        _isRefreshing = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Your login session has expired. Please log in again.',
        );
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/api/VolunteerSchedule/today',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session has expired. Please log in again.',
        );
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Unable to load today\'s tasks. '
          'Server returned ${response.statusCode}.',
        );
      }

      final decoded =
          jsonDecode(response.body) as Map<String, dynamic>;

      // ========================================================
      // CONTROLLER RESPONSE
      //
      // {
      //   "date": "...",
      //   "shift": {...},
      //   "tasks": [...],
      //   "totalTasks": 3
      // }
      //
      // taskId is the VolunteerTaskAssignmentId.
      // ========================================================

      final date =
          decoded['date']?.toString();

      final tasksJson =
          decoded['tasks'] as List<dynamic>? ?? [];

      final shiftJson =
          decoded['shift'];

      final loadedTasks = tasksJson
          .whereType<Map<String, dynamic>>()
          .map(
            (task) => DailyTask.fromJson(task),
          )
          .toList();

      DailyShift? loadedShift;

      if (shiftJson is Map<String, dynamic>) {
        loadedShift =
            DailyShift.fromJson(shiftJson);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _date = date;
        _tasks = loadedTasks;
        _shift = loadedShift;

        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      });
    }
  }

  // ============================================================
  // START TASK
  // ============================================================

  Future<void> _startTask(
    DailyTask task,
  ) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Your login session has expired. Please log in again.',
        );
      }

      final response = await http.post(
        Uri.parse(
          '$_baseUrl/api/VolunteerSchedule/tasks/${task.taskId}/start',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session has expired. Please log in again.',
        );
      }

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        String message =
            'Unable to start this task.';

        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            message =
                decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                decoded['title']?.toString() ??
                message;
          }
        } catch (_) {}

        throw Exception(message);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Task started successfully.',
          ),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      await _loadToday(refresh: true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  // ============================================================
  // COMPLETE TASK
  // ============================================================

  Future<void> _completeTask(
    DailyTask task,
    String completionNotes,
  ) async {
    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'Your login session has expired. Please log in again.',
        );
      }

      final response = await http.post(
        Uri.parse(
          '$_baseUrl/api/VolunteerSchedule/tasks/${task.taskId}/complete',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'completionNotes': completionNotes,
        }),
      );

      if (response.statusCode == 401) {
        throw Exception(
          'Your login session has expired. Please log in again.',
        );
      }

      if (response.statusCode != 200 &&
          response.statusCode != 204) {
        String message =
            'Unable to complete this task.';

        try {
          final decoded =
              jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            message =
                decoded['message']?.toString() ??
                decoded['error']?.toString() ??
                decoded['title']?.toString() ??
                message;
          }
        } catch (_) {}

        throw Exception(message);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Task completed successfully.',
          ),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      await _loadToday(refresh: true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  // ============================================================
  // SHOW COMPLETE DIALOG
  // ============================================================

  Future<void> _showCompleteDialog(
    DailyTask task,
  ) async {
    final controller =
        TextEditingController();

    bool isSubmitting = false;

    try {
      final result =
          await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
              context,
              setDialogState,
            ) {
              final availableHeight = MediaQuery.sizeOf(dialogContext).height -
                  MediaQuery.viewInsetsOf(dialogContext).bottom - 64;
              return AlertDialog(
                scrollable: false,
                insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                constraints: BoxConstraints(
                  maxWidth: 440,
                  maxHeight: availableHeight > 180 ? availableHeight : 180,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Complete Task',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Completion Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 7),

                    TextField(
                      controller: controller,
                      maxLength: 2000,
                      maxLines: 5,
                      minLines: 3,
                      enabled: !isSubmitting,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration:
                          InputDecoration(
                        hintText:
                            'Add notes about the completed task...',
                        filled: true,
                        fillColor:
                            const Color(0xFFF0FDF4),
                        counterText: '',
                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFFD5E7D6),
                          ),
                        ),
                        enabledBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFFD5E7D6),
                          ),
                        ),
                        focusedBorder:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                          borderSide:
                              const BorderSide(
                            color:
                                Color(0xFF2E7D32),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    ValueListenableBuilder<
                        TextEditingValue>(
                      valueListenable:
                          controller,
                      builder: (
                        context,
                        value,
                        child,
                      ) {
                        return Align(
                          alignment:
                              Alignment.centerRight,
                          child: Text(
                            '${value.text.length}/2000',
                            style:
                                const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  ElevatedButton.icon(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setDialogState(() {
                              isSubmitting = true;
                            });

                            Navigator.of(
                              dialogContext,
                            ).pop(
                              controller.text.trim(),
                            );
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            size: 18,
                          ),
                    label: const Text(
                      'Complete',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF2E7D32),
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      await _completeTask(
        task,
        result,
      );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2E7D32),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF2E7D32),
      onRefresh: () =>
          _loadToday(refresh: true),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24,
        ),
        children: [
          // ======================================================
          // ERROR
          // ======================================================

          if (_errorMessage != null)
            _buildErrorCard(),

          // ======================================================
          // SUMMARY
          // ======================================================

          _buildSummaryCard(
            _tasks.length,
          ),

          const SizedBox(height: 14),

          // ======================================================
          // TODAY'S SHIFT
          // ======================================================

          if (_shift != null)
            _buildShiftCard(),

          if (_shift != null)
            const SizedBox(height: 18),

          // ======================================================
          // TITLE
          // ======================================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's Tasks",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),

              if (_isRefreshing)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2E7D32),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ======================================================
          // TASKS
          // ======================================================

          if (_tasks.isEmpty)
            _buildEmptyCard()
          else
            ..._tasks.map(
              (task) => _buildTaskCard(task),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard(
    int taskCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 3),
            color: Color(0x10000000),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFDCEDC8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.today,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(_date),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$taskCount ${taskCount == 1 ? 'task' : 'tasks'} assigned',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
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
  // SHIFT CARD
  // ============================================================

  Widget _buildShiftCard() {
    final shift = _shift!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            Color(0xFFF0FDF4),
            Color(0xFFDCEDC8),
          ],
        ),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD5E7D6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.access_time_filled,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Shift",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${shift.startTime} - ${shift.endTime}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  shift.status,
                  style: const TextStyle(
                    fontSize: 12,
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
  // TASK CARD
  // ============================================================

  Widget _buildTaskCard(
    DailyTask task,
  ) {
    return GestureDetector(
      onTap: () =>
          _showTaskDetails(task),
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // ICON
            // ==================================================

            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    const Color(0xFFDCEDC8),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Icon(
                _getTaskIcon(task),
                color:
                    const Color(0xFF2E7D32),
              ),
            ),

            const SizedBox(width: 13),

            // ==================================================
            // DETAILS
            // ==================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF1B5E20),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Expanded(
                        child: Text(
                          '${task.startTime} - ${task.endTime}',
                          style:
                              const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (task.location != null &&
                      task.location!.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            task.location!,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (task.area.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            task.area,
                            style:
                                const TextStyle(
                              fontSize: 13,
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
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    String status,
  ) {
    final normalized =
        status.toLowerCase();

    Color background;
    Color foreground;

    if (normalized == 'completed') {
      background =
          const Color(0xFFE8F5E9);
      foreground =
          const Color(0xFF2E7D32);
    } else if (normalized == 'inprogress' ||
        normalized == 'in progress') {
      background =
          const Color(0xFFE3F2FD);
      foreground =
          const Color(0xFF1565C0);
    } else if (normalized == 'cancelled' ||
        normalized == 'canceled') {
      background =
          const Color(0xFFFFEBEE);
      foreground =
          const Color(0xFFC62828);
    } else if (normalized == 'missed') {
      background =
          const Color(0xFFFFF3E0);
      foreground =
          const Color(0xFFE65100);
    } else {
      background =
          const Color(0xFFFFF8E1);
      foreground =
          const Color(0xFF8D6E00);
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyCard() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
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
          Container(
            width: 62,
            height: 62,
            decoration:
                const BoxDecoration(
              color: Color(0xFFDCEDC8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_outlined,
              size: 32,
              color: Color(0xFF2E7D32),
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'No tasks assigned today',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'You currently have no volunteer tasks scheduled for today.',
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
  // ERROR CARD
  // ============================================================

  Widget _buildErrorCard() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFCDD2),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFC62828),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _errorMessage ??
                  'Unable to load today\'s tasks.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFC62828),
              ),
            ),
          ),

          IconButton(
            onPressed: () =>
                _loadToday(),
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFFC62828),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TASK DETAILS
  // ============================================================

  void _showTaskDetails(
    DailyTask task,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            28,
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
                      width: 42,
                      height: 5,
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

                  const SizedBox(height: 20),

                  // ==================================================
                  // TASK TITLE
                  // ==================================================

                  Row(
                    children: [
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
                            15,
                          ),
                        ),
                        child: Icon(
                          _getTaskIcon(task),
                          color:
                              const Color(
                            0xFF2E7D32,
                          ),
                          size: 26,
                        ),
                      ),

                      const SizedBox(width: 12),

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

                  // ==================================================
                  // TASK INFORMATION
                  // ==================================================

                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    '${task.startTime} - ${task.endTime}',
                  ),

                  if (task.location != null &&
                      task.location!.isNotEmpty)
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Location',
                      task.location!,
                    ),

                  if (task.area.isNotEmpty)
                    _buildDetailRow(
                      Icons.place_outlined,
                      'Area',
                      task.area,
                    ),

                  _buildDetailRow(
                    Icons.flag_outlined,
                    'Priority',
                    task.priority,
                  ),

                  _buildDetailRow(
                    Icons.info_outline,
                    'Status',
                    task.status,
                  ),

                  // ==================================================
                  // TASK DESCRIPTION
                  // ==================================================

                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 18),

                    const Text(
                      'Task Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(
                          0xFF1B5E20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      task.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.black,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ==================================================
                  // ACTION BUTTONS
                  // ==================================================

                  _buildTaskActionButtons(
                    task,
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TASK ACTION BUTTONS
  // ============================================================

  Widget _buildTaskActionButtons(
    DailyTask task,
  ) {
    final normalized =
        task.status
            .trim()
            .toLowerCase();

    // ==========================================================
    // ASSIGNED
    // Start Task + Close
    // ==========================================================

    if (normalized == 'assigned') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFF2E7D32,
                ),
                side:
                    const BorderSide(
                  color:
                      Color(0xFF2E7D32),
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
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

          const SizedBox(width: 10),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _startTask(task);
              },
              icon: const Icon(
                Icons.play_arrow_rounded,
                size: 19,
              ),
              label: const Text(
                'Start Task',
              ),
              style:
                  ElevatedButton.styleFrom(
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
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // IN PROGRESS
    // Complete + Close
    // ==========================================================

    if (normalized == 'inprogress' ||
        normalized == 'in progress') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFF2E7D32,
                ),
                side:
                    const BorderSide(
                  color:
                      Color(0xFF2E7D32),
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
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

          const SizedBox(width: 10),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCompleteDialog(task);
              },
              icon: const Icon(
                Icons.check_circle_outline,
                size: 19,
              ),
              label: const Text(
                'Complete',
              ),
              style:
                  ElevatedButton.styleFrom(
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
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // COMPLETED
    // Non-action Completed + Close
    // ==========================================================

    if (normalized == 'completed') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFF2E7D32,
                ),
                side:
                    const BorderSide(
                  color:
                      Color(0xFF2E7D32),
                ),
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 14,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
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

          const SizedBox(width: 10),

          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color:
                    const Color(
                  0xFFE8F5E9,
                ),
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
              ),
              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 19,
                    color:
                        Color(0xFF2E7D32),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Completed',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ==========================================================
    // CANCELLED / MISSED / OTHER
    // No action for now
    // ==========================================================

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style:
            ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF2E7D32),
          foregroundColor:
              Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 14,
          ),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
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
        bottom: 13,
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
            width: 85,
            child: Text(
              label,
              style:
                  const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(
                fontSize: 13,
                color:
                    Colors.black87,
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
    DailyTask task,
  ) {
    final text =
        '${task.title} ${task.area}'
            .toLowerCase();

    if (text.contains('breakfast') ||
        text.contains('food') ||
        text.contains('meal') ||
        text.contains('dining') ||
        text.contains('kitchen')) {
      return Icons.restaurant_outlined;
    }

    if (text.contains('check') ||
        text.contains('resident')) {
      return Icons.health_and_safety_outlined;
    }

    if (text.contains('activity') ||
        text.contains('recreation') ||
        text.contains('game')) {
      return Icons.sports_esports_outlined;
    }

    if (text.contains('clean')) {
      return Icons.cleaning_services_outlined;
    }

    if (text.contains('garden') ||
        text.contains('outdoor')) {
      return Icons.yard_outlined;
    }

    if (text.contains('transport') ||
        text.contains('drive')) {
      return Icons.directions_car_outlined;
    }

    return Icons.task_alt_outlined;
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
    String? date,
  ) {
    if (date == null ||
        date.trim().isEmpty) {
      return 'Today';
    }

    try {
      final parsed =
          DateTime.parse(date);

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

      return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
    } catch (_) {
      return date;
    }
  }
}

// ============================================================================
// DAILY TASK MODEL
// ============================================================================

class DailyTask {
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

  DailyTask({
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

  factory DailyTask.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyTask(
      // IMPORTANT:
      // Backend taskId is now VolunteerTaskAssignmentId.
      taskId:
          _toInt(json['taskId']),
      title:
          json['title']?.toString() ?? '',
      description:
          json['description']?.toString(),
      area:
          json['area']?.toString() ?? '',
      location:
          json['location']?.toString(),
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

  static int _toInt(
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

// ============================================================================
// DAILY SHIFT MODEL
// ============================================================================

class DailyShift {
  final int shiftId;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? notes;

  DailyShift({
    required this.shiftId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.notes,
  });

  factory DailyShift.fromJson(
    Map<String, dynamic> json,
  ) {
    return DailyShift(
      shiftId:
          _toInt(json['shiftId']),
      date:
          json['date']?.toString() ?? '',
      startTime:
          json['startTime']?.toString() ?? '',
      endTime:
          json['endTime']?.toString() ?? '',
      status:
          json['status']?.toString() ?? '',
      notes:
          json['notes']?.toString(),
    );
  }

  static int _toInt(
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