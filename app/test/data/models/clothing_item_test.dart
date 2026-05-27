import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/models/clothing_item.dart';

void main() {
  group('ClothingItem', () {
    test('fromJson / toJson round-trip preserves all fields', () {
      final item = ClothingItem(
        id: 'test-id',
        type: ClothingType.blazer,
        colorHex: '#FF0000',
        pattern: ClothingPattern.floral,
        createdAt: DateTime(2024, 1, 15),
      );
      final json = item.toJson();
      final restored = ClothingItem.fromJson(json);
      expect(restored, equals(item));
    });

    group('ClothingTypeX coverage derivation', () {
      test('shirt, blouse, tshirt, tank, sweater → top', () {
        for (final type in [
          ClothingType.shirt,
          ClothingType.blouse,
          ClothingType.tshirt,
          ClothingType.tank,
          ClothingType.sweater,
        ]) {
          expect(type.coverage, CoverageType.top,
              reason: '${type.name} should be top');
        }
      });

      test('pants, jeans, skirt, shorts → bottom', () {
        for (final type in [
          ClothingType.pants,
          ClothingType.jeans,
          ClothingType.skirt,
          ClothingType.shorts,
        ]) {
          expect(type.coverage, CoverageType.bottom,
              reason: '${type.name} should be bottom');
        }
      });

      test('dress, jumpsuit → fullbody', () {
        for (final type in [ClothingType.dress, ClothingType.jumpsuit]) {
          expect(type.coverage, CoverageType.fullbody);
        }
      });

      test('jacket, coat, cardigan, blazer → layer', () {
        for (final type in [
          ClothingType.jacket,
          ClothingType.coat,
          ClothingType.cardigan,
          ClothingType.blazer,
        ]) {
          expect(type.coverage, CoverageType.layer);
        }
      });
    });

    test('label is non-empty for all types', () {
      for (final type in ClothingType.values) {
        expect(type.label.isNotEmpty, isTrue);
      }
    });

    test('equality is value-based via Equatable', () {
      final a = ClothingItem(
        id: 'x',
        type: ClothingType.jeans,
        colorHex: '#00FF00',
        pattern: ClothingPattern.solid,
        createdAt: DateTime(2024),
      );
      final b = ClothingItem(
        id: 'x',
        type: ClothingType.jeans,
        colorHex: '#00FF00',
        pattern: ClothingPattern.solid,
        createdAt: DateTime(2024),
      );
      expect(a, equals(b));
    });
  });
}
