import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:quickalert/quickalert.dart';
import 'package:skeletonizer/skeletonizer.dart';

class UserEditProfilePage extends StatefulWidget {
  const UserEditProfilePage({super.key});

  @override
  State<UserEditProfilePage> createState() => _UserEditProfilePageState();
}

class _UserEditProfilePageState extends State<UserEditProfilePage> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _uploadImage() async {
    try {
      setState(() => _isLoading = true);

      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      _imageFile = File(pickedFile.path);
      final String path = await _uploadToSupabase(_imageFile!);
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Error uploading image: $e',
          confirmBtnColor: primary,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadToSupabase(File imageFile) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String filePath = 'user_image/$fileName';

    try {
      await Supabase.instance.client.storage
          .from('libx_image')
          .upload(filePath, imageFile);

      final String imageUrl = Supabase.instance.client.storage
          .from('libx_image')
          .getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      throw 'Error uploading to Supabase: $e';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _profileImageUrl;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() => _isLoadingProfile = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      setState(() {
        _fullNameController.text = response['full_name'] ?? '';
        _bioController.text = response['bio'] ?? '';
        _emailController.text = user.email ?? '';
        _profileImageUrl = response['avatar_url'];
        _isLoadingProfile = false;
      });
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Error loading profile: $e',
          confirmBtnColor: primary,
        );
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = true, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          cursorColor: primary,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: primary),
            hintText: 'Enter your $label',
            filled: enabled,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: primary),
              borderRadius: BorderRadius.circular(15),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(15),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _updateProfile() async {
    try {
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final updates = {
        'id': user.id,
        'full_name': _fullNameController.text,
        'bio': _bioController.text,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_imageFile != null) {
        final String imageUrl = await _uploadToSupabase(_imageFile!);
        updates['avatar_url'] = imageUrl;
      }

      await Supabase.instance.client.from('profiles').upsert(updates);

      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success',
          text: 'Profile updated successfully!',
          confirmBtnColor: primary,
          onConfirmBtnTap: () {
            Navigator.pop(context);
            Navigator.pop(context, true);
          },
        );
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Error updating profile: $e',
          confirmBtnColor: primary,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: secondary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Skeletonizer(
        enabled: _isLoadingProfile,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: secondary, width: 2),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(secondary),
                            )
                          : CircleAvatar(
                              radius: 58,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_profileImageUrl != null
                                      ? NetworkImage(_profileImageUrl!)
                                      : null) as ImageProvider<Object>?,
                              child: (_imageFile == null &&
                                      _profileImageUrl == null)
                                  ? Icon(
                                      Icons.person,
                                      size: 90,
                                      color: Colors.grey[400],
                                    )
                                  : null,
                            ),
                    ),
                    if (!_isLoadingProfile)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _uploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Full Name', _fullNameController),
                    _buildTextField('Bio', _bioController, maxLines: 3),
                    _buildTextField('Email', _emailController, enabled: false),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
