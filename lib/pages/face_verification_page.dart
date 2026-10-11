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
      'https://swiftcareapi20261008091404-a5c8ade5cfaahea4.spaincentral-01.azurewebsites.net';

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

  bool _isStarting = false;
  bool _isChecking = false;
  bool _isSuccess = false;
  bool _diditRunning = false;

  bool _leavingPage = false;
  bool _loginHandled = false;
  bool _pollInProgress = false;
  bool _requestingLocation = false;

  String? _errorMessage;
  String? _sessionId;

  Position? _currentPosition;

  Timer? _pollTimer;

  // ============================================================
  // POLLING CONFIGURATION
  // ============================================================

  static const Duration _pollInterval =
      Duration(seconds: 3);

  static const Duration _requestTimeout =
      Duration(seconds: 20);

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_leavingPage) {
        _prepareLocation();
      }
    });
  }

  @override
  void dispose() {
    _leavingPage = true;
    _stopPolling();
    super.dispose();
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _prepareLocation() async {
    if (_leavingPage ||
        !mounted ||
        _requestingLocation) {
      return;
    }

    _requestingLocation = true;

    try {
      if (mounted) {
        setState(() {
          _isStarting = false;
          _isChecking = false;
          _isSuccess = false;
          _diditRunning = false;
          _errorMessage = null;
        });
      }

      // ----------------------------------------------------------
      // 1. CHECK LOCATION PERMISSION
      //
      // Works on both Android and iOS through Geolocator.
      // The native permission dialog is shown by the OS.
      // ----------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (_leavingPage || !mounted) {
        return;
      }

      // ----------------------------------------------------------
      // 2. REQUEST LOCATION PERMISSION
      // ----------------------------------------------------------

      if (permission == LocationPermission.denied) {
        debugPrint(
          '[LOCATION] Permission denied. Requesting native permission...',
        );

        permission =
            await Geolocator.requestPermission();

        if (_leavingPage || !mounted) {
          return;
        }

        debugPrint(
          '[LOCATION] Permission result: $permission',
        );
      }

      // ----------------------------------------------------------
      // 3. USER DENIED LOCATION PERMISSION
      // ----------------------------------------------------------

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Location permission was denied. '
                'SwiftCare needs your location to securely '
                'complete sign in. Please allow Location '
                'permission and try again.';
          });
        }

        return;
      }

      // ----------------------------------------------------------
      // 4. USER PERMANENTLY DENIED LOCATION PERMISSION
      // ----------------------------------------------------------

      if (permission ==
          LocationPermission.deniedForever) {
        debugPrint(
          '[LOCATION] Permission permanently denied. '
          'Opening app settings...',
        );

        try {
          await Geolocator.openAppSettings();
        } catch (e) {
          debugPrint(
            '[LOCATION] Could not open app settings: $e',
          );
        }

        if (_leavingPage || !mounted) {
          return;
        }

        setState(() {
          _errorMessage =
              'Location permission is blocked for SwiftCare. '
              'Open SwiftCare settings, allow Location, '
              'then tap Try Again.';
        });

        return;
      }

      // ----------------------------------------------------------
      // 5. CHECK DEVICE LOCATION SERVICES
      // ----------------------------------------------------------

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (_leavingPage || !mounted) {
        return;
      }

      if (!serviceEnabled) {
        debugPrint(
          '[LOCATION] Location services are disabled. '
          'Opening location settings...',
        );

        try {
          await Geolocator.openLocationSettings();
        } catch (e) {
          debugPrint(
            '[LOCATION] Could not open location settings: $e',
          );
        }

        if (_leavingPage || !mounted) {
          return;
        }

        setState(() {
          _errorMessage =
              'Location services are turned off. '
              'Please enable Location on your device '
              'and tap Try Again.';
        });

        return;
      }

      // ----------------------------------------------------------
      // 6. GET CURRENT LOCATION
      // ----------------------------------------------------------

      if (mounted) {
        setState(() {
          _isStarting = true;
          _errorMessage = null;
        });
      }

      debugPrint(
        '[LOCATION] Permission granted. '
        'Getting current location...',
      );

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 20),
      );

      if (_leavingPage || !mounted) {
        return;
      }

      _currentPosition = position;

      debugPrint(
        '[LOCATION] Position acquired. '
        'Latitude=${position.latitude}, '
        'Longitude=${position.longitude}, '
        'Accuracy=${position.accuracy}',
      );

      // ----------------------------------------------------------
      // 7. LOCATION READY — START FACE LOGIN
      // ----------------------------------------------------------

      await _startFaceLogin();
    } on TimeoutException {
      if (_leavingPage || !mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage =
            'We could not get your location in time. '
            'Please make sure Location is enabled '
            'and try again.';
      });
    } on LocationServiceDisabledException {
      if (_leavingPage || !mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage =
            'Location services are turned off. '
            'Please enable Location and try again.';
      });
    } on PermissionDeniedException {
      if (_leavingPage || !mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage =
            'SwiftCare needs location permission to securely '
            'complete sign in. Please allow Location and try again.';
      });
    } catch (e, stackTrace) {
      debugPrint(
        '========================================',
      );
      debugPrint('[LOCATION] ERROR: $e');
      debugPrint(
        '[LOCATION] STACK TRACE:\n$stackTrace',
      );
      debugPrint(
        '========================================',
      );

      if (_leavingPage || !mounted) {
        return;
      }

      setState(() {
        _isStarting = false;
        _errorMessage =
            'Unable to get your location. '
            'Please check your Location settings and try again.';
      });
    } finally {
      _requestingLocation = false;
    }
  }

  // ============================================================
  // START FACE LOGIN
  // ============================================================

  Future<void> _startFaceLogin() async {
    if (_leavingPage || !mounted) {
      return;
    }

    if (_currentPosition == null) {
      await _prepareLocation();
      return;
    }

    _stopPolling();

    _loginHandled = false;
    _pollInProgress = false;
    _sessionId = null;

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
      // ========================================================
      // CREATE BACKEND FACE LOGIN SESSION
      // ========================================================

      final createUri = Uri.parse(
        '$_apiBaseUrl/api/Auth/face-login',
      );

      debugPrint(
        '========================================',
      );
      debugPrint(
        '[FACE LOGIN] Creating face-login session',
      );
      debugPrint(
        '[FACE LOGIN] URL: $createUri',
      );
      debugPrint(
        '========================================',
      );

      final response = await http
          .post(
            createUri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
              <String, dynamic>{},
            ),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (_leavingPage || !mounted) {
        return;
      }

      debugPrint(
        '[FACE LOGIN] Create session HTTP '
        '${response.statusCode}',
      );

      debugPrint(
        '[FACE LOGIN] Response body: '
        '${response.body}',
      );

      final data = _decodeResponse(response);

      // ========================================================
      // BACKEND ERROR
      // ========================================================

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message = _serverMessage(
          data,
          'SwiftCare could not create a face verification session.',
        );

        throw FaceLoginException(
          stage: 'CREATE_SESSION',
          message: message,
          statusCode: response.statusCode,
        );
      }

      // ========================================================
      // INVALID RESPONSE
      // ========================================================

      if (data == null) {
        throw FaceLoginException(
          stage: 'CREATE_SESSION',
          message:
              'SwiftCare received an invalid response from the server.',
          statusCode: response.statusCode,
        );
      }

      final sessionId =
          data['sessionId']?.toString();

      final sessionToken =
          data['sessionToken']?.toString();

      debugPrint(
        '[FACE LOGIN] Session ID received: '
        '${sessionId != null && sessionId.isNotEmpty}',
      );

      debugPrint(
        '[FACE LOGIN] Session token received: '
        '${sessionToken != null && sessionToken.isNotEmpty}',
      );

      // ========================================================
      // VALIDATE SESSION ID
      // ========================================================

      if (sessionId == null ||
          sessionId.trim().isEmpty) {
        throw FaceLoginException(
          stage: 'CREATE_SESSION',
          message:
              'The SwiftCare server did not return a verification session.',
          statusCode: response.statusCode,
        );
      }

      // ========================================================
      // VALIDATE SESSION TOKEN
      // ========================================================

      if (sessionToken == null ||
          sessionToken.trim().isEmpty) {
        throw FaceLoginException(
          stage: 'CREATE_SESSION',
          message:
              'The SwiftCare server did not return a verification token.',
          statusCode: response.statusCode,
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

      // ========================================================
      // OPEN DIDIT
      //
      // This call is platform-neutral.
      //
      // The didit_sdk Flutter package handles the native
      // Android/iOS implementation.
      // ========================================================

      debugPrint(
        '[FACE LOGIN] Starting Didit SDK...',
      );

      dynamic result;

      try {
        result =
            await DiditSdk.startVerification(
          sessionToken,
          config: const DiditConfig(
            loggingEnabled: true,
          ),
        );

        debugPrint(
          '[FACE LOGIN] Didit SDK returned: '
          '${result.runtimeType}',
        );
      } catch (e, stackTrace) {
        debugPrint(
          '========================================',
        );
        debugPrint(
          '[DIDIT] SDK EXCEPTION',
        );
        debugPrint(
          '[DIDIT] TYPE: ${e.runtimeType}',
        );
        debugPrint(
          '[DIDIT] ERROR: $e',
        );
        debugPrint(
          '[DIDIT] STACK TRACE:\n$stackTrace',
        );
        debugPrint(
          '========================================',
        );

        _stopPolling();

        throw FaceLoginException(
          stage: 'DIDIT_SDK',
          message:
              'The secure identity verification service '
              'could not be opened.',
          originalError: e,
        );
      }

      if (_leavingPage || _loginHandled) {
        return;
      }

      // ========================================================
      // START POLLING AFTER DIDIT RETURNS
      // ========================================================

      if (_sessionId != null &&
          _sessionId!.isNotEmpty) {
        _startPolling();
      }

      await _handleDiditResult(result);
    } on TimeoutException {
      if (_leavingPage || _loginHandled) {
        return;
      }

      _stopPolling();

      debugPrint(
        '[FACE LOGIN] CREATE SESSION TIMEOUT',
      );

      if (mounted) {
        setState(() {
          _isStarting = false;
          _isChecking = false;
          _diditRunning = false;
          _errorMessage =
              'The secure sign-in request timed out. '
              'Please check your connection and try again.';
        });
      }
    } on FaceLoginException catch (e) {
      if (_leavingPage || _loginHandled) {
        return;
      }

      _stopPolling();

      debugPrint(
        '========================================',
      );
      debugPrint(
        '[FACE LOGIN] FACE LOGIN EXCEPTION',
      );
      debugPrint(
        '[FACE LOGIN] STAGE: ${e.stage}',
      );
      debugPrint(
        '[FACE LOGIN] STATUS: ${e.statusCode}',
      );
      debugPrint(
        '[FACE LOGIN] MESSAGE: ${e.message}',
      );
      debugPrint(
        '[FACE LOGIN] ORIGINAL: ${e.originalError}',
      );
      debugPrint(
        '========================================',
      );

      if (mounted) {
        setState(() {
          _isStarting = false;
          _isChecking = false;
          _diditRunning = false;
          _errorMessage =
              _friendlyFaceLoginError(e);
        });
      }
    } catch (e, stackTrace) {
      if (_leavingPage || _loginHandled) {
        return;
      }

      _stopPolling();

      debugPrint(
        '========================================',
      );
      debugPrint(
        '[FACE LOGIN] UNEXPECTED ERROR',
      );
      debugPrint(
        '[FACE LOGIN] TYPE: ${e.runtimeType}',
      );
      debugPrint(
        '[FACE LOGIN] ERROR: $e',
      );
      debugPrint(
        '[FACE LOGIN] STACK TRACE:\n$stackTrace',
      );
      debugPrint(
        '========================================',
      );

      if (mounted) {
        setState(() {
          _isStarting = false;
          _isChecking = false;
          _diditRunning = false;
          _errorMessage =
              'Unable to complete secure sign in. '
              'Please try again.';
        });
      }
    }
  }

  // ============================================================
  // DIDIT RESULT
  // ============================================================

  Future<void> _handleDiditResult(
    dynamic result,
  ) async {
    if (_leavingPage || _loginHandled) {
      return;
    }

    debugPrint(
      '[DIDIT] Verification result: '
      '${result.runtimeType}',
    );

    if (result is VerificationCompleted) {
      if (mounted) {
        setState(() {
          _diditRunning = false;
          _isChecking = true;
        });
      }

      // Backend remains authoritative.
      _startPolling();

      return;
    }

    if (result is VerificationCancelled) {
      _stopPolling();

      if (mounted) {
        setState(() {
          _diditRunning = false;
          _isChecking = false;
          _errorMessage =
              'Face verification was cancelled. '
              'You can try again when you are ready.';
        });
      }

      return;
    }

    if (result is VerificationFailed) {
      debugPrint(
        '[DIDIT] VerificationFailed received.',
      );

      _stopPolling();

      if (mounted) {
        setState(() {
          _diditRunning = false;
          _isChecking = false;
          _errorMessage =
              'Face verification could not be completed. '
              'Please try again.';
        });
      }

      return;
    }

    // Unknown result.
    //
    // Keep checking the backend because the backend remains
    // authoritative for authentication.

    if (mounted) {
      setState(() {
        _diditRunning = false;
        _isChecking = true;
      });
    }

    _startPolling();
  }

  // ============================================================
  // POLLING
  // ============================================================

  void _startPolling() {
    _stopPolling();

    if (_sessionId == null ||
        _sessionId!.isEmpty ||
        _leavingPage ||
        _loginHandled) {
      return;
    }

    debugPrint(
      '[FACE LOGIN] Starting status polling for session.',
    );

    _checkFaceLoginStatus();

    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) {
        if (!_leavingPage &&
            !_loginHandled) {
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
  // STATUS URI
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
        'latitude':
            position.latitude.toString(),
        'longitude':
            position.longitude.toString(),
        'accuracy':
            position.accuracy.toString(),
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
      final uri = _buildFaceLoginStatusUri(
        sessionId,
        position,
      );

      debugPrint(
        '[FACE LOGIN] Checking verification status...',
      );

      final response = await http
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
            },
          )
          .timeout(_requestTimeout);

      if (_leavingPage || _loginHandled) {
        return;
      }

      debugPrint(
        '[FACE LOGIN] Status HTTP '
        '${response.statusCode}',
      );

      debugPrint(
        '[FACE LOGIN] Status response: '
        '${response.body}',
      );

      final data = _decodeResponse(response);

      // ========================================================
      // SUCCESSFUL HTTP RESPONSE
      // ========================================================

      if (response.statusCode == 200 &&
          data != null) {
        final authenticated =
            data['authenticated'] == true;

        if (authenticated) {
          final token =
              data['token']?.toString();

          if (token == null ||
              token.trim().isEmpty) {
            debugPrint(
              '[FACE LOGIN] Backend says authenticated '
              'but no JWT token was returned.',
            );

            return;
          }

          debugPrint(
            '[FACE LOGIN] AUTHENTICATED = TRUE',
          );

          _loginHandled = true;
          _stopPolling();

          await _handleSuccessfulLogin(data);

          return;
        }

        // ------------------------------------------------------
        // BACKEND STILL PROCESSING
        // ------------------------------------------------------

        final completed =
            data['completed'] == true;

        if (!completed) {
          debugPrint(
            '[FACE LOGIN] Verification still processing.',
          );

          if (mounted) {
            setState(() {
              _isChecking = true;
            });
          }

          return;
        }

        // ------------------------------------------------------
        // BACKEND COMPLETED BUT AUTHENTICATION FAILED
        // ------------------------------------------------------

        debugPrint(
          '[FACE LOGIN] Backend completed without authentication.',
        );

        _stopPolling();

        if (mounted) {
          setState(() {
            _isChecking = false;
            _diditRunning = false;
            _errorMessage = _serverMessage(
              data,
              'Face verification was not successful. '
              'Please try again.',
            );
          });
        }

        return;
      }

      // ========================================================
      // 404
      //
      // Keep polling because backend processing may still be
      // taking place.
      // ========================================================

      if (response.statusCode == 404) {
        debugPrint(
          '[FACE LOGIN] Status returned 404. '
          'Keeping session alive and retrying.',
        );

        if (mounted) {
          setState(() {
            _isChecking = true;
          });
        }

        return;
      }

      // ========================================================
      // CLIENT AUTHENTICATION ERROR
      // ========================================================

      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        debugPrint(
          '[FACE LOGIN] Permanent client/auth error: '
          '${response.statusCode}',
        );

        _stopPolling();

        if (mounted) {
          setState(() {
            _isChecking = false;
            _diditRunning = false;

            _errorMessage = _serverMessage(
              data,
              'Face verification could not be completed. '
              'Please try again.',
            );
          });
        }

        return;
      }

      // ========================================================
      // SERVER ERROR
      //
      // Keep polling through transient 5xx errors.
      // ========================================================

      if (response.statusCode >= 500) {
        debugPrint(
          '[FACE LOGIN] Server returned '
          '${response.statusCode}. Will retry.',
        );

        if (mounted) {
          setState(() {
            _isChecking = true;
          });
        }

        return;
      }

      // ========================================================
      // UNEXPECTED HTTP STATUS
      // ========================================================

      debugPrint(
        '[FACE LOGIN] Unexpected HTTP status: '
        '${response.statusCode}',
      );
    } on TimeoutException {
      debugPrint(
        '[FACE LOGIN] Status polling timed out. '
        'Will retry.',
      );

      if (mounted && !_loginHandled) {
        setState(() {
          _isChecking = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint(
        '========================================',
      );
      debugPrint(
        '[FACE LOGIN] STATUS POLLING ERROR',
      );
      debugPrint(
        '[FACE LOGIN] TYPE: ${e.runtimeType}',
      );
      debugPrint(
        '[FACE LOGIN] ERROR: $e',
      );
      debugPrint(
        '[FACE LOGIN] STACK TRACE:\n$stackTrace',
      );
      debugPrint(
        '========================================',
      );

      if (mounted && !_loginHandled) {
        setState(() {
          _isChecking = true;
        });
      }
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
    if (response.body.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (e) {
      debugPrint(
        '[HTTP] JSON decode failed: $e',
      );
    }

    return null;
  }

  String _serverMessage(
    Map<String, dynamic>? data,
    String fallback,
  ) {
    if (data == null) {
      return fallback;
    }

    final message =
        data['message'] ??
        data['error'] ??
        data['detail'];

    if (message is String &&
        message.trim().isNotEmpty) {
      return message.trim();
    }

    return fallback;
  }

  // ============================================================
  // FRIENDLY ERROR
  // ============================================================

  String _friendlyFaceLoginError(
    FaceLoginException exception,
  ) {
    switch (exception.stage) {
      case 'CREATE_SESSION':
        if (exception.statusCode == 401 ||
            exception.statusCode == 403) {
          return 'SwiftCare could not authorize secure sign in. '
              'Please try again.';
        }

        if (exception.statusCode != null &&
            exception.statusCode! >= 500) {
          return 'The SwiftCare server could not start secure sign in. '
              'Please try again.';
        }

        return exception.message;

      case 'DIDIT_SDK':
        return 'The secure identity verification screen '
            'could not be opened. Please try again.';

      default:
        return 'Unable to complete secure sign in. '
            'Please try again.';
    }
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void> _handleSuccessfulLogin(
    Map<String, dynamic> data,
  ) async {
    if (_leavingPage) {
      return;
    }

    _currentPosition = null;

    if (mounted) {
      setState(() {
        _isStarting = false;
        _isChecking = false;
        _isSuccess = true;
        _diditRunning = false;
        _errorMessage = null;
      });
    }

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (_leavingPage || !mounted) {
      return;
    }

    Navigator.of(context).pop(data);
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> _retry() async {
    if (_leavingPage ||
        _requestingLocation) {
      return;
    }

    _stopPolling();

    _loginHandled = false;
    _pollInProgress = false;
    _sessionId = null;
    _currentPosition = null;

    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isStarting = false;
        _isChecking = false;
        _isSuccess = false;
        _diditRunning = false;
      });
    }

    await _prepareLocation();
  }

  // ============================================================
  // CLOSE
  // ============================================================

  void _closePage() {
    if (_leavingPage) {
      return;
    }

    _leavingPage = true;

    _stopPolling();
    _currentPosition = null;

    Navigator.of(context).pop();
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
            borderRadius:
                BorderRadius.circular(14),
            child: InkWell(
              onTap: _closePage,
              borderRadius:
                  BorderRadius.circular(14),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
              borderRadius:
                  BorderRadius.circular(14),
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
          mainAxisAlignment:
              MainAxisAlignment.center,
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
                    ? Icons
                        .face_retouching_natural_rounded
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
                child:
                    CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    _green,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color:
                    _lightGreen.withOpacity(0.55),
                borderRadius:
                    BorderRadius.circular(16),
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
          mainAxisAlignment:
              MainAxisAlignment.center,
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
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
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
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
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
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor: _darkGreen,
                  side: const BorderSide(
                    color: _border,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
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
          mainAxisAlignment:
              MainAxisAlignment.center,
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

// ================================================================
// FACE LOGIN EXCEPTION
// ================================================================

class FaceLoginException implements Exception {
  final String stage;
  final String message;
  final int? statusCode;
  final Object? originalError;

  FaceLoginException({
    required this.stage,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    return 'FaceLoginException('
        'stage=$stage, '
        'statusCode=$statusCode, '
        'message=$message, '
        'originalError=$originalError'
        ')';
  }
}