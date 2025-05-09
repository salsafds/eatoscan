import 'signup_screen.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
// import halaman lain jika sudah ada: scan_screen.dart, informasi_screen.dart, rekomendasi_screen.dart, profil_screen.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EatoScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        // Tambahkan route lainnya di sini jika file-nya sudah dibuat
        // '/scan': (context) => ScanScreen(),
        // '/info': (context) => InformasiScreen(),
        // '/rekom': (context) => RekomendasiScreen(),
        // '/profil': (context) => ProfilScreen(),
      },
      // Gunakan onGenerateRoute untuk meng-handle route yang butuh arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/dashboard') {
          final username = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => DashboardScreen(username: username),
          );
        }
        return null;
      },
    );
  }
}
