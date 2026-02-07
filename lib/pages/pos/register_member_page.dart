import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart'; // Ganti SharePlus dengan ini

class RegisterMemberPage extends StatefulWidget {
  const RegisterMemberPage({super.key});

  @override
  State<RegisterMemberPage> createState() => _RegisterMemberPageState();
}

class _RegisterMemberPageState extends State<RegisterMemberPage> {
  // Controller Form
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Data Paket yang dipilih
  String? _selectedPackageId;
  String? _selectedPackageName;
  int _selectedPackagePrice = 0;
  int _selectedPackageDuration = 0; // Hari
  int _bonusDays = 0;

  bool _isLoading = false;
  
  // Controller Screenshot (Untuk Download Kartu)
  final ScreenshotController _screenshotController = ScreenshotController();

  // FORMATTER
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // --- LOGIC: SIMPAN MEMBER & TRANSAKSI ---
  Future<void> _processRegistration() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _selectedPackageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi semua data!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Generate ID Unik (Misal: MEM-timestamp)
      String memberId = "MEM${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";
      
      // 2. Hitung Tanggal Expired
      DateTime now = DateTime.now();
      int totalDays = _selectedPackageDuration + _bonusDays;
      DateTime expiredDate = now.add(Duration(days: totalDays));

      // 3. Batch Write (Agar Member & Transaksi tersimpan bersamaan)
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // A. Simpan ke Collection 'members'
      DocumentReference memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
      batch.set(memberRef, {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'registeredDate': Timestamp.now(),
        'expiredDate': Timestamp.fromDate(expiredDate),
        'status': 'active',
        'currentPackage': _selectedPackageName,
        'memberId': memberId, // QR Code akan berisi String ini
      });

      // B. Simpan ke Collection 'transactions' (Agar masuk Laporan Admin)
      DocumentReference transRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transRef, {
        'amount': _selectedPackagePrice,
        'date': Timestamp.now(),
        'timestamp': Timestamp.now(), // Field untuk sorting
        'memberId': memberId,
        'memberName': _nameController.text,
        'packageName': _selectedPackageName,
        'type': 'registration', // Tipe transaksi
        'paymentMethod': 'Cash',
      });

      // C. Commit Batch
      await batch.commit();

      // 4. Tampilkan Kartu Member (Dialog)
      if (mounted) {
        _showSuccessDialog(memberId, _nameController.text, expiredDate);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI: POPUP KARTU MEMBER SETELAH SUKSES ---
  void _showSuccessDialog(String memberId, String name, DateTime expiry) {
    showDialog(
      context: context,
      barrierDismissible: false, // User harus klik tombol tutup/download
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Registrasi Berhasil!", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              
              // WIDGET KARTU MEMBER (YANG AKAN DI-SCREENSHOT)
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  width: 300,
                  height: 450,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF121212), Color(0xFF2C2C2C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo / Nama Gym
                      const Icon(Icons.fitness_center, color: Color(0xFFFFD700), size: 40),
                      const SizedBox(height: 10),
                      const Text("GOLDEN GYM", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
                      const Text("MEMBER CARD", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 5)),
                      const Divider(color: Colors.grey, height: 30),

                      // Nama Member
                      Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
                      const SizedBox(height: 5),
                      Text("ID: $memberId", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      
                      const SizedBox(height: 20),
                      
                      // QR CODE (BACKGROUND PUTIH AGAR BISA DI-SCAN)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: QrImageView(
                          data: memberId, // Data QR adalah ID Member
                          version: QrVersions.auto,
                          size: 140.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Text("Valid Until: ${DateFormat('dd MMM yyyy').format(expiry)}", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              
              // TOMBOL ACTION
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Tutup Dialog
                          Navigator.pop(context); // Kembali ke Home POS
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.grey)),
                        child: const Text("Tutup", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloadMemberCard, // FUNGSI BARU (DOWNLOAD SAJA)
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        icon: const Icon(Icons.download, color: Colors.white, size: 18),
                        label: const Text("Download", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC BARU: DOWNLOAD KE GALERI ---
  Future<void> _downloadMemberCard() async {
    try {
      // 1. Tangkap Layar Widget Kartu
      final Uint8List? imageBytes = await _screenshotController.capture();
      
      if (imageBytes != null) {
        // 2. Simpan ke Galeri menggunakan ImageGallerySaver
        final String fileName = "GoldenGym_Card_${DateTime.now().millisecondsSinceEpoch}";
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 100,
          name: fileName
        );

        // 3. Beri Notifikasi
        if (result['isSuccess'] == true || result != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Berhasil disimpan ke Galeri!"), 
                backgroundColor: Colors.green
              )
            );
            // Opsional: Tutup dialog setelah download
            // Navigator.pop(context); 
            // Navigator.pop(context); 
          }
        } else {
           throw Exception("Gagal menyimpan");
        }
      }
    } catch (e) {
      print("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Registrasi Member", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // STEP 1: DATA DIRI
            const Text("1. Data Diri", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            _buildTextField("Nama Lengkap", _nameController, Icons.person),
            const SizedBox(height: 15),
            _buildTextField("No. WhatsApp", _phoneController, Icons.phone, isNumber: true),

            const SizedBox(height: 30),

            // STEP 2: PILIH PAKET
            const Text("2. Pilih Paket Membership", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            
            // STREAM PAKET DARI FIREBASE
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('packages').where('isActive', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                
                var packages = snapshot.data!.docs;

                return Column(
                  children: packages.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isSelected = _selectedPackageId == doc.id;
                    bool hasBonus = (data['bonusDays'] ?? 0) > 0;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPackageId = doc.id;
                          _selectedPackageName = data['name'];
                          _selectedPackagePrice = data['price'];
                          _selectedPackageDuration = data['duration'];
                          _bonusDays = data['bonusDays'] ?? 0;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700).withOpacity(0.2) : const Color(0xFF1E1E1E),
                          border: Border.all(color: isSelected ? const Color(0xFFFFD700) : Colors.white10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text("${data['duration']} Hari ${hasBonus ? '+ Bonus' : ''}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            Text(_currencyFormat.format(data['price']), style: TextStyle(color: isSelected ? const Color(0xFFFFD700) : Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),

            // STEP 3: RINGKASAN & PEMBAYARAN
            if (_selectedPackageId != null) ...[
              const Divider(color: Colors.grey),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Pembayaran", style: TextStyle(color: Colors.white)),
                  Text(_currencyFormat.format(_selectedPackagePrice), style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Metode Bayar", style: TextStyle(color: Colors.white)),
                  const Text("CASH / TUNAI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("PROSES PENDAFTARAN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFD700))),
      ),
    );
  }
}