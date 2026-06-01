import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/di/service_locator.dart';
import '../../data/models/clothing_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../shared/widgets/clothing_item_card.dart';
import '../shared/widgets/zoomable_image.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final wardrobeRepo = sl<WardrobeRepository>();
    final userId = sl<AuthService>().currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(item.type.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => _showEditSheet(context, item, wardrobeRepo, userId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, wardrobeRepo, userId),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo / color swatch — tap to zoom
            item.photoUrl != null
                ? ZoomableNetworkImage(
                    url: item.photoUrl!,
                    height: 320,
                    fallback: _PatternSwatch(item: item),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 320,
                      child: _PatternSwatch(item: item),
                    ),
                  ),
            const SizedBox(height: 24),

            // Attributes
            _AttributeCard(
              children: [
                _AttributeRow(
                  label: 'Category',
                  value: item.type.label,
                ),
                _AttributeRow(
                  label: 'Coverage',
                  value: item.coverage.name,
                ),
                _AttributeRow(
                  label: 'Pattern',
                  value: item.pattern.name,
                ),
                _AttributeRow(
                  label: 'Color',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _hexToColor(item.colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.colorHex.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                _AttributeRow(
                  label: 'Added',
                  value: _formatDate(item.createdAt),
                  isLast: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WardrobeRepository repo,
    String userId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text(
          'Remove ${item.type.label} from your closet? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await repo.deleteItem(userId, item.id);
      if (context.mounted) context.pop();
    }
  }

  void _showEditSheet(
    BuildContext context,
    ClothingItem item,
    WardrobeRepository repo,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditItemSheet(
        item: item,
        repo: repo,
        userId: userId,
        onSaved: () {
          if (context.mounted) context.pop();
        },
      ),
    );
  }
}

// ── Edit bottom sheet ─────────────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({
    required this.item,
    required this.repo,
    required this.userId,
    required this.onSaved,
  });

  final ClothingItem item;
  final WardrobeRepository repo;
  final String userId;
  final VoidCallback onSaved;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late ClothingType _type;
  late ClothingPattern _pattern;
  late String _colorHex;
  bool _saving = false;

  static const _colorOptions = [
    '#36454F', '#ECBDA4', '#F0E0C8', '#FFFFFF',
    '#000000', '#C9778A', '#7A9E9F', '#D4A5A5',
    '#8B7355', '#F5DEB3', '#708090', '#E8D5C4',
    '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
    '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F',
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.item.type;
    _pattern = widget.item.pattern;
    _colorHex = widget.item.colorHex;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.item.copyWith(
        type: _type,
        pattern: _pattern,
        colorHex: _colorHex,
      );
      await widget.repo.updateItem(widget.userId, updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved!')),
        );
        Navigator.of(context).pop(); // close sheet
        widget.onSaved();
      }
    } catch (e) {
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
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Edit Item',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SheetLabel('CATEGORY'),
          const SizedBox(height: 8),
          DropdownButtonFormField<ClothingType>(
            initialValue: _type,
            decoration: const InputDecoration(),
            items: ClothingType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) => v != null ? setState(() => _type = v) : null,
          ),
          const SizedBox(height: 20),
          const _SheetLabel('PATTERN'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ClothingPattern.values.map((p) {
              return ChoiceChip(
                label: Text(p.name),
                selected: _pattern == p,
                onSelected: (_) => setState(() => _pattern = p),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _SheetLabel('COLOR'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorOptions.map((hex) {
              final isSelected = hex == _colorHex;
              final color = _hexToColor(hex);
              return GestureDetector(
                onTap: () => setState(() => _colorHex = hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hex == '#FFFFFF'
                          ? AppTheme.outlineVariant
                          : color,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: color.computeLuminance() > 0.5
                              ? Colors.black87
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE CHANGES'),
          ),
        ],
      ),
    );
  }
}

// ── Helpers & sub-widgets ─────────────────────────────────────────────────────

class _PatternSwatch extends StatelessWidget {
  const _PatternSwatch({required this.item});
  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    return ClothingItemCard(item: item);
  }
}

class _AttributeCard extends StatelessWidget {
  const _AttributeCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36454F).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  const _AttributeRow({
    required this.label,
    this.value,
    this.trailing,
    this.isLast = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (trailing != null)
                trailing!
              else
                Text(
                  value ?? '—',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppTheme.outline,
        letterSpacing: 1.5,
      ),
    );
  }
}

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String _formatDate(DateTime dt) {
  return '${dt.day}/${dt.month}/${dt.year}';
}
