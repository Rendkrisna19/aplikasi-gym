import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// --- IMPORT SEMUA HALAMAN ---
import 'pos_home_page.dart';
import 'register_member_page.dart'; // [1] Menu Daftar
import 'pos_member_list_page.dart'; // [3] Menu Member (SUDAH KEMBALI)
import 'pos_history_page.dart';     // [4] Menu Riwayat
import 'pos_profile_page.dart';     // [5] Menu Profil
import 'scanner_page.dart';         // Scanner

class PosLayout extends StatefulWidget {
  const PosLayout({super.key});

  @override
  State<PosLayout> createState() => _PosLayoutState();
}

class _PosLayoutState extends State<PosLayout> {
  int _selectedIndex = 0;

  // --- DAFTAR HALAMAN (Total 6 Slot termasuk Spacer) ---
  final List<Widget> _pages = [
    const PosHomePage(),           // Index 0
    const RegisterMemberPage(),    // Index 1
    const SizedBox(),              // Index 2 (Spacer untuk Tombol Scanner)
    const PosMemberListPage(),     // Index 3 (Data Member)
    const PosHistoryPage(),        // Index 4
    const PosProfilePage(),        // Index 5
  ];

  // --- NAVIGASI ---
  void _onItemTapped(int index) {
    if (index == 2) {
      _openScanner(); // Aksi Tombol Tengah
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  // --- LOGIC SCANNER ---
  Future<void> _openScanner() async {
    final String? code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UniversalScannerPage()),
    );

    if (code != null && code.isNotEmpty) {
      if (mounted) _checkMemberStatus(code);
    }
  }

  Future<void> _checkMemberStatus(String memberId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
    );

    try {
      var query = await FirebaseFirestore.instance
          .collection('members')
          .where('memberId', isEqualTo: memberId)
          .limit(1)
          .get();
      
      if (mounted) Navigator.pop(context);

      if (query.docs.isNotEmpty) {
        _showMemberDetailDialog(query.docs.first.data());
      } else {
        _showErrorDialog("Data Member Tidak Ditemukan!");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorDialog("Error: $e");
    }
  }

  void _showMemberDetailDialog(Map<String, dynamic> data) {
    Timestamp? expTs = data['expiredDate'];
    bool isExpired = true;
    String timeLeft = "Expired";
    
    if (expTs != null) {
      DateTime expiry = expTs.toDate();
      DateTime now = DateTime.now();
      Duration diff = expiry.difference(now);
      
      if (!diff.isNegative) {
        isExpired = false;
        timeLeft = "${diff.inDays} Hari Lagi";
      } else {
        timeLeft = "Habis sejak ${DateFormat('dd MMM').format(expiry)}";
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: isExpired ? Colors.red : Colors.green, width: 2)
        ),
        title: Row(
          children: [
            Icon(isExpired ? Icons.cancel : Icons.check_circle, color: isExpired ? Colors.red : Colors.green),
            const SizedBox(width: 10),
            Text(isExpired ? "Akses Ditolak" : "Akses Diterima", style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow("Nama", data['name']),
            _detailRow("ID", data['memberId']),
            _detailRow("Paket", data['currentPackage']),
            const Divider(color: Colors.grey),
            const SizedBox(height: 5),
            Text(
              isExpired ? "MEMBERSHIP EXPIRED" : "MEMBERSHIP AKTIF", 
              style: TextStyle(color: isExpired ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 18)
            ),
            Text(timeLeft, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
          const Text(": ", style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(value ?? "-", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      
      // BODY HALAMAN
      body: _pages[_selectedIndex],

      // TOMBOL TENGAH (SCANNER)
      floatingActionButton: Container(
        width: 70, 
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.5), 
              blurRadius: 20, 
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2), // Index 2 = Scanner
          backgroundColor: const Color(0xFFFFD700),
          elevation: 0, 
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 32, color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // NAVIGATION BAR MODERN (Split 2 Kiri - 3 Kanan)
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E1E1E),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        height: 80, // TINGGI DITAMBAH BIAR GAK GEMPET
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            // --- ZONA KIRI (2 MENU) ---
            Expanded(
              flex: 1, // Mengambil 50% Lebar Layar (dikurangi tengah)
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.grid_view_rounded, "Home", 0),
                  _buildNavItem(Icons.person_add_alt_1_rounded, "Daftar", 1),
                ],
              ),
            ),
            
            // --- ZONA TENGAH (SPACER UNTUK FAB) ---
            const SizedBox(width: 70), 

            // --- ZONA KANAN (3 MENU) ---
            Expanded(
              flex: 1, // Mengambil 50% Lebar Layar Sisa
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.people_alt_rounded, "Member", 3), // Menu Member
                  _buildNavItem(Icons.history_rounded, "Riwayat", 4),   // Menu Riwayat
                  _buildNavItem(Icons.person_rounded, "Profil", 5),     // Menu Profil
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET ITEM NAVIGASI
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Padding agar area sentuh luas
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: isSelected ? BoxDecoration(
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.4), blurRadius: 8)
                ]
              ) : null,
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFFFFD700) : Colors.grey.withOpacity(0.5),
                size: isSelected ? 26 : 24,
              ),
            ),
            const SizedBox(height: 6), // Jarak Icon ke Text
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFD700) : Colors.grey.withOpacity(0.5),
                fontSize: 10, // Ukuran font pas
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}