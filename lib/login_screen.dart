import 'package:eatoscan/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:bcrypt/bcrypt.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Semua kolom harus diisi!');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password harus minimal 8 karakter!');
      return;
    }

    try {
      final userBox = Hive.box<UserModel>('users');
      final user = userBox.values.firstWhereOrNull(
        (u) => u.username == username,
      );

      if (user != null && BCrypt.checkpw(password, user.password)) {
        final box = Hive.box('eatoscanBox');
        await box.put('loggedInUser', username);
        await box.put('isLoggedIn', true);
        await box.put('user_name_$username', user.username);
        await box.put('user_email_$username', user.email);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/landingPage', arguments: username);
      } else {
        _showMessage('Username atau password salah!');
      }
    } catch (e) {
      _showMessage('Terjadi kesalahan saat login: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 12, 84, 16),
      body: Column(
        children: [
          const SizedBox(height: 40),
          _buildWelcomeText(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildLoginForm(),
          ),
          _buildBottomNavigationBar(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
  return Padding(
  padding: const EdgeInsets.only(left: 16, top: 5, right: 16),
  child: Stack(
    children: [
      SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              'Selamat Datang di',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'EatoScan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      IconButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, '/landingPage');
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    ],
  ),
);
}


  Widget _buildLoginForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Image.asset('assets/images/eatoscan.png', height: 60),
            const SizedBox(height: 12),
            Image.asset('assets/images/eatoscan1.png', height: 18),
            const SizedBox(height: 32),
            _buildTextField(_usernameController, 'Masukkan Nama', 'Username'),
            const SizedBox(height: 20),
            _buildTextField(_passwordController, 'Masukkan kata sandi', 'Kata Sandi', obscureText: true),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 12),
            _buildForgotPasswordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, String labelText, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _handleLogin,
        child: const Text(
          'Masuk',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {},
      child: const Text(
        'Lupa kata sandi?',
        style: TextStyle(
          fontSize: 14,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
  return Container(
    color: Colors.white, 
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity, 
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/signup');
            },
            child: const Text(
              'Belum punya akun? Daftar sekarang!',
              style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 12, 84, 16),fontWeight: FontWeight.bold),
            ),
          ),
        ),
        SizedBox(
          width: double.infinity, 
          child: TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/loginAdmin');
            },
            child: const Text(
              'Masuk sebagai admin.',
              style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 12, 84, 16),fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
} 
}