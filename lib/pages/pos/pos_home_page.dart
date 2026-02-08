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
        physics: const BouncingScrollPhysics(), // Efek mantul saat scroll
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Greeting)
            _buildHeader(),
            
            const SizedBox(height: 24), 

            // 2. STATISTIK HARI INI (Visual Diperbesar)
            _buildDailyStats(),

            const SizedBox(height: 24),

            // 3. MENU AKSI CEPAT (Card Besar)
            const Text("Aksi Cepat", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Row(
              children: [
                // TOMBOL 1: MEMBER BARU
                Expanded(
                  child: _buildBigActionButton(
                    "Member Baru", 
                    "Daftar Walk-in", 
                    Icons.person_add_alt_1_rounded, 
                    const Color(0xFFFFD700), // Emas
                    const Color(0xFF332F00), // Background gelap emas
                    () {
                       Navigator.push(
                         context,
                         MaterialPageRoute(builder: (context) => const RegisterMemberPage())
                       );
                    }
                  ),
                ),
                
                const SizedBox(width: 16), // Jarak antar tombol
                
                // TOMBOL 2: CEK STATUS
                Expanded(
                  child: _buildBigActionButton(
                    "Cek Status", 
                    "Cari Data", 
                    Icons.manage_search_rounded, 
                    Colors.cyanAccent,
                    const Color(0xFF003333), // Background gelap cyan
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

            const SizedBox(height: 24),

            // 4. LIVE FEED
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Member Terbaru", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Realtime", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildLiveFeed(),
            
            const SizedBox(height: 80), // Space untuk Floating Button
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
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "Kasir";
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
                Text("Halo, $name 👋", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                const Text(
                  "POS Dashboard", 
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                ),
                const SizedBox(height: 2),
                Text(_todayDate, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C), 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10)
              ),
              child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
            )
          ],
        );
      },
    );
  }

  Widget _buildDailyStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('members').snapshots(),
        builder: (context, snapshot) {
          String totalMember = "-";
          if (snapshot.hasData) {
            totalMember = snapshot.data!.docs.length.toString();
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Icon dibesarkan jadi 32, Font Value jadi 24
              _buildStatItem("Check-in Hari Ini", "0", Icons.qr_code_scanner_rounded), 
              
              Container(width: 1, height: 50, color: Colors.white10), // Divider lebih tinggi
              
              _buildStatItem("Total Member", totalMember, Icons.groups_rounded),
            ],
          );
        }
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 32), // ICON LEBIH BESAR
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), // ANGKA LEBIH BESAR
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // WIDGET BARU: Tampilan Tombol Lebih Besar & Modern (Vertikal)
  Widget _buildBigActionButton(String title, String subtitle, IconData icon, Color mainColor, Color bgColor, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 140, // Tinggi fix agar kotak besar
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: mainColor.withOpacity(0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E1E1E),
                bgColor, // Sedikit tint warna di ujung
              ]
            )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Background Icon Glow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: mainColor, size: 36), // ICON SANGAT BESAR
              ),
              const Spacer(),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('members')
          .orderBy('joinDate', descending: true) // Pastikan field ini ada di DB, atau ganti 'createdAt'
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
        }
        
        // Handle jika field 'joinDate' belum ada index-nya atau data kosong
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)
            ),
            child: Column(
              children: [
                Icon(Icons.person_off_outlined, color: Colors.grey[700], size: 40),
                const SizedBox(height: 10),
                const Text("Belum ada member terdaftar.", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            
            // Safety check untuk data
            String name = data['name'] ?? 'Tanpa Nama';
            String package = data['currentPackage'] ?? 'Member';
            
            bool isActive = false;
            if (data['expiredDate'] != null) {
              Timestamp exp = data['expiredDate'];
              isActive = exp.toDate().isAfter(DateTime.now());
            }

            return _buildLiveCheckinItem(name, package, isActive);
          }).toList(),
        );
      },
    );
  }

  Widget _buildLiveCheckinItem(String name, String package, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Avatar dengan inisial
          Container(
            width: 45, height: 45,
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?', 
                style: TextStyle(
                  color: isActive ? Colors.greenAccent : Colors.redAccent, 
                  fontWeight: FontWeight.bold,
                  fontSize: 18
                )
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(
                    package, 
                    style: TextStyle(color: Colors.grey[400], fontSize: 10)
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                width: 1
              )
            ),
            child: Text(
              isActive ? "AKTIF" : "EXPIRED", 
              style: TextStyle(
                color: isActive ? Colors.greenAccent : Colors.redAccent, 
                fontSize: 10,
                fontWeight: FontWeight.bold
              )
            ),
          ),
        ],
      ),
    );
  }
}