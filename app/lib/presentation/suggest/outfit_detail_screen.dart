import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/clothing_item.dart';
import '../../data/models/outfit.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../shared/widgets/clothing_item_card.dart';
import '../shared/widgets/zoomable_image.dart';

class OutfitDetailScreen extends StatefulWidget {
  const OutfitDetailScreen({
    super.key,
    required this.outfit,
    required this.wardrobeItems,
  });

  final Outfit outfit;
  final List<ClothingItem> wardrobeItems;

  @override
  State<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends State<OutfitDetailScreen> {
  late bool _saved;
  bool _saving = false;

  final _outfitRepo = sl<OutfitRepository>();
  final _userId = sl<AuthService>().currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _saved = widget.outfit.saved;
  }

  Future<void> _toggleSave() async {
    if (_saving) return;
    final newVal = !_saved;
    setState(() {
      _saved = newVal;
      _saving = true;
    });
    try {
      await _outfitRepo.saveOutfit(_userId, widget.outfit.id, saved: newVal);
    } catch (e) {
      // Revert on failure
      if (mounted) setState(() => _saved = !newVal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outfitItems = widget.wardrobeItems
        .where((i) => widget.outfit.itemIds.contains(i.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.outfit.mood.label),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _saved ? Icons.favorite : Icons.favorite_border,
                    color: _saved ? AppTheme.dustyRose : null,
                  ),
                  tooltip: _saved ? 'Unsave' : 'Save',
                  onPressed: _toggleSave,
                ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full image — tap to zoom
              if (widget.outfit.imageUrl != null)
                ZoomableNetworkImage(
                  url: widget.outfit.imageUrl!,
                  height: 380,
                  borderRadius: 0,
                  fallback: Container(
                    height: 380,
                    color: AppTheme.champagne,
                    child: const Center(
                      child: Icon(
                        Icons.checkroom_outlined,
                        size: 64,
                        color: AppTheme.outlineVariant,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  color: AppTheme.champagne,
                  child: const Center(
                    child: Icon(
                      Icons.checkroom_outlined,
                      size: 64,
                      color: AppTheme.outlineVariant,
                    ),
                  ),
                ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mood + vibe chips
                  Row(
                    children: [
                      _InfoChip(
                        icon: widget.outfit.mood.emoji,
                        label: widget.outfit.mood.label,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: '👗',
                        label: widget.outfit.mood.dresscode,
                      ),
                    ],
                  ),

                  // Style note
                  if (widget.outfit.styleNote != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Style Note',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.outline,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.outfit.styleNote!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Items used
                  if (outfitItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'PIECES IN THIS LOOK',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.outline,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: outfitItems.length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final piece = outfitItems[i];
                          return GestureDetector(
                            onTap: () => context.push(
                              AppConstants.routeItemDetail,
                              extra: piece,
                            ),
                            child: SizedBox(
                              width: 85,
                              child: ClothingItemCard(item: piece),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _toggleSave,
                      icon: Icon(
                        _saved ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                      ),
                      label: Text(_saved ? 'SAVED TO FAVOURITES' : 'SAVE OUTFIT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _saved ? AppTheme.dustyRose : AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ), // Column
      ), // SingleChildScrollView
      ), // SafeArea
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.champagne,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$icon  $label',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
