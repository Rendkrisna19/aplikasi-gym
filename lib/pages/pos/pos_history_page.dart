import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PosHistoryPage extends StatefulWidget {
  const PosHistoryPage({super.key});

  @override
  State<PosHistoryPage> createState() => _PosHistoryPageState();
}

class _PosHistoryPageState extends State<PosHistoryPage> {
  // STATE FILTER
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPackage; // Null = Semua Paket

  // FORMATTER
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  // --- LOGIC: PILIH RENTANG TANGGAL ---
  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFFFD700),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        // Set end date ke akhir hari (23:59:59) agar transaksi hari itu masuk semua
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  // --- LOGIC: RESET FILTER ---
  void _resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedPackage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Riwayat Transaksi", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
            tooltip: "Reset Filter",
          )
        ],
      ),
      body: Column(
        children: [
          // 1. BAGIAN FILTER (HEADER)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BARIS 1: FILTER TANGGAL
                InkWell(
                  onTap: _pickDateRange,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Color(0xFFFFD700), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (_startDate == null || _endDate == null)
                                ? "Filter Tanggal (Semua)"
                                : "${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),

                // BARIS 2: FILTER PAKET (STREAM DARI DB)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('packages').snapshots(),
                  builder: (context, snapshot) {
                    List<DropdownMenuItem<String>> items = [
                      const DropdownMenuItem(value: null, child: Text("Semua Paket")),
                    ];

                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        String name = doc['name'];
                        items.add(DropdownMenuItem(value: name, child: Text(name)));
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPackage,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2C2C2C),
                          style: const TextStyle(color: Colors.white),
                          icon: const Icon(Icons.filter_list, color: Color(0xFFFFD700)),
                          items: items,
                          onChanged: (val) => setState(() => _selectedPackage = val),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 2. LIST TRANSAKSI
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada transaksi.", style: TextStyle(color: Colors.grey)));
                }

                // --- LOGIKA FILTERING (CLIENT SIDE) ---
                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool passDate = true;
                  bool passPackage = true;

                  // Cek Filter Tanggal
                  if (_startDate != null && _endDate != null) {
                    Timestamp ts = data['timestamp'];
                    DateTime date = ts.toDate();
                    passDate = date.isAfter(_startDate!) && date.isBefore(_endDate!);
                  }

                  // Cek Filter Paket
                  if (_selectedPackage != null) {
                    String pkgName = data['packageName'] ?? '';
                    passPackage = pkgName == _selectedPackage;
                  }

                  return passDate && passPackage;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Tidak ada data sesuai filter.", style: TextStyle(color: Colors.grey)));
                }

                // HITUNG TOTAL DARI HASIL FILTER
                int totalFiltered = docs.fold(0, (sum, doc) => sum + (doc['amount'] as int));

                return Column(
                  children: [
                    // TOTAL RINGKASAN KECIL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      color: Colors.black26,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total (${docs.length} Tx)", style: const TextStyle(color: Colors.grey)),
                          Text(_currencyFormat.format(totalFiltered), style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    // LIST ITEM
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          DateTime date = (data['timestamp'] as Timestamp).toDate();
                          
                          // Styling Tipe Transaksi
                          bool isRegis = data['type'] == 'registration';
                          IconData icon = isRegis ? Icons.person_add : Icons.update;
                          Color iconColor = isRegis ? Colors.greenAccent : Colors.orangeAccent;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: iconColor.withOpacity(0.1),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              title: Text(
                                data['memberName'] ?? 'Tanpa Nama',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['packageName'] ?? '-', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12)),
                                  Text(_dateFormat.format(date), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              trailing: Text(
                                _currencyFormat.format(data['amount']),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}