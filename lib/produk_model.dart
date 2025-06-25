import 'package:hive/hive.dart';

part 'produk_model.g.dart';

@HiveType(typeId: 1)
class ProdukModel extends HiveObject {
  @HiveField(0)
  String nama;

  @HiveField(1)
  String kode;

  @HiveField(2)
  String nutrisi;

  @HiveField(3)
  String tambahan;

  @HiveField(4)
  String risiko;

  @HiveField(5)
  Map<String, bool> preferensiNutrisi;

  @HiveField(6)
  double takaranKemasan;

  @HiveField(7)
  double sajianPerKemasan;

  @HiveField(8)
  String? gambarPath;

  @HiveField(9)
  String? unitTakaranKemasan; 

  @HiveField(10)
  List<Map<String, dynamic>>? nutrisiDetail; 

  ProdukModel({
    required this.nama,
    required this.kode,
    required this.nutrisi,
    required this.tambahan,
    required this.risiko,
    this.preferensiNutrisi = const {
      'bebas_laktosa': false,
      'bebas_gluten': false,
      'vegetarian': false,
      'vegan': false,
    },
    this.takaranKemasan = 0.0,
    this.sajianPerKemasan = 0.0,
    this.gambarPath,
    this.unitTakaranKemasan = 'g',
    this.nutrisiDetail,
  });
}
