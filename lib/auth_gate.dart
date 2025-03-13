import 'package:flutter/material.dart';

import 'package:libx_final/pages/auth/admin/root_app.dart';
import 'package:libx_final/pages/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    // Return LoginPage or RootApp instead of HomePage
    return session == null ? const LoginPage() : const RootApp();
  }
}
