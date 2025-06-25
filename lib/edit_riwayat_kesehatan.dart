import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crud_penyakit.dart';

class EditRiwayatKesehatanPage extends StatefulWidget {
  const EditRiwayatKesehatanPage({super.key});

  @override
  State<EditRiwayatKesehatanPage> createState() =>
      _EditRiwayatKesehatanPageState();
}

class _EditRiwayatKesehatanPageState extends State<EditRiwayatKesehatanPage> {
  String? _gender;
  int? _age;
  double? _weight;
  double? _height;
  final Map<String, bool> _penyakitStatus = {};
  String? _savedGender;
  int? _savedAge;
  double? _savedWeight;
  double? _savedHeight;
  Map<String, bool> _savedPenyakitStatus = {};
  bool _hasChanges = false;
  bool _isLoading = true;

  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePenyakitStatus();
    _loadSavedData();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _initializePenyakitStatus() {
    for (var penyakit in PenyakitFormPage.dataPenyakit) {
      _penyakitStatus[penyakit['nama']] = false;
      _savedPenyakitStatus[penyakit['nama']] = false;
    }
  }

  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _gender = prefs.getString('gender');
        _age = prefs.getInt('age');
        _weight = prefs.getDouble('weight');
        _height = prefs.getDouble('height');
        
        _savedGender = _gender;
        _savedAge = _age;
        _savedWeight = _weight;
        _savedHeight = _height;
        
        if (_age != null) _ageController.text = _age.toString();
        if (_weight != null) _weightController.text = _weight.toString();
        if (_height != null) _heightController.text = _height.toString();
        
        for (var penyakit in PenyakitFormPage.dataPenyakit) {
          final nama = penyakit['nama'];
          _penyakitStatus[nama] = prefs.getBool('penyakit_$nama') ?? false;
          _savedPenyakitStatus[nama] = _penyakitStatus[nama]!;
        }
        _hasChanges = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _simpanData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('gender', _gender ?? '');
      if (_age != null) await prefs.setInt('age', _age!);
      if (_weight != null) await prefs.setDouble('weight', _weight!);
      if (_height != null) await prefs.setDouble('height', _height!);
      
      await prefs.setString('health_data_updated', DateTime.now().toIso8601String());
      
      for (var penyakit in PenyakitFormPage.dataPenyakit) {
        final nama = penyakit['nama'];
        await prefs.setBool('penyakit_$nama', _penyakitStatus[nama] ?? false);
      }
      
      if (_weight != null && _height != null && _height! > 0) {
        final bmi = _weight! / ((_height! / 100) * (_height! / 100));
        await prefs.setDouble('bmi', bmi);
        
        String bmiCategory = _getBMICategory(bmi);
        await prefs.setString('bmi_category', bmiCategory);
      }
      
      await _saveRiskProfile();
      
      setState(() {
        _savedGender = _gender;
        _savedAge = _age;
        _savedWeight = _weight;
        _savedHeight = _height;
        _savedPenyakitStatus = Map.from(_penyakitStatus);
        _hasChanges = false;
      });
      
      _showSuccessDialog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveRiskProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    List<String> riskFactors = [];
    List<String> nutritionConcerns = [];
    
    _penyakitStatus.forEach((penyakit, hasCondition) {
      if (hasCondition) {
        switch (penyakit.toLowerCase()) {
          case 'diabetes':
          case 'diabetes melitus':
            riskFactors.add('diabetes');
            nutritionConcerns.addAll(['gula_tinggi', 'karbohidrat_tinggi']);
            break;
          case 'hipertensi':
          case 'tekanan darah tinggi':
            riskFactors.add('hipertensi');
            nutritionConcerns.add('natrium_tinggi');
            break;
          case 'penyakit jantung':
          case 'jantung koroner':
            riskFactors.add('jantung');
            nutritionConcerns.addAll(['lemak_jenuh_tinggi', 'kolesterol_tinggi']);
            break;
          case 'kolesterol tinggi':
            riskFactors.add('kolesterol');
            nutritionConcerns.add('kolesterol_tinggi');
            break;
          case 'obesitas':
            riskFactors.add('obesitas');
            nutritionConcerns.add('kalori_tinggi');
            break;
          case 'asam urat':
            riskFactors.add('asam_urat');
            nutritionConcerns.add('protein_tinggi');
            break;
          case 'maag':
          case 'gastritis':
            riskFactors.add('maag');
            nutritionConcerns.add('makanan_pedas');
            break;
        }
      }
    });
    
    await prefs.setStringList('risk_factors', riskFactors);
    await prefs.setStringList('nutrition_concerns', nutritionConcerns);
    
