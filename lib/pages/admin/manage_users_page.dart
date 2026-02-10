import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  bool _isLoading = false;

  // --- WARNA TEMA (TIDAK DIRUBAH) ---
  final Color _goldColor = const Color(0xFFFFD700);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _bgColor = const Color(0xFF121212);

  // --- 1. FUNGSI TAMBAH AKUN POS ---
  Future<void> _showAddUserDialog() async {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    bool isPasswordVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Modal
                    Row(
                      children: [
                        Icon(Icons.person_add_rounded, color: _goldColor, size: 28),
                        const SizedBox(width: 15),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tambah Staff Kasir",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                            Text("Buat akun login untuk POS", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Input Form
                    _buildModernInput(nameCtrl, "Nama Lengkap", "Contoh: Budi Santoso", Icons.badge_outlined),
                    const SizedBox(height: 15),
                    _buildModernInput(emailCtrl, "Email Login", "staff@gym.com", Icons.alternate_email),
                    const SizedBox(height: 15),

                    // Password Field
                    const Text("Password", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
                          onPressed: () => setModalState(() => isPasswordVisible = !isPasswordVisible),
                        ),
                        filled: true,
                        fillColor: Colors.black26,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder:
                            OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _goldColor)),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (emailCtrl.text.isEmpty || passwordCtrl.text.isEmpty) return;
                          Navigator.pop(context);
                          await _registerPosUser(emailCtrl.text, passwordCtrl.text, nameCtrl.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _goldColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("BUAT AKUN",
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 2. FUNGSI EDIT USER (BARU) ---
  Future<void> _showEditUserDialog(String docId, String currentName) async {
    final nameCtrl = TextEditingController(text: currentName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_rounded, color: _goldColor, size: 28),
                  const SizedBox(width: 15),
                  const Text("Edit Profil Staff",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 24),
              _buildModernInput(nameCtrl, "Nama Lengkap", "Nama Staff", Icons.badge_outlined),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) return;
                        Navigator.pop(context);
                        await _updatePosUser(docId, nameCtrl.text);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _goldColor),
                      child: const Text("SIMPAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC BACKEND ---

  Future<void> _registerPosUser(String email, String password, String name) async {
    setState(() => _isLoading = true);
    try {
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'pos',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      await secondaryApp.delete();

      if (mounted) {
        _showSnack("Akun Kasir Berhasil Dibuat!", Colors.green);
      }
    } catch (e) {
      if (mounted) _showSnack("Gagal: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePosUser(String uid, String newName) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': newName,
      });
      if (mounted) _showSnack("Data berhasil diperbarui", Colors.green);
    } catch (e) {
      if (mounted) _showSnack("Gagal update: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteUser(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Akses?", style: TextStyle(color: Colors.white)),
        content: Text("Staff '$name' tidak akan bisa login lagi.", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance.collection('users').doc(uid).delete();
              if (mounted) _showSnack("Staff dihapus", Colors.orange);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- UI UTAMA ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        // SafeArea mencegah tertutup poni HP (Notch)
        child: Column(
          children: [
            // HEADER HALAMAN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Staff Kasir", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("Kelola akses POS", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  // Tombol Tambah
                  Material(
                    color: _goldColor,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 4,
                    shadowColor: _goldColor.withOpacity(0.3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _isLoading ? null : _showAddUserDialog,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Icon(Icons.person_add_rounded, color: Colors.black, size: 24),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // LIST USER
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'pos').snapshots(),
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
                          const Text("Belum ada staff.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var data = snapshot.data!.docs[index];
                      String name = data['name'] ?? 'Staff';
                      String email = data['email'] ?? '-';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: _goldColor.withOpacity(0.15),
                            child: Icon(Icons.person, color: _goldColor),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Text(email, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tombol Edit
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 22),
                                onPressed: () => _showEditUserDialog(data.id, name),
                                tooltip: 'Edit',
                              ),
                              // Tombol Hapus
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
                                onPressed: () => _deleteUser(data.id, name),
                                tooltip: 'Hapus',
                              ),
                            ],
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
      ),
    );
  }

  // --- HELPER INPUT WIDGET ---
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