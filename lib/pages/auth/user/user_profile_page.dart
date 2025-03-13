import 'package:flutter/material.dart';
import 'package:libx_final/pages/auth/user/borrowed_books_page.dart';
import 'package:libx_final/pages/auth/user/favorite_books_page.dart';
import 'package:libx_final/pages/auth/user/user_root_app.dart';
import 'package:libx_final/pages/login.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:libx_final/pages/auth/user/user_edit_profile.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
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
        _bio = response['bio'] ?? 'User';
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
                Icons.person_rounded,
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

  Widget _buildMenuItem(IconData icon, String title, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        if (title == "Change Password") {
          _showChangePasswordDialog();
        } else if (title == "Edit Profile") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserEditProfilePage(),
            ),
          ).then((value) {
            if (value == true) {
              _loadUserProfile();
            }
          });
        } else if (title == "My Borrowed Books") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BorrowedBooksPage(),
            ),
          );
        } else if (title == "My Favorites") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FavoriteBooksPage(),
            ),
          );
        }
      },
    );
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
                    _buildProfileImage(),
                    const SizedBox(height: 10),
                    Text(
                      _fullName ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _bio ?? 'User',
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
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                    const SizedBox(height: 10),
                    _buildMenuItem(
                        Icons.edit_rounded, "Edit Profile", Colors.blue),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                        Icons.lock_rounded, "Change Password", Colors.green),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                        Icons.favorite_rounded, "My Favorites", Colors.red),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[400],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Sign Out",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Password change functionality
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
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_newPasswordController.text.isEmpty ||
                          _confirmPasswordController.text.isEmpty) {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          text: 'Please fill in all fields',
                          confirmBtnColor: primary,
                        );
                        return;
                      }
                      if (_newPasswordController.text !=
                          _confirmPasswordController.text) {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          text: 'Passwords do not match',
                          confirmBtnColor: primary,
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _updatePassword(_newPasswordController.text);
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
}
