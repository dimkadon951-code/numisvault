import 'metal.dart';

/// Сторона монеты.
enum CoinFace { obverse, reverse }

/// Одна монета в коллекции.
class Coin {
  const Coin({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.country = '',
    this.year,
    this.mint = '',
    this.metal = MetalType.silver,
    this.fineness = '',
    this.obverseDescription = '',
    this.reverseDescription = '',
    this.weight,
    this.diameter,
    this.mintage = '',
    this.grade = Grade.vf,
  });

  final String id;
  final String title;
  final String country;
  final int? year;
  final String mint;
  final MetalType metal;

  /// Проба: "925", "900", "585" и т.п.
  final String fineness;
  final String obverseDescription;
  final String reverseDescription;
  final double? weight;
  final double? diameter;
  final String mintage;
  final Grade grade;
  final DateTime updatedAt;

  Coin copyWith({
    String? id,
    String? title,
    String? country,
    int? year,
    bool clearYear = false,
    String? mint,
    MetalType? metal,
    String? fineness,
    String? obverseDescription,
    String? reverseDescription,
    double? weight,
    bool clearWeight = false,
    double? diameter,
    bool clearDiameter = false,
    String? mintage,
    Grade? grade,
    DateTime? updatedAt,
  }) {
    return Coin(
      id: id ?? this.id,
      title: title ?? this.title,
      country: country ?? this.country,
      year: clearYear ? null : (year ?? this.year),
      mint: mint ?? this.mint,
      metal: metal ?? this.metal,
      fineness: fineness ?? this.fineness,
      obverseDescription: obverseDescription ?? this.obverseDescription,
      reverseDescription: reverseDescription ?? this.reverseDescription,
      weight: clearWeight ? null : (weight ?? this.weight),
      diameter: clearDiameter ? null : (diameter ?? this.diameter),
      mintage: mintage ?? this.mintage,
      grade: grade ?? this.grade,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Строка для таблицы public.coins в Supabase.
  Map<String, dynamic> toRow(String userId) => <String, dynamic>{
        'id': id,
        'user_id': userId,
        'title': title,
        'country': country,
        'year': year,
        'mint': mint,
        'metal': metal.name,
        'fineness': fineness,
        'obverse_desc': obverseDescription,
        'reverse_desc': reverseDescription,
        'weight': weight,
        'diameter': diameter,
        'mintage': mintage,
        'grade': grade.name,
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory Coin.fromRow(Map<String, dynamic> row) {
    String str(String key) => (row[key] as String?) ?? '';
    double? num_(String key) => (row[key] as num?)?.toDouble();
    return Coin(
      id: str('id'),
      title: str('title'),
      country: str('country'),
      year: (row['year'] as num?)?.toInt(),
      mint: str('mint'),
      metal: MetalType.parse(row['metal'] as String?),
      fineness: str('fineness'),
      obverseDescription: str('obverse_desc'),
      reverseDescription: str('reverse_desc'),
      weight: num_('weight'),
      diameter: num_('diameter'),
      mintage: str('mintage'),
      grade: Grade.parse(row['grade'] as String?),
      updatedAt: DateTime.tryParse(str('updated_at'))?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Для локального кэша (JSON-файл на устройстве).
  Map<String, dynamic> toJson() => toRow('');
  factory Coin.fromJson(Map<String, dynamic> json) => Coin.fromRow(json);

  String get yearLabel => year?.toString() ?? '—';
  String get countryLabel => country.trim().isEmpty ? 'Страна не указана' : country;

  String get specsLine {
    final parts = <String>[
      if (country.trim().isNotEmpty) country,
      if (year != null) '$year',
      metal.label,
      if (fineness.trim().isNotEmpty) 'проба $fineness',
    ];
    return parts.join(' · ');
  }

  /// Полнотекстовый поиск по всем значимым полям.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final haystack = <String>[
      title,
      country,
      mint,
      year?.toString() ?? '',
      metal.label,
      grade.short,
      grade.ru,
      fineness,
      mintage,
      obverseDescription,
      reverseDescription,
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }
}
