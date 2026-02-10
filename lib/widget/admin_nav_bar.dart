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
    double screenWidth = MediaQuery.of(context).size.width;
    // Sedikit lebih lebar agar terlihat luas tapi tetap floating
    double navWidth = screenWidth > 600 ? 500 : screenWidth * 0.92;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
        height: 75, // Sedikit lebih tinggi untuk nafas layout
        width: navWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          // Gradient agar kaca terlihat lebih "hidup" dan tidak flat abu-abu
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.08), // Sedikit lebih terang di kiri atas
              Colors.white.withOpacity(0.03), // Lebih transparan di kanan bawah
            ],
          ),
          border: Border.all(
            // Border sangat tipis untuk efek "pinggiran kaca"
            color: Colors.white.withOpacity(0.15),
            width: 1.2,
          ),
          boxShadow: [
            // Shadow hitam lembut untuk efek melayang (Depth)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: -5,
            ),
          ],
        ),
        // ClipRRect + BackdropFilter = Kunci Glassmorphism
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            // Blur sedikit ditingkatkan agar background di belakangnya lebih smooth
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Jarak otomatis rapi
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
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;
    
    // Warna Emas
    final Color activeColor = const Color(0xFFFFD700);
    
    return GestureDetector(
      onTap: () => onItemSelected(index),
      behavior: HitTestBehavior.opaque, // Agar area sentuh optimal
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10, 
          vertical: 10
        ),
        decoration: isSelected
            ? BoxDecoration(
                // Background saat dipilih lebih gelap sedikit/kontras
                color: activeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: activeColor.withOpacity(0.2), width: 1),
              )
            : const BoxDecoration(
                color: Colors.transparent, // Transparan total saat tidak dipilih
              ),
        child: Row( // Ubah Column jadi Row agar lebih hemat tempat vertikal (Opsional, tapi lebih rapi)
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animasi Ikon Membesar sedikit saat dipilih
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                icon,
                color: isSelected ? activeColor : Colors.white.withOpacity(0.6),
                size: 24,
              ),
            ),
            
            // Teks hanya muncul jika dipilih (AnimatedSize handle efek slide-nya)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: SizedBox(
                width: isSelected ? null : 0, // Lebar 0 jika tidak dipilih
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}