import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'register_member_page.dart';
import 'pos_member_list_page.dart';

class PosHomePage extends StatefulWidget {
  const PosHomePage({super.key});

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  String _todayDate = "";

  @override
  void initState() {
    super.initState();
    try {
      _todayDate = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(DateTime.now());
    } catch (e) {
      _todayDate = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        // Padding dikurangi agar tidak terlalu masuk ke dalam
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Greeting)
            _buildHeader(),
            
            const SizedBox(height: 20), // Jarak dikurangi (sebelumnya 25)

            // 2. STATISTIK HARI INI
            _buildDailyStats(),

            const SizedBox(height: 20), // Jarak dikurangi

            // 3. MENU AKSI CEPAT
            const Text("Aksi Cepat", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10), // Jarak ke tombol dikurangi
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    "Member Baru", 
                    "Daftar Walk-in", 
                    Icons.person_add_alt_1, 
                    const Color(0xFFFFD700),
                    () {
                       // NAVIGASI KE REGISTER PAGE
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const RegisterMemberPage())
                       );
                    }
                  ),
                ),
                const SizedBox(width: 12), // Jarak antar tombol dikurangi
                Expanded(
                  child: _buildActionButton(
                    "Cek Status", 
                    "Cari Member", 
                    Icons.manage_search, 
                    Colors.cyanAccent,
                    () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const PosMemberListPage())
                       );
                    }
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. LIVE FEED
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Member Terbaru", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                Text("Lihat Semua", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            
            _buildLiveFeed(),
            
            // Tambahan space bawah agar tidak ketutup FAB
            const SizedBox(height: 80), 
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    final User? user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Kasir";
        if (snapshot.hasData && snapshot.data!.exists) {
          name = snapshot.data!['name'] ?? "Kasir";
          // Ambil nama depan saja biar tidak kepanjangan
          if (name.contains(" ")) {
            name = name.split(" ")[0];
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Halo, $name 👋", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 2),
                const Text(
                  "POS Dashboard", 
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                ),
                Text(_todayDate, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF2C2C2C), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            )
          ],
        );
      },
    );
  }

  Widget _buildDailyStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('members').snapshots(),
        builder: (context, snapshot) {
          String totalMember = "0";
          if (snapshot.hasData) {
            totalMember = snapshot.data!.docs.length.toString();
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Check-in", "0", Icons.qr_code), 
              Container(width: 1, height: 35, color: Colors.grey.withOpacity(0.3)),
              _buildStatItem("Total Member", totalMember, Icons.people),
            ],
          );
        }
      ),
    );
  }

  Widget _buildLiveFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('members')
          .orderBy('registeredDate', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text("Belum ada data.", style: TextStyle(color: Colors.grey, fontSize: 12))),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            bool isActive = false;
            if (data['expiredDate'] != null) {
              Timestamp exp = data['expiredDate'];
              isActive = exp.toDate().isAfter(DateTime.now());
            }
            String package = data['currentPackage'] ?? 'Member';

            return _buildLiveCheckinItem(data['name'] ?? 'Tanpa Nama', package, isActive);
          }).toList(),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  Widget _buildActionButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12), // Padding dikurangi biar gak gembung
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row( // Ubah jadi Row biar lebih hemat tempat ke bawah
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCheckinItem(String name, String statusText, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Margin antar item dikurangi
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Padding dalam dikurangi
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isActive ? Colors.greenAccent : Colors.redAccent, 
            width: 3, // Border lebih tipis dikit
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            radius: 16, // Avatar lebih kecil dikit
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?', 
              style: const TextStyle(color: Colors.white, fontSize: 12)
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(
                  isActive ? "Aktif" : "Expired", 
                  style: TextStyle(
                    color: isActive ? Colors.greenAccent : Colors.redAccent, 
                    fontSize: 10,
                    fontWeight: FontWeight.w600
                  )
                ),
              ],
            ),
          ),
          Text(statusText, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}