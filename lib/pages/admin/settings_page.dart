import 'dart:convert'; // Untuk Base64
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../login_page.dart'; // Import login page untuk logout

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _imageBase64; // Menyimpan string gambar
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // LOAD DATA AWAL
  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'] ?? '';
        _imageBase64 = doc['profileImage']; // Ambil string base64 lama
      });
    }
  }

  // FUNGSI PICK IMAGE & CONVERT TO BASE64
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, 
      imageQuality: 50, // Kompres agar string tidak terlalu panjang
      maxWidth: 500,    // Resize agar ringan
    );

    if (image != null) {
      File file = File(image.path);
      Uint8List imageBytes = await file.readAsBytes();
      String base64String = base64Encode(imageBytes);

      setState(() {
        _imageBase64 = base64String; // Update preview
      });
    }
  }

  // SIMPAN PERUBAHAN KE FIREBASE
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'name': _nameController.text,
        'profileImage': _imageBase64, // Simpan string panjang ini ke Firestore
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile berhasil diupdate!"), backgroundColor: Color(0xFFFFD700)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // LOGOUT FUNCTION
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // FOTO PROFIL (BISA DIKLIK)
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
                                  image: MemoryImage(base64Decode(_imageBase64!)), // Decode Base64
                                  fit: BoxFit.cover,
                                )
                              : const DecorationImage(
                                  image: NetworkImage("https://i.pravatar.cc/150?img=3"), // Default jika kosong
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
                
                const SizedBox(height: 30),

                // FORM INPUT NAMA
                _buildTextField("Nama Lengkap", _nameController, Icons.person),
                const SizedBox(height: 15),
                // EMAIL (READ ONLY)
                _buildTextField("Email", TextEditingController(text: currentUser?.email), Icons.email, isReadOnly: true),

                const SizedBox(height: 30),

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

                // TOMBOL LOGOUT
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Pengaturan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text("Update profil & keamanan akun", style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

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
}