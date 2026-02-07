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

  // --- FUNGSI TAMBAH AKUN POS ---
  // Trik: Kita menggunakan 'Secondary App' agar saat create user baru,
  // Admin yang sedang login TIDAK log out.
  Future<void> _showAddUserDialog() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Tambah Akun Kasir (POS)", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField("Nama Staff", nameCtrl, Icons.person),
            const SizedBox(height: 10),
            _buildTextField("Email Login", emailCtrl, Icons.email),
            const SizedBox(height: 10),
            _buildTextField("Password", passwordCtrl, Icons.lock, isPassword: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () async {
              if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
              Navigator.pop(context); // Tutup dialog dulu
              await _registerPosUser(emailCtrl.text, passwordCtrl.text, nameCtrl.text);
            },
            child: const Text("Buat Akun", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

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
          const SnackBar(content: Text("Akun Kasir Berhasil Dibuat!"), backgroundColor: Color(0xFFFFD700)),
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

  // --- HAPUS USER (Hanya Hapus Data di Firestore) ---
  // Catatan: Menghapus Auth user butuh Admin SDK (Backend), 
  // jadi di client side kita hanya hapus akses di Firestore agar tidak bisa login.
  void _deleteUser(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Hapus Akses?", style: TextStyle(color: Colors.red)),
        content: const Text("Staff ini tidak akan bisa login lagi.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    return Column(
      children: [
        // HEADER
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Manajemen Staff", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("Kelola akun kasir (POS)", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              IconButton(
                onPressed: _isLoading ? null : _showAddUserDialog,
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Icon(Icons.person_add, color: Colors.black),
              )
            ],
          ),
        ),

        // LIST USER
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'pos') // Hanya tampilkan POS, jangan Admin
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Belum ada staff POS.", style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var data = snapshot.data!.docs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFFFD700).withOpacity(0.2),
                        child: const Icon(Icons.badge, color: Color(0xFFFFD700)),
                      ),
                      title: Text(data['name'] ?? 'Staff', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(data['email'], style: const TextStyle(color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteUser(data.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        labelStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}