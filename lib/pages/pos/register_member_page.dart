import 'dart:convert'; // Import untuk Base64
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class RegisterMemberPage extends StatefulWidget {
  const RegisterMemberPage({super.key});

  @override
  State<RegisterMemberPage> createState() => _RegisterMemberPageState();
}

class _RegisterMemberPageState extends State<RegisterMemberPage> {
  // Controller Form
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Data Paket
  String? _selectedPackageId;
  String? _selectedPackageName;
  int _selectedPackagePrice = 0;
  int _selectedPackageDuration = 0;
  int _bonusDays = 0;

  bool _isLoading = false;
  
  // Controller Screenshot
  final ScreenshotController _screenshotController = ScreenshotController();

  // FORMATTER
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // --- LOGIC: SIMPAN DATA MEMBER ---
  Future<void> _processRegistration() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _selectedPackageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon lengkapi semua data!"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String memberId = "MEM${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";
      DateTime now = DateTime.now();
      int totalDays = _selectedPackageDuration + _bonusDays;
      DateTime expiredDate = now.add(Duration(days: totalDays));

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Simpan Data Member (Awal)
      DocumentReference memberRef = FirebaseFirestore.instance.collection('members').doc(memberId);
      batch.set(memberRef, {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'registeredDate': Timestamp.now(),
        'expiredDate': Timestamp.fromDate(expiredDate),
        'status': 'active',
        'currentPackage': _selectedPackageName,
        'memberId': memberId,
        'cardBase64': "", // Nanti diisi setelah kartu digenerate
      });

      // 2. Simpan Transaksi
      DocumentReference transRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transRef, {
        'amount': _selectedPackagePrice,
        'date': Timestamp.now(),
        'timestamp': Timestamp.now(),
        'memberId': memberId,
        'memberName': _nameController.text,
        'packageName': _selectedPackageName,
        'type': 'registration',
        'paymentMethod': 'Cash',
      });

      await batch.commit();

      if (mounted) {
        // Tampilkan Dialog untuk Generate Kartu
        _showSuccessDialog(memberId, _nameController.text, expiredDate);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- UI: POPUP KARTU MEMBER (FIX NO SIZE ERROR) ---
  void _showSuccessDialog(String memberId, String name, DateTime expiry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Gunakan Dialog biasa + SingleChildScrollView untuk menghindari error layout
        return Dialog(
          backgroundColor: Colors.transparent, 
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Sukses
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: const Text("Registrasi Berhasil! ✅", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 20),

              // --- BAGIAN KARTU YANG AKAN DI-SCREENSHOT ---
              Center(
                child: SingleChildScrollView(
                  child: Screenshot(
                    controller: _screenshotController,
                    // Container ini WAJIB punya width fix agar tidak error "No Size"
                    child: Container(
                      width: 320, 
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF000000), Color(0xFF2C2C2C)], 
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFD700), width: 3),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fitness_center, color: Color(0xFFFFD700), size: 30),
                          const SizedBox(height: 5),
                          const Text("GOLDEN GYM", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                          const SizedBox(height: 20),
                          
                          Text(name.toUpperCase(), 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), 
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          Text("ID: $memberId", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          
                          const SizedBox(height: 15),
                          
                          // QR CODE (Wajib background putih)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: QrImageView(
                              data: memberId,
                              version: QrVersions.auto,
                              size: 140.0,
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          
                          const SizedBox(height: 15),
                          Text("Valid Until: ${DateFormat('dd MMM yyyy').format(expiry)}", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              
              // TOMBOL ACTION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text("Tutup", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _saveCardAndBase64(memberId), // Update Logic
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                    ),
                    icon: const Icon(Icons.download_rounded, color: Colors.black, size: 18),
                    label: const Text("Simpan Kartu", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // --- LOGIC: SIMPAN GALERI & UPDATE BASE64 KE FIRESTORE ---
  Future<void> _saveCardAndBase64(String memberId) async {
    try {
      // 1. Capture Screenshot
      // pixelRatio 2.0 agar kualitas bagus tapi size tidak terlalu besar (agar muat di Firestore)
      final Uint8List? imageBytes = await _screenshotController.capture(pixelRatio: 2.0); 
      
      if (imageBytes != null) {
        
        // A. Simpan ke Galeri HP
        final String fileName = "GoldenGym_${DateTime.now().millisecondsSinceEpoch}";
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 80,
          name: fileName
        );

        // B. Konversi ke Base64 & Update Firestore (Tanpa Storage)
        String base64String = base64Encode(imageBytes);
        
        await FirebaseFirestore.instance.collection('members').doc(memberId).update({
          'cardBase64': base64String, // Data gambar tersimpan di dokumen
        });

        // C. Feedback User
        if (result['isSuccess'] == true || result != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Kartu disimpan di Galeri & Database! ✅"), backgroundColor: Colors.green)
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Gagal: $e. Coba Restart Aplikasi."), backgroundColor: Colors.red)
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
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('packages').where('isActive', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                
                var packages = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    var doc = packages[index];
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700) : const Color(0xFF1E1E1E),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.white10,
                            width: 2
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_membership_rounded, color: isSelected ? Colors.black : const Color(0xFFFFD700), size: 32),
                            const SizedBox(height: 8),
                            Text(data['name'], style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text("${data['duration']} Hari ${hasBonus ? '+ Bonus' : ''}", style: TextStyle(color: isSelected ? Colors.black87 : Colors.grey, fontSize: 10)),
                            const SizedBox(height: 8),
                            Text(_currencyFormat.format(data['price']), style: TextStyle(color: isSelected ? Colors.black : const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),

            // STEP 3: BAYAR
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
            
            const SizedBox(height: 50),
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