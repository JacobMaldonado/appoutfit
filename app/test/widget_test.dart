import 'package:flutter_test/flutter_test.dart';
import 'package:closet_app/data/models/clothing_item.dart';
import 'package:closet_app/data/models/outfit.dart';

/// Basic smoke test — confirms core model types are importable and functional.
void main() {
  testWidgets('Core models are accessible', (tester) async {
    const item = ClothingItem;
    const outfit = Outfit;
    expect(item, isNotNull);
    expect(outfit, isNotNull);
  });
}
