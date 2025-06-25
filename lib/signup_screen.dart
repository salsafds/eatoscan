import 'package:eatoscan/user_model.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:bcrypt/bcrypt.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _konfirController = TextEditingController();
  
    void _submitForm() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final verifikasiPassword = _konfirController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || verifikasiPassword.isEmpty) {
      _showMessage('Semua kolom harus diisi!');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password harus minimal 8 karakter!');
      return;
    }

    if (password != verifikasiPassword) {
      _showMessage('Password tidak cocok!');
      return;
    }

    if (!RegExp(r"^[\w\.-]+@[\w\.-]+\.\w{2,4}$").hasMatch(email)) {
      _showMessage('Format email tidak valid!');
      return;
    }

    try {
      final userBox = Hive.box<UserModel>('users');

      final isExist = userBox.values.any((u) => u.username == username || u.email == email);
      if (isExist) {
        _showMessage('Username atau email sudah digunakan!');
        return;
      }

      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      final newUser = UserModel(
        username: username,
        email: email,
        password: hashedPassword, 
      );
      await userBox.add(newUser);
      _showMessage('Akun berhasil dibuat!');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      _showMessage('Gagal menyimpan: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: 24), 
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Selamat Datang di',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 24), 
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'EatoScan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
            _buildTextField(_usernameController, 'Masukkan nama', 'Nama'),
            const SizedBox(height: 32),
            _buildTextField(_emailController, 'abcd@gmail.com', 'Email'),
            const SizedBox(height: 20),
            _buildTextField(_passwordController, 'Masukkan kata sandi', 'Kata Sandi', obscureText: true),
            const SizedBox(height: 32),
            _buildTextField(_konfirController, 'Masukkan kata sandi', 'Konfirmasi Kata Sandi', obscureText: true),
            const SizedBox(height: 24),
            _buildLoginButton(),
            const SizedBox(height: 12),
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
        onPressed: _submitForm,
        child: const Text(
          'Daftar',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(255, 255, 255, 255),
          ),
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
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text(
              'Sudah punya akun? masuk sekarang!',
              style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 12, 84, 16),fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
} 
}