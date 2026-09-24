import 'dart:async';
import 'dart:convert';

import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({super.key});

  @override
  State<FaceVerificationPage> createState() =>
      _FaceVerificationPageState();
}

class _FaceVerificationPageState
    extends State<FaceVerificationPage> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color forestGreen = Color(0xFF1B5E20);
  static const Color darkGreen = Color(0xFF124116);
  static const Color logoGreen = Color(0xFF155F30);
  static const Color mediumGreen = Color(0xFF2E7D32);
  static const Color limeGreen = Color(0xFF8BC34A);
  static const Color lightGreen = Color(0xFFDCEDC8);
  static const Color paleGreen = Color(0xFFF0FDF4);
  static const Color borderGreen = Color(0xFFD5E7D6);
  static const Color textGreen = Color(0xFF4B6350);

  // ============================================================
  // API
  // ============================================================

  static const String _apiBaseUrl =
      'https://flop-enjoyment-unexposed.ngrok-free.dev';

  // ============================================================
  // STATE
  // ============================================================

  bool _isStarting = true;
  bool _isChecking = false;
  bool _isSuccess = false;
  bool _diditRunning = false;

  String? _errorMessage;
  String? _sessionId;

  Timer? _pollTimer;

  bool _leavingPage = false;

  // ============================================================
  // LOGIN HANDLING LOCK
  // ============================================================

  bool _loginHandled = false;

  // ============================================================
  // POLLING LOCK
  // ============================================================

  bool _pollInProgress = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _startFaceLogin();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _leavingPage = true;

    _pollTimer?.cancel();
    _pollTimer = null;

    super.dispose();
  }

  // ============================================================
  // START FACE LOGIN
  // ============================================================

  Future<void> _startFaceLogin() async {
    if (_leavingPage) {
      return;
    }

    _pollTimer?.cancel();
    _pollTimer = null;

    _pollInProgress = false;
    _loginHandled = false;

    if (!mounted) {
      return;
    }

    setState(() {
      _isStarting = true;
      _isChecking = false;
      _isSuccess = false;
      _diditRunning = false;

      _errorMessage = null;
      _sessionId = null;
    });

    try {
      // ========================================================
      // START SWIFTCARE FACE LOGIN SESSION
      // ========================================================

      final uri = Uri.parse(
        '$_apiBaseUrl/api/Auth/face-login',
      );

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'STARTING FACE LOGIN',
      );

      debugPrint(
        'POST: $uri',
      );

      final response = await http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({}),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      debugPrint(
        'FACE LOGIN START STATUS: '
        '${response.statusCode}',
      );

      if (!mounted || _leavingPage) {
        return;
      }

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(
          response.body,
        );

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (e) {
        debugPrint(
          'Could not decode face-login response: $e',
        );
      }

      // ========================================================
      // API ERROR
      // ========================================================

      if (response.statusCode != 200) {
        if (!mounted || _leavingPage) {
          return;
        }

        setState(() {
          _isStarting = false;
          _isChecking = false;

          _errorMessage =
              data['message']?.toString() ??
              data['error']?.toString() ??
              'Unable to start face verification.';
        });

        return;
      }

      // ========================================================
      // SESSION ID
      // ========================================================

      final sessionId =
          data['sessionId']?.toString();

      // ========================================================
      // DIDIT SESSION TOKEN
      // ========================================================

      final sessionToken =
          data['sessionToken']?.toString();

      if (sessionId == null ||
          sessionId.trim().isEmpty) {
        if (!mounted || _leavingPage) {
          return;
        }

        setState(() {
          _isStarting = false;
          _isChecking = false;

          _errorMessage =
              'SwiftCare did not return a Didit session ID.';
        });

        return;
      }

      if (sessionToken == null ||
          sessionToken.trim().isEmpty) {
        if (!mounted || _leavingPage) {
          return;
        }

        setState(() {
          _isStarting = false;
          _isChecking = false;

          _errorMessage =
              'SwiftCare did not return a Didit session token.';
        });

        return;
      }

      debugPrint(
        'Didit Session ID: $sessionId',
      );

      debugPrint(
        'Didit session token received.',
      );

      _sessionId = sessionId;

      // ========================================================
      // PREPARE NATIVE DIDIT SDK
      // ========================================================

      if (!mounted || _leavingPage) {
        return;
      }

      setState(() {
        _isStarting = false;
        _isChecking = true;
        _diditRunning = true;
        _errorMessage = null;
      });

      // ========================================================
      // START BACKEND POLLING
      // ========================================================

      _startPolling();

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'STARTING NATIVE DIDIT SDK',
      );

      debugPrint(
        'Session ID: $sessionId',
      );

      debugPrint(
        '==========================================',
      );

      // ========================================================
      // START NATIVE DIDIT VERIFICATION
      // ========================================================

      final result =
          await DiditSdk.startVerification(
        sessionToken,
        config: const DiditConfig(
          loggingEnabled: false,
        ),
      );

      if (!mounted || _leavingPage) {
        return;
      }

      _diditRunning = false;

      // ========================================================
      // HANDLE DIDIT RESULT
      // ========================================================

      await _handleDiditResult(
        result,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '==========================================',
      );

      debugPrint(
        'FACE LOGIN START EXCEPTION',
      );

      debugPrint(
        '$e',
      );

      debugPrint(
        '$stackTrace',
      );

      debugPrint(
        '==========================================',
      );

      _diditRunning = false;

      if (!mounted || _leavingPage) {
        return;
      }

      _pollTimer?.cancel();
      _pollTimer = null;

      _pollInProgress = false;

      setState(() {
        _isStarting = false;
        _isChecking = false;

        _errorMessage =
            'Could not start face verification.\n\n'
            '$e';
      });
    }
  }

  // ============================================================
  // HANDLE DIDIT RESULT
  // ============================================================

  Future<void> _handleDiditResult(
    VerificationResult result,
  ) async {
    if (!mounted ||
        _leavingPage ||
        _loginHandled) {
      return;
    }

    switch (result) {
      // ========================================================
      // COMPLETED
      // ========================================================

      case VerificationCompleted(:final session):
        debugPrint(
          '==========================================',
        );

        debugPrint(
          'DIDIT SDK COMPLETED',
        );

        debugPrint(
          'Didit session ID: ${session.sessionId}',
        );

        debugPrint(
          'Didit client status: '
          '${session.status.name}',
        );

        debugPrint(
          '==========================================',
        );

        if (session.status ==
            VerificationStatus.declined) {
          _pollTimer?.cancel();
          _pollTimer = null;

          if (!mounted || _leavingPage) {
            return;
          }

          setState(() {
            _isChecking = false;

            _errorMessage =
                'Didit could not verify your face. '
                'Please try again.';
          });

          return;
        }

        if (!mounted ||
            _leavingPage ||
            _loginHandled) {
          return;
        }

        setState(() {
          _isChecking = true;
          _errorMessage = null;
        });

        await _checkFaceLoginStatus();

        return;

      // ========================================================
      // USER CANCELLED
      // ========================================================

      case VerificationCancelled(:final session):
        debugPrint(
          '==========================================',
        );

        debugPrint(
          'DIDIT SDK CANCELLED',
        );

        if (session != null) {
          debugPrint(
            'Didit session ID: '
            '${session.sessionId}',
          );
        }

        debugPrint(
          '==========================================',
        );

        _pollTimer?.cancel();
        _pollTimer = null;

        if (!mounted || _leavingPage) {
          return;
        }

        setState(() {
          _isChecking = false;

          _errorMessage =
              'Face verification was cancelled.';
        });

        return;

      // ========================================================
      // DIDIT FAILED
      // ========================================================

      case VerificationFailed(:final error):
        debugPrint(
          '==========================================',
        );

        debugPrint(
          'DIDIT SDK FAILED',
        );

        debugPrint(
          'Error type: ${error.type.name}',
        );

        debugPrint(
          'Error message: ${error.message}',
        );

        debugPrint(
          '==========================================',
        );

        _pollTimer?.cancel();
        _pollTimer = null;

        if (!mounted || _leavingPage) {
          return;
        }

        setState(() {
          _isChecking = false;

          _errorMessage =
              _getDiditErrorMessage(
            error,
          );
        });

        return;
    }
  }

  // ============================================================
  // DIDIT ERROR MESSAGE
  // ============================================================

  String _getDiditErrorMessage(
    VerificationError error,
  ) {
    switch (error.type) {
      case VerificationErrorType.sessionExpired:
        return 'The face verification session has expired. '
            'Please try again.';

      case VerificationErrorType.networkError:
        return 'Didit could not connect to its verification '
            'service. Please check your internet connection '
            'and try again.';

      case VerificationErrorType.cameraAccessDenied:
        return 'Camera access was denied. '
            'Please allow camera access for SwiftCare '
            'and try again.';

      case VerificationErrorType.notInitialized:
        return 'Didit could not initialize correctly. '
            'Please restart SwiftCare and try again.';

      case VerificationErrorType.apiError:
        return 'Didit encountered a verification service '
            'error. Please try again.';

      case VerificationErrorType.retryBlocked:
        return 'Too many verification attempts have been made. '
            'Please wait and try again later.';

      case VerificationErrorType.unknown:
        return error.message.isNotEmpty
            ? error.message
            : 'Didit could not complete face verification.';
    }
  }

  // ============================================================
  // POLLING
  // ============================================================

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;

    _pollInProgress = false;

    if (_leavingPage ||
        _loginHandled ||
        !_isChecking) {
      return;
    }

    _checkFaceLoginStatus();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (_leavingPage ||
            _loginHandled ||
            !_isChecking) {
          _pollTimer?.cancel();
          _pollTimer = null;
          return;
        }

        _checkFaceLoginStatus();
      },
    );
  }

  // ============================================================
  // CHECK FACE LOGIN STATUS
  // ============================================================

  Future<void> _checkFaceLoginStatus() async {
    final sessionId = _sessionId;

    if (sessionId == null ||
        sessionId.isEmpty ||
        !_isChecking ||
        _isSuccess ||
        _leavingPage ||
        _loginHandled ||
        _pollInProgress) {
      return;
    }

    _pollInProgress = true;

    try {
      final uri = Uri.parse(
        '$_apiBaseUrl/api/Auth/face-login/status/'
        '${Uri.encodeComponent(sessionId)}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      debugPrint(
        'FACE LOGIN STATUS: '
        '${response.statusCode}',
      );

      if (!mounted ||
          _leavingPage ||
          _loginHandled) {
        return;
      }

      Map<String, dynamic> data = {};

      try {
        final decoded = jsonDecode(
          response.body,
        );

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (e) {
        debugPrint(
          'Could not decode face login status response: $e',
        );
      }

      // ========================================================
      // SUCCESS
      // ========================================================

      if (response.statusCode == 200 &&
          data['authenticated'] == true) {
        final token =
            data['token']?.toString();

        if (token == null ||
            token.isEmpty) {
          _pollTimer?.cancel();
          _pollTimer = null;

          if (!mounted ||
              _leavingPage ||
              _loginHandled) {
            return;
          }

          setState(() {
            _isChecking = false;

            _errorMessage =
                'Face verification succeeded, '
                'but SwiftCare did not return a login token.';
          });

          return;
        }

        if (_loginHandled) {
          return;
        }

        _loginHandled = true;

        _pollTimer?.cancel();
        _pollTimer = null;

        debugPrint(
          '==========================================',
        );

        debugPrint(
          'FACE LOGIN AUTHENTICATED',
        );

        debugPrint(
          'Navigation/login handling locked.',
        );

        debugPrint(
          '==========================================',
        );

        await _handleSuccessfulLogin(
          data,
        );

        return;
      }

      // ========================================================
      // STILL PROCESSING
      // ========================================================

      if (response.statusCode == 200 &&
          data['completed'] == false) {
        if (mounted &&
            !_leavingPage &&
            !_loginHandled) {
          setState(() {
            _isChecking = true;
          });
        }

        return;
      }

      // ========================================================
      // VERIFICATION FAILED
      // ========================================================

      if (response.statusCode == 401) {
        _pollTimer?.cancel();
        _pollTimer = null;

        if (!mounted ||
            _leavingPage ||
            _loginHandled) {
          return;
        }

        setState(() {
          _isChecking = false;

          _errorMessage =
              data['message']?.toString() ??
              'Face verification was not successful.';
        });

        return;
      }

      // ========================================================
      // SERVER ERROR
      // ========================================================

      if (response.statusCode >= 500) {
        _pollTimer?.cancel();
        _pollTimer = null;

        if (!mounted ||
            _leavingPage ||
            _loginHandled) {
          return;
        }

        setState(() {
          _isChecking = false;

          _errorMessage =
              data['message']?.toString() ??
              'SwiftCare could not complete face verification.';
        });

        return;
      }
    } catch (e) {
      debugPrint(
        'Face login status check failed: $e',
      );

      // Keep polling.
    } finally {
      _pollInProgress = false;
    }
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void> _handleSuccessfulLogin(
    Map<String, dynamic> data,
  ) async {
    if (!mounted ||
        _leavingPage ||
        !_loginHandled) {
      return;
    }

    _pollTimer?.cancel();
    _pollTimer = null;

    _pollInProgress = false;

    setState(() {
      _isChecking = false;
      _isSuccess = true;
      _errorMessage = null;
    });

    debugPrint(
      'Showing successful face-login screen.',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 900,
      ),
    );

    if (!mounted ||
        _leavingPage) {
      return;
    }

    _leavingPage = true;

    _pollTimer?.cancel();
    _pollTimer = null;

    debugPrint(
      'Returning successful face-login result.',
    );

    debugPrint(
      'Navigator.pop() will execute exactly once.',
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      data,
    );
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> _retry() async {
    if (_isStarting ||
        _diditRunning ||
        _leavingPage ||
        _loginHandled) {
      return;
    }

    await _startFaceLogin();
  }

  // ============================================================
  // SAFE POP
  // ============================================================

  void _closePage() {
    if (!mounted ||
        _leavingPage ||
        _diditRunning ||
        _loginHandled) {
      return;
    }

    _leavingPage = true;

    _pollTimer?.cancel();
    _pollTimer = null;

    _pollInProgress = false;

    Navigator.of(context).pop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: paleGreen,

      body: SafeArea(
        child: Stack(
          children: [

            // ==================================================
            // BACKGROUND DECORATION
            // ==================================================

            Positioned(
              top: -100,
              right: -90,
              child: Container(
                width: 230,
                height: 230,

                decoration: BoxDecoration(
                  color:
                      limeGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -120,
              left: -100,
              child: Container(
                width: 250,
                height: 250,

                decoration: BoxDecoration(
                  color:
                      lightGreen.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ==================================================
            // PAGE
            // ==================================================

            Column(
              children: [

                _buildHeader(),

                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ],
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

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),

        border: const Border(
          bottom: BorderSide(
            color: borderGreen,
            width: 1,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                forestGreen.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [

          // ==================================================
          // BACK BUTTON
          // ==================================================

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: IconButton(
              onPressed: _closePage,

              icon: const Icon(
                Icons.arrow_back_rounded,
                color: forestGreen,
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ==================================================
          // LOGO
          // ==================================================

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: limeGreen,
              borderRadius:
                  BorderRadius.circular(13),
            ),

            child: const Icon(
              Icons.monitor_heart_rounded,
              color: logoGreen,
              size: 25,
            ),
          ),

          const SizedBox(width: 12),

          // ==================================================
          // TITLE
          // ==================================================

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Text(
                  'SwiftCare',

                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: mediumGreen,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  'Face Verification',

                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: forestGreen,
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // SECURITY ICON
          // ==================================================

          if (_isChecking)
            Container(
              width: 38,
              height: 38,

              decoration: BoxDecoration(
                color:
                    lightGreen.withOpacity(0.65),
                shape: BoxShape.circle,
              ),

              child: const Padding(
                padding: EdgeInsets.all(9),

                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: mediumGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    if (_isStarting) {
      return _buildLoading();
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_isSuccess) {
      return _buildSuccess();
    }

    if (_diditRunning) {
      return _buildDiditLoading();
    }

    if (_isChecking) {
      return _buildBackendChecking();
    }

    return _buildLoading();
  }

  // ============================================================
  // COMMON PAGE WRAPPER
  // ============================================================

  Widget _pageWrapper({
    required Widget child,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 28,
        ),
        child: child,
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _statusCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconBackground,
    required Color iconColor,
    Widget? bottom,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),

        borderRadius:
            BorderRadius.circular(30),

        border: Border.all(
          color: borderGreen,
          width: 1.2,
        ),

        boxShadow: [
          BoxShadow(
            color:
                forestGreen.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: Column(
        children: [

          // ==================================================
          // ICON
          // ==================================================

          Container(
            width: 92,
            height: 92,

            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,

              border: Border.all(
                color:
                    limeGreen.withOpacity(0.35),
                width: 2,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      limeGreen.withOpacity(0.12),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),

            child: Icon(
              icon,
              size: 48,
              color: iconColor,
            ),
          ),

          const SizedBox(height: 25),

          // ==================================================
          // TITLE
          // ==================================================

          Text(
            title,
            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: forestGreen,
            ),
          ),

          const SizedBox(height: 12),

          // ==================================================
          // DESCRIPTION
          // ==================================================

          Text(
            description,
            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: textGreen,
            ),
          ),

          if (bottom != null) ...[
            const SizedBox(height: 28),
            bottom,
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STEP INDICATOR
  // ============================================================

  Widget _buildSteps({
    required int activeStep,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      decoration: BoxDecoration(
        color:
            lightGreen.withOpacity(0.42),

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color:
              limeGreen.withOpacity(0.20),
        ),
      ),

      child: Row(
        children: [

          _buildStep(
            number: 1,
            label: 'Scan',
            active: activeStep >= 1,
            completed: activeStep > 1,
          ),

          _buildStepLine(
            active: activeStep > 1,
          ),

          _buildStep(
            number: 2,
            label: 'Verify',
            active: activeStep >= 2,
            completed: activeStep > 2,
          ),

          _buildStepLine(
            active: activeStep > 2,
          ),

          _buildStep(
            number: 3,
            label: 'Sign In',
            active: activeStep >= 3,
            completed: activeStep > 3,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP
  // ============================================================

  Widget _buildStep({
    required int number,
    required String label,
    required bool active,
    required bool completed,
  }) {
    return Column(
      children: [

        Container(
          width: 32,
          height: 32,

          decoration: BoxDecoration(
            color: completed
                ? limeGreen
                : active
                    ? forestGreen
                    : Colors.white,

            shape: BoxShape.circle,

            border: Border.all(
              color: active
                  ? forestGreen
                  : borderGreen,
              width: 1.5,
            ),
          ),

          child: Center(
            child: completed
                ? const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: logoGreen,
                  )
                : Text(
                    '$number',

                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.bold,
                      color: active
                          ? Colors.white
                          : textGreen,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          label,

          style: TextStyle(
            fontSize: 11,
            fontWeight:
                active
                    ? FontWeight.w700
                    : FontWeight.w500,
            color: active
                ? forestGreen
                : textGreen,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STEP CONNECTOR
  // ============================================================

  Widget _buildStepLine({
    required bool active,
  }) {
    return Expanded(
      child: Container(
        height: 2,
        margin:
            const EdgeInsets.only(
          bottom: 19,
          left: 6,
          right: 6,
        ),

        decoration: BoxDecoration(
          color: active
              ? limeGreen
              : borderGreen,

          borderRadius:
              BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return _pageWrapper(
      child: _statusCard(
        icon: Icons
            .fingerprint_rounded,
        title:
            'Preparing Verification',
        description:
            'We are securely preparing your face verification. '
            'Please wait a moment.',

        iconBackground: lightGreen,
        iconColor: forestGreen,

        bottom: Column(
          children: [

            _buildSteps(
              activeStep: 1,
            ),

            const SizedBox(height: 24),

            const SizedBox(
              width: 32,
              height: 32,

              child:
                  CircularProgressIndicator(
                strokeWidth: 3,
                color: mediumGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIDIT LOADING
  // ============================================================

  Widget _buildDiditLoading() {
    return _pageWrapper(
      child: _statusCard(
        icon: Icons
            .face_retouching_natural,
        title:
            'Scan Your Face',
        description:
            'Follow the secure Didit verification screen '
            'and position your face inside the camera frame.',

        iconBackground: limeGreen,
        iconColor: logoGreen,

        bottom: Column(
          children: [

            _buildSteps(
              activeStep: 1,
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color:
                    paleGreen,

                borderRadius:
                    BorderRadius.circular(16),

                border: Border.all(
                  color: borderGreen,
                ),
              ),

              child: const Row(
                children: [

                  Icon(
                    Icons
                        .camera_alt_outlined,
                    color: mediumGreen,
                    size: 20,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Camera verification is running securely.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textGreen,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const SizedBox(
              width: 30,
              height: 30,

              child:
                  CircularProgressIndicator(
                strokeWidth: 3,
                color: mediumGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BACKEND CHECKING
  // ============================================================

  Widget _buildBackendChecking() {
    return _pageWrapper(
      child: _statusCard(
        icon: Icons.verified_user_rounded,
        title:
            'Checking Your Identity',
        description:
            'Your face has been submitted successfully. '
            'SwiftCare is securely confirming your identity.',

        iconBackground: lightGreen,
        iconColor: forestGreen,

        bottom: Column(
          children: [

            _buildSteps(
              activeStep: 2,
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color:
                    paleGreen,

                borderRadius:
                    BorderRadius.circular(16),

                border: Border.all(
                  color: borderGreen,
                ),
              ),

              child: const Row(
                children: [

                  Icon(
                    Icons.lock_outline_rounded,
                    color: mediumGreen,
                    size: 20,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Verification is being confirmed by SwiftCare.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textGreen,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(
              width: 30,
              height: 30,

              child:
                  CircularProgressIndicator(
                strokeWidth: 3,
                color: mediumGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return _pageWrapper(
      child: _statusCard(
        icon: Icons
            .error_outline_rounded,
        title:
            'Verification Unsuccessful',
        description:
            _errorMessage ??
            'Face verification could not be completed. '
            'Please try again.',

        iconBackground:
            const Color(0xFFFFF1F1),

        iconColor:
            const Color(0xFFC62828),

        bottom: Column(
          children: [

            // ==================================================
            // RETRY
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 54,

              child: ElevatedButton.icon(
                onPressed: _retry,

                icon: const Icon(
                  Icons.refresh_rounded,
                ),

                label: const Text(
                  'Try Again',
                ),

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      forestGreen,

                  foregroundColor:
                      Colors.white,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  textStyle:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // BACK
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 54,

              child: OutlinedButton.icon(
                onPressed: _closePage,

                icon: const Icon(
                  Icons.arrow_back_rounded,
                ),

                label: const Text(
                  'Back to Login',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      forestGreen,

                  side: const BorderSide(
                    color: borderGreen,
                    width: 1.5,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),

                  textStyle:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Widget _buildSuccess() {
    return _pageWrapper(
      child: _statusCard(
        icon: Icons.verified_rounded,
        title:
            'Face Verified Successfully',
        description:
            'Your identity has been confirmed. '
            'Signing you in to SwiftCare now.',

        iconBackground: limeGreen,
        iconColor: logoGreen,

        bottom: Column(
          children: [

            _buildSteps(
              activeStep: 3,
            ),

            const SizedBox(height: 24),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color:
                    lightGreen.withOpacity(
                  0.55,
                ),

                borderRadius:
                    BorderRadius.circular(16),

                border: Border.all(
                  color:
                      limeGreen.withOpacity(
                    0.30,
                  ),
                ),
              ),

              child: const Row(
                children: [

                  Icon(
                    Icons
                        .check_circle_outline_rounded,
                    color: mediumGreen,
                    size: 21,
                  ),

                  SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Authentication successful. Welcome to SwiftCare.',
                      style: TextStyle(
                        fontSize: 13,
                        color: forestGreen,
                        fontWeight:
                            FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(
              width: 28,
              height: 28,

              child:
                  CircularProgressIndicator(
                strokeWidth: 3,
                color: mediumGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 