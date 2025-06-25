import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'user_model.dart';
import 'package:bcrypt/bcrypt.dart';


class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  _EditProfilPageState createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController teleponController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController kataSandiLamaController = TextEditingController();
  final TextEditingController kataSandiBaruController = TextEditingController();
  final TextEditingController konfirmasiSandiController = TextEditingController();

  late Box _eatoscanBox;
  late Box<UserModel> _userBox;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _eatoscanBox = Hive.box('eatoscanBox');
    _userBox = Hive.box<UserModel>('users');
    _loadUserData();
  }

  void _loadUserData() async {
    final isLoggedIn = _eatoscanBox.get('isLoggedIn', defaultValue: false);
    final loggedInUser = _eatoscanBox.get('loggedInUser');
    if (isLoggedIn && loggedInUser != null) {
        _currentUser = _userBox.values.firstWhere(
        (user) => user.username == loggedInUser,
        orElse: () => UserModel(username: '', email: '', password: ''),
      );
      setState(() {
        namaController.text = _currentUser!.username;
        emailController.text = _currentUser!.email;
        teleponController.text = _currentUser!.telepon ?? ''; 
      });
    }
  }


  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF265D4F), width: 2),
      ),
    );
  }

  Future<void> _simpanPerubahan() async {
    if (namaController.text.isEmpty ||
        teleponController.text.isEmpty ||
        emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mohon lengkapi semua data pengguna.')),
      );
      return;
    }

    if (kataSandiBaruController.text.isNotEmpty) {
      if (!BCrypt.checkpw(kataSandiLamaController.text, _currentUser!.password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kata sandi lama salah.')),
        );
        return;
      }

    if (kataSandiLamaController.text != _currentUser!.password) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kata sandi lama salah.')),
        );
        return;
      }

    if (kataSandiBaruController.text != konfirmasiSandiController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konfirmasi kata sandi tidak cocok.')),
      );
      return;
    }

    if (kataSandiBaruController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kata sandi baru harus minimal 8 karakter.')),
        );
        return;
      }
    }

    if (teleponController.text.isNotEmpty &&
        !RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(teleponController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format nomor telepon tidak valid.')),
      );
      return;
    }

    if (_currentUser != null) {
      _currentUser!.username = namaController.text;
      _currentUser!.email = emailController.text;
      _currentUser!.telepon = teleponController.text.isNotEmpty ? teleponController.text : null;
      if (kataSandiBaruController.text.isNotEmpty) {
        _currentUser!.password = kataSandiBaruController.text;
      }

      await _currentUser!.save();

      await _eatoscanBox.put('loggedInUser', namaController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil berhasil diperbarui.')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF265D4F),
      appBar: AppBar(
        backgroundColor: Color(0xFF265D4F),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: AssetImage('assets/images/default_profil.jpg'),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Data Pengguna',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: namaController,
                        decoration: inputStyle('Username'),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: teleponController,
                        decoration: inputStyle('Nomor Telepon'),
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: inputStyle('Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Ganti Kata Sandi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: kataSandiLamaController,
                        decoration: inputStyle('Kata Sandi Lama'),
                        obscureText: true,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: kataSandiBaruController,
                        decoration: inputStyle('Kata Sandi Baru'),
                        obscureText: true,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: konfirmasiSandiController,
                        decoration: inputStyle('Konfirmasi Kata Sandi Baru'),
                        obscureText: true,
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/lupa-kata-sandi');
                        },
                        child: Text(
                          'Lupa kata sandi?',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      SizedBox(height: 28),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF265D4F),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _simpanPerubahan,
                        child: Center(
                          child: Text(
                            'Simpan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}