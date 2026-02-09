import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ManagePackagesPage extends StatefulWidget {
  const ManagePackagesPage({super.key});

  @override
  State<ManagePackagesPage> createState() => _ManagePackagesPageState();
}

class _ManagePackagesPageState extends State<ManagePackagesPage> {
  // Format Currency
  final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Warna Tema
  final Color _goldColor = const Color(0xFFFFD700);
  final Color _cardColor = const Color(0xFF1E1E1E);
  final Color _bgColor = const Color(0xFF121212);

  // --- FUNGSI CREATE / EDIT PAKET (MODAL BESAR) ---
  void _showPackageDialog({DocumentSnapshot? doc}) {
    final nameController = TextEditingController(text: doc?['name'] ?? '');
    final durationController = TextEditingController(text: doc != null ? doc['duration'].toString() : '');
    final priceController = TextEditingController(text: doc != null ? doc['price'].toString() : '');
    
    bool hasBonus = doc != null ? (doc['bonusDays'] ?? 0) > 0 : false;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog( // Pakai Dialog biasa agar bisa custom ukuran
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(20), // Jarak dari tepi layar (biar full tapi ada sela)
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Container(
                width: double.infinity, // Pakai lebar maksimal yang diizinkan insetPadding
                constraints: const BoxConstraints(maxWidth: 500), // Batasi max lebar agar tidak aneh di Tablet/PC
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Modal
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _goldColor.withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(doc == null ? Icons.add : Icons.edit, color: _goldColor, size: 28),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            doc == null ? "Tambah Paket Baru" : "Edit Paket", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),

                      // Input Nama Paket
                      _buildModernInput(nameController, "Nama Paket", "Contoh: Gold Member 1 Bulan", Icons.label_important_outline),
                      
                      const SizedBox(height: 20),
                      
                      // Row untuk Durasi & Harga (Responsive)
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernInput(durationController, "Durasi (Hari)", "30", Icons.timer_outlined, isNumber: true)
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: _buildModernInput(priceController, "Harga (Rp)", "150000", Icons.monetization_on_outlined, isNumber: true)
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 25),
                      
                      // --- FITUR BONUS SWITCH (Tampilan Card) ---
                      InkWell(
                        onTap: () {
                          setDialogState(() => hasBonus = !hasBonus);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: hasBonus ? _goldColor.withOpacity(0.1) : Colors.black38,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: hasBonus ? _goldColor : Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.stars_rounded, color: hasBonus ? _goldColor : Colors.grey, size: 30),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Bonus Gratis 1 Bulan", 
                                      style: TextStyle(color: hasBonus ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                    Text(
                                      hasBonus ? "Member dapat tambahan +30 hari gratis" : "Tidak ada bonus tambahan",
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: hasBonus,
                                activeColor: _goldColor,
                                onChanged: (val) => setDialogState(() => hasBonus = val),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Tombol Aksi
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context), 
                              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              child: const Text("Batal", style: TextStyle(color: Colors.grey, fontSize: 16))
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                                  Map<String, dynamic> data = {
                                    'name': nameController.text,
                                    'duration': int.tryParse(durationController.text) ?? 30,
                                    'price': int.tryParse(priceController.text) ?? 0,
                                    'bonusDays': hasBonus ? 30 : 0, 
                                    'isActive': true,
                                  };

                                  if (doc == null) {
                                    await FirebaseFirestore.instance.collection('packages').add(data);
                                  } else {
                                    await FirebaseFirestore.instance.collection('packages').doc(doc.id).update(data);
                                  }
                                  if (mounted) Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _goldColor,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 5,
                                shadowColor: _goldColor.withOpacity(0.4),
                              ),
                              child: const Text("SIMPAN DATA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            }
          ),
        );
      },
    );
  }

  // --- DELETE CONFIRMATION ---
  void _confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Paket?", style: TextStyle(color: Colors.white)),
        content: Text("Anda yakin ingin menghapus paket '$name'?", style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('packages').doc(docId).delete();
              Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // HEADER HALAMAN
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Manajemen Paket", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text("Atur harga & durasi membership", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                // Tombol Tambah (Big)
                ElevatedButton.icon(
                  onPressed: () => _showPackageDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text("Tambah", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),

          // LIST PAKET GRID (PETAK)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('packages').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Terjadi Kesalahan", style: TextStyle(color: Colors.red)));
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _goldColor));
                
                var docs = snapshot.data!.docs;
                
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_membership_rounded, size: 60, color: Colors.grey[800]),
                        const SizedBox(height: 10),
                        const Text("Belum ada paket tersedia.", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                // GRID VIEW BUILDER
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Kolom (Petak)
                    childAspectRatio: 0.8, // Rasio Tinggi:Lebar (Agar memanjang ke bawah dikit)
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index];
                    bool hasBonus = (data['bonusDays'] ?? 0) > 0;

                    return _buildPackageCard(data, hasBonus);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CARD PAKET (PETAK ROUNDED) ---
  Widget _buildPackageCard(QueryDocumentSnapshot data, bool hasBonus) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20), // Rounded Petak
        border: Border.all(color: hasBonus ? _goldColor.withOpacity(0.5) : Colors.white10, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          // KONTEN UTAMA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasBonus ? _goldColor.withOpacity(0.1) : Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.card_membership_rounded, 
                    color: hasBonus ? _goldColor : Colors.grey, 
                    size: 24
                  ),
                ),
                
                const Spacer(),

                // Nama Paket
                Text(
                  data['name'], 
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 5),
                
                // Durasi
                Text(
                  "${data['duration']} Hari",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 10),
                Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                const SizedBox(height: 10),

                // Harga
                Text(
                  currency.format(data['price']), 
                  style: TextStyle(color: _goldColor, fontSize: 16, fontWeight: FontWeight.w900)
                ),
              ],
            ),
          ),

          // BADGE BONUS (Jika Ada)
          if (hasBonus)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _goldColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "BONUS", 
                  style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ),

          // TOMBOL AKSI (Edit/Delete) - POSISI POJOK KANAN BAWAH
          Positioned(
            bottom: 5,
            right: 5,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              color: _cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white10)),
              onSelected: (value) {
                if (value == 'edit') _showPackageDialog(doc: data);
                if (value == 'delete') _confirmDelete(data.id, data['name']);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text("Edit", style: TextStyle(color: Colors.white))]),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Hapus", style: TextStyle(color: Colors.white))]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- WIDGET HELPER INPUT ---
  Widget _buildModernInput(TextEditingController controller, String label, String hint, IconData icon, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withOpacity(0.4)),
            prefixIcon: Icon(icon, color: _goldColor, size: 20),
            filled: true,
            fillColor: Colors.black26,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _goldColor)),
          ),
        ),
      ],
    );
  }
}