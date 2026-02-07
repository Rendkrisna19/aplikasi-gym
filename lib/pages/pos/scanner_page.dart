import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class UniversalScannerPage extends StatefulWidget {
  const UniversalScannerPage({super.key});

  @override
  State<UniversalScannerPage> createState() => _UniversalScannerPageState();
}

class _UniversalScannerPageState extends State<UniversalScannerPage> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );
  bool _isTorchOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan QR Member", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        actions: [
          // TOMBOL FLASH
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: const Color(0xFFFFD700),
            ),
            onPressed: () {
              controller.toggleTorch();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          // TOMBOL GALERI
          IconButton(
            icon: const Icon(Icons.image, color: Colors.white),
            onPressed: _pickImageFromGallery,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String code = barcodes.first.rawValue ?? "";
                if (code.isNotEmpty) {
                  controller.stop();
                  Navigator.pop(context, code); // KEMBALIKAN KODE KE HALAMAN SEBELUMNYA
                }
              }
            },
          ),
          // OVERLAY KOTAK FOKUS
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFD700), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  "Arahkan ke QR Code", 
                  style: TextStyle(color: Colors.white70, fontSize: 12, backgroundColor: Colors.black45)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // LOGIC AMBIL GAMBAR DARI GALERI
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // Analisa gambar menggunakan MobileScanner
      final BarcodeCapture? capture = await controller.analyzeImage(image.path);
      
      if (capture != null && capture.barcodes.isNotEmpty) {
        final String code = capture.barcodes.first.rawValue ?? "";
        if (mounted && code.isNotEmpty) {
           Navigator.pop(context, code); // KEMBALIKAN KODE
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("QR Code tidak ditemukan di gambar ini."))
          );
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}