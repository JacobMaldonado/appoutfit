import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/models/outfit.dart';

void main() {
  group('Outfit', () {
    test('fromJson / toJson round-trip', () {
      final outfit = Outfit(
        id: 'outfit-1',
        itemIds: ['a', 'b', 'c'],
        mood: Mood.work,
        saved: true,
        createdAt: DateTime(2024, 6, 1),
        batchId: 'batch-1',
      );
      final restored = Outfit.fromJson(outfit.toJson());
      expect(restored, equals(outfit));
    });

    test('copyWith changes only specified fields', () {
      final original = Outfit(
        id: 'o1',
        itemIds: ['x'],
        mood: Mood.casual,
        createdAt: DateTime(2024),
      );
      final modified = original.copyWith(saved: true);
      expect(modified.saved, isTrue);
      expect(modified.id, 'o1');
      expect(modified.mood, Mood.casual);
    });

    test('saved defaults to false', () {
      final outfit = Outfit(
        id: 'o',
        itemIds: [],
        mood: Mood.brunch,
        createdAt: DateTime(2024),
      );
      expect(outfit.saved, isFalse);
    });
  });

  group('Mood', () {
    test('all moods have non-empty label and emoji', () {
      for (final mood in Mood.values) {
        expect(mood.label.isNotEmpty, isTrue);
        expect(mood.emoji.isNotEmpty, isTrue);
      }
    });
  });
}
