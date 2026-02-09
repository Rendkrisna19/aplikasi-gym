import 'dart:convert'; // Untuk Base64
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../login_page.dart';

class PosProfilePage extends StatefulWidget {
  const PosProfilePage({super.key});

  @override
  State<PosProfilePage> createState() => _PosProfilePageState();
}

class _PosProfilePageState extends State<PosProfilePage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 1. LOAD DATA USER
  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'] ?? '';
        _imageBase64 = doc['profileImage'];
      });
    }
  }

  // 2. GANTI FOTO (BASE64)
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 25, // Kompres
        maxWidth: 400,
      );

      if (image != null) {
        Uint8List imageBytes = await image.readAsBytes();
        String base64String = base64Encode(imageBytes);

        if (base64String.length > 900000) { 
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gambar terlalu besar!"), backgroundColor: Colors.red));
          return;
        }

        setState(() {
          _imageBase64 = base64String;
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // 3. SIMPAN PERUBAHAN PROFILE
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'name': _nameController.text,
        'profileImage': _imageBase64,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diupdate!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 4. FITUR GANTI PASSWORD (POPUP)
  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isObscure = true;
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Perlu StatefulBuilder agar bisa refresh dialog (mata password)
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text("Ganti Password", style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle Lihat Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            setDialogState(() => isObscure = !isObscure);
                          },
                          icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFFFFD700), size: 18),
                          label: Text(isObscure ? "Lihat" : "Sembunyi", style: const TextStyle(color: Color(0xFFFFD700))),
                        ),
                      ),
                      
                      // Input Password Lama
                      TextFormField(
                        controller: oldPassCtrl,
                        obscureText: isObscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration("Password Lama"),
                        validator: (val) => val!.isEmpty ? "Isi password lama" : null,
                      ),
                      const SizedBox(height: 15),
                      
                      // Input Password Baru
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: isObscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration("Password Baru"),
                        validator: (val) => val!.length < 6 ? "Minimal 6 karakter" : null,
                      ),
                      const SizedBox(height: 15),
                      
                      // Konfirmasi Password Baru
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: isObscure,
                        style: const TextStyle(color: Colors.white),
                        decoration: _dialogInputDecoration("Ulangi Password Baru"),
                        validator: (val) => val != newPassCtrl.text ? "Password tidak sama" : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Batal", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setDialogState(() => isProcessing = true);
                      await _processChangePassword(oldPassCtrl.text, newPassCtrl.text);
                      setDialogState(() => isProcessing = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
                  child: isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text("Simpan", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 5. LOGIC CHANGE PASSWORD (FIREBASE REAUTH)
  Future<void> _processChangePassword(String oldPass, String newPass) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      String email = user!.email!;

      // 1. Re-Authenticate (Wajib untuk ganti password)
      AuthCredential credential = EmailAuthProvider.credential(email: email, password: oldPass);
      await user.reauthenticateWithCredential(credential);

      // 2. Update Password
      await user.updatePassword(newPass);

      if (mounted) {
        Navigator.pop(context); // Tutup Dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password Berhasil Diganti! Silakan Login Ulang."), backgroundColor: Colors.green)
        );
        _logout(); // Logout paksa agar aman
      }
    } on FirebaseAuthException catch (e) {
      String err = "Gagal Mengganti Password";
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') err = "Password lama salah!";
      if (e.code == 'weak-password') err = "Password terlalu lemah";
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // 6. LOGOUT FUNCTION
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Yakin ingin keluar shift?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Profil Kasir", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // FOTO PROFIL
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700), width: 3),
                      color: Colors.grey[800],
                      image: _imageBase64 != null
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(_imageBase64!)),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: NetworkImage("https://i.pravatar.cc/150?img=12"),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD700),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // INPUT FORM
            _buildTextField("Nama Lengkap", _nameController, Icons.person),
            const SizedBox(height: 15),
            _buildTextField("Email Login", TextEditingController(text: currentUser?.email), Icons.email, isReadOnly: true),

            const SizedBox(height: 20),

            // --- BUTTON GANTI PASSWORD (BARU) ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_reset, color: Color(0xFFFFD700)),
                label: const Text("GANTI PASSWORD", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFFD700)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("SIMPAN PERUBAHAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),

            // TOMBOL LOGOUT (MERAH)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text("KELUAR APLIKASI", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Styles
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isReadOnly = false}) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      style: TextStyle(color: isReadOnly ? Colors.grey : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : const Color(0xFFFFD700)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFD700)),
        ),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      labelText: hint,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.grey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFFD700))),
    );
  }
}