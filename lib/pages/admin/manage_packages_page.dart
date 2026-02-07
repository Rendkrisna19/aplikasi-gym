import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Tambahkan intl di pubspec.yaml untuk format rupiah

class ManagePackagesPage extends StatefulWidget {
  const ManagePackagesPage({super.key});

  @override
  State<ManagePackagesPage> createState() => _ManagePackagesPageState();
}

class _ManagePackagesPageState extends State<ManagePackagesPage> {
  // Format Currency
  final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

  // Fungsi Create / Edit Paket
  void _showPackageDialog({DocumentSnapshot? doc}) {
    final nameController = TextEditingController(text: doc?['name'] ?? '');
    final durationController = TextEditingController(text: doc != null ? doc['duration'].toString() : '');
    final priceController = TextEditingController(text: doc != null ? doc['price'].toString() : '');
    
    // Logic Bonus: Jika edit, cek apakah bonusDays > 0. Jika baru, default false.
    bool hasBonus = doc != null ? (doc['bonusDays'] ?? 0) > 0 : false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Perlu StatefulBuilder agar Switch bisa berubah state-nya dalam Dialog
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(doc == null ? "Tambah Paket Baru" : "Edit Paket", style: const TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Input Nama Paket
                    _buildTextField("Nama Paket (Cth: Gold 3 Bulan)", nameController, false),
                    const SizedBox(height: 10),
                    // Input Durasi Hari
                    _buildTextField("Durasi (Hari)", durationController, true),
                    const SizedBox(height: 10),
                    // Input Harga
                    _buildTextField("Harga (Angka saja)", priceController, true),
                    const SizedBox(height: 20),
                    
                    // --- FITUR BONUS ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: hasBonus ? const Color(0xFFFFD700).withOpacity(0.1) : Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: hasBonus ? const Color(0xFFFFD700) : Colors.transparent),
                      ),
                      child: SwitchListTile(
                        activeColor: const Color(0xFFFFD700),
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Bonus Gratis 1 Bulan?", style: TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(
                          hasBonus ? "Member dapat +30 hari gratis" : "Tidak ada bonus tambahan",
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        value: hasBonus,
                        onChanged: (val) {
                          setDialogState(() {
                            hasBonus = val;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text("Batal", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      // DATA YANG AKAN DISIMPAN
                      Map<String, dynamic> data = {
                        'name': nameController.text,
                        'duration': int.tryParse(durationController.text) ?? 30,
                        'price': int.tryParse(priceController.text) ?? 0,
                        // LOGIC BONUS DISIMPAN DISINI
                        'bonusDays': hasBonus ? 30 : 0, 
                        'isActive': true,
                      };

                      if (doc == null) {
                        // Create Baru
                        await FirebaseFirestore.instance.collection('packages').add(data);
                      } else {
                        // Update Existing
                        await FirebaseFirestore.instance.collection('packages').doc(doc.id).update(data);
                      }
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // HEADER HALAMAN PAKET
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manajemen Paket", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => _showPackageDialog(),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
                icon: const Icon(Icons.add, color: Colors.black),
              )
            ],
          ),
        ),

        // LIST PAKET DARI FIREBASE
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('packages').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error", style: TextStyle(color: Colors.white)));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              
              var docs = snapshot.data!.docs;
              
              if (docs.isEmpty) {
                return const Center(child: Text("Belum ada paket.", style: TextStyle(color: Colors.grey)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index];
                  bool hasBonus = (data['bonusDays'] ?? 0) > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: hasBonus ? const Color(0xFFFFD700).withOpacity(0.5) : Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(
                              "${data['duration']} Hari ${hasBonus ? '+ 30 Hari (Bonus)' : ''}",
                              style: TextStyle(color: hasBonus ? const Color(0xFFFFD700) : Colors.grey, fontSize: 13)
                            ),
                            const SizedBox(height: 5),
                            Text(currency.format(data['price']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            if (hasBonus) 
                              const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.star, color: Color(0xFFFFD700), size: 18),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _showPackageDialog(doc: data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                FirebaseFirestore.instance.collection('packages').doc(data.id).delete();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isNumber) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}