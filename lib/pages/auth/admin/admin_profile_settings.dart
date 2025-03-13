import 'package:flutter/material.dart';
import 'package:libx_final/pages/login.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:libx_final/pages/auth/admin/edit_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AdminProfilePage extends StatefulWidget {
  final VoidCallback onBack;
  const AdminProfilePage({Key? key, required this.onBack}) : super(key: key);

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String? _fullName;
  String? _avatarUrl;
  String? _bio;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      if (!mounted) return;
      setState(() {
        _fullName = response['full_name'] ?? 'No Name';
        _avatarUrl = response['avatar_url'];
        _bio = response['bio'] ?? 'Admin';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print("Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 65,
      backgroundColor: primary,
      child: CircleAvatar(
        radius: 63,
        backgroundColor: Colors.grey[200],
        backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
        child: _avatarUrl == null
            ? Icon(
                Icons.person,
                size: 90,
                color: Colors.grey[400],
              )
            : null,
      ),
    );
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Skeletonizer(
        enabled: _isLoading,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Section with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 8, 83, 163),
                      Color(0xFF5CA0F2)
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const SizedBox(height: 10),
                    _buildProfileImage(),
                    const SizedBox(height: 10),
                    // Username & Status
                    Text(
                      _fullName ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _bio ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // White Menu Section
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                        Icons.edit_rounded, "Edit Profile", Colors.blue),
                    _buildMenuItem(
                        Icons.lock_rounded, "Change Password", Colors.green),
                    _buildMenuItem(Icons.account_circle_sharp,
                        "Registered Accounts", Colors.purple),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        child: const Text(
                          "Sign Out",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _logout,
                      ),
                    ),
                    const SizedBox(
                      height: 60,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add these controllers at the top of the class
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword(String newPassword) async {
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'Password updated successfully!',
        confirmBtnColor: primary,
      );
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Error updating password: $e',
        confirmBtnColor: primary,
      );
    }
  }

  Future<void> _showChangePasswordDialog() async {
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Change Password',
                style: TextStyle(
                  color: primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                cursorColor: primary,
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                cursorColor: primary,
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: primary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (_newPasswordController.text.isEmpty ||
                          _confirmPasswordController.text.isEmpty) {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.warning,
                          text: 'Please fill in all fields',
                          confirmBtnColor: primary,
                        );
                        return;
                      }
                      if (_newPasswordController.text ==
                          _confirmPasswordController.text) {
                        Navigator.pop(context);
                        await _updatePassword(_newPasswordController.text);
                      } else {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          text: 'Passwords do not match!',
                          confirmBtnColor: primary,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, Color iconColor) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      onTap: () async {
        switch (title) {
          case "Edit Profile":
            final shouldRefresh = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfilePage(),
              ),
            );
            if (shouldRefresh == true) {
              _loadUserProfile();
            }
            break;
          case "Change Password":
            await _showChangePasswordDialog();
            break;
          case "Registered Accounts":
            // Add registered accounts navigation
            break;
        }
      },
    );
  }
}
