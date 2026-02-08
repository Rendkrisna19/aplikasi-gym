import 'dart:convert'; // Untuk Base64
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../login_page.dart'; // Sesuaikan path login page kamu

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

  // Warna Tema
  final Color _primaryBlack = const Color(0xFF121212);
  final Color _secondaryBlack = const Color(0xFF1E1E1E);
  final Color _goldColor = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // --- 1. LOAD DATA AWAL ---
  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _imageBase64 = doc['profileImage']; 
        });
      }
    } catch (e) {
      debugPrint("Gagal load data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 2. FUNGSI PICK IMAGE (FIXED) ---
  Future<void> _pickImage() async {
    try {
      // 1. Ambil Gambar dari Galeri
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        // KOMPRESI AGRESIF AGAR MUAT DI FIRESTORE (Max 1MB)
        maxWidth: 512,      // Resize ke 512px (Cukup untuk avatar)
        maxHeight: 512,
        imageQuality: 50,   // Kualitas 50%
      );

      if (image != null) {
        File file = File(image.path);
        
        // 2. Cek Ukuran File sebelum convert (Optional safety)
        int sizeInBytes = await file.length();
        double sizeInMb = sizeInBytes / (1024 * 1024);
        
        if (sizeInMb > 1) {
           _showSnackBar("Gambar terlalu besar! Pilih gambar lain.", isError: true);
           return;
        }

        // 3. Convert ke Base64
        Uint8List imageBytes = await file.readAsBytes();
        String base64String = base64Encode(imageBytes);

        setState(() {
          _imageBase64 = base64String; // Update preview UI
        });
      }
    } catch (e) {
      _showSnackBar("Gagal ambil gambar: $e. Cek Izin Aplikasi.", isError: true);
    }
  }

  // --- 3. SIMPAN PERUBAHAN KE FIREBASE ---
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar("Nama tidak boleh kosong", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Update data ke Firestore
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'name': _nameController.text,
        'profileImage': _imageBase64, // Simpan string Base64
      });

      if (mounted) {
        _showSnackBar("Profile berhasil diupdate! ✅", isError: false);
      }
    } catch (e) {
      _showSnackBar("Gagal menyimpan: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- 4. LOGOUT FUNCTION ---
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _secondaryBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Logout?", style: TextStyle(color: Colors.white)),
        content: const Text("Anda yakin ingin keluar?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Batal", style: TextStyle(color: Colors.grey))
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            }, 
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBlack,
      body: _isLoading && _nameController.text.isEmpty
          ? Center(child: CircularProgressIndicator(color: _goldColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // --- AVATAR SECTION ---
                        _buildAvatarSection(),
                        
                        const SizedBox(height: 40),

                        // --- FORM SECTION ---
                        _buildTextField("Nama Lengkap", _nameController, Icons.person_outline_rounded),
                        const SizedBox(height: 20),
                        _buildTextField("Email Akun", TextEditingController(text: currentUser?.email), Icons.alternate_email_rounded, isReadOnly: true),

                        const SizedBox(height: 50),

                        // --- ACTION BUTTONS ---
                        _buildSaveButton(),
                        const SizedBox(height: 20),
                        _buildLogoutButton(),
                        
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
      decoration: BoxDecoration(
        color: _secondaryBlack,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Pengaturan", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 5),
              Text("Profil Admin", style: TextStyle(color: _goldColor, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.settings, color: _goldColor.withOpacity(0.8), size: 28),
          )
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            // GLOW EFFECT
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _goldColor.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
                ],
              ),
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _goldColor, width: 3),
                  color: _secondaryBlack,
                ),
                // LOGIC MENAMPILKAN GAMBAR
                child: ClipOval(
                  child: _imageBase64 != null
                      ? Image.memory(
                          base64Decode(_imageBase64!), // Decode Base64 dari memory
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image, color: Colors.grey);
                          },
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
              ),
            ),
            
            // CAMERA ICON BADGE
            Container(
              margin: const EdgeInsets.only(right: 5, bottom: 5),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _goldColor,
                shape: BoxShape.circle,
                border: Border.all(color: _primaryBlack, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 5)],
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isReadOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _secondaryBlack,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isReadOnly ? [] : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))],
          ),
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            style: TextStyle(color: isReadOnly ? Colors.grey : Colors.white, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: "Masukkan $label",
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: isReadOnly ? Colors.grey : _goldColor),
              filled: true,
              fillColor: Colors.transparent, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: _goldColor,
          foregroundColor: Colors.black,
          elevation: 5,
          shadowColor: _goldColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, size: 22),
                SizedBox(width: 10),
                Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
              ],
            ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _logout,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: Colors.redAccent,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 22),
            SizedBox(width: 10),
            Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}