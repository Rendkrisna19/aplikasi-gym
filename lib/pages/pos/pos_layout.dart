import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// IMPORT SEMUA HALAMAN
import 'pos_home_page.dart';
import 'pos_history_page.dart'; 
import 'pos_member_list_page.dart'; 
import 'pos_profile_page.dart'; // <--- IMPORT HALAMAN BARU TADI
import 'scanner_page.dart'; 

class PosLayout extends StatefulWidget {
  const PosLayout({super.key});

  @override
  State<PosLayout> createState() => _PosLayoutState();
}

class _PosLayoutState extends State<PosLayout> {
  int _selectedIndex = 0;

  // DAFTAR HALAMAN (URUTAN 0 - 4)
  final List<Widget> _pages = [
    const PosHomePage(),           // Index 0
    const PosHistoryPage(),        // Index 1
    const SizedBox(),              // Index 2 (Spacer Scanner)
    const PosMemberListPage(),     // Index 3 (Daftar Member)
    const PosProfilePage(),        // Index 4 (Profil & Logout ada di sini)
  ];

  // NAVIGASI
  void _onItemTapped(int index) {
    if (index == 2) {
      _openScanner();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  // LOGIC SCANNER (SAMA SEPERTI SEBELUMNYA)
  Future<void> _openScanner() async {
    final String? code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UniversalScannerPage()),
    );

    if (code != null && code.isNotEmpty) {
      if (mounted) {
        _checkMemberStatus(code);
      }
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
      
      Navigator.pop(context);

      if (query.docs.isNotEmpty) {
        var data = query.docs.first.data();
        _showMemberDetailDialog(data);
      } else {
        _showErrorDialog("Data Member Tidak Ditemukan!");
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog("Terjadi Kesalahan: $e");
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
        timeLeft = "Sudah Habis sejak ${DateFormat('dd MMM').format(expiry)}";
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isExpired ? Colors.red : Colors.green, width: 2)),
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
            const Text("Status Membership:", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            Text(
              isExpired ? "EXPIRED" : "AKTIF", 
              style: TextStyle(color: isExpired ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 24)
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
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
        title: const Text("Gagal", style: TextStyle(color: Colors.red)),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      
      body: _pages[_selectedIndex],

      // FLOATING SCANNER
      floatingActionButton: SizedBox(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          onPressed: () => _onItemTapped(2),
          backgroundColor: const Color(0xFFFFD700),
          elevation: 5,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 32, color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // NAVIGATION BAR
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFF1E1E1E),
        height: 65,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavButton(Icons.grid_view_rounded, "Home", 0),
            _buildNavButton(Icons.history_rounded, "Riwayat", 1),
            
            const SizedBox(width: 40), // Space Scanner
            
            _buildNavButton(Icons.people_alt_rounded, "Member", 3), // Index 3: LIST MEMBER
            _buildNavButton(Icons.person_rounded, "Profil", 4),     // Index 4: PROFIL (Bukan Logout lagi)
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFFD700) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFD700) : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}