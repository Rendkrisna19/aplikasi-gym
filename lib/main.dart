import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart'; 
import 'package:intl/date_symbol_data_local.dart'; // Import ini wajib

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. PERBAIKAN: Inisialisasi Format Tanggal untuk Indonesia
  // Ini wajib dipanggil agar tidak error "Locale data has not been initialized"
  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym POS',
      // TEMA HITAM & KUNING
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFD700), // Kuning Emas
        scaffoldBackgroundColor: const Color(0xFF121212), // Hitam tidak pekat (agar nyaman)
        
        // Warna Aksen & Tombol
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700), // Kuning
          secondary: Color(0xFFFFD700),
          surface: Color(0xFF1E1E1E), // Warna Card/Input
        ),

        // Style Input Text (Form)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2C2C2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
        ),
        
        // Style Tombol Elevated
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700), // Background Kuning
            foregroundColor: Colors.black, // Teks Hitam
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: const LoginPage(), // Arahkan ke Halaman Login
    );
  }
}