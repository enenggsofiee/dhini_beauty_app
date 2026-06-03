import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';
import '../utils/glassmorphism.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _user = {};
  bool _isLoading = true;
  String? _profileImagePath;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('user_id') ?? 0;
    
    if (userId != 0) {
      final result = await _apiService.getUserData(userId);
      if (result['success']) {
        setState(() {
          _user = result['user'];
          if (_user['profile_image'] != null && 
              _user['profile_image'].toString() != 'null' && 
              _user['profile_image'].toString().isNotEmpty) {
            _profileImagePath = '${Constants.baseUrl}/../uploads/profiles/${_user['profile_image']}';
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() => _isLoading = true);
      
      File file = File(image.path);
      List<int> imageBytes = await file.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      
      int userId = int.tryParse(_user['id'].toString()) ?? 0;
      final result = await _apiService.uploadProfileImage(userId, base64Image);
      
      if (result['success']) {
        await _loadUserData(); // Reload data
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      }
    }
  }

  Future<void> _linkGoogleAccount() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase
        final UserCredential userCredential = 
            await FirebaseAuth.instance.signInWithCredential(credential);
        final User? firebaseUser = userCredential.user;

        if (firebaseUser != null && firebaseUser.email != null) {
          final String googleEmail = firebaseUser.email!;
          int userId = int.tryParse(_user['id'].toString()) ?? 0;
          
          final result = await _apiService.linkGoogleAccount(userId, googleEmail);

          if (result['success']) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Berhasil menautkan akun Google!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
            await _loadUserData(); // Reload user data
          } else {
            setState(() => _isLoading = false);
            _showErrorSnackBar(result['message'] ?? 'Gagal menautkan akun Google');
          }
        } else {
          setState(() => _isLoading = false);
          _showErrorSnackBar('Gagal mendapatkan email Google');
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (error) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Google Link failed: $error');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 30),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sign Out',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Constants.textDark),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to sign out?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Constants.textLight, fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: Constants.textLight),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Constants.textDark, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, anim, secAnim) => const LoginScreen(),
            transitionsBuilder: (context, anim, secAnim, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Constants.primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Constants.textDark),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, color: Constants.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Profile Avatar
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Constants.primaryColor.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: ClipOval(
                              child: _profileImagePath != null && _profileImagePath!.startsWith('http')
                                  ? Image.network(
                                      _profileImagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Constants.secondaryColor,
                                        child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
                                      ),
                                    )
                                  : Container(
                                      color: Constants.secondaryColor,
                                      child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Constants.primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _user['nama_lengkap']?.toString() ?? 'User',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Constants.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${_user['username']?.toString() ?? 'unknown'}',
                      style: const TextStyle(color: Constants.textLight, fontSize: 16),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Settings List
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        children: [
                          _buildSettingItem(
                            icon: Icons.phone_rounded,
                            title: 'Phone Number',
                            subtitle: (_user['no_telepon']?.toString() ?? '').isEmpty 
                                ? 'Not set' 
                                : _user['no_telepon'].toString(),
                          ),
                          const Divider(height: 1, color: Colors.black12, indent: 64, endIndent: 24),
                          _buildSettingItem(
                            icon: Icons.email_rounded,
                            title: 'Google Account',
                            subtitle: (_user['email']?.toString() ?? '').isNotEmpty 
                                ? _user['email'].toString() 
                                : 'Belum ditautkan',
                            trailing: (_user['email']?.toString() ?? '').isNotEmpty
                                ? const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                      SizedBox(width: 4),
                                      Text('Terhubung', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                : ElevatedButton(
                                    onPressed: _linkGoogleAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Constants.primaryColor.withOpacity(0.15),
                                      foregroundColor: Constants.primaryColor,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Tautkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                          ),
                          const Divider(height: 1, color: Colors.black12, indent: 64, endIndent: 24),
                          _buildSettingItem(
                            icon: Icons.shield_rounded,
                            title: 'Privacy & Security',
                            isLink: true,
                          ),
                          const Divider(height: 1, color: Colors.black12, indent: 64, endIndent: 24),
                          _buildSettingItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Help & Support',
                            isLink: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Padding for bottom nav
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    bool isLink = false,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Constants.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Constants.primaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, color: Constants.textDark),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(subtitle, style: const TextStyle(color: Constants.textLight)),
            )
          : null,
      trailing: trailing ?? (isLink ? const Icon(Icons.chevron_right_rounded, color: Constants.textLight) : null),
      onTap: isLink ? () {} : null, // Mock tap for links
    );
  }
}