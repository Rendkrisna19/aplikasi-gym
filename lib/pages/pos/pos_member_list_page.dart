import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';

class PosMemberListPage extends StatefulWidget {
  const PosMemberListPage({super.key});

  @override
  State<PosMemberListPage> createState() => _PosMemberListPageState();
}

class _PosMemberListPageState extends State<PosMemberListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Daftar Member", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cari Nama Member...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('members').orderBy('registeredDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada member.", style: TextStyle(color: Colors.grey)));
          }

          // FILTER SEARCH (Client Side)
          var docs = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            var name = (data['name'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery);
          }).toList();

          if (docs.isEmpty) {
             return const Center(child: Text("Member tidak ditemukan.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return _MemberCardItem(docId: docs[index].id, data: data);
            },
          );
        },
      ),
    );
  }
}

// --- WIDGET ITEM MEMBER (DIPISAH AGAR TIMER BERJALAN SENDIRI-SENDIRI) ---
class _MemberCardItem extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _MemberCardItem({required this.docId, required this.data});

  @override
  State<_MemberCardItem> createState() => _MemberCardItemState();
}

class _MemberCardItemState extends State<_MemberCardItem> {
  late Timer _timer;
  String _timeLeft = "Menghitung...";
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel(); // Matikan timer saat scroll/tutup agar hemat memori
    super.dispose();
  }

  void _startTimer() {
    _updateTime(); // Jalan sekali di awal
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    Timestamp? expTs = widget.data['expiredDate'];
    if (expTs == null) return;

    DateTime expiry = expTs.toDate();
    DateTime now = DateTime.now();
    Duration diff = expiry.difference(now);

    if (diff.isNegative) {
      // SUDAH EXPIRED
      if (!_isExpired) setState(() => _isExpired = true);
      setState(() => _timeLeft = "Expired pada ${DateFormat('dd MMM yyyy HH:mm').format(expiry)}");
    } else {
      // MASIH AKTIF (HITUNG MUNDUR)
      if (_isExpired) setState(() => _isExpired = false);
      
      String days = diff.inDays.toString();
      String hours = (diff.inHours % 24).toString().padLeft(2, '0');
      String minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
      String seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

      setState(() {
        _timeLeft = "$days Hari : $hours Jam : $minutes Menit : $seconds Detik";
      });
    }
  }

  // --- LOGIC: PERPANJANG MEMBER ---
  void _showRenewDialog() {
    showDialog(
      context: context,
      builder: (context) => _RenewDialog(
        memberId: widget.docId, 
        currentName: widget.data['name'],
        currentExpiry: (widget.data['expiredDate'] as Timestamp).toDate()
      )
    );
  }

  // --- LOGIC: DOWNLOAD KARTU ---
  void _showCardPreview() {
    showDialog(
      context: context,
      builder: (context) => _CardPreviewDialog(
        memberId: widget.data['memberId'] ?? widget.docId,
        name: widget.data['name'],
        expiry: (widget.data['expiredDate'] as Timestamp).toDate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = _isExpired ? Colors.redAccent : const Color(0xFFFFD700);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: NAMA & PAKET
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.data['name'] ?? 'No Name', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.data['currentPackage'] ?? '-', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(_isExpired ? "EXPIRED" : "AKTIF", style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          
          const Divider(color: Colors.white10, height: 20),

          // COUNTDOWN WAKTU
          Row(
            children: [
              Icon(Icons.timer_outlined, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _timeLeft,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'), // Monospace biar angkanya rapi
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // TOMBOL AKSI (PERPANJANG & DOWNLOAD)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showCardPreview,
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text("QR Card"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showRenewDialog,
                  icon: const Icon(Icons.update, size: 16, color: Colors.black),
                  label: const Text("Perpanjang"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- DIALOG PERPANJANGAN (STATEFUL UNTUK PILIH PAKET) ---
class _RenewDialog extends StatefulWidget {
  final String memberId;
  final String currentName;
  final DateTime currentExpiry;

  const _RenewDialog({required this.memberId, required this.currentName, required this.currentExpiry});

  @override
  State<_RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends State<_RenewDialog> {
  String? _selectedPkgId;
  String? _selectedPkgName;
  int _pkgPrice = 0;
  int _pkgDuration = 0;
  bool _isLoading = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<void> _processRenew() async {
    if (_selectedPkgId == null) return;
    setState(() => _isLoading = true);

    try {
      // LOGIC TANGGAL
      DateTime now = DateTime.now();
      DateTime newExpiry;
      
      // Jika masih aktif, tambah dari tanggal expired lama. Jika sudah mati, mulai dari hari ini.
      if (widget.currentExpiry.isAfter(now)) {
        newExpiry = widget.currentExpiry.add(Duration(days: _pkgDuration));
      } else {
        newExpiry = now.add(Duration(days: _pkgDuration));
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Update Member
      DocumentReference memberRef = FirebaseFirestore.instance.collection('members').doc(widget.memberId);
      batch.update(memberRef, {
        'expiredDate': Timestamp.fromDate(newExpiry),
        'currentPackage': _selectedPkgName,
        'status': 'active', // Pastikan jadi aktif lagi
      });

      // 2. Catat Transaksi
      DocumentReference transRef = FirebaseFirestore.instance.collection('transactions').doc();
      batch.set(transRef, {
        'amount': _pkgPrice,
        'date': Timestamp.now(),
        'timestamp': Timestamp.now(),
        'memberId': widget.memberId,
        'memberName': widget.currentName,
        'packageName': _selectedPkgName,
        'type': 'renewal', // Tipe: Perpanjangan
        'paymentMethod': 'Cash',
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perpanjangan Berhasil!"), backgroundColor: Colors.green));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text("Perpanjang Membership", style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Member: ${widget.currentName}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            const Text("Pilih Paket Baru:", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // LIST PAKET (Dropdown/List)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('packages').where('isActive', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    bool isSelected = _selectedPkgId == doc.id;
                    int bonus = data['bonusDays'] ?? 0;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPkgId = doc.id;
                          _selectedPkgName = data['name'];
                          _pkgPrice = data['price'];
                          _pkgDuration = data['duration'] + bonus; // Total hari termasuk bonus
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700).withOpacity(0.2) : Colors.black26,
                          border: Border.all(color: isSelected ? const Color(0xFFFFD700) : Colors.transparent),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(data['name'], style: const TextStyle(color: Colors.white)),
                            Text(_currencyFormat.format(data['price']), style: const TextStyle(color: Color(0xFFFFD700))),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: _isLoading || _selectedPkgId == null ? null : _processRenew,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
            : const Text("Bayar & Perpanjang", style: TextStyle(color: Colors.black)),
        )
      ],
    );
  }
}

// --- DIALOG DOWNLOAD KARTU (REUSABLE) ---
class _CardPreviewDialog extends StatefulWidget {
  final String memberId;
  final String name;
  final DateTime expiry;

  const _CardPreviewDialog({required this.memberId, required this.name, required this.expiry});

  @override
  State<_CardPreviewDialog> createState() => _CardPreviewDialogState();
}

class _CardPreviewDialogState extends State<_CardPreviewDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _download() async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        final String fileName = "GoldenGym_${widget.name}_${DateTime.now().millisecondsSinceEpoch}";
        final result = await ImageGallerySaverPlus.saveImage(imageBytes, quality: 100, name: fileName);
        if (mounted && (result['isSuccess'] == true || result != null)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kartu disimpan ke Galeri!"), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121212),
      contentPadding: const EdgeInsets.all(16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // WIDGET YANG DI-CAPTURE
          Screenshot(
            controller: _screenshotController,
            child: Container(
              width: 280,
              height: 420,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF121212), Color(0xFF2C2C2C)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, color: Color(0xFFFFD700), size: 40),
                  const SizedBox(height: 10),
                  const Text("GOLDEN GYM", style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                  const Divider(color: Colors.grey, height: 30),
                  Text(widget.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20), textAlign: TextAlign.center),
                  Text("ID: ${widget.memberId}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white,
                    child: QrImageView(data: widget.memberId, version: QrVersions.auto, size: 120.0),
                  ),
                  const SizedBox(height: 20),
                  Text("Valid: ${DateFormat('dd MMM yyyy').format(widget.expiry)}", style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _download,
            icon: const Icon(Icons.download, color: Colors.black),
            label: const Text("Download Ulang", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), minimumSize: const Size(double.infinity, 45)),
          )
        ],
      ),
    );
  }
}