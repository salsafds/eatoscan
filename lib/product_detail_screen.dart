import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'produk_model.dart';
import 'crud_penyakit.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProdukModel product;
  final String imagePath;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.imagePath,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final Box<ProdukModel> _produkBox;
  Map<String, bool> _userHealthConditions = {};
  List<Map<String, dynamic>> _userActiveDiseases = [];
  String? _userGender;
  bool _isLoadingHealthData = true;

  @override
  void initState() {
    super.initState();
    _produkBox = Hive.box<ProdukModel>('produk');
    _loadUserHealthData();
  }

  Future<void> _loadUserHealthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userGender = prefs.getString('gender');
        
        for (var penyakit in PenyakitFormPage.dataPenyakit) {
          final nama = penyakit['nama'];
          final hasCondition = prefs.getBool('penyakit_$nama') ?? false;
          _userHealthConditions[nama] = hasCondition;
          
          if (hasCondition) {
            _userActiveDiseases.add(penyakit);
          }
        }
        
        _isLoadingHealthData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingHealthData = false;
      });
      print('Error loading health data: $e');
    }
  }

  List<PersonalizedWarning> _analyzePersonalizedRisks() {
    List<PersonalizedWarning> warnings = [];
    
    if (_userActiveDiseases.isEmpty) {
      return warnings;
    }
    
    final nutrients = _parseNutrients(widget.product.nutrisi);
    
    for (var disease in _userActiveDiseases) {
      final diseaseWarnings = _analyzeDiseaseRisks(disease, nutrients);
      warnings.addAll(diseaseWarnings);
    }
    
    return warnings;
  }

  List<PersonalizedWarning> _analyzeDiseaseRisks(
    Map<String, dynamic> disease, 
    Map<String, String> nutrients
  ) {
    List<PersonalizedWarning> warnings = [];
    final diseaseName = disease['nama'];
    final diseaseDescription = disease['deskripsi'];
    final hindariBahan = disease['hindariBahan'] as List<dynamic>;
    
    for (var bahan in hindariBahan) {
      final bahanNama = bahan['nama'].toString().toLowerCase();
      final batasMaksimal = bahan['batas_maksimal'] as double;
      final unit = bahan['unit'];
      
      final nutrientValue = _findNutrientValue(nutrients, bahanNama);
      
      if (nutrientValue > batasMaksimal) {
        final severity = _determineSeverity(nutrientValue, batasMaksimal);
        
        warnings.add(PersonalizedWarning(
          title: 'Peringatan $diseaseName',
          message: _generateWarningMessage(
            diseaseName, 
            bahanNama, 
            nutrientValue, 
            batasMaksimal, 
            unit,
            diseaseDescription
          ),
          severity: severity,
          icon: _getWarningIcon(diseaseName),
          diseaseInfo: {
            'disease': diseaseName,
            'ingredient': bahanNama,
            'current_value': nutrientValue,
            'max_limit': batasMaksimal,
            'unit': unit,
          },
        ));
      }
    }
    
    return warnings;
  }

  double _findNutrientValue(Map<String, String> nutrients, String bahanNama) {
    final keywords = _getKeywords(bahanNama);
    
    for (String keyword in keywords) {
      for (String nutrientKey in nutrients.keys) {
        if (nutrientKey.toLowerCase().contains(keyword.toLowerCase())) {
          return double.tryParse(nutrients[nutrientKey]?.replaceAll(',', '.') ?? '0') ?? 0.0;
        }
      }
    }
    
    return 0.0;
  }

  List<String> _getKeywords(String bahanNama) {
    final lowerBahan = bahanNama.toLowerCase();
    
    if (lowerBahan.contains('gula')) {
      return ['gula', 'sugar', 'sukrosa'];
    } else if (lowerBahan.contains('natrium') || lowerBahan.contains('garam')) {
      return ['natrium', 'sodium', 'garam', 'salt'];
    } else if (lowerBahan.contains('lemak')) {
      return ['lemak', 'fat', 'lipid'];
    } else if (lowerBahan.contains('kolesterol')) {
      return ['kolesterol', 'cholesterol'];
    } else if (lowerBahan.contains('kalori') || lowerBahan.contains('energi')) {
      return ['kalori', 'energi', 'energy', 'kkal'];
    } else if (lowerBahan.contains('protein')) {
      return ['protein'];
    } else if (lowerBahan.contains('karbohidrat')) {
      return ['karbohidrat', 'carbohydrate', 'karbo'];
    } else {
      return [bahanNama];
    }
  }

  WarningSeverity _determineSeverity(double currentValue, double maxLimit) {
    final ratio = currentValue / maxLimit;
    
    if (ratio >= 2.0) {
      return WarningSeverity.high;
    } else if (ratio >= 1.5) {
      return WarningSeverity.medium;
    } else {
      return WarningSeverity.low;
    }
  }

  String _generateWarningMessage(
    String diseaseName,
    String bahanNama,
    double currentValue,
    double maxLimit,
    String unit,
    String diseaseDescription,
  ) {
    final ratio = currentValue / maxLimit;
    String intensityText;
    
    if (ratio >= 2.0) {
      intensityText = 'sangat tinggi';
    } else if (ratio >= 1.5) {
      intensityText = 'tinggi';
    } else {
      intensityText = 'melebihi batas';
    }
    
    return 'Produk ini mengandung $bahanNama $intensityText (${currentValue.toStringAsFixed(1)} $unit) '
           'yang melebihi batas aman untuk penderita $diseaseName (maksimal: ${maxLimit.toStringAsFixed(1)} $unit). '
           'Konsumsi berlebihan dapat memperburuk kondisi $diseaseName Anda.';
  }

  IconData _getWarningIcon(String diseaseName) {
    final lowerName = diseaseName.toLowerCase();
    
    if (lowerName.contains('diabetes')) {
      return Icons.bloodtype;
    } else if (lowerName.contains('hipertensi') || lowerName.contains('tekanan darah')) {
      return Icons.favorite;
    } else if (lowerName.contains('jantung')) {
      return Icons.favorite_border;
    } else if (lowerName.contains('kolesterol')) {
      return Icons.water_drop;
    } else if (lowerName.contains('obesitas')) {
      return Icons.fitness_center;
    } else if (lowerName.contains('asam urat')) {
      return Icons.healing;
    } else if (lowerName.contains('maag') || lowerName.contains('gastritis')) {
      return Icons.local_fire_department;
    } else {
      return Icons.warning;
    }
  }

  Map<String, String> _parseNutrients(String nutrisiString) {
    final Map<String, String> nutrients = {};
    
    if (nutrisiString.isEmpty) return nutrients;
    
    final parts = nutrisiString.split(', ');
    
    for (var part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.isEmpty) continue;
      
      bool matched = false;
      
      RegExpMatch? match = RegExp(r'(.+)\s*$$(.+)\s*g$$').firstMatch(trimmedPart);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final weight = match.group(2)?.trim() ?? '';
        if (name.isNotEmpty && weight.isNotEmpty) {
          nutrients[name] = weight;
          matched = true;
        }
      }
      
      if (!matched) {
        match = RegExp(r'(.+)\s*$$(.+)$$').firstMatch(trimmedPart);
        if (match != null) {
          final name = match.group(1)?.trim() ?? '';
          var weight = match.group(2)?.trim() ?? '';
          weight = weight.replaceAll(RegExp(r'\s*(g|mg|kkal|kcal|ml|l)\s*$', caseSensitive: false), '');
          if (name.isNotEmpty && weight.isNotEmpty) {
            nutrients[name] = weight;
            matched = true;
          }
        }
      }
      
      if (!matched) {
        match = RegExp(r'(.+):\s*(.+)').firstMatch(trimmedPart);
        if (match != null) {
          final name = match.group(1)?.trim() ?? '';
          var weight = match.group(2)?.trim() ?? '';
          weight = weight.replaceAll(RegExp(r'\s*(g|mg|kkal|kcal|ml|l)\s*$', caseSensitive: false), '');
          if (name.isNotEmpty && weight.isNotEmpty) {
            nutrients[name] = weight;
            matched = true;
          }
        }
      }
      
      if (!matched) {
        final spaceParts = trimmedPart.split(' ');
        if (spaceParts.length >= 2) {
          for (int j = spaceParts.length - 1; j >= 1; j--) {
            final potentialWeight = spaceParts[j].replaceAll(RegExp(r'[^\d.,]'), '');
            if (potentialWeight.isNotEmpty && double.tryParse(potentialWeight.replaceAll(',', '.')) != null) {
              final name = spaceParts.sublist(0, j).join(' ');
              if (name.isNotEmpty) {
                nutrients[name] = potentialWeight;
                matched = true;
                break;
              }
            }
          }
        }
      }
    }
    
    return nutrients;
  }

  String _getNutrientUnit(String nutrient) {
    final lowerNutrient = nutrient.toLowerCase();
    
    if (lowerNutrient.contains('kalori') || lowerNutrient.contains('energi') || lowerNutrient.contains('energy')) {
      return 'kkal';
    } else if (lowerNutrient.contains('natrium') || lowerNutrient.contains('sodium') || lowerNutrient.contains('garam')) {
      return 'mg';
    } else if (lowerNutrient.contains('vitamin') || lowerNutrient.contains('mineral') || lowerNutrient.contains('kalsium')) {
      return 'mg';
    } else {
      return 'g';
    }
  }

  List<ProdukModel> _getRecommendedProducts() {
    final currentRisks = widget.product.risiko.split(', ').map((r) => r.trim().toLowerCase()).toSet();
    return _produkBox.values.where((p) {
      final otherRisks = p.risiko.split(', ').map((r) => r.trim().toLowerCase()).toSet();
      return p.nama != widget.product.nama && !currentRisks.any(otherRisks.contains);
    }).toList().take(4).toList();
  }

  Color _getNutrientColor(String nutrient, double value) {
    final lowerNutrient = nutrient.toLowerCase();
    
    if (lowerNutrient.contains('gula') || lowerNutrient.contains('sugar')) {
      return value > 10 ? Colors.red : Colors.green;
    } else if (lowerNutrient.contains('garam') || lowerNutrient.contains('sodium') || lowerNutrient.contains('natrium')) {
      return value > 1000 ? Colors.red : Colors.green;
    } else if (lowerNutrient.contains('lemak') || lowerNutrient.contains('fat')) {
      return value > 5 ? Colors.red : Colors.green;
    } else if (lowerNutrient.contains('kalori') || lowerNutrient.contains('energi')) {
      return value > 200 ? Colors.red : Colors.green;
    } else {
      return Colors.green;
    }
  }

  String _getNutrientStatus(String nutrient, double value) {
    final lowerNutrient = nutrient.toLowerCase();
    
    if (lowerNutrient.contains('gula') || lowerNutrient.contains('sugar')) {
      return value > 10 ? 'Tinggi' : 'Rendah';
    } else if (lowerNutrient.contains('garam') || lowerNutrient.contains('sodium') || lowerNutrient.contains('natrium')) {
      return value > 1000 ? 'Tinggi' : 'Rendah';
    } else if (lowerNutrient.contains('lemak') || lowerNutrient.contains('fat')) {
      return value > 5 ? 'Tinggi' : 'Rendah';
    } else if (lowerNutrient.contains('kalori') || lowerNutrient.contains('energi')) {
      return value > 200 ? 'Tinggi' : 'Rendah';
    } else {
      return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingHealthData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nutrients = _parseNutrients(widget.product.nutrisi);
    final recommendedProducts = _getRecommendedProducts();
    final isAssetImage = widget.imagePath.startsWith('assets/');
    final personalizedWarnings = _analyzePersonalizedRisks();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: isAssetImage
                    ? AssetImage(widget.imagePath) as ImageProvider
                    : FileImage(File(widget.imagePath)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Container(
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            const Text(
                              'Nutri-Score',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildScoreCircle('A', Colors.green),
                                _buildScoreCircle('B', Colors.lightGreen),
                                _buildScoreCircle('C', Colors.yellow, isSelected: true),
                                _buildScoreCircle('D', Colors.orange),
                                _buildScoreCircle('E', Colors.red),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.product.nama.isNotEmpty ? widget.product.nama : 'Produk Tidak Ditemukan',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.product.tambahan.isNotEmpty ? widget.product.tambahan : 'Kategori tidak tersedia',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      if (personalizedWarnings.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.health_and_safety, color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Peringatan Kesehatan Personal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...personalizedWarnings.map((warning) => 
                                _buildPersonalizedWarning(warning)
                              ).toList(),
                            ],
                          ),
                        ),
                      
                      if (_userActiveDiseases.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
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
                                    Icon(Icons.info, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Profil Kesehatan Anda',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Peringatan di atas berdasarkan kondisi kesehatan: ${_userActiveDiseases.map((d) => d['nama']).join(', ')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Batas nutrisi disesuaikan dengan data medis yang tersimpan dalam sistem',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Nutrisi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (nutrients.isNotEmpty) ...[
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.5,
                                children: nutrients.entries.take(6).map((entry) {
                                  final value = double.tryParse(entry.value.replaceAll(',', '.')) ?? 0.0;
                                  final status = _getNutrientStatus(entry.key, value);
                                  final color = _getNutrientColor(entry.key, value);
                                  return _buildNutrientCard(entry.key, entry.value, status, color: color);
                                }).toList(),
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.grey[600], size: 48),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Data Nutrisi Tidak Tersedia',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Rekomendasi Produk Lain',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      SizedBox(
                        height: 180,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: recommendedProducts.map((recommendedProduct) {
                            return _buildRecommendationCard(
                              recommendedProduct.nama,
                              recommendedProduct.preferensiNutrisi['bebas_laktosa'] == true 
                                ? 'Bebas Laktosa' 
                                : recommendedProduct.preferensiNutrisi['bebas_gluten'] == true
                                  ? 'Bebas Gluten'
                                  : 'Sehat',
                              recommendedProduct.gambarPath, 
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Preferensi Nutrisi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildPreferenceItem(
                              'Bebas Laktosa',
                              widget.product.preferensiNutrisi['bebas_laktosa'] ?? false,
                            ),
                            _buildPreferenceItem(
                              'Bebas Gluten',
                              widget.product.preferensiNutrisi['bebas_gluten'] ?? false,
                            ),
                            _buildPreferenceItem(
                              'Vegetarian',
                              widget.product.preferensiNutrisi['vegetarian'] ?? false,
                            ),
                            _buildPreferenceItem(
                              'Vegan',
                              widget.product.preferensiNutrisi['vegan'] ?? false,
                            ),
                          ],
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informasi Gizi Lengkap',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Informasi Kemasan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildNutritionRow('Takaran kemasan', '${widget.product.takaranKemasan.toInt()} gram'),
                                    _buildNutritionRow('Sajian per kemasan', '${widget.product.sajianPerKemasan.toInt()}'),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kandungan Nutrisi per Sajian',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    if (nutrients.isNotEmpty) ...[
                                      ...nutrients.entries.map((entry) {
                                        final value = double.tryParse(entry.value.replaceAll(',', '.')) ?? 0.0;
                                        final color = _getNutrientColor(entry.key, value);
                                        final unit = _getNutrientUnit(entry.key);
                                        
                                        bool isProblematic = false;
                                        for (var disease in _userActiveDiseases) {
                                          final hindariBahan = disease['hindariBahan'] as List<dynamic>;
                                          for (var bahan in hindariBahan) {
                                            final keywords = _getKeywords(bahan['nama']);
                                            if (keywords.any((keyword) => entry.key.toLowerCase().contains(keyword.toLowerCase()))) {
                                              if (value > bahan['batas_maksimal']) {
                                                isProblematic = true;
                                                break;
                                              }
                                            }
                                          }
                                          if (isProblematic) break;
                                        }
                                        
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  entry.key,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isProblematic 
                                                      ? Colors.red.withOpacity(0.2)
                                                      : color.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isProblematic ? Colors.red : color, 
                                                    width: isProblematic ? 1.5 : 0.5
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (isProblematic) ...[
                                                      Icon(
                                                        Icons.warning,
                                                        size: 12,
                                                        color: Colors.red,
                                                      ),
                                                      const SizedBox(width: 4),
                                                    ],
                                                    Text(
                                                      '${entry.value} $unit',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: isProblematic ? Colors.red : color,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ] else ...[
                                      Text(
                                        'Data nutrisi tidak dapat diparsing dari: "${widget.product.nutrisi}"',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.orange[600],
                                        ),
                                      ),
                                    ],
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
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedWarning(PersonalizedWarning warning) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    
    switch (warning.severity) {
      case WarningSeverity.high:
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red;
        textColor = Colors.red[800]!;
        break;
      case WarningSeverity.medium:
        backgroundColor = Colors.orange[50]!;
        borderColor = Colors.orange;
        textColor = Colors.orange[800]!;
        break;
      case WarningSeverity.low:
        backgroundColor = Colors.yellow[50]!;
        borderColor = Colors.yellow[700]!;
        textColor = Colors.yellow[800]!;
        break;
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(warning.icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warning.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              if (warning.diseaseInfo != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${warning.diseaseInfo!['current_value'].toStringAsFixed(1)}/${warning.diseaseInfo!['max_limit'].toStringAsFixed(1)} ${warning.diseaseInfo!['unit']}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            warning.message,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCircle(String letter, Color color, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: color == Colors.yellow ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String name, String value, String status, {Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String name, String tag, String? imagePath) {
  return Container(
    width: 150,
    margin: const EdgeInsets.only(right: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: _buildProductImage(imagePath),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Icon(Icons.favorite_border, size: 16),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildProductImage(String? imagePath) {
  if (imagePath != null && imagePath.isNotEmpty) {
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: double.infinity,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
      );
    }
  }
  
  return _buildPlaceholderImage();
}

Widget _buildPlaceholderImage() {
  return Container(
    width: double.infinity,
    height: 100,
    color: Colors.grey[200],
    child: const Center(
      child: Icon(
        Icons.image,
        size: 40,
        color: Colors.grey,
      ),
    ),
  );
}

  Widget _buildPreferenceItem(String label, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: isChecked ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalizedWarning {
  final String title;
  final String message;
  final WarningSeverity severity;
  final IconData icon;
  final Map<String, dynamic>? diseaseInfo;

  PersonalizedWarning({
    required this.title,
    required this.message,
    required this.severity,
    required this.icon,
    this.diseaseInfo,
  });
}

enum WarningSeverity { high, medium, low }