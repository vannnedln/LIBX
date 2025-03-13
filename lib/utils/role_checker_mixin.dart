import 'package:flutter/material.dart';
import 'package:libx_final/pages/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

mixin RoleCheckerMixin<T extends StatefulWidget> on State<T> {
  bool _isChecking = true;

  Future<void> checkRole(String expectedRole) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

      final userData = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      if (userData['role'] != expectedRole) {
        _redirectToLogin();
      }
    } catch (e) {
      if (mounted) _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }
}