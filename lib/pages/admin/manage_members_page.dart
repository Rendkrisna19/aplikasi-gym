import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Pastikan tambah intl di pubspec.yaml

class ManageMembersPage extends StatefulWidget {
  const ManageMembersPage({super.key});

  @override
  State<ManageMembersPage> createState() => _ManageMembersPageState();
}

class _ManageMembersPageState extends State<ManageMembersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // FORMATTER TANGGAL & RUPIAH
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  // --- HELPER: Hitung Sisa Hari ---
  int _calculateRemainingDays(Timestamp? expiredDate) {
    if (expiredDate == null) return 0;
    final now = DateTime.now();
    final expired = expiredDate.toDate();
    final difference = expired.difference(now).inDays;
    return difference; // Bisa negatif jika sudah lewat
  }

  // --- HELPER: Warna Berdasarkan Status ---
  Color _getStatusColor(int daysLeft) {
    if (daysLeft < 0) return Colors.redAccent; // Expired
    if (daysLeft <= 7) return Colors.orangeAccent; // Warning (Hampir habis)
    return const Color(0xFFFFD700); // Aman (Gold)
  }

  // --- ALERT / NOTIFIKASI ---
  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFFFFD700),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- CRUD: EDIT MEMBER ---
  void _showEditDialog(DocumentSnapshot doc) {
    final nameCtrl = TextEditingController(text: doc['name']);
    final phoneCtrl = TextEditingController(text: doc['phone']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Edit Member", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField("Nama Lengkap", nameCtrl, Icons.person),
            const SizedBox(height: 15),
            _buildTextField("No. WhatsApp", phoneCtrl, Icons.phone, isNumber: true),
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
              try {
                await FirebaseFirestore.instance.collection('members').doc(doc.id).update({
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text,
                });
                if (mounted) Navigator.pop(context);
                _showSnack("Data member berhasil diperbarui!");
              } catch (e) {
                _showSnack("Gagal update data.", isError: true);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // --- CRUD: HAPUS MEMBER ---
  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Hapus Member?", style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          "Data yang dihapus tidak bisa dikembalikan. Riwayat transaksi mungkin akan kehilangan referensi nama.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('members').doc(docId).delete();
                if (mounted) Navigator.pop(context);
                _showSnack("Member berhasil dihapus.");
              } catch (e) {
                _showSnack("Gagal menghapus.", isError: true);
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. HEADER & PENCARIAN
        Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Kelola Member", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text("Pantau masa aktif dan data member", style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 20),
              
              // SEARCH BAR
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Cari nama member...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ],
          ),
        ),

        // 2. LIST MEMBER
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('members')
                .orderBy('registeredDate', descending: true) // Urutkan dari yang terbaru
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // Filter Data (Client Side Search)
              var docs = snapshot.data!.docs.where((doc) {
                var data = doc.data() as Map<String, dynamic>;
                var name = (data['name'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

              if (docs.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String docId = docs[index].id;
                  
                  // LOGIC MASA AKTIF
                  Timestamp? expiredTs = data['expiredDate'];
                  int daysLeft = _calculateRemainingDays(expiredTs);
                  Color statusColor = _getStatusColor(daysLeft);
                  String statusText = daysLeft < 0 
                      ? "EXPIRED" 
                      : (daysLeft == 0 ? "HARI INI HABIS" : "$daysLeft HARI LAGI");

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      // AVATAR
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Text(
                          (data['name'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                      ),
                      // INFO UTAMA
                      title: Text(
                        data['name'] ?? 'Tanpa Nama',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("${data['currentPackage'] ?? '-'} • ${data['phone'] ?? '-'}", 
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 6),
                          
                          // BADGE STATUS (Modern Look)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  daysLeft < 0 ? Icons.error_outline : Icons.timer, 
                                  size: 14, 
                                  color: statusColor
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusText,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                      // MENU OPSI (Edit/Delete)
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                        color: const Color(0xFF2C2C2C),
                        onSelected: (value) {
                          if (value == 'edit') _showEditDialog(docs[index]);
                          if (value == 'delete') _confirmDelete(docId);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 10), Text("Edit Data", style: TextStyle(color: Colors.white))]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 10), Text("Hapus", style: TextStyle(color: Colors.white))]),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 10),
          Text("Data member tidak ditemukan", style: TextStyle(color: Colors.white.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}