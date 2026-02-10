import 'dart:convert';
import 'dart:ui'; // Diperlukan untuk ImageFilter (Blur)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  // State Filter
  String _selectedFilter = "Bulan Ini";
  final List<String> _filterOptions = ["Hari Ini", "Bulan Ini", "Tahun Ini"];
  
  // Format Mata Uang
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // --- LOGIC: Hitung Pendapatan ---
  int _calculateRevenue(List<DocumentSnapshot> docs) {
    int total = 0;
    DateTime now = DateTime.now();

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('amount') && data.containsKey('timestamp')) {
        int amount = data['amount'];
        Timestamp ts = data['timestamp'];
        DateTime date = ts.toDate();

        bool include = false;
        if (_selectedFilter == "Hari Ini") {
          include = date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (_selectedFilter == "Bulan Ini") {
          include = date.year == now.year && date.month == now.month;
        } else if (_selectedFilter == "Tahun Ini") {
          include = date.year == now.year;
        }

        if (include) total += amount;
      }
    }
    return total;
  }

  // --- LOGIC: Hitung Member ---
  Map<String, int> _calculateMemberStats(List<DocumentSnapshot> docs) {
    int active = 0;
    int expired = 0;
    DateTime now = DateTime.now();

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('expiredDate')) {
        Timestamp expiredTs = data['expiredDate'];
        if (expiredTs.toDate().isAfter(now)) {
          active++;
        } else {
          expired++;
        }
      }
    }
    return {'total': docs.length, 'active': active, 'expired': expired};
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. BACKGROUND DECORATION (Agar tidak sepi)
        _buildBackgroundGlow(),

        // 2. MAIN CONTENT
        Column(
          children: [
            // Header Custom
            _buildHeader(),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(),
                children: [
                  // --- SECTION 1: FILTER & REVENUE CARD ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Overview Keuangan", 
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                      _buildFilterButton(),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildRevenueCard(),

                  const SizedBox(height: 25),

                  // --- SECTION 2: QUICK ACTIONS (MENU CEPAT) ---
                  const Text("Menu Cepat", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildQuickActions(),

                  const SizedBox(height: 25),

                  // --- SECTION 3: STATISTIK MEMBER (3 KOLOM) ---
                  _buildMemberStatsGrid(),

                  const SizedBox(height: 25),

                  // --- SECTION 4: AKTIVITAS TERBARU ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Transaksi Terbaru", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () {
                           // Navigasi ke halaman detail transaksi jika ada
                        },
                        child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFFFFD700), fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildRecentTransactions(),
                  
                  const SizedBox(height: 100), // Bottom padding extra
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- WIDGET COMPONENTS ---

  // Background estetik
  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFD700).withOpacity(0.15),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }

  // Header dengan Profil & Notifikasi
  Widget _buildHeader() {
    final User? user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          String displayName = "Admin";
          ImageProvider avatarImage = const NetworkImage("https://ui-avatars.com/api/?name=Admin&background=1E1E1E&color=FFD700");

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? "Admin";
            if (data['profileImage'] != null && data['profileImage'].isNotEmpty) {
              try {
                avatarImage = MemoryImage(base64Decode(data['profileImage']));
              } catch (_) {}
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
                      image: DecorationImage(image: avatarImage, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Halo, $displayName", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Dashboard Owner", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              // Tombol Notifikasi
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
              )
            ],
          );
        },
      ),
    );
  }

  // Tombol Filter Dropdown
  Widget _buildFilterButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: const Color(0xFF2C2C2C),
          value: _selectedFilter,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFFD700), size: 18),
          style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12),
          items: _filterOptions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: (v) => setState(() => _selectedFilter = v!),
        ),
      ),
    );
  }

  // Kartu Pendapatan Besar
  Widget _buildRevenueCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        int revenue = 0;
        if (snapshot.hasData) revenue = _calculateRevenue(snapshot.data!.docs);

        return Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFAB00)], // Gradient Emas Kaya
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 10))
            ],
          ),
          child: Stack(
            children: [
              // Pattern Hiasan Background
              Positioned(
                right: -20, bottom: -20,
                child: Icon(Icons.monetization_on, size: 150, color: Colors.white.withOpacity(0.2)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.wallet, color: Colors.black87),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                          child: const Text("+12% Trend", style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Pendapatan ($_selectedFilter)", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 5),
                        Text(
                          _currencyFormat.format(revenue),
                          style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Menu Cepat Horizontal
  Widget _buildQuickActions() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _quickActionButton("Tambah Member", Icons.person_add, Colors.blueAccent),
          _quickActionButton("Transaksi Baru", Icons.qr_code_scanner, Colors.purpleAccent),
          _quickActionButton("Laporan", Icons.bar_chart, Colors.orangeAccent),
          _quickActionButton("Pengaturan", Icons.settings, Colors.grey),
        ],
      ),
    );
  }

  Widget _quickActionButton(String label, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  // Statistik Member Grid (3 Items)
  Widget _buildMemberStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('members').snapshots(),
      builder: (context, snapshot) {
        var stats = {'total': 0, 'active': 0, 'expired': 0};
        if (snapshot.hasData) stats = _calculateMemberStats(snapshot.data!.docs);

        return Row(
          children: [
            Expanded(child: _statSmallCard("Total", stats['total'].toString(), Icons.groups, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _statSmallCard("Aktif", stats['active'].toString(), Icons.check_circle, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _statSmallCard("Expired", stats['expired'].toString(), Icons.cancel, Colors.redAccent)),
          ],
        );
      },
    );
  }

  Widget _statSmallCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  // Transaksi Terbaru (Limit 5)
  Widget _buildRecentTransactions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(5) // --- BATASI 5 DATA SAJA ---
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Belum ada data", style: TextStyle(color: Colors.grey)));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            DateTime date = (data['timestamp'] as Timestamp).toDate();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFFFFD700), size: 20),
                ),
                title: Text(data['packageName'] ?? 'Paket', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(DateFormat('dd MMM • HH:mm').format(date), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: Text(
                  "+ ${_currencyFormat.format(data['amount'])}",
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}