import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'produk_model.dart';
import 'product_detail_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late Box<ProdukModel> _produkBox;
  late Box _userBox;
  bool _isScanning = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _produkBox = Hive.box<ProdukModel>('produk');
    _userBox = Hive.box('eatoscanBox');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E4D2B),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildScannerSection(),
            const SizedBox(height: 12),
            _buildSlideSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _userBox.listenable(),
      builder: (context, box, _) {
        final isLoggedIn = box.get('isLoggedIn', defaultValue: false);
        final username = box.get('loggedInUser', defaultValue: 'User');
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EatoScan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selamat datang, ${isLoggedIn ? username : 'User'}!',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              isLoggedIn
                  ? IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed:
                        () =>
                            Navigator.pushReplacementNamed(context, '/setting'),
                  )
                  : Container(
                    width: 95,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed:
                          () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        "Masuk",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScannerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _buildCameraScanner(),
    );
  }

  Widget _buildCameraScanner() {
    return SizedBox(
      width: 300,
      height: 300,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: MobileScanner(
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.normal,
            facing: CameraFacing.back,
            returnImage: true, 
          ),
          onDetect: (BarcodeCapture capture) async {
            if (_isScanning) return;
            setState(() => _isScanning = true);

            final List<Barcode> barcodes = capture.barcodes;
            final Uint8List? imageBytes = capture.image;

            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code == null) {
                setState(() => _isScanning = false);
                continue;
              }

              debugPrint('Barcode ditemukan: $code');

              final matchedProduct = _produkBox.values.firstWhere(
                (produk) => produk.kode == code,
                orElse:
                    () => ProdukModel(
                      nama: '',
                      kode: '',
                      nutrisi: '',
                      tambahan: '',
                      risiko: '',
                      preferensiNutrisi: const {
                        'bebas_laktosa': false,
                        'bebas_gluten': false,
                        'vegetarian': false,
                        'vegan': false,
                      },
                      takaranKemasan: 0.0,
                      sajianPerKemasan: 0.0,
                      gambarPath: null,
                    ),
              );

              if (matchedProduct.nama.isEmpty) {
                if (!mounted) {
                  setState(() => _isScanning = false);
                  return;
                }
                await showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: const Text(
                          'Produk Tidak Ditemukan',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'Produk tidak ada dalam data aplikasi.',
                          textAlign: TextAlign.center,
                        ),
                        actionsAlignment: MainAxisAlignment.center,
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E4D2B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              setState(() => _isScanning = false);
                            },
                            child: const Text(
                              'Coba Lagi',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                );
                return;
              }

              String imagePath =
                  'assets/images/eatoscan.png'; 
              if (imageBytes != null && imageBytes.isNotEmpty) {
                try {
                  final tempDir = await getTemporaryDirectory();
                  final fileName =
                      '${DateTime.now().millisecondsSinceEpoch}.jpg';
                  final tempImagePath = path.join(tempDir.path, fileName);
                  final imageFile = File(tempImagePath);
                  await imageFile.writeAsBytes(imageBytes);
                  imagePath = tempImagePath;
                  debugPrint('Gambar disimpan di: $imagePath');
                } catch (e) {
                  debugPrint('Gagal menyimpan gambar: $e');
                }
              } else {
                debugPrint('Tidak ada imageBytes dari capture.image');
              }

              if (!mounted) {
                setState(() => _isScanning = false);
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProductDetailScreen(
                        product: matchedProduct,
                        imagePath: imagePath,

                      ),
                ),
              ).then((_) {
                if (mounted) {
                  setState(() => _isScanning = false);
                }
              });

              break; 
            }
          },
        ),
      ),
    );
  }

  Widget _buildSlideSection() {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildSlide(
                  title: 'Sehat Itu Pilihan, Scan Dulu Sebelum Beli',
                  subtitle:
                      'Eatoscan bantu kamu cek produk kemasan secara cepat & akurat',
                  icon: Icons.camera_alt,
                ),
                _buildSlide(
                  title: 'Gizi Lebih Transparan',
                  subtitle:
                      'Eatoscan bantu kamu cek gizi, komposisi, dan lainnya. Yuk jadi lebih bijak!',
                  icon: Icons.info_outline,
                ),
                _buildSlide(
                  title: 'Scan Makananmu, Cek Gizinya!',
                  subtitle:
                      'Arahkan kamera ke barcode produk dan temukan info gizi secara instan!',
                  icon: Icons.qr_code_scanner,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        _currentPage == index ? Colors.white : Colors.white38,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: const Color(0xFF1E4D2B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 50.0),
          const SizedBox(height: 20.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14.0),
          ),
        ],
      ),
    );
  }
}
