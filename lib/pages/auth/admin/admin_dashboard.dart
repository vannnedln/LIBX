import 'package:flutter/material.dart';

import 'package:libx_final/pages/auth/user/user_root_app.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserRootApp(
                      firstName: 'Admin',
                    ),
                  ),
                );
              },
              child: const Text('Go to User Homepage'),
            ),
            SizedBox(height: 10),
            Text('hello nigga'),
          ],
        ),
      ),
    );
  }
}
