import 'package:flutter/material.dart';
import '../../widget/admin_nav_bar.dart'; // Pastikan widget navbar yang lama ada di sini
import 'home_admin_page.dart';
import 'manage_packages_page.dart';
import 'manage_members_page.dart';
import 'settings_page.dart';
import 'manage_users_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  // DAFTAR HALAMAN (Setiap menu punya file sendiri)
  final List<Widget> _pages = [
    const HomeAdminPage(), // 0. Dashboard / Statistik
    const ManagePackagesPage(), // 1. Kelola Paket (CRUD + Bonus)
    const ManageMembersPage(),
    const ManageUsersPage(), // 4. Staff / Users (BARU)
    // 2. Kelola Member
    const SettingsPage(), // 3 (Ini halaman yang baru kita buat)   // 3. Setting
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // KONTEN HALAMAN
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100), // Ruang untuk Navbar
              child: _pages[_selectedIndex],
            ),
          ),

          // NAVIGATION BAR (Tetap mengambang di bawah)
          AdminNavBar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemTapped,
          ),
        ],
      ),
    );
  }
}
