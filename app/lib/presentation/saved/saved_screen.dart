import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/clothing_item.dart';
import '../../data/models/outfit.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../shared/widgets/hanger_divider.dart';
import '../shared/widgets/outfit_card_widget.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = sl<AuthService>();
    final outfitRepo = sl<OutfitRepository>();
    final wardrobeRepo = sl<WardrobeRepository>();
    final userId = authService.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Outfits')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: HangerDivider(),
          ),
          Expanded(
            child: StreamBuilder<List<Outfit>>(
              stream: outfitRepo.watchOutfits(userId),
              builder: (context, snapshot) {
                final saved = (snapshot.data ?? [])
                    .where((o) => o.saved)
                    .toList();

                if (saved.isEmpty) {
                  return const _EmptySaved();
                }

                return FutureBuilder<List<ClothingItem>>(
                  future: wardrobeRepo.getItems(userId),
                  builder: (context, wardrobeSnap) {
                    final items = {
                      for (final item in wardrobeSnap.data ?? [])
                        item.id: item,
                    };

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: saved.length,
                      itemBuilder: (context, index) {
                        final outfit = saved[index];
                        final colors = outfit.itemIds
                            .map((id) => items[id])
                            .whereType<ClothingItem>()
                            .map((item) => _hexToColor(item.colorHex))
                            .toList();

                        return OutfitCard(
                          outfit: outfit,
                          colorSwatches: colors,
                          isSaved: true,
                          onSave: () => outfitRepo.saveOutfit(
                            userId,
                            outfit.id,
                            saved: false,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border,
            size: 64,
            color: AppTheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved outfits yet',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the heart on an outfit to save it',
            style: TextStyle(color: AppTheme.outline),
          ),
        ],
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
