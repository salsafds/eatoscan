import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CrudPenyakit extends StatelessWidget {
  const CrudPenyakit({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EatoScan',
      theme: ThemeData(primarySwatch: Colors.orange, fontFamily: 'Arial'),
      home: const PenyakitFormPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PenyakitFormPage extends StatefulWidget {
  const PenyakitFormPage({super.key});

  static List<Map<String, dynamic>> dataPenyakit = [];

  @override
  State<PenyakitFormPage> createState() => _PenyakitFormPageState();
}

class _PenyakitFormPageState extends State<PenyakitFormPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _bahanController = TextEditingController();
  final TextEditingController _batasController = TextEditingController();

  List<Map<String, dynamic>> _hindariBahan = [];
  int? _selectedIndex;
  
  String _selectedUnit = 'g';
  final List<String> _availableUnits = ['g', 'mg', 'kkal', 'ml', '%', 'IU'];

  @override
  void initState() {
    super.initState();
    _loadPenyakitData();
  }

  Future<void> _loadPenyakitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? penyakitData = prefs.getString('dataPenyakit');
      if (penyakitData != null) {
        final List<dynamic> decoded = jsonDecode(penyakitData);
        setState(() {
          PenyakitFormPage.dataPenyakit = decoded.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data penyakit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePenyakitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(PenyakitFormPage.dataPenyakit);
      await prefs.setString('dataPenyakit', encoded);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data penyakit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _selectedIndex = null;
      _namaController.clear();
      _deskripsiController.clear();
      _keteranganController.clear();
      _bahanController.clear();
      _batasController.clear();
      _hindariBahan.clear();
      _selectedUnit = 'g'; 
    });
  }

  void _tambahBahan() {
    if (_bahanController.text.isNotEmpty && _batasController.text.isNotEmpty) {
      final batas = double.tryParse(_batasController.text);
      if (batas != null) {
        setState(() {
          _hindariBahan.add({
            'nama': _bahanController.text,
            'batas_maksimal': batas,
            'unit': _selectedUnit, 
          });
          _bahanController.clear();
          _batasController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Batas maksimal harus berupa angka'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama bahan dan batas maksimal harus diisi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getSuggestedUnit(String bahan) {
    final lowerBahan = bahan.toLowerCase();
    if (lowerBahan.contains('gula') || lowerBahan.contains('sugar') ||
        lowerBahan.contains('lemak') || lowerBahan.contains('protein') ||
        lowerBahan.contains('karbohidrat')) {
      return 'g';
    } else if (lowerBahan.contains('natrium') || lowerBahan.contains('sodium') ||
               lowerBahan.contains('kolesterol') || lowerBahan.contains('vitamin')) {
      return 'mg';
    } else if (lowerBahan.contains('kalori') || lowerBahan.contains('energi')) {
      return 'kkal';
    } else {
      return 'g';
    }
  }

  void _autoSuggestUnit() {
    if (_bahanController.text.isNotEmpty) {
      final suggestedUnit = _getSuggestedUnit(_bahanController.text);
      setState(() {
        _selectedUnit = suggestedUnit;
      });
    }
  }

  void _hapusBahan(int index) {
    setState(() {
      _hindariBahan.removeAt(index);
    });
  }

  void _baru() {
    _resetForm();
  }

  void _simpan() {
    if (_namaController.text.isEmpty || _deskripsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Nama dan deskripsi penyakit harus diisi.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_hindariBahan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Minimal satu bahan yang harus dihindari.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      final penyakitData = {
        'nama': _namaController.text,
        'deskripsi': _deskripsiController.text,
        'keterangan': _keteranganController.text,
        'hindariBahan': List.from(_hindariBahan),
        'created_at': DateTime.now().toIso8601String(),
      };

      if (_selectedIndex != null) {
        penyakitData['updated_at'] = DateTime.now().toIso8601String();
        PenyakitFormPage.dataPenyakit[_selectedIndex!] = penyakitData;
      } else {
        PenyakitFormPage.dataPenyakit.add(penyakitData);
      }
    });

    _savePenyakitData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sukses: Penyakit berhasil disimpan.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
    
    _resetForm();
  }

  void _ubah() {
    if (_selectedIndex != null) {
      setState(() {
        final data = PenyakitFormPage.dataPenyakit[_selectedIndex!];
        _namaController.text = data['nama'];
        _deskripsiController.text = data['deskripsi'];
        _keteranganController.text = data['keterangan'] ?? '';
        _hindariBahan = List<Map<String, dynamic>>.from(data['hindariBahan']);
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
  }

  void _hapus() {
    if (_selectedIndex != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus data penyakit "${PenyakitFormPage.dataPenyakit[_selectedIndex!]['nama']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  PenyakitFormPage.dataPenyakit.removeAt(_selectedIndex!);
                  _selectedIndex = null;
                  _resetForm();
                });
                _savePenyakitData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sukses: Data berhasil dihapus.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text(
                'Ya, Hapus',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal: Pilih data yang akan dihapus.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
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
                      'EatoScan - Data Penyakit',
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
                                'Manajemen Data Penyakit',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Kelola data penyakit dan batas nutrisi untuk personalisasi peringatan',
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
                              label: 'Nama Penyakit',
                              controller: _namaController,
                              hint: 'Contoh: Diabetes, Hipertensi',
                            ),

                            FormFieldWithLabel(
                              label: 'Deskripsi',
                              controller: _deskripsiController,
                              maxLines: 3,
                              hint: 'Deskripsi singkat tentang penyakit',
                            ),

                            FormFieldWithLabel(
                              label: 'Keterangan',
                              controller: _keteranganController,
                              maxLines: 2,
                              hint: 'Keterangan tambahan (opsional)',
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
                                      'Bahan Dihindari',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      ..._hindariBahan.asMap().entries.map((entry) {
                                        int index = entry.key;
                                        Map<String, dynamic> bahan = entry.value;
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
                                                        bahan['nama'],
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Batas: ${bahan['batas_maksimal']} ${bahan['unit']}',
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
                                                onPressed: () => _hapusBahan(index),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),

                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.blue[200]!),
                                          borderRadius: BorderRadius.circular(15),
                                          color: Colors.blue[50],
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _bahanController,
                                                    style: const TextStyle(fontSize: 12),
                                                    decoration: InputDecoration(
                                                      hintText: 'Nama bahan (contoh: Gula, Natrium)',
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
                                                  onPressed: _autoSuggestUnit,
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
                                                    controller: _batasController,
                                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                    style: const TextStyle(fontSize: 12),
                                                    decoration: InputDecoration(
                                                      hintText: 'Batas maksimal',
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
                                                        value: _selectedUnit,
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
                                                              _selectedUnit = newValue;
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
                                            
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Unit terpilih: $_selectedUnit ${_getUnitDescription(_selectedUnit)}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: _tambahBahan,
                                                icon: const Icon(Icons.add, size: 16),
                                                label: const Text(
                                                  'Tambah Bahan',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
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

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton('BARU', const Color(0xFF225840), _baru),
                                _buildActionButton('SIMPAN', const Color(0xFF225840), _simpan),
                                _buildActionButton('UBAH', const Color(0xFF225840), _ubah),
                                _buildActionButton('HAPUS', const Color(0xFF225840), _hapus),
                              ],
                            ),

                            const SizedBox(height: 24),

                            Container(
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
                                    child: const Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Nama Penyakit',
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
                                            'Deskripsi',
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
                                            'Bahan & Batas',
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
                                    child: PenyakitFormPage.dataPenyakit.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Belum ada data penyakit',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            itemCount: PenyakitFormPage.dataPenyakit.length,
                                            itemBuilder: (context, index) {
                                              final data = PenyakitFormPage.dataPenyakit[index];
                                              final isSelected = _selectedIndex == index;
                                              final hindariBahan = data['hindariBahan'] as List<dynamic>;

                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedIndex = index;
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
                                                        flex: 2,
                                                        child: Text(
                                                          data['nama'],
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
                                                        flex: 2,
                                                        child: Text(
                                                          data['deskripsi'],
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
                                                          children: hindariBahan.map<Widget>((bahan) {
                                                            return Text(
                                                              '${bahan['nama']}: ${bahan['batas_maksimal']}${bahan['unit']}',
                                                              textAlign: TextAlign.center,
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight: isSelected
                                                                    ? FontWeight.bold
                                                                    : FontWeight.normal,
                                                              ),
                                                            );
                                                          }).toList(),
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
                          ],
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

  String _getUnitDescription(String unit) {
    switch (unit) {
      case 'g':
        return '(gram)';
      case 'mg':
        return '(miligram)';
      case 'kkal':
        return '(kilokalori)';
      case 'ml':
        return '(mililiter)';
      case '%':
        return '(persen)';
      case 'IU':
        return '(International Unit)';
      default:
        return '';
    }
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: 80,
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

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _keteranganController.dispose();
    _bahanController.dispose();
    _batasController.dispose();
    super.dispose();
  }
}

class FormFieldWithLabel extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;

  const FormFieldWithLabel({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
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
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint ?? label,
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
