
import 'dart:async';
import 'dart:convert';

import 'package:didit_sdk/sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class FaceVerificationPage extends StatefulWidget {
  const FaceVerificationPage({super.key});

  @override
  State<FaceVerificationPage> createState() =>
      _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  // ============================================================
  // API
  // ============================================================

  static const String _apiBaseUrl =
      'https://flop-enjoyment-unexposed.ngrok-free.dev';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _darkGreen = Color(0xFF1B5E20);
  static const Color _deepGreen = Color(0xFF124116);
  static const Color _green = Color(0xFF2E7D32);
  static const Color _lime = Color(0xFF8BC34A);
  static const Color _lightGreen = Color(0xFFDCEDC8);
  static const Color _background = Color(0xFFF0FDF4);
  static const Color _border = Color(0xFFD5E7D6);

  // ============================================================
  // STATE
  // ============================================================

  bool _isStarting = true;
  bool _isChecking = false;
  bool _isSuccess = false;
  bool _diditRunning = false;

  bool _leavingPage = false;
  bool _loginHandled = false;
  bool _pollInProgress = false;

  String? _errorMessage;
  String? _sessionId;

  Position? _currentPosition;

  Timer? _pollTimer;

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _startFaceLogin();
  }

  @override
  void dispose() {
    _leavingPage = true;
    _stopPolling();
    _currentPosition = null;
    super.dispose();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<Position> _getCurrentLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw StateError('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).timeout(const Duration(seconds: 20));
  }

  // ============================================================
  // START FACE LOGIN
  // ============================================================

  Future<void> _startFaceLogin() async {
    if (_leavingPage) return;

    _stopPolling();

    _loginHandled = false;
    _pollInProgress = false;
    _sessionId = null;
    _currentPosition = null;

    if (mounted) {
      setState(() {
        _isStarting = true;
        _isChecking = false;
        _isSuccess = false;
        _diditRunning = false;
        _errorMessage = null;
      });
    }

    try {
      // Capture once for this login attempt.
      final position = await _getCurrentLocation();

      if (_leavingPage) return;

      _currentPosition = position;

      // Create the Didit session.
      // Coordinates are NOT sent to this POST action.
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/Auth/face-login'),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{}),
      ).timeout(const Duration(seconds: 30));

      if (_leavingPage) return;

      final data = _decodeResponse(response);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw StateError(
          _serverMessage(
            data,
            'Unable to start face verification.',
          ),
        );
      }

      if (data == null) {
        throw StateError(
          'The server returned an invalid response.',
        );
      }

      final sessionId = data['sessionId']?.toString();
      final sessionToken = data['sessionToken']?.toString();

      if (sessionId == null || sessionId.isEmpty) {
        throw StateError(
          'The server did not return a verification session.',
        );
      }

      if (sessionToken == null || sessionToken.isEmpty) {
        throw StateError(
          'The server did not return a verification token.',
        );
      }

      _sessionId = sessionId;

      if (mounted) {
        setState(() {
          _isStarting = false;
          _isChecking = true;
          _diditRunning = true;
        });
      }

      // Polling now sends the coordinates as query parameters.
      _startPolling();

      final result = await DiditSdk.startVerification(
        sessionToken,
        config: const DiditConfig(
          loggingEnabled: false,
        ),
      );

      if (_leavingPage || _loginHandled) return;

      await _handleDiditResult(result);
    } on TimeoutException {
      if (_leavingPage || _loginHandled) return;

      _stopPolling();
      _currentPosition = null;

      _showError(
        'The request took too long. Please try again.',
      );
    } catch (e) {
      if (_leavingPage || _loginHandled) return;

      _stopPolling();
      _currentPosition = null;

      // Do not expose raw server exceptions or coordinates.
      debugPrint(
        '[SWIFTCARE FACE LOGIN] Unable to start verification.',
      );

      _showError(
        'Unable to complete secure sign in. Please try again.',
      );
    }
  }

  // ============================================================
  // DIDIT RESULT
  // ============================================================

  Future<void> _handleDiditResult(dynamic result) async {
    if (_leavingPage || _loginHandled) return;

    if (result is VerificationCompleted) {
      if (mounted) {
        setState(() {
          _diditRunning = false;
          _isChecking = true;
        });
      }

      // The backend decides whether verification succeeded.
      return;
    }

    if (result is VerificationCancelled) {
      _stopPolling();
      _currentPosition = null;

      _showError('Face verification was cancelled.');
      return;
    }

    if (result is VerificationFailed) {
      _stopPolling();
      _currentPosition = null;

      _showError(
        'Face verification could not be completed. '
        'Please try again.',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _diditRunning = false;
      });
    }
  }

  // ============================================================
  // POLLING
  // ============================================================

  void _startPolling() {
    _stopPolling();

    if (_sessionId == null ||
        _sessionId!.isEmpty ||
        _leavingPage) {
      return;
    }

    _checkFaceLoginStatus();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (!_leavingPage && !_loginHandled) {
          _checkFaceLoginStatus();
        }
      },
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ============================================================
  // STATUS URI WITH COORDINATES
  // ============================================================

  Uri _buildFaceLoginStatusUri(
    String sessionId,
    Position position,
  ) {
    final baseUri = Uri.parse(
      '$_apiBaseUrl/api/Auth/face-login/status/'
      '${Uri.encodeComponent(sessionId)}',
    );

    return baseUri.replace(
      queryParameters: {
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'accuracy': position.accuracy.toString(),
      },
    );
  }

  // ============================================================
  // CHECK FACE LOGIN STATUS
  // ============================================================

  Future<void> _checkFaceLoginStatus() async {
    if (_leavingPage ||
        _loginHandled ||
        _pollInProgress) {
      return;
    }

    final sessionId = _sessionId;
    final position = _currentPosition;

    if (sessionId == null ||
        sessionId.isEmpty ||
        position == null) {
      return;
    }

    _pollInProgress = true;

    try {
      // Matches:
      //
      // [HttpGet("face-login/status/{sessionId}")]
      //
      // [FromQuery] double? latitude
      // [FromQuery] double? longitude
      // [FromQuery] double? accuracy
      //
      final uri = _buildFaceLoginStatusUri(
        sessionId,
        position,
      );

      final response = await http.get(
        uri,
        headers: const {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (_leavingPage || _loginHandled) return;

      final data = _decodeResponse(response);

      // ========================================================
      // SUCCESSFUL AUTHENTICATION
      // ========================================================

      if (response.statusCode == 200 && data != null) {
        final authenticated =
            data['authenticated'] == true;

        if (authenticated) {
          final token = data['token']?.toString();

          if (token == null || token.isEmpty) {
            return;
          }

          _loginHandled = true;
          _stopPolling();

          await _handleSuccessfulLogin(data);
          return;
        }

        // Still processing.
        if (data['completed'] != true) {
          if (mounted) {
            setState(() {
              _isChecking = true;
            });
          }

          return;
        }

        // The backend has finished but did not authenticate.
        _stopPolling();
        _currentPosition = null;

        _showError(
          _serverMessage(
            data,
            'Face verification was not successful.',
          ),
        );

        return;
      }

      // ========================================================
      // AUTHENTICATION FAILED
      // ========================================================

      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404) {
        _stopPolling();
        _currentPosition = null;

        _showError(
          'Face verification was not successful. '
          'Please try again.',
        );

        return;
      }

      // ========================================================
      // SERVER ERROR
      // ========================================================

      if (response.statusCode >= 500) {
        _stopPolling();
        _currentPosition = null;

        _showError(
          'The SwiftCare server encountered an error. '
          'Please try again.',
        );
      }
    } on TimeoutException {
      // Retry during the next polling cycle.
    } catch (_) {
      // Retry transient network errors.
    } finally {
      _pollInProgress = false;
    }
  }

  // ============================================================
  // RESPONSE HELPERS
  // ============================================================

  Map<String, dynamic>? _decodeResponse(
    http.Response response,
  ) {
    if (response.body.isEmpty) return null;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _serverMessage(
    Map<String, dynamic>? data,
    String fallback,
  ) {
    if (data == null) return fallback;

    final message =
        data['message'] ?? data['error'] ?? data['detail'];

    if (message is String &&
        message.trim().isNotEmpty) {
      return message.trim();
    }

    return fallback;
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void> _handleSuccessfulLogin(
    Map<String, dynamic> data,
  ) async {
    if (_leavingPage) return;

    _currentPosition = null;

    if (mounted) {
      setState(() {
        _isStarting = false;
        _isChecking = false;
        _isSuccess = true;
        _diditRunning = false;
      });
    }

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (_leavingPage || !mounted) return;

    Navigator.of(context).pop(data);
  }

  // ============================================================
  // RETRY / CLOSE / ERROR
  // ============================================================

  Future<void> _retry() async {
    if (_leavingPage) return;
    await _startFaceLogin();
  }

  void _closePage() {
    if (_leavingPage) return;

    _leavingPage = true;
    _stopPolling();
    _currentPosition = null;

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    if (_leavingPage || !mounted) return;

    setState(() {
      _isStarting = false;
      _isChecking = false;
      _isSuccess = false;
      _diditRunning = false;
      _errorMessage = message;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
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
        horizontal: 20,
        vertical: 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: _lightGreen,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _closePage,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: _darkGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Face Verification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _deepGreen,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Secure SwiftCare sign in',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: _darkGreen,
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
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_isSuccess) {
      return _buildSuccessState();
    }

    return _buildVerificationState();
  }

  // ============================================================
  // VERIFICATION STATE
  // ============================================================

  Widget _buildVerificationState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lightGreen,
                border: Border.all(
                  color: _lime,
                  width: 2,
                ),
              ),
              child: Icon(
                _diditRunning
                    ? Icons.face_retouching_natural_rounded
                    : Icons.face_rounded,
                size: 62,
                color: _darkGreen,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _isStarting
                  ? 'Preparing Verification'
                  : _diditRunning
                      ? 'Verify Your Identity'
                      : 'Checking Verification',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _deepGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isStarting
                  ? 'Preparing your secure face verification.'
                  : _diditRunning
                      ? 'Follow the instructions on screen '
                          'to complete face verification.'
                      : 'SwiftCare is securely confirming '
                          'your identity.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            if (_isStarting || _isChecking)
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(_green),
                ),
              ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: _lightGreen.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 20,
                    color: _darkGreen,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your face verification is securely '
                      'processed through SwiftCare.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _darkGreen,
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
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade50,
                border: Border.all(
                  color: Colors.red.shade100,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 58,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Verification Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: _deepGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _closePage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _darkGreen,
                  side: const BorderSide(color: _border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
  // SUCCESS STATE
  // ============================================================

  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _lightGreen,
                border: Border.all(
                  color: _lime,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 68,
                color: _green,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: _deepGreen,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your identity has been verified successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Signing you in securely...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}