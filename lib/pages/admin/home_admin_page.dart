import 'dart:convert'; // Untuk decode Base64 Image
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Wajib: flutter pub add intl

class HomeAdminPage extends StatefulWidget {
  const HomeAdminPage({super.key});

  @override
  State<HomeAdminPage> createState() => _HomeAdminPageState();
}

class _HomeAdminPageState extends State<HomeAdminPage> {
  // State untuk Filter Pendapatan
  String _selectedFilter = "Bulan Ini";
  final List<String> _filterOptions = ["Hari Ini", "Bulan Ini", "Tahun Ini"];
  
  // Formatter Rupiah
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // --- LOGIC: Hitung Pendapatan Berdasarkan Filter ---
  int _calculateRevenue(List<DocumentSnapshot> docs) {
    int total = 0;
    DateTime now = DateTime.now();

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      // Pastikan ada field 'amount' dan 'timestamp'
      if (data.containsKey('amount') && data.containsKey('timestamp')) {
        int amount = data['amount'];
        Timestamp ts = data['timestamp'];
        DateTime date = ts.toDate();

        bool include = false;
        
        // Logika Filter
        if (_selectedFilter == "Hari Ini") {
          include = date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (_selectedFilter == "Bulan Ini") {
          include = date.year == now.year && date.month == now.month;
        } else if (_selectedFilter == "Tahun Ini") {
          include = date.year == now.year;
        }

        if (include) {
          total += amount;
        }
      }
    }
    return total;
  }

  // --- LOGIC: Hitung Member Aktif ---
  int _calculateActiveMembers(List<DocumentSnapshot> docs) {
    int activeCount = 0;
    DateTime now = DateTime.now();

    for (var doc in docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('expiredDate')) {
        Timestamp expiredTs = data['expiredDate'];
        if (expiredTs.toDate().isAfter(now)) {
          activeCount++;
        }
      }
    }
    return activeCount;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. HEADER (Dynamic Profile)
        _buildHeader(),

        // 2. SCROLLABLE CONTENT
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              // FILTER DROPDOWN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Ringkasan Keuangan", 
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF2C2C2C),
                      value: _selectedFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFFD700)),
                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                      underline: Container(),
                      items: _filterOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedFilter = newValue);
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 15),

              // 3. CARD PENDAPATAN (REAL-TIME STREAM)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard();
                  }
                  
                  // Hitung Total
                  int revenue = 0;
                  if (snapshot.hasData) {
                    revenue = _calculateRevenue(snapshot.data!.docs);
                  }

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monetization_on_outlined, color: Colors.black.withOpacity(0.6)),
                            const SizedBox(width: 8),
                            Text("Pendapatan $_selectedFilter", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _currencyFormat.format(revenue), // Format Rupiah
                          style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: const Text("Data Real-time", style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              // 4. GRID STATISTIK MEMBER (REAL-TIME STREAM)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('members').snapshots(),
                builder: (context, snapshot) {
                  int totalMembers = 0;
                  int activeMembers = 0;

                  if (snapshot.hasData) {
                    totalMembers = snapshot.data!.docs.length;
                    activeMembers = _calculateActiveMembers(snapshot.data!.docs);
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Total Member", 
                          totalMembers.toString(), 
                          Icons.groups,
                          Colors.blueAccent
                        )
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildStatCard(
                          "Member Aktif", 
                          activeMembers.toString(), 
                          Icons.verified,
                          Colors.greenAccent
                        )
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 25),
              
              // 5. BONUS: AKTIVITAS TERBARU (Mini List)
              const Text("Aktivitas Terbaru", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildRecentTransactions(),
            ],
          ),
        ),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildHeader() {
    final User? user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          String displayName = "Admin";
          ImageProvider avatarImage = const NetworkImage("https://i.pravatar.cc/150?img=12");

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['name'] ?? "Admin";
            if (data['profileImage'] != null && data['profileImage'].toString().isNotEmpty) {
              try {
                avatarImage = MemoryImage(base64Decode(data['profileImage']));
              } catch (e) { /* Fallback */ }
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Selamat Datang,", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700), width: 2),
                  image: DecorationImage(image: avatarImage, fit: BoxFit.cover),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Belum ada transaksi.", style: TextStyle(color: Colors.grey)));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            DateTime date = (data['timestamp'] as Timestamp).toDate();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
                  child: const Icon(Icons.receipt_long, color: Color(0xFFFFD700), size: 18),
                ),
                title: Text(data['packageName'] ?? 'Paket Gym', style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(DateFormat('dd MMM HH:mm').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Text(
                  "+ ${_currencyFormat.format(data['amount'])}",
                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 150,
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
      child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
    );
  }
}