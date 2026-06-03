import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/models/capture_item.dart';
import 'package:closet_app/data/models/clothing_item.dart';

void main() {
  group('CaptureItem.fromFirestore', () {
    test('parses fully-populated document', () {
      final data = {
        'captureSessionId': 'sess-1',
        'createdAt': '2024-01-15T10:00:00.000',
        'photoUrl': 'https://storage.test/photo.jpg',
        'status': 'ready',
        'type': 'shirt',
        'colorHex': '#FF5733',
        'pattern': 'striped',
        'name': 'Summer Shirt',
        'shortDescription': 'A bright striped shirt',
      };

      final item = CaptureItem.fromFirestore(data, 'item-123');

      expect(item.id, 'item-123');
      expect(item.captureSessionId, 'sess-1');
      expect(item.status, CaptureStatus.ready);
      expect(item.type, ClothingType.shirt);
      expect(item.colorHex, '#FF5733');
      expect(item.pattern, ClothingPattern.striped);
      expect(item.name, 'Summer Shirt');
      expect(item.shortDescription, 'A bright striped shirt');
      expect(item.isReady, isTrue);
      expect(item.isClassifying, isFalse);
    });

    test('defaults to classifying status for unknown status string', () {
      final data = {
        'captureSessionId': 'sess-1',
        'createdAt': '2024-01-15T10:00:00.000',
        'status': 'unknown_future_status',
      };

      final item = CaptureItem.fromFirestore(data, 'item-x');
      expect(item.status, CaptureStatus.classifying);
      expect(item.isClassifying, isTrue);
    });

    test('tolerates legacy color field name', () {
      final data = {
        'captureSessionId': 'sess-1',
        'createdAt': '2024-01-15T10:00:00.000',
        'status': 'ready',
        'color': '#AABBCC', // legacy key
      };

      final item = CaptureItem.fromFirestore(data, 'item-legacy');
      expect(item.colorHex, '#AABBCC');
    });

    test('prefers colorHex over legacy color field', () {
      final data = {
        'captureSessionId': 'sess-1',
        'createdAt': '2024-01-15T10:00:00.000',
        'status': 'ready',
        'colorHex': '#112233',
        'color': '#AABBCC',
      };

      final item = CaptureItem.fromFirestore(data, 'item-prefer');
      expect(item.colorHex, '#112233');
    });

    test('handles null optional fields gracefully', () {
      final data = {
        'captureSessionId': 'sess-1',
        'createdAt': '2024-01-15T10:00:00.000',
      };

      final item = CaptureItem.fromFirestore(data, 'item-minimal');
      expect(item.type, isNull);
      expect(item.colorHex, isNull);
      expect(item.pattern, isNull);
      expect(item.name, isNull);
      expect(item.photoUrl, isNull);
    });

    test('ignores unknown type string', () {
      final data = {
        'captureSessionId': 'sess-1',
        'createdAt': '2024-01-15T10:00:00.000',
        'type': 'not_a_real_type',
      };

      final item = CaptureItem.fromFirestore(data, 'item-bad-type');
      expect(item.type, isNull);
    });
  });

  group('CaptureItem.toFirestore', () {
    test('includes pendingReview: true', () {
      final item = CaptureItem(
        id: 'item-1',
        captureSessionId: 'sess-1',
        createdAt: DateTime(2024, 1, 15),
        status: CaptureStatus.classifying,
        photoUrl: 'https://example.com/photo.jpg',
      );

      final map = item.toFirestore();
      expect(map['pendingReview'], isTrue);
      expect(map['status'], 'classifying');
      expect(map['captureSessionId'], 'sess-1');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
    });

    test('omits null optional fields', () {
      final item = CaptureItem(
        id: 'item-1',
        captureSessionId: 'sess-1',
        createdAt: DateTime(2024, 1, 15),
      );

      final map = item.toFirestore();
      expect(map.containsKey('type'), isFalse);
      expect(map.containsKey('colorHex'), isFalse);
      expect(map.containsKey('pattern'), isFalse);
      expect(map.containsKey('name'), isFalse);
      expect(map.containsKey('shortDescription'), isFalse);
    });
  });

  group('CaptureItem.copyWith', () {
    test('overrides specified fields only', () {
      final original = CaptureItem(
        id: 'item-1',
        captureSessionId: 'sess-1',
        createdAt: DateTime(2024),
        type: ClothingType.shirt,
        colorHex: '#FFFFFF',
        status: CaptureStatus.classifying,
      );

      final copy = original.copyWith(
        status: CaptureStatus.ready,
        colorHex: '#000000',
      );

      expect(copy.id, original.id);
      expect(copy.captureSessionId, original.captureSessionId);
      expect(copy.type, ClothingType.shirt); // unchanged
      expect(copy.colorHex, '#000000'); // changed
      expect(copy.status, CaptureStatus.ready); // changed
    });
  });

  group('CaptureItem.toClothingItem', () {
    test('converts to ClothingItem with defaults for missing fields', () {
      final capture = CaptureItem(
        id: 'item-1',
        captureSessionId: 'sess-1',
        createdAt: DateTime(2024, 3, 10),
        status: CaptureStatus.confirmed,
        type: ClothingType.jeans,
        colorHex: '#4A4A4A',
        pattern: ClothingPattern.solid,
        name: 'Blue Jeans',
        photoUrl: 'https://example.com/jeans.jpg',
      );

      final clothing = capture.toClothingItem();

      expect(clothing.id, 'item-1');
      expect(clothing.type, ClothingType.jeans);
      expect(clothing.colorHex, '#4A4A4A');
      expect(clothing.pattern, ClothingPattern.solid);
      expect(clothing.name, 'Blue Jeans');
      expect(clothing.photoUrl, 'https://example.com/jeans.jpg');
    });

    test('uses fallback values when type and color are null', () {
      final capture = CaptureItem(
        id: 'item-2',
        captureSessionId: 'sess-1',
        createdAt: DateTime(2024),
        status: CaptureStatus.confirmed,
      );

      final clothing = capture.toClothingItem();
      expect(clothing.type, ClothingType.shirt); // default
      expect(clothing.colorHex, '#808080'); // default
      expect(clothing.pattern, ClothingPattern.solid); // default
    });
  });

  group('CaptureStatus', () {
    test('fromString maps known values correctly', () {
      expect(CaptureStatus.fromString('classifying'), CaptureStatus.classifying);
      expect(CaptureStatus.fromString('ready'), CaptureStatus.ready);
      expect(CaptureStatus.fromString('confirmed'), CaptureStatus.confirmed);
    });

    test('fromString defaults to classifying for unknown values', () {
      expect(CaptureStatus.fromString(''), CaptureStatus.classifying);
      expect(CaptureStatus.fromString('pending'), CaptureStatus.classifying);
    });
  });
}
