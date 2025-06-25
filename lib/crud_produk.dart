import 'package:eatoscan/produk_model.dart';
import 'package:flutter/material.dart';
import 'package:eatoscan/lihat_produk.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class CrudProduk extends StatelessWidget {
  const CrudProduk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EatoScan',
      theme: ThemeData(primarySwatch: Colors.orange, fontFamily: 'Arial'),
      home: const ProductFormPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kodeController = TextEditingController();
  final TextEditingController _takaranKemasanController = TextEditingController();
  final TextEditingController _sajianPerKemasanController = TextEditingController();
  
  final List<TextEditingController> _nutrisiNamaControllers = [];
  final List<TextEditingController> _nutrisiBeratControllers = [];
  final List<String> _nutrisiUnits = [];
  
  final List<TextEditingController> _risikoControllers = [TextEditingController()];
  
  String? _selectedKategori;
  String _unitTakaranKemasan = 'g';
  final List<String> _availableUnits = ['g', 'mg', 'kkal', 'ml', '%', 'IU'];
  
  Map<String, bool> _preferensiNutrisi = {
    'bebas_laktosa': false,
    'bebas_gluten': false,
    'vegetarian': false,
    'vegan': false,
  };
  XFile? _gambarProduk;
  String? _gambarPath;

  final TextEditingController _currentNutrisiNamaController = TextEditingController();
  final TextEditingController _currentNutrisiBeratController = TextEditingController();
  String _currentSelectedUnit = 'g';

  Future<void> _pilihGambar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _gambarProduk = pickedFile;
      });
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _gambarPath = savedImage.path;
      });
    }
  }

  String _getSuggestedUnit(String nama) {
    final lowerNama = nama.toLowerCase();
    if (lowerNama.contains('gula') || lowerNama.contains('lemak') || 
        lowerNama.contains('protein') || lowerNama.contains('karbohidrat')) {
      return 'g';
    } else if (lowerNama.contains('natrium') || lowerNama.contains('kolesterol') ||
               lowerNama.contains('vitamin')) {
      return 'mg';
    } else if (lowerNama.contains('kalori') || lowerNama.contains('energi')) {
      return 'kkal';
    } else {
      return 'g';
    }
  }

  void _resetForm() {
    _namaController.clear();
    _kodeController.clear();
    _takaranKemasanController.clear();
    _sajianPerKemasanController.clear();
    
    for (var controller in _nutrisiNamaControllers) {
      controller.dispose();
    }
    for (var controller in _nutrisiBeratControllers) {
      controller.dispose();
    }
    for (var controller in _risikoControllers) {
      controller.dispose();
    }
    
    setState(() {
      _selectedKategori = null;
      _unitTakaranKemasan = 'g';
      _preferensiNutrisi = {
        'bebas_laktosa': false,
        'bebas_gluten': false,
        'vegetarian': false,
        'vegan': false,
      };
      _gambarProduk = null;
      _gambarPath = null;
      
      _nutrisiNamaControllers.clear();
      _nutrisiBeratControllers.clear();
      _nutrisiUnits.clear();
      _risikoControllers.clear();
      
      _risikoControllers.add(TextEditingController());

      _currentNutrisiNamaController.clear();
      _currentNutrisiBeratController.clear();
      _currentSelectedUnit = 'g';
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _takaranKemasanController.dispose();
    _sajianPerKemasanController.dispose();
    for (var c in _nutrisiNamaControllers) {
      c.dispose();
    }
    for (var c in _nutrisiBeratControllers) {
      c.dispose();
    }
    for (var c in _risikoControllers) {
      c.dispose();
    }
    _currentNutrisiNamaController.dispose();
    _currentNutrisiBeratController.dispose();
    super.dispose();
  }

  void _simpanProduk() async {
    if (_namaController.text.isEmpty || _kodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Nama dan kode produk harus diisi.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_nutrisiNamaControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Minimal harus menambahkan satu data nutrisi.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final nutrisiList = <String>[];
    final nutrisiDetailList = <Map<String, dynamic>>[];
    
    for (int i = 0; i < _nutrisiNamaControllers.length; i++) {
      final nama = _nutrisiNamaControllers[i].text.trim();
      final berat = _nutrisiBeratControllers[i].text.trim();
      final unit = _nutrisiUnits[i];
      
      if (nama.isEmpty || berat.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: Data nutrisi "${nama.isEmpty ? 'tanpa nama' : nama}" tidak lengkap.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      nutrisiList.add('$nama ($berat $unit)');
      nutrisiDetailList.add({
        'nama': nama,
        'berat': double.tryParse(berat) ?? 0.0,
        'unit': unit,
      });
    }

    if (_takaranKemasanController.text.isEmpty || _sajianPerKemasanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Takaran kemasan dan sajian per kemasan harus diisi.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_selectedKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Kategori produk harus dipilih.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final risikoList = <String>[];
    for (var controller in _risikoControllers) {
      final text = controller.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal: Semua potensi risiko harus diisi.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      risikoList.add(text);
    }

    try {
      final produk = ProdukModel(
        nama: _namaController.text,
        kode: _kodeController.text,
        nutrisi: nutrisiList.join(', '),
        tambahan: _selectedKategori ?? 'Tidak diketahui',
        risiko: risikoList.join(', '),
        preferensiNutrisi: _preferensiNutrisi,
        takaranKemasan: double.parse(_takaranKemasanController.text),
        sajianPerKemasan: double.parse(_sajianPerKemasanController.text),
        gambarPath: _gambarPath,
        unitTakaranKemasan: _unitTakaranKemasan,
        nutrisiDetail: nutrisiDetailList,
      );

      final produkBox = Hive.box<ProdukModel>('produk');
      await produkBox.add(produk);

      _resetForm();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sukses: Produk berhasil disimpan.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: Terjadi kesalahan saat menyimpan produk. ($e)'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _lihatData() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LihatProdukPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        _resetForm();
                        Navigator.of(context, rootNavigator: true).pushNamed('/dashboard');
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
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                'Kelola data produk dengan informasi nutrisi dan unit yang tepat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),

                            FormFieldWithLabel(
                              label: 'Nama Produk',
                              controller: _namaController,
                            ),
                            FormFieldWithLabel(
                              label: 'Kode Produk',
                              controller: _kodeController,
                            ),
                            
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      'Takaran Kemasan',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: _takaranKemasanController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            hintText: 'Takaran kemasan',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _unitTakaranKemasan,
                                              isExpanded: true,
                                              style: const TextStyle(fontSize: 12, color: Colors.black),
                                              items: _availableUnits.map((String unit) {
                                                return DropdownMenuItem<String>(
                                                  value: unit,
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(unit),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  setState(() {
                                                    _unitTakaranKemasan = newValue;
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            FormFieldWithLabel(
                              label: 'Sajian per Kemasan',
                              controller: _sajianPerKemasanController,
                              keyboardType: TextInputType.number,
                            ),

                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Text(
                                      'Kandungan Nutrisi',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      if (_nutrisiNamaControllers.isEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(16),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.orange[200]!),
                                            borderRadius: BorderRadius.circular(15),
                                            color: Colors.orange[50],
                                          ),
                                          child: const Text(
                                            'Belum ada data nutrisi. Silakan tambahkan minimal satu nutrisi.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.orange,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                      ...List.generate(_nutrisiNamaControllers.length, (index) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey),
                                                    borderRadius: BorderRadius.circular(15),
                                                    color: Colors.grey[50],
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _nutrisiNamaControllers[index].text,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Jumlah: ${_nutrisiBeratControllers[index].text} ${_nutrisiUnits[index]}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                onPressed: () {
                                                  setState(() {
                                                    _nutrisiNamaControllers[index].dispose();
                                                    _nutrisiBeratControllers[index].dispose();
                                                    _nutrisiNamaControllers.removeAt(index);
                                                    _nutrisiBeratControllers.removeAt(index);
                                                    _nutrisiUnits.removeAt(index);
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      }),

                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.green[200]!),
                                          borderRadius: BorderRadius.circular(15),
                                          color: Colors.green[50],
                                        ),
                                        child: Column(
                                          children: [
                                            
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _currentNutrisiNamaController,
                                                    style: const TextStyle(fontSize: 12),
                                                    decoration: InputDecoration(
                                                      hintText: 'Nama nutrisi (contoh: Protein, Karbohidrat)',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      isDense: true,
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () {
                                                    final suggestedUnit = _getSuggestedUnit(_currentNutrisiNamaController.text);
                                                    setState(() {
                                                      _currentSelectedUnit = suggestedUnit;
                                                    });
                                                  },
                                                  icon: const Icon(Icons.auto_fix_high, size: 20),
                                                  tooltip: 'Auto-suggest unit',
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Colors.orange[100],
                                                    foregroundColor: Colors.orange[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            Row(
                                              children: [
                                                Expanded(
                                                  flex: 2,
                                                  child: TextField(
                                                    controller: _currentNutrisiBeratController,
                                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                    style: const TextStyle(fontSize: 12),
                                                    decoration: InputDecoration(
                                                      hintText: 'Jumlah',
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      isDense: true,
                                                      contentPadding: const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 1,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.grey),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: DropdownButtonHideUnderline(
                                                      child: DropdownButton<String>(
                                                        value: _currentSelectedUnit,
                                                        isExpanded: true,
                                                        style: const TextStyle(fontSize: 12, color: Colors.black),
                                                        items: _availableUnits.map((String unit) {
                                                          return DropdownMenuItem<String>(
                                                            value: unit,
                                                            child: Padding(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                                              child: Text(unit),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (String? newValue) {
                                                          if (newValue != null) {
                                                            setState(() {
                                                              _currentSelectedUnit = newValue;
                                                            });
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: () {
                                                  if (_currentNutrisiNamaController.text.trim().isEmpty) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Nama nutrisi harus diisi'),
                                                        backgroundColor: Colors.orange,
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  
                                                  if (_currentNutrisiBeratController.text.trim().isEmpty) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Jumlah nutrisi harus diisi'),
                                                        backgroundColor: Colors.orange,
                                                        duration: Duration(seconds: 2),
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  setState(() {
                                                    _nutrisiNamaControllers.add(
                                                      TextEditingController(text: _currentNutrisiNamaController.text.trim())
                                                    );
                                                    _nutrisiBeratControllers.add(
                                                      TextEditingController(text: _currentNutrisiBeratController.text.trim())
                                                    );
                                                    _nutrisiUnits.add(_currentSelectedUnit);
                                                    _currentNutrisiNamaController.clear();
                                                    _currentNutrisiBeratController.clear();
                                                    _currentSelectedUnit = 'g';
                                                  });
                                                },
                                                icon: const Icon(Icons.add, size: 16),
                                                label: const Text(
                                                  'Tambah Nutrisi',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            RiskInputList(controllerList: _risikoControllers),
                            CategoryDropdown(
                              onChanged: (value) => setState(() => _selectedKategori = value),
                              selectedValue: _selectedKategori,
                            ),
                            
                            const SizedBox(height: 16),
                            const Text(
                              'Preferensi Nutrisi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Column(
                              children: _preferensiNutrisi.keys.map((key) {
                                return CheckboxListTile(
                                  title: Text(key.replaceAll('_', ' ').toUpperCase()),
                                  value: _preferensiNutrisi[key],
                                  onChanged: (value) {
                                    setState(() {
                                      _preferensiNutrisi[key] = value ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text('Gambar Produk'),
                                ),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _pilihGambar,
                                    child: Text(
                                      _gambarProduk == null ? 'Pilih Gambar' : 'Gambar Dipilih',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_gambarProduk != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Image.file(
                                  File(_gambarProduk!.path),
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    ActionButtons(onSimpan: _simpanProduk, onLihat: _lihatData),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const FormFieldWithLabel({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RiskInputList extends StatefulWidget {
  final List<TextEditingController> controllerList;

  const RiskInputList({super.key, required this.controllerList});

  @override
  State<RiskInputList> createState() => _RiskInputListState();
}

class _RiskInputListState extends State<RiskInputList> {
  void _addField() {
    setState(() {
      widget.controllerList.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    setState(() {
      widget.controllerList[index].dispose();
      widget.controllerList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.controllerList.length, (index) {
        return RiskInputRow(
          controller: widget.controllerList[index],
          isLast: index == widget.controllerList.length - 1,
          onAdd: _addField,
          onRemove: widget.controllerList.length > 1 ? () => _removeField(index) : null,
          showLabel: index == 0,
        );
      }),
    );
  }
}

class RiskInputRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final bool isLast;
  final bool showLabel;

  const RiskInputRow({
    super.key,
    required this.controller,
    required this.onAdd,
    this.onRemove,
    required this.isLast,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: showLabel
                  ? const Text(
                      'Potensi Risiko',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Potensi Risiko',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(isLast ? Icons.add : Icons.remove),
                  onPressed: isLast ? onAdd : onRemove,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDropdown extends StatelessWidget {
  final Function(String?) onChanged;
  final String? selectedValue;

  const CategoryDropdown({
    super.key,
    required this.onChanged,
    this.selectedValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 120,
          child: Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text(
              'Kategori Produk',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            onChanged: onChanged,
            items: const [
              DropdownMenuItem(value: 'roti', child: Text('Roti')),
              DropdownMenuItem(value: 'snack', child: Text('Snack')),
              DropdownMenuItem(value: 'makanan', child: Text('Makanan')),
              DropdownMenuItem(value: 'minuman', child: Text('Minuman')),
            ],
            decoration: InputDecoration(
              hintText: 'Kategori Produk',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ActionButtons extends StatelessWidget {
  final VoidCallback onSimpan;
  final VoidCallback onLihat;

  const ActionButtons({
    super.key,
    required this.onSimpan,
    required this.onLihat,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 61) / 2; 
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), 
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 43,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF225840),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onLihat,
                child: const Text(
                  'Lihat Data',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: SizedBox(
              height: 43,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF225840),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onSimpan,
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}