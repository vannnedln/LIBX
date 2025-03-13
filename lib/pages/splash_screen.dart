import 'package:flutter/material.dart';
import 'package:libx_final/pages/auth/admin/root_app.dart';

import 'package:libx_final/pages/login.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      final session = supabase.auth.currentSession;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              session == null ? const LoginPage() : const RootApp(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 40, 40, 10),
              child: LottieBuilder.asset(
                "assets/lottie/Animation - 1740913255854.json",
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 50.0, vertical: 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) => LinearProgressIndicator(
                    minHeight: 10,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                    value: value,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
