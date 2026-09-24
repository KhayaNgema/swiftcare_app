import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swiftcare_volunteer_app/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // =========================================================
    // LOGO ANIMATION
    // =========================================================

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    // =========================================================
    // SHOW SPLASH FOR 3 SECONDS
    // =========================================================

    Timer(
      const Duration(seconds: 3),
      _goToLogin,
    );
  }

  // =========================================================
  // REDIRECT TO LOGIN
  // =========================================================

  void _goToLogin() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),

        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const LoginPage();
        },

        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF155F30);
    const Color limeGreen = Color(0xFFA8FF2A);

    return Scaffold(
      backgroundColor: darkGreen,

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF155F30),
              Color(0xFF176B35),
              Color(0xFF0F5128),
            ],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,

              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,

                  child: Transform.scale(
                    scale: _scaleAnimation.value,

                    child: child,
                  ),
                );
              },

              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  // =================================================
                  // SWIFTCARE LOGO
                  // =================================================

                  Container(
                    width: 125,
                    height: 125,

                    decoration: BoxDecoration(
                      color: limeGreen,
                      borderRadius: BorderRadius.circular(32),

                      boxShadow: [
                        BoxShadow(
                          color: limeGreen.withOpacity(0.20),
                          blurRadius: 35,
                          spreadRadius: 5,
                        ),
                      ],
                    ),

                    child: const Center(
                      child: Icon(
                        Icons.monitor_heart_rounded,
                        size: 65,
                        color: Color(0xFF155F30),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =================================================
                  // APP NAME
                  // =================================================

                  const Text(
                    'SwiftCare',

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 7),

                  // =================================================
                  // SUBTITLE
                  // =================================================

                  const Text(
                    'Nursing Home Management',

                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 55),

                  // =================================================
                  // LOADING INDICATOR
                  // =================================================

                  SizedBox(
                    width: 230,

                    child: Column(
                      children: [

                        Container(
                          height: 6,

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),

                            child: const LinearProgressIndicator(
                              minHeight: 6,

                              backgroundColor: Colors.transparent,

                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                limeGreen,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        const Text(
                          'Loading SwiftCare...',

                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}