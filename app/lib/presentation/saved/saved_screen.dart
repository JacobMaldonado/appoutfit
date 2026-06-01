import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
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
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load saved outfits.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.outline),
                      ),
                    ),
                  );
                }

                final saved = (snapshot.data ?? [])
                    .where((o) => o.saved)
                    .toList();

                debugPrint(
                  '[saved] stream update: total=${snapshot.data?.length ?? 0} '
                  'saved=${saved.length}',
                );

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
                          onTap: () => context.push(
                            AppConstants.routeOutfitDetail,
                            extra: {
                              'outfit': outfit,
                              'wardrobeItems':
                                  wardrobeSnap.data ?? <ClothingItem>[],
                            },
                          ),
                          onSave: () async {
                            try {
                              await outfitRepo.saveOutfit(
                                userId,
                                outfit.id,
                                saved: false,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not unsave: $e'),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          },
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
