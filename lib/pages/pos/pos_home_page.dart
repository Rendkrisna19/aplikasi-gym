import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'register_member_page.dart';
import 'pos_member_list_page.dart';
import 'dart:convert'; // Untuk Base64


class PosHomePage extends StatefulWidget {
  const PosHomePage({super.key});

  @override
  State<PosHomePage> createState() => _PosHomePageState();
}

class _PosHomePageState extends State<PosHomePage> {
  String _todayDate = "";
  
  // STATE UNTUK BANNER SLIDER
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentBannerIndex = 0;
  Timer? _autoScrollTimer;

  // Pastikan nama file di folder assets/images/ sama persis dengan ini
  final List<String> _bannerImages = [
    'assets/images/banner1.png', 
    'assets/images/banner2.png',
    'assets/images/banner3.png',
  ];

  @override
  void initState() {
    super.initState();
    try {
      _todayDate = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(DateTime.now());
    } catch (e) {
      _todayDate = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());
    }
    
    // Auto scroll banner setiap 4 detik
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentBannerIndex + 1) % _bannerImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 20, 
          vertical: isTablet ? 24 : 16
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            _buildHeader(isTablet),
            
            SizedBox(height: isTablet ? 28 : 20), 

            // 2. STATISTIK
            _buildDailyStats(isTablet),

            SizedBox(height: isTablet ? 28 : 20),

            // 3. MENU AKSI CEPAT
            Text(
              "Aksi Cepat", 
              style: TextStyle(
                color: Colors.white, 
                fontSize: isTablet ? 18 : 16, 
                fontWeight: FontWeight.bold
              )
            ),
            SizedBox(height: isTablet ? 16 : 12),
            
            _buildActionButtons(isTablet),

            SizedBox(height: isTablet ? 28 : 20),

            // 4. BANNER SLIDER (INTERACTIVE & RESPONSIVE)
            _buildBannerSlider(isTablet),
            
            SizedBox(height: isTablet ? 28 : 20),

            // 5. LIVE FEED
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Member Terbaru", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: isTablet ? 18 : 16, 
                    fontWeight: FontWeight.bold
                  )
                ),
                Text(
                  "Realtime", 
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5), 
                    fontSize: 12, 
                    fontStyle: FontStyle.italic
                  )
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            
            _buildLiveFeed(isTablet),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildBannerSlider(bool isTablet) {
    final bannerHeight = isTablet ? 220.0 : 170.0;
    
    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _bannerImages.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemBuilder: (context, index) {
              // Scale effect untuk banner yang aktif
              bool isActive = index == _currentBannerIndex;
              
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                tween: Tween(begin: 0.92, end: isActive ? 1.0 : 0.92),
                curve: Curves.easeOutCubic,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    // Aksi ketika banner diklik
                    _showBannerDetail(index);
                  },
                  onHorizontalDragEnd: (details) {
                    // Gesture swipe manual
                    if (details.primaryVelocity! > 0) {
                      // Swipe ke kanan
                      if (_currentBannerIndex > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    } else if (details.primaryVelocity! < 0) {
                      // Swipe ke kiri
                      if (_currentBannerIndex < _bannerImages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF2C2C2C),
                      boxShadow: [
                        BoxShadow(
                          color: isActive 
                            ? const Color(0xFFFFD700).withOpacity(0.3)
                            : Colors.black.withOpacity(0.3),
                          blurRadius: isActive ? 16 : 10,
                          offset: Offset(0, isActive ? 6 : 4),
                          spreadRadius: isActive ? 1 : 0,
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Gambar Banner
                          Image.asset(
                            _bannerImages[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF2C2C2C),
                                      const Color(0xFF1A1A1A),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey[700],
                                        size: 48,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Banner ${index + 1}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          // Overlay gradient untuk readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                          
                          // Indicator tap (opsional)
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tap untuk detail',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // INDICATOR DOTS (Improved)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Arrow kiri
            IconButton(
              icon: Icon(
                Icons.chevron_left_rounded,
                color: _currentBannerIndex > 0 
                  ? Colors.white 
                  : Colors.white.withOpacity(0.3),
                size: 28,
              ),
              onPressed: _currentBannerIndex > 0 
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            ),
            
            // Dots
            ...List.generate(_bannerImages.length, (index) {
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentBannerIndex == index ? 28 : 8,
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == index 
                        ? const Color(0xFFFFD700) 
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: _currentBannerIndex == index
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                  ),
                ),
              );
            }),
            
            // Arrow kanan
            IconButton(
              icon: Icon(
                Icons.chevron_right_rounded,
                color: _currentBannerIndex < _bannerImages.length - 1
                  ? Colors.white 
                  : Colors.white.withOpacity(0.3),
                size: 28,
              ),
              onPressed: _currentBannerIndex < _bannerImages.length - 1
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            ),
          ],
        ),
      ],
    );
  }

  void _showBannerDetail(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Promo Banner ${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Informasi detail tentang promo ini akan ditampilkan di sini. Anda bisa menambahkan deskripsi, syarat & ketentuan, atau tombol aksi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Mengerti',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
// --- WIDGET HEADER (UPDATE: Bell + Profile Picture) ---
  Widget _buildHeader(bool isTablet) {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String name = "Kasir";
        String? base64Image; // Variabel untuk menampung gambar

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? "Kasir";
          base64Image = data['profileImage']; // Ambil data foto dari Firebase
          
          if (name.contains(" ")) {
            name = name.split(" ")[0];
          }
        }

        // Logic Gambar Profil
        ImageProvider profileImage;
        if (base64Image != null && base64Image.isNotEmpty) {
          try {
            profileImage = MemoryImage(base64Decode(base64Image)); // Pakai foto upload
          } catch (e) {
            profileImage = const NetworkImage("https://i.pravatar.cc/150?img=12"); // Fallback jika error
          }
        } else {
          profileImage = const NetworkImage("https://i.pravatar.cc/150?img=12"); // Default
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // BAGIAN KIRI: TEKS SAPAAN
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, $name 👋", 
                    style: TextStyle(
                      color: Colors.grey, 
                      fontSize: isTablet ? 16 : 14
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "POS Dashboard", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: isTablet ? 26 : 22, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 0.5
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _todayDate, 
                    style: TextStyle(
                      color: const Color(0xFFFFD700), 
                      fontSize: isTablet ? 13 : 12, 
                      fontWeight: FontWeight.w500
                    )
                  ),
                ],
              ),
            ),

            // BAGIAN KANAN: LONCENG & PROFIL
            Row(
              children: [
                // 1. TOMBOL LONCENG (NOTIFIKASI)
                Container(
                  padding: EdgeInsets.all(isTablet ? 12 : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10)
                  ),
                  child: Icon(
                    Icons.notifications_none_rounded, 
                    color: Colors.white, 
                    size: isTablet ? 26 : 24
                  ),
                ),

                const SizedBox(width: 12), // Jarak antar tombol

                // 2. ICON PROFILE (TERHUBUNG KE SETTINGS)
                Container(
                  width: isTablet ? 50 : 45,
                  height: isTablet ? 50 : 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFD700), width: 2), // Ring Emas
                    image: DecorationImage(
                      image: profileImage, // Foto dari Logic di atas
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildDailyStats(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), 
            blurRadius: 10, 
            offset: const Offset(0, 4)
          )
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
              _buildStatItem(
                "Check-in Hari Ini", 
                "0", 
                Icons.qr_code_scanner_rounded,
                isTablet
              ), 
              Container(
                width: 1, 
                height: isTablet ? 60 : 50, 
                color: Colors.white10
              ), 
              _buildStatItem(
                "Total Member", 
                totalMember, 
                Icons.groups_rounded,
                isTablet
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isTablet) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon, 
            color: const Color(0xFFFFD700), 
            size: isTablet ? 36 : 32
          ),
          SizedBox(height: isTablet ? 10 : 8),
          Text(
            value, 
            style: TextStyle(
              color: Colors.white, 
              fontSize: isTablet ? 30 : 26, 
              fontWeight: FontWeight.bold
            )
          ),
          const SizedBox(height: 4),
          Text(
            label, 
            style: TextStyle(
              color: Colors.grey, 
              fontSize: isTablet ? 13 : 12
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTablet && constraints.maxWidth > 600) {
          // Layout untuk tablet: 2 tombol dalam 1 baris
          return Row(
            children: [
              Expanded(
                child: _buildBigActionButton(
                  "Member Baru", 
                  "Daftar Walk-in", 
                  Icons.person_add_alt_1_rounded, 
                  const Color(0xFFFFD700),
                  const Color(0xFF332F00), 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterMemberPage())
                    );
                  },
                  isTablet
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBigActionButton(
                  "Cek Status", 
                  "Cari Data", 
                  Icons.manage_search_rounded, 
                  Colors.cyanAccent,
                  const Color(0xFF003333),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PosMemberListPage())
                    );
                  },
                  isTablet
                ),
              ),
            ],
          );
        } else {
          // Layout mobile: tetap 2 tombol dalam 1 baris tapi lebih compact
          return Row(
            children: [
              Expanded(
                child: _buildBigActionButton(
                  "Member Baru", 
                  "Daftar Walk-in", 
                  Icons.person_add_alt_1_rounded, 
                  const Color(0xFFFFD700),
                  const Color(0xFF332F00), 
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterMemberPage())
                    );
                  },
                  isTablet
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBigActionButton(
                  "Cek Status", 
                  "Cari Data", 
                  Icons.manage_search_rounded, 
                  Colors.cyanAccent,
                  const Color(0xFF003333),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PosMemberListPage())
                    );
                  },
                  isTablet
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildBigActionButton(
    String title, 
    String subtitle, 
    IconData icon, 
    Color mainColor, 
    Color bgColor, 
    VoidCallback onTap,
    bool isTablet
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: mainColor.withOpacity(0.2),
        highlightColor: mainColor.withOpacity(0.1),
        child: Container(
          height: isTablet ? 160 : 140, 
          padding: EdgeInsets.all(isTablet ? 18 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: mainColor.withOpacity(0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1E1E1E), bgColor]
            )
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 14 : 12),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  color: mainColor, 
                  size: isTablet ? 40 : 36
                ),
              ),
              const Spacer(),
              Text(
                title, 
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: isTablet ? 16 : 15
                )
              ),
              const SizedBox(height: 4),
              Text(
                subtitle, 
                style: TextStyle(
                  color: Colors.grey, 
                  fontSize: isTablet ? 12 : 11
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveFeed(bool isTablet) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('members')
          .orderBy('registeredDate', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700))
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 28 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10)
            ),
            child: Column(
              children: [
                Icon(
                  Icons.person_off_outlined, 
                  color: Colors.grey[700], 
                  size: isTablet ? 48 : 40
                ),
                SizedBox(height: isTablet ? 12 : 10),
                Text(
                  "Belum ada member terdaftar.", 
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isTablet ? 15 : 14,
                  )
                ),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            
            String name = data['name'] ?? 'Tanpa Nama';
            String package = data['currentPackage'] ?? 'Member';
            
            bool isActive = false;
            if (data['expiredDate'] != null) {
              Timestamp exp = data['expiredDate'];
              isActive = exp.toDate().isAfter(DateTime.now());
            }

            return _buildLiveCheckinItem(name, package, isActive, isTablet);
          }).toList(),
        );
      },
    );
  }

  Widget _buildLiveCheckinItem(String name, String package, bool isActive, bool isTablet) {
    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 12 : 10),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 16, 
        vertical: isTablet ? 14 : 12
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 52 : 45, 
            height: isTablet ? 52 : 45,
            decoration: BoxDecoration(
              color: isActive 
                ? Colors.green.withOpacity(0.1) 
                : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?', 
                style: TextStyle(
                  color: isActive ? Colors.greenAccent : Colors.redAccent, 
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 20 : 18
                )
              ),
            ),
          ),
          SizedBox(width: isTablet ? 16 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: isTablet ? 15 : 14
                  )
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(
                    package, 
                    style: TextStyle(
                      color: Colors.grey[400], 
                      fontSize: isTablet ? 11 : 10
                    )
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 10, 
              vertical: isTablet ? 6 : 5
            ),
            decoration: BoxDecoration(
              color: isActive 
                ? Colors.green.withOpacity(0.2) 
                : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive 
                  ? Colors.green.withOpacity(0.5) 
                  : Colors.red.withOpacity(0.5),
                width: 1
              )
            ),
            child: Text(
              isActive ? "AKTIF" : "EXPIRED", 
              style: TextStyle(
                color: isActive ? Colors.greenAccent : Colors.redAccent, 
                fontSize: isTablet ? 11 : 10,
                fontWeight: FontWeight.bold
              )
            ),
          ),
        ],
      ),
    );
  }
}