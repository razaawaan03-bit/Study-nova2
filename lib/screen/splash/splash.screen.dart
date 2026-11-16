import 'dart:async';

import 'package:flutter/material.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/welcome/welcome_screen.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _goNext);
  }

  void _goNext() {
    if (!mounted) return;

    // Session restoration: a student who is already signed in goes straight
    // to Home instead of being asked to log in again on every launch.
    final Widget next = AuthService().isLoggedIn
        ? const HomeScreen()
        : const WelcomeScreen();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => next));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/study_nova.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.school,
                    size: 100,
                    color: Colors.blue.shade700,
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // App Name
            Text(
              'Study Nova',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 10),

            // Tagline
            Text(
              'Study Smarter Every Day',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
