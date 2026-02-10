import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Pastikan tambah package ini di pubspec.yaml
import 'pages/admin/admin_layout.dart';
import 'pages/pos/pos_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  // Controller & State
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isObscure = true;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // --- LOGIN LOGIC (SAMA SEPERTI SEBELUMNYA) ---
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String role = userDoc.get('role');
        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminLayout()));
        } else if (role == 'pos') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PosLayout()));
        } else {
          _showError("Role tidak valid");
          await FirebaseAuth.instance.signOut();
        }
      } else {
        _showError("User tidak ditemukan");
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login Gagal");
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black, // Fallback color
        body: Stack(
          children: [
            // 1. BACKGROUND FULL IMAGE
            Positioned.fill(
              child: Image.asset(
                'assets/images/login.jpg', // Ganti dengan gambar background gym Anda
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                   // Fallback jika gambar background gagal load
                   return Container(color: const Color(0xFF121212));
                },
              ),
            ),

            // 2. OVERLAY GRADIENT (Agar teks terbaca jelas)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3), // Atas agak terang
                      Colors.black.withOpacity(0.8), // Tengah gelap
                      Colors.black.withOpacity(0.95), // Bawah sangat gelap
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 3. KONTEN UTAMA
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        
                        // LOGO & JUDUL (Kiri Atas / Tengah sesuai selera, ini versi Clean Left-Align)
                        Row(
                          children: [
                            // Logo Tanpa Background
                            Image.asset(
                              'assets/images/logo.png',
                              width: 50,
                              height: 50,
                              fit: BoxFit.contain,
                              errorBuilder: (_,__,___) => const Icon(Icons.fitness_center, color: Color(0xFFFFD700), size: 40),
                            ),
                            const SizedBox(width: 15),
                            // Nama App Font Poppins
                            Text(
                              "ETNIC GYM APP",
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24, // Ukuran font besar
                                  fontWeight: FontWeight.w800, // Extra Bold
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(), // Dorong Form ke Bawah

                        // TEKS SAMBUTAN
                        Text(
                          "Welcome Back,\nLet's Get Started!",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Sign in to manage your gym dashboard.",
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // FORM INPUT
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTransparentInput(
                                controller: _emailController,
                                hint: "Email Address",
                                icon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 20),
                              _buildTransparentInput(
                                controller: _passwordController,
                                hint: "Password",
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // TOMBOL LOGIN FULL WIDTH
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700), // Kuning Emas
                              foregroundColor: Colors.black, // Teks Hitam
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                                : Text(
                                    "SIGN IN",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 50), // Jarak bawah agar tidak terlalu mepet
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET INPUT TRANSPARAN (GLASS STYLE)
  Widget _buildTransparentInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Efek Blur Kaca
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // Transparan Putih
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: isPassword ? _isObscure : false,
            style: GoogleFonts.poppins(color: Colors.white),
            cursorColor: const Color(0xFFFFD700),
            validator: (val) => val!.isEmpty ? "" : null, // Validasi diam (hanya merah border)
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(color: Colors.white38),
              prefixIcon: Icon(icon, color: Colors.white70, size: 22),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(_isObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white30),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              errorStyle: const TextStyle(height: 0), // Sembunyikan teks error default
            ),
          ),
        ),
      ),
    );
  }
}