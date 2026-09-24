import 'package:flutter/material.dart';

import 'face_verification_page.dart';
import '../services/auth_storage.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // ============================================================
  // COLORS
  // ============================================================

  static const Color forestGreen = Color(0xFF1B5E20);
  static const Color darkGreen = Color(0xFF124116);
  static const Color logoGreen = Color(0xFF155F30);
  static const Color limeGreen = Color(0xFF8BC34A);
  static const Color lightGreen = Color(0xFFDCEDC8);
  static const Color paleGreen = Color(0xFFF0FDF4);
  static const Color borderGreen = Color(0xFFD5E7D6);
  static const Color textGreen = Color(0xFF4B6350);

  // ============================================================
  // FACE VERIFICATION
  // ============================================================

  Future<void> _openFaceVerification(
    BuildContext context,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FaceVerificationPage(),
      ),
    );

    if (result == null) {
      return;
    }

    if (result is! Map) {
      return;
    }

    final data = Map<String, dynamic>.from(result);

    final authenticated =
        data['authenticated'] == true;

    final token =
        data['token']?.toString();

    if (!authenticated ||
        token == null ||
        token.isEmpty) {
      return;
    }

    // ============================================================
    // SAVE VOLUNTEER LOGIN
    // ============================================================

    await AuthStorage.saveLogin(
      token: token,

      volunteerId:
          data['volunteerId']?.toString(),

      volunteerNumber:
          data['volunteerNumber']?.toString(),

      firstName:
          data['firstName']?.toString(),

      lastName:
          data['lastName']?.toString(),

      email:
          data['email']?.toString(),

      userName:
          data['userName']?.toString(),

      role:
          data['role']?.toString(),

      onboardingId:
          data['onboardingId']?.toString(),
    );

    // ============================================================
    // SAVE ATTENDANCE
    //
    // Backend response:
    //
    // attendance = {
    //   checkedIn,
    //   alreadyCheckedIn,
    //   status,
    //   message,
    //   attendanceId,
    //   volunteerRosterShiftId,
    //   checkInTime,
    //   lateMinutes
    // }
    // ============================================================

    final attendanceData =
        data['attendance'];

    if (attendanceData is Map) {
      final attendance =
          Map<String, dynamic>.from(attendanceData);

      await AuthStorage.saveAttendance(
        checkedIn:
            attendance['checkedIn'] == true,

        alreadyCheckedIn:
            attendance['alreadyCheckedIn'] == true,

        status:
            attendance['status']?.toString(),

        message:
            attendance['message']?.toString(),

        attendanceId:
            int.tryParse(
          attendance['attendanceId']?.toString() ?? '',
        ),

        volunteerRosterShiftId:
            int.tryParse(
          attendance['volunteerRosterShiftId']?.toString() ?? '',
        ),

        checkInTime:
            attendance['checkInTime']?.toString(),

        lateMinutes:
            int.tryParse(
          attendance['lateMinutes']?.toString() ?? '',
        ),
      );
    } else {
      // ==========================================================
      // NO ATTENDANCE OBJECT
      //
      // Clear any previous attendance information so that an old
      // check-in status is not displayed for the new login.
      // ==========================================================

      await AuthStorage.clearAttendance();
    }

    // ============================================================
    // MAKE SURE LOGIN PAGE IS STILL MOUNTED
    // ============================================================

    if (!context.mounted) {
      return;
    }

    // ============================================================
    // GO TO HOME
    // ============================================================

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paleGreen,

      body: SafeArea(
        child: Stack(
          children: [

            // ======================================================
            // DECORATIVE LIME GREEN CIRCLE - TOP RIGHT
            // ======================================================

            Positioned(
              top: -90,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: limeGreen.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ======================================================
            // DECORATIVE LIGHT GREEN CIRCLE - BOTTOM LEFT
            // ======================================================

            Positioned(
              bottom: -110,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: lightGreen.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ======================================================
            // MAIN CONTENT
            // ======================================================

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [

                    // ==================================================
                    // SWIFTCARE LOGO
                    // ==================================================

                    Container(
                      width: 95,
                      height: 95,

                      decoration: BoxDecoration(
                        color: limeGreen,
                        borderRadius:
                            BorderRadius.circular(26),

                        boxShadow: [
                          BoxShadow(
                            color:
                                limeGreen.withOpacity(0.20),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),

                      child: const Center(
                        child: Icon(
                          Icons.monitor_heart_rounded,
                          size: 50,
                          color: logoGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ==================================================
                    // WELCOME
                    // ==================================================

                    const Text(
                      'Welcome back',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: forestGreen,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Sign in securely to your SwiftCare volunteer account.',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        fontSize: 16,
                        color: textGreen,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ==================================================
                    // SECURE CHECK-IN CARD
                    // ==================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),

                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.94),

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
                            blurRadius: 30,
                            offset:
                                const Offset(0, 12),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [

                          // ==================================================
                          // FACE ICON CONTAINER
                          // ==================================================

                          Container(
                            width: 86,
                            height: 86,

                            decoration: BoxDecoration(
                              color: lightGreen,
                              shape: BoxShape.circle,

                              border: Border.all(
                                color:
                                    limeGreen.withOpacity(0.45),
                                width: 2,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color:
                                      limeGreen.withOpacity(0.12),
                                  blurRadius: 18,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),

                            child: const Icon(
                              Icons.face_retouching_natural,
                              size: 46,
                              color: forestGreen,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ==================================================
                          // TITLE
                          // ==================================================

                          const Text(
                            'Secure Check-In',
                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: const [

                              // ==================================================
                              // STEP 1
                              // ==================================================

                              _StepItem(
                                text: 'Scan your face',
                              ),

                              SizedBox(height: 10),

                              // ==================================================
                              // STEP 2
                              // ==================================================

                              _StepItem(
                                text: 'Sign in',
                              ),

                              SizedBox(height: 10),

                              // ==================================================
                              // STEP 3
                              // ==================================================

                              _StepItem(
                                text:
                                    'Check-In & Start Working',
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ==================================================
                          // CONTINUE SECURELY BUTTON
                          // ==================================================

                          SizedBox(
                            width: double.infinity,
                            height: 58,

                            child: ElevatedButton(
                              onPressed: () =>
                                  _openFaceVerification(
                                context,
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
                                    18,
                                  ),
                                ),
                              ),

                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,

                                children: [

                                  // Lime accent behind icon
                                  Container(
                                    width: 34,
                                    height: 34,

                                    decoration:
                                        BoxDecoration(
                                      color: limeGreen,
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),

                                    child: const Icon(
                                      Icons
                                          .face_retouching_natural,
                                      size: 21,
                                      color: logoGreen,
                                    ),
                                  ),

                                  const SizedBox(width: 11),

                                  const Text(
                                    'Continue Securely',

                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ==================================================
                          // SECURITY MESSAGE
                          // ==================================================

                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),

                            decoration: BoxDecoration(
                              color:
                                  lightGreen.withOpacity(0.45),

                              borderRadius:
                                  BorderRadius.circular(14),

                              border: Border.all(
                                color:
                                    limeGreen.withOpacity(0.25),
                              ),
                            ),

                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              children: const [

                                Icon(
                                  Icons.lock_outline,
                                  size: 17,
                                  color: Color(0xFF2E7D32),
                                ),

                                SizedBox(width: 7),

                                Flexible(
                                  child: Text(
                                    'Your biometric verification is securely processed.',
                                    textAlign:
                                        TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Color(0xFF657568),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ==================================================
                    // FOOTER
                    // ==================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,

                      children: [

                        Container(
                          width: 8,
                          height: 8,

                          decoration:
                              const BoxDecoration(
                            color: limeGreen,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          'SwiftCare Volunteer Portal',

                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF718074),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          width: 8,
                          height: 8,

                          decoration:
                              const BoxDecoration(
                            color: limeGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STEP ITEM
// ============================================================

class _StepItem extends StatelessWidget {
  final String text;

  const _StepItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        // ==================================================
        // LIME DOT
        // ==================================================

        Container(
          width: 9,
          height: 9,

          decoration: const BoxDecoration(
            color: LoginPage.limeGreen,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 12),

        // ==================================================
        // TEXT
        // ==================================================

        Expanded(
          child: Text(
            text,

            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5B6F60),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}