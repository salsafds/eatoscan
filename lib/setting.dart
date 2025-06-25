import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profil.dart';
import 'edit_riwayat_kesehatan.dart';

void main() {
  runApp(MaterialApp(
    home: SettingPage(),
  ));
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  File? _profileImage;
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final box = Hive.box('eatoscanBox');
      
      _isLoggedIn = box.get('isLoggedIn', defaultValue: false);
      final currentUser = box.get('loggedInUser');
      
      print('Status login: $_isLoggedIn');
      print('Current user: $currentUser');
      
      if (_isLoggedIn && currentUser != null) {
        String? userName;
        String? userEmail;
        
        final currentUserData = box.get('current_user_data');
        if (currentUserData != null) {
          userName = currentUserData['name'] ?? currentUserData['username'];
          userEmail = currentUserData['email'];
          print('Data dari current_user_data: $currentUserData');
        }
        
        if (userName == null || userEmail == null) {
          userName = box.get('user_name_$currentUser') ?? 
                   prefs.getString('current_name');
          userEmail = box.get('user_email_$currentUser') ?? 
                     prefs.getString('current_email');
          print('Data dari key terpisah: name=$userName, email=$userEmail');
        }
        
        if (userName == null || userEmail == null) {
          try {
            final userBox = Hive.box('users');
            final userData = userBox.get(currentUser);
            if (userData != null) {
              userName = userData['name'] ?? userData['username'] ?? currentUser;
              userEmail = userData['email'] ?? 'No email';
              print('Data dari user box: $userData');
            }
          } catch (e) {
            print('Error mengakses user box: $e');
          }
        }
        
        setState(() {
          _userName = userName ?? currentUser;
          _userEmail = userEmail ?? 'No email available';
        });
        
        final imagePath = prefs.getString('profile_picture_$currentUser') ?? 
                         prefs.getString('profile_picture');
        
        if (imagePath != null && File(imagePath).existsSync()) {
          setState(() {
            _profileImage = File(imagePath);
          });
        }
        
      } else {
        setState(() {
          _userName = 'Guest';
          _userEmail = 'Silakan login untuk melihat profil';
          _isLoggedIn = false;
        });
      }
      
    } catch (e) {
      print('Error loading profile data: $e');
      setState(() {
        _userName = 'Error loading data';
        _userEmail = 'Please try again';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (!_isLoggedIn) {
      _showMessage('Silakan login terlebih dahulu');
      return;
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditProfilPage()),
    );
    _loadProfileData(); 
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLogoutDialog() {
    if (!_isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Apakah Anda yakin ingin keluar dari akun ini?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      
                      final box = Hive.box('eatoscanBox');
                      await box.delete('loggedInUser');
                      await box.delete('current_user_data');
                      await box.put('isLoggedIn', false);
                      
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.remove('current_username');
                      await prefs.remove('current_name');
                      await prefs.remove('current_email');
                      
                      Navigator.pushNamedAndRemoveUntil(
                        context, 
                        '/landingPage',
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text('Ya', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Tidak', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F684A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pushReplacementNamed(context, '/landingPage'),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Pengaturan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 24),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _profileImage != null
                                      ? FileImage(_profileImage!)
                                      : const AssetImage('assets/images/default_profil.jpg')
                                          as ImageProvider,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _userEmail,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isLoggedIn ? Colors.green[100] : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _isLoggedIn ? 'Logged In' : 'Guest Mode',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isLoggedIn ? Colors.green[700] : Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildMenuItem(Icons.person, 'Edit Profil', _navigateToEditProfile),
                                _buildMenuItem(Icons.favorite_border, 'Edit Riwayat Kesehatan', () {
                                  if (!_isLoggedIn) {
                                    _showMessage('Silakan login terlebih dahulu');
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const EditRiwayatKesehatanPage()),
                                  );
                                }),
                                _buildMenuItem(
                                  _isLoggedIn ? Icons.logout : Icons.login, 
                                  _isLoggedIn ? 'Keluar' : 'Masuk', 
                                  _showLogoutDialog
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Image.asset(
                              'assets/images/eatoscan1.png',
                              height: 40,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: onTap,
        ),
        const Divider(),
      ],
    );
  }
}