    int riskScore = _calculateOverallRiskScore();
    await prefs.setInt('overall_risk_score', riskScore);
  }

  int _calculateOverallRiskScore() {
    int score = 0;
    
    int activeConditions = _penyakitStatus.values.where((v) => v).length;
    score += activeConditions * 10;
    
    if (_weight != null && _height != null && _height! > 0) {
      final bmi = _weight! / ((_height! / 100) * (_height! / 100));
      if (bmi >= 30) {
        score += 20; // Obesitas
      } else if (bmi >= 25) {
        score += 10; // Overweight
      }
      else if (bmi < 18.5) {
        score += 15; // Underweight
      }
    }
    
    if (_age != null) {
      if (_age! >= 60) {
        score += 15;
      } else if (_age! >= 45) {
        score += 10;
      }
      else if (_age! >= 30) {
        score += 5;
      }
    }
    
    return score;
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obesitas';
  }

  void _checkForChanges() {
    bool hasChanges = _gender != _savedGender ||
        _age != _savedAge ||
        _weight != _savedWeight ||
        _height != _savedHeight ||
        _penyakitStatus.entries.any(
          (entry) => _savedPenyakitStatus[entry.key] != entry.value,
        );
    setState(() {
      _hasChanges = hasChanges;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text("Berhasil Disimpan"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Data riwayat kesehatan telah disimpan."),
            const SizedBox(height: 12),
            if (_weight != null && _height != null && _height! > 0) ...[
              const Divider(),
              const Text(
                "Informasi BMI Anda:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text("BMI: ${(_weight! / ((_height! / 100) * (_height! / 100))).toStringAsFixed(1)}"),
              Text("Kategori: ${_getBMICategory(_weight! / ((_height! / 100) * (_height! / 100)))}"),
            ],
            if (_penyakitStatus.values.any((v) => v)) ...[
              const SizedBox(height: 8),
              const Text(
                "Peringatan produk akan disesuaikan dengan kondisi kesehatan Anda.",
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSummary() {
    if (_isLoading) return const SizedBox.shrink();
    
    List<String> activeConditions = _penyakitStatus.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    
    if (activeConditions.isEmpty && _weight == null && _height == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Kesehatan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          if (_weight != null && _height != null && _height! > 0) ...[
            Row(
              children: [
                Icon(Icons.monitor_weight, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  'BMI: ${(_weight! / ((_height! / 100) * (_height! / 100))).toStringAsFixed(1)} (${_getBMICategory(_weight! / ((_height! / 100) * (_height! / 100)))})',
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          
          if (activeConditions.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_services, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Kondisi: ${activeConditions.join(', ')}',
                    style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          
          Text(
            'Peringatan produk akan disesuaikan dengan profil kesehatan Anda',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Colors.blue[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2F684A),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2F684A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Profil Kesehatan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/eatoscan.png', height: 80),
                      const SizedBox(height: 16),
                      const Text(
                        "Profil Kesehatan Pengguna",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Data ini akan digunakan untuk personalisasi peringatan produk",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      _buildHealthSummary(),

                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Data Dasar",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              const Text("Jenis Kelamin"),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text("Laki-laki"),
                                      value: "Laki-laki",
                                      groupValue: _gender,
                                      onChanged: (value) {
                                        setState(() {
                                          _gender = value;
                                          _checkForChanges();
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<String>(
                                      title: const Text("Perempuan"),
                                      value: "Perempuan",
                                      groupValue: _gender,
                                      onChanged: (value) {
                                        setState(() {
                                          _gender = value;
                                          _checkForChanges();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              TextField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Usia (tahun)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.cake),
                                ),
                                onChanged: (value) {
                                  _age = int.tryParse(value);
                                  _checkForChanges();
                                },
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _weightController,
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Berat (kg)',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.monitor_weight),
                                      ),
                                      onChanged: (value) {
                                        _weight = double.tryParse(value);
                                        _checkForChanges();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _heightController,
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Tinggi (cm)',
                                        border: OutlineInputBorder(),
                                        prefixIcon: Icon(Icons.height),
                                      ),
                                      onChanged: (value) {
                                        _height = double.tryParse(value);
                                        _checkForChanges();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Riwayat Penyakit",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Pilih kondisi kesehatan yang Anda miliki:",
                                style: TextStyle(fontSize: 14),
                              ),
                              const Text(
                                "*dapat memilih lebih dari satu",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              if (PenyakitFormPage.dataPenyakit.isEmpty)
                                const Text(
                                  "Belum ada data penyakit tersedia",
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                )
                              else
                                ...PenyakitFormPage.dataPenyakit.map((penyakit) {
                                  return CheckboxListTile(
                                    title: Text(
                                      penyakit['nama'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: penyakit['deskripsi'] != null 
                                        ? Text(
                                            penyakit['deskripsi'],
                                            style: const TextStyle(fontSize: 12),
                                          )
                                        : null,
                                    value: _penyakitStatus[penyakit['nama']] ?? false,
                                    onChanged: (val) {
                                      setState(() {
                                        _penyakitStatus[penyakit['nama']] = val!;
                                        _checkForChanges();
                                      });
                                    },
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _hasChanges ? _simpanData : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE85D04),
                            disabledBackgroundColor: Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _hasChanges ? "Simpan Perubahan" : "Tidak Ada Perubahan",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        "Data akan digunakan untuk memberikan peringatan yang sesuai dengan kondisi kesehatan Anda",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}