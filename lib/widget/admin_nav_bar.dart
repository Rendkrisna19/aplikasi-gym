import 'dart:ui';
import 'package:flutter/material.dart';

class AdminNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AdminNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Menentukan lebar container berdasarkan lebar layar (Responsive dasar)
    double screenWidth = MediaQuery.of(context).size.width;
    double navWidth = screenWidth > 600 ? 500 : screenWidth * 0.9; // iPad vs HP

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        height: 70,
        width: navWidth,
        decoration: BoxDecoration(
          // Efek Transparan Putih keabu-abuan
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            // Glow Halus
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        // Efek Blur (Kaca)
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.dashboard_rounded, "Home", 0),
                _buildNavItem(Icons.card_membership_rounded, "Paket", 1),
                _buildNavItem(Icons.people_alt_rounded, "Member", 2),
                 _buildNavItem(Icons.badge_rounded, "Staff", 3),
                _buildNavItem(Icons.settings_rounded, "Setting", 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2), // Kuning Transparan
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
              size: 26,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}