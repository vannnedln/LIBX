import 'package:flutter/material.dart';
import 'package:libx_final/pages/auth/admin/root_app.dart';

import 'package:libx_final/pages/login.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://htwnelpqhxdwpfaytdzq.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh0d25lbHBxaHhkd3BmYXl0ZHpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA0NzY1NjUsImV4cCI6MjA1NjA1MjU2NX0.NKWA7Vufm4-t8rfMu90F7f0_kYQt4alzNxKKNzQhO1s',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final supabase = Supabase.instance.client;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  void _navigateAfterSplash() {
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
      ),
      home: _showSplash
          ? Scaffold(
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50.0, vertical: 10.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 1),
                          duration: const Duration(seconds: 3),
                          curve: Curves.easeInOut,
                          builder: (context, value, child) =>
                              LinearProgressIndicator(
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
            )
          : supabase.auth.currentSession == null
              ? const LoginPage()
              : const RootApp(),
    );
  }
}
