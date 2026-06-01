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
import '../../data/services/generation/generation_service.dart';
import '../shared/widgets/hanger_divider.dart';
import '../shared/widgets/mood_chip.dart';
import '../shared/widgets/outfit_card_widget.dart';

class SuggestScreen extends StatefulWidget {
  const SuggestScreen({super.key});

  @override
  State<SuggestScreen> createState() => _SuggestScreenState();
}

class _SuggestScreenState extends State<SuggestScreen> {
  Mood _selectedMood = Mood.casual;
  bool _loading = false;
  String? _activeBatchId;
  String? _error;

  final _authService = sl<AuthService>();
  final _generationService = sl<GenerationService>();
  final _outfitRepo = sl<OutfitRepository>();
  final _wardrobeRepo = sl<WardrobeRepository>();

  Future<void> _generate() async {
    final userId = _authService.currentUser?.id ?? '';
    debugPrint('[suggest] _generate() userId=$userId mood=${_selectedMood.name}');
    setState(() { _loading = true; _error = null; _activeBatchId = null; });
    try {
      final batchId = await _generationService.triggerGeneration(
        userId: userId,
        mood: _selectedMood.name,
      );
      debugPrint('[suggest] triggerGeneration returned batchId=$batchId');
      setState(() => _activeBatchId = batchId);
    } catch (e, st) {
      debugPrint('[suggest] triggerGeneration error: $e\n$st');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggest Outfit'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'History',
            onPressed: () => context.push(AppConstants.routeHistory),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: HangerDivider(label: 'CURATING STAGE'),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s the vibe?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: Mood.values
                        .map((mood) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: MoodChip(
                                mood: mood,
                                selected: _selectedMood == mood,
                                onTap: () =>
                                    setState(() => _selectedMood = mood),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      _loading ? 'CURATING...' : 'SUGGEST 4 OUTFITS',
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _activeBatchId != null
                ? _BatchResults(
                    batchId: _activeBatchId!,
                    userId: _authService.currentUser?.id ?? '',
                    outfitRepo: _outfitRepo,
                    wardrobeRepo: _wardrobeRepo,
                  )
                : const _EmptySuggest(),
          ),
        ],
      ),
    );
  }
}

class _BatchResults extends StatelessWidget {
  const _BatchResults({
    required this.batchId,
    required this.userId,
    required this.outfitRepo,
    required this.wardrobeRepo,
  });

  final String batchId;
  final String userId;
  final OutfitRepository outfitRepo;
  final WardrobeRepository wardrobeRepo;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Outfit>>(
      stream: outfitRepo.watchBatchOutfits(userId, batchId),
      builder: (context, outfitSnap) {
        debugPrint(
          '[suggest] watchBatchOutfits state=${outfitSnap.connectionState} '
          'count=${outfitSnap.data?.length} hasError=${outfitSnap.hasError} '
          'error=${outfitSnap.error}',
        );

        if (outfitSnap.hasError) {
          return Center(child: Text('Error loading outfits: ${outfitSnap.error}'));
        }

        final batchOutfits = outfitSnap.data ?? [];
        if (batchOutfits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Assembling your looks...'),
              ],
            ),
          );
        }

        return FutureBuilder<List<ClothingItem>>(
          future: wardrobeRepo.getItems(userId),
          builder: (context, wardrobeSnap) {
            final items = {
              for (final item in wardrobeSnap.data ?? []) item.id: item,
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
              itemCount: batchOutfits.length,
              itemBuilder: (context, index) {
                final outfit = batchOutfits[index];
                final colors = outfit.itemIds
                    .map((id) => items[id])
                    .whereType<ClothingItem>()
                    .map((item) => _hexToColor(item.colorHex))
                    .toList();

                return OutfitCard(
                  outfit: outfit,
                  colorSwatches: colors,
                  isSaved: outfit.saved,
                  onTap: () => context.push(
                    AppConstants.routeOutfitDetail,
                    extra: {
                      'outfit': outfit,
                      'wardrobeItems': wardrobeSnap.data ?? <ClothingItem>[],
                    },
                  ),
                  onSave: () async {
                    try {
                      await outfitRepo.saveOutfit(
                        userId,
                        outfit.id,
                        saved: !outfit.saved,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not save outfit: $e'),
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
    );
  }
}

class _EmptySuggest extends StatelessWidget {
  const _EmptySuggest();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: AppTheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Choose a mood and\ntap Suggest',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppTheme.outline),
            textAlign: TextAlign.center,
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
