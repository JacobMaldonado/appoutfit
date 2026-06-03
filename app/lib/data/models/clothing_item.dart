import 'package:equatable/equatable.dart';

enum ClothingType {
  shirt,
  blouse,
  tshirt,
  tank,
  sweater,
  pants,
  jeans,
  skirt,
  shorts,
  dress,
  jumpsuit,
  jacket,
  coat,
  cardigan,
  blazer,
}

enum CoverageType { top, bottom, fullbody, layer }

enum ClothingPattern { solid, striped, floral, plaid, printed }

extension ClothingTypeX on ClothingType {
  CoverageType get coverage {
    switch (this) {
      case ClothingType.shirt:
      case ClothingType.blouse:
      case ClothingType.tshirt:
      case ClothingType.tank:
      case ClothingType.sweater:
        return CoverageType.top;
      case ClothingType.pants:
      case ClothingType.jeans:
      case ClothingType.skirt:
      case ClothingType.shorts:
        return CoverageType.bottom;
      case ClothingType.dress:
      case ClothingType.jumpsuit:
        return CoverageType.fullbody;
      case ClothingType.jacket:
      case ClothingType.coat:
      case ClothingType.cardigan:
      case ClothingType.blazer:
        return CoverageType.layer;
    }
  }

  String get label {
    switch (this) {
      case ClothingType.shirt:
        return 'Shirt';
      case ClothingType.blouse:
        return 'Blouse';
      case ClothingType.tshirt:
        return 'T-Shirt';
      case ClothingType.tank:
        return 'Tank Top';
      case ClothingType.sweater:
        return 'Sweater';
      case ClothingType.pants:
        return 'Pants';
      case ClothingType.jeans:
        return 'Jeans';
      case ClothingType.skirt:
        return 'Skirt';
      case ClothingType.shorts:
        return 'Shorts';
      case ClothingType.dress:
        return 'Dress';
      case ClothingType.jumpsuit:
        return 'Jumpsuit';
      case ClothingType.jacket:
        return 'Jacket';
      case ClothingType.coat:
        return 'Coat';
      case ClothingType.cardigan:
        return 'Cardigan';
      case ClothingType.blazer:
        return 'Blazer';
    }
  }
}

class ClothingItem extends Equatable {
  final String id;
  final String? name;
  final ClothingType type;
  final String colorHex;
  final ClothingPattern pattern;
  final String? photoUrl;
  final DateTime createdAt;

  const ClothingItem({
    required this.id,
    this.name,
    required this.type,
    required this.colorHex,
    required this.pattern,
    this.photoUrl,
    required this.createdAt,
  });

  CoverageType get coverage => type.coverage;

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        id: json['id'] as String,
        name: json['name'] as String?,
        type: ClothingType.values.byName(json['type'] as String),
        colorHex: json['colorHex'] as String? ?? '#808080',
        pattern: ClothingPattern.values.byName(
            (json['pattern'] as String?) ?? ClothingPattern.solid.name),
        photoUrl: json['photoUrl'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'colorHex': colorHex,
        'pattern': pattern.name,
        'photoUrl': photoUrl,
        'createdAt': createdAt.toIso8601String(),
        'pendingReview': false,
      };

  ClothingItem copyWith({
    String? id,
    String? name,
    ClothingType? type,
    String? colorHex,
    ClothingPattern? pattern,
    String? photoUrl,
    DateTime? createdAt,
  }) =>
      ClothingItem(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        colorHex: colorHex ?? this.colorHex,
        pattern: pattern ?? this.pattern,
        photoUrl: photoUrl ?? this.photoUrl,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, name, type, colorHex, pattern, photoUrl, createdAt];
}
