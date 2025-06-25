import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'dart:io';

import 'produk_model.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Box<ProdukModel> _produkBox;

  @override
  void initState() {
    super.initState();
    _produkBox = Hive.box<ProdukModel>('produk');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E4D2B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                      const Text(
                        'Selamat Datang,',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${widget.username}!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/setting');
                    },
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 3),
                image: const DecorationImage(
                  image: AssetImage("assets/images/barcode_example.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rekomendasi Produk!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _produkBox.listenable(),
                builder: (context, Box<ProdukModel> box, _) {
                  final List<ProdukModel> produkList = box.values.toList();

                  if (produkList.isEmpty) {
                    return const Center(
                      child: Text(
                        "Belum ada produk tersedia.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: produkList.length,
                    itemBuilder: (context, index) {
                      final produk = produkList[index];
                      final Color warnaTag = const Color.fromARGB(
                        255,
                        37,
                        189,
                        54,
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            produk.gambarPath != null &&
                                    File(produk.gambarPath!).existsSync()
                                ? Image.file(
                                  File(produk.gambarPath!),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Image.asset(
                                            "assets/images/eatoscan.png",
                                            width: 60,
                                            height: 60,
                                          ),
                                )
                                : Image.asset(
                                  "assets/images/eatoscan.png",
                                  width: 60,
                                  height: 60,
                                ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    produk.tambahan.isNotEmpty
                                        ? produk.tambahan
                                        : "Kategori tidak tersedia",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color.fromARGB(137, 0, 0, 0),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: warnaTag,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    produk.nama,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: warnaTag.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      produk.risiko.isNotEmpty
                                          ? produk.risiko
                                          : "Tidak diketahui",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: warnaTag,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
