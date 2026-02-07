import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/admin/admin_layout.dart'; // Import Layout Admin
import 'pages/pos/pos_layout.dart';     // Import Layout POS (YANG DITAMBAHKAN)

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  // Controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _isObscure = true; 
  final _formKey = GlobalKey<FormState>();

  // Animation Controller
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Setup Animasi saat halaman dibuka
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Mulai animasi
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- LOGIC LOGIN ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Auth ke Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Cek Role di Firestore
      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String role = userDoc.get('role');
        
        if (!mounted) return;

        // --- LOGIKA PEMBAGIAN ROLE ---
        if (role == 'admin') {
          // JIKA ADMIN -> KE DASHBOARD ADMIN
          _showSuccessSnackbar("Welcome back, Admin!");
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const AdminLayout())
          );

        } else if (role == 'pos') {
          // JIKA POS / KASIR -> KE POS LAYOUT (UPDATED)
          _showSuccessSnackbar("Login Kasir Berhasil");
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const PosLayout())
          );
          
        } else {
          _showError("Role akun tidak valid/tidak aktif.");
          await FirebaseAuth.instance.signOut();
        }

      } else {
        _showError("Data user tidak ditemukan di database.");
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login Gagal";
      if (e.code == 'user-not-found') message = "Email tidak terdaftar.";
      if (e.code == 'wrong-password') message = "Password salah.";
      if (e.code == 'invalid-email') message = "Format email salah.";
      if (e.code == 'too-many-requests') message = "Terlalu banyak percobaan. Coba lagi nanti.";
      _showError(message);
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showSuccessSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fallback color
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF050505), // Hampir Hitam
                  Color(0xFF1A1A1A), // Abu Sangat Gelap
                  Color(0xFF000000), // Hitam
                ],
              ),
            ),
          ),

          // 2. GLOW EFFECT (Atas Kiri)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withOpacity(0.1), // Kuning Pudar
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 3. GLOW EFFECT (Bawah Kanan - Penyeimbang)
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.05), // Sedikit biru untuk kontras elegan
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // 4. KONTEN UTAMA (CENTER CARD)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // LOGO & TEXT HEADER
                      Hero(
                        tag: 'logo',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 50,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "GYM POS SYSTEM",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Manage your gym professionally",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                      ),
                      
                      const SizedBox(height: 40),

                      // CARD GLASSMORPHISM
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 400),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03), // Lebih transparan
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // INPUT EMAIL
                              const Text("Email", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) => value!.isEmpty ? "Email required" : null,
                                decoration: _inputDecoration("ex: admin@gym.com", Icons.email_outlined),
                              ),
                              
                              const SizedBox(height: 20),

                              // INPUT PASSWORD
                              const Text("Password", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isObscure,
                                style: const TextStyle(color: Colors.white),
                                validator: (value) => value!.isEmpty ? "Password required" : null,
                                decoration: _inputDecoration("••••••", Icons.lock_outline).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isObscure ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() => _isObscure = !_isObscure),
                                  ),
                                ),
                              ),

                              // LUPA PASSWORD (Visual)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Reset Password belum aktif")));
                                  },
                                  child: Text(
                                    "Forgot Password?",
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // TOMBOL LOGIN (GRADIENT ANIMATED)
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    backgroundColor: Colors.transparent,
                                    shadowColor: const Color(0xFFFFD700).withOpacity(0.3),
                                    elevation: 8,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)], // Emas ke Oranye
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: _isLoading 
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                        : const Text(
                                            "LOGIN", // Text diubah jadi LOGIN agar netral untuk Admin/POS
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      Text(
                        "© 2024 Gym POS System v1.0",
                        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk Style Input
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
      prefixIcon: Icon(icon, color: const Color(0xFFFFD700), size: 20),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }
}