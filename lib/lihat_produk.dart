import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'produk_model.dart';
import 'edit_produk.dart';

class LihatProdukPage extends StatefulWidget {
  const LihatProdukPage({super.key});

  @override
  State<LihatProdukPage> createState() => _LihatProdukPageState();
}

class _LihatProdukPageState extends State<LihatProdukPage> {
  late Box<ProdukModel> produkBox;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    produkBox = Hive.box<ProdukModel>('produk');
  }

  void hapusProduk(int index) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "${produkBox.getAt(index)?.nama}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              try {
                produkBox.deleteAt(index);
                setState(() {
                  selectedIndex = null;
                });
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sukses: Produk berhasil dihapus.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal: Terjadi kesalahan saat menghapus produk: $e'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text(
              'Ya, Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final produkList = produkBox.values.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE85D04),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).pushNamed('/crudAdmin');
                      },
                    ),
                  ),
                  const Center(
                    child: Text(
                      'EatoScan - Data Produk',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Center(
                      child: Text(
                        'Manajemen Data Produk',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Daftar produk yang telah disimpan dalam sistem',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton('UBAH', const Color(0xFF225840), () {
                          if (selectedIndex != null) {
                            final produk = produkBox.getAt(selectedIndex!)!;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProdukPage(
                                  index: selectedIndex!,
                                  produk: produk,
                                ),
                              ),
                            ).then((result) {
                              if (result == true && mounted) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sukses: Produk berhasil diubah.'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal: Pilih data yang akan diubah.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }),
                        _buildActionButton('HAPUS', const Color(0xFF225840), () {
                          if (selectedIndex != null) {
                            hapusProduk(selectedIndex!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal: Pilih data yang akan dihapus.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        }),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 800, 
                          child: Container(
                            height: 300,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Gambar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Nama Produk',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'Kode',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Nutrisi & Unit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Kategori',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: produkList.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Belum ada data produk',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: produkList.length,
                                          itemBuilder: (context, index) {
                                            final produk = produkList[index];
                                            final isSelected = selectedIndex == index;
                                            final nutrisiDetail = produk.nutrisiDetail ?? [];

                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedIndex = index;
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? const Color(0xFF225840).withOpacity(0.1)
                                                      : null,
                                                  border: Border(
                                                    bottom: BorderSide(color: Colors.grey[300]!),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      flex: 1,
                                                      child: Center(
                                                        child: produk.gambarPath != null
                                                            ? ClipRRect(
                                                                borderRadius: BorderRadius.circular(4),
                                                                child: Image.file(
                                                                  File(produk.gambarPath!),
                                                                  width: 40,
                                                                  height: 40,
                                                                  fit: BoxFit.cover,
                                                                  errorBuilder: (context, error, stackTrace) =>
                                                                      const Icon(Icons.image_not_supported, size: 20),
                                                                ),
                                                              )
                                                            : const Icon(Icons.image, size: 20, color: Colors.grey),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        produk.nama,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Text(
                                                        produk.kode,
                                                        textAlign: TextAlign.center,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: isSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.normal,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 3,
                                                      child: Column(
                                                        children: nutrisiDetail.isNotEmpty 
                                                            ? nutrisiDetail.map<Widget>((nutrisi) {
                                                                return Text(
                                                                  '${nutrisi['nama']}: ${nutrisi['berat']}${nutrisi['unit']}',
                                                                  textAlign: TextAlign.center,
                                                                  style: TextStyle(
                                                                    fontSize: 8,
                                                                    fontWeight: isSelected
                                                                        ? FontWeight.bold
                                                                        : FontWeight.normal,
                                                                  ),
                                                                );
                                                              }).toList()
                                                            : [
                                                                ...produk.nutrisi.split(', ').map<Widget>((nutrisiString) {
                                                                  return Text(
                                                                    nutrisiString,
                                                                    textAlign: TextAlign.center,
                                                                    style: TextStyle(
                                                                      fontSize: 8,
                                                                      fontWeight: isSelected
                                                                          ? FontWeight.bold
                                                                          : FontWeight.normal,
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                              ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 2,
                                                      child: Column(
                                                        children: [
                                                          Text(
                                                            produk.tambahan,
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: isSelected
                                                                  ? FontWeight.bold
                                                                  : FontWeight.normal,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${produk.takaranKemasan}${produk.unitTakaranKemasan ?? 'g'}',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 120,
      height: 43,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
          elevation: 2,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}