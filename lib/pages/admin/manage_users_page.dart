import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Diperlukan untuk trik secondary app

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  bool _isLoading = false;

  // Warna Tema
  final Color _goldColor = const Color(0xFFFFD700);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _bgColor = const Color(0xFF121212);

  // --- FUNGSI TAMBAH AKUN POS (MODAL BESAR) ---
  Future<void> _showAddUserDialog() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    bool isPasswordVisible = false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 500), // Responsive Max Width
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Modal
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _goldColor.withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(Icons.person_add_rounded, color: _goldColor, size: 28),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Tambah Staff Kasir", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                Text("Buat akun login untuk POS", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),

                      // Input Form
                      _buildModernInput(nameCtrl, "Nama Lengkap", "Contoh: Budi Santoso", Icons.badge_outlined),
                      const SizedBox(height: 15),
                      _buildModernInput(emailCtrl, "Email Login", "staff@gym.com", Icons.alternate_email),
                      const SizedBox(height: 15),
                      
                      // Password Field (Custom)
                      Text("Password", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: !isPasswordVisible,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: "Minimal 6 karakter",
                          hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
                          prefixIcon: Icon(Icons.lock_outline, color: _goldColor, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                            onPressed: () => setDialogState(() => isPasswordVisible = !isPasswordVisible),
                          ),
                          filled: true,
                          fillColor: Colors.black26,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _goldColor)),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
                                Navigator.pop(context); // Tutup dialog
                                await _registerPosUser(emailCtrl.text, passwordCtrl.text, nameCtrl.text);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _goldColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 5,
                                shadowColor: _goldColor.withOpacity(0.4),
                              ),
                              child: const Text("BUAT AKUN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }
          ),
        );
      },
    );
  }

  // --- LOGIC REGISTER (TIDAK BERUBAH) ---
  Future<void> _registerPosUser(String email, String password, String name) async {
    setState(() => _isLoading = true);
    try {
      // 1. Inisialisasi App Sekunder (Agar sesi Admin tidak putus)
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      // 2. Buat User di Auth menggunakan App Sekunder
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      // 3. Simpan Data ke Firestore (Pakai instance utama)
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'pos', // PENTING: Role khusus POS
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // 4. Hapus App Sekunder
      await secondaryApp.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("Akun Kasir Berhasil Dibuat!")]),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- HAPUS USER (CONFIRMATION) ---
  void _deleteUser(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Akses?", style: TextStyle(color: Colors.white)),
        content: Text("Staff '$name' tidak akan bisa login lagi ke aplikasi POS.", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Hapus Akses", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Pakai Scaffold agar aman
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // HEADER HALAMAN
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Manajemen Staff", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text("Kelola akun kasir (POS)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                // Tombol Tambah
                Container(
                  decoration: BoxDecoration(
                    color: _goldColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: _goldColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _showAddUserDialog,
                    icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                      : const Icon(Icons.person_add_rounded, color: Colors.black, size: 28),
                  ),
                )
              ],
            ),
          ),

          // LIST USER CARD
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'pos') // Hanya tampilkan POS
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: _goldColor));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey[800]),
                        const SizedBox(height: 10),
                        const Text("Belum ada staff POS.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _goldColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: _goldColor.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.person, color: _goldColor),
                        ),
                        title: Text(
                          data['name'] ?? 'Staff', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: Colors.grey, size: 14),
                            const SizedBox(width: 5),
                            Text(data['email'], style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                          ),
                          onPressed: () => _deleteUser(data.id, data['name'] ?? 'Staff'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER INPUT ---
  Widget _buildModernInput(TextEditingController controller, String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
            prefixIcon: Icon(icon, color: _goldColor, size: 20),
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _goldColor)),
          ),
        ),
      ],
    );
  }
}