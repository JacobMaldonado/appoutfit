import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/notifiers/mass_capture_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/capture_item.dart';
import '../../../data/models/clothing_item.dart';
import '../../../data/repositories/wardrobe_repository.dart';
import '../../../data/services/auth/auth_service.dart';

class MassReviewScreen extends StatelessWidget {
  const MassReviewScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final userId = sl<AuthService>().currentUser?.id ?? '';
    final repo = sl<WardrobeRepository>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Review Items'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppConstants.routeWardrobe),
        ),
      ),
      body: StreamBuilder<List<CaptureItem>>(
        stream: repo.watchCaptureSession(userId, sessionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text('No items found for this session.'),
            );
          }

          final allReady = items.every((i) => !i.isClassifying);
          final classifyingCount = items.where((i) => i.isClassifying).length;

          return Column(
            children: [
              if (classifyingCount > 0)
                _ProcessingBanner(count: classifyingCount),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) => _CaptureItemRow(
                    item: items[i],
                    onEdit: (updated) => repo.updateCaptureItem(
                      userId,
                      updated,
                    ),
                  ),
                ),
              ),
              _ConfirmBar(
                count: items.length,
                allReady: allReady,
                onConfirm: () => _confirm(context, userId, items),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context,
    String userId,
    List<CaptureItem> items,
  ) async {
    try {
      await sl<MassCaptureNotifier>().confirmSession(
        userId: userId,
        items: items,
      );
      sl<MassCaptureNotifier>().clearSession();
      if (context.mounted) context.go(AppConstants.routeWardrobe);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save items. Please try again.')),
        );
      }
    }
  }
}

class _ProcessingBanner extends StatelessWidget {
  const _ProcessingBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.champagne,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Classifying $count item${count == 1 ? '' : 's'}...',
            style: const TextStyle(
                color: AppTheme.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _CaptureItemRow extends StatelessWidget {
  const _CaptureItemRow({required this.item, required this.onEdit});
  final CaptureItem item;
  final Future<void> Function(CaptureItem) onEdit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.isReady
          ? () => _showEditSheet(context)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            _Thumbnail(photoUrl: item.photoUrl),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: item.isClassifying
                  ? _ClassifyingPlaceholder()
                  : _ItemDetails(item: item),
            ),
            // Edit indicator
            if (item.isReady)
              const Icon(Icons.chevron_right,
                  color: AppTheme.outlineVariant, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditItemSheet(item: item, onSave: onEdit),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 64,
        height: 80,
        color: AppTheme.champagne,
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.checkroom_outlined,
                  color: AppTheme.outlineVariant,
                ),
              )
            : const Icon(Icons.checkroom_outlined,
                color: AppTheme.outlineVariant),
      ),
    );
  }
}

class _ClassifyingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 8),
        Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
                color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 6),
        const Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child:
                  CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.outlineVariant),
            ),
            SizedBox(width: 6),
            Text('Classifying…',
                style: TextStyle(fontSize: 12, color: AppTheme.outline)),
          ],
        ),
      ],
    );
  }
}

class _ItemDetails extends StatelessWidget {
  const _ItemDetails({required this.item});
  final CaptureItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name?.isNotEmpty == true
              ? item.name!
              : item.type?.label ?? 'Unknown',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (item.type != null)
              _SmallChip(label: item.type!.label),
            const SizedBox(width: 4),
            if (item.pattern != null)
              _SmallChip(label: item.pattern!.name),
            const SizedBox(width: 4),
            if (item.colorHex != null)
              _ColorDot(hex: item.colorHex!),
          ],
        ),
        if (item.shortDescription != null) ...[
          const SizedBox(height: 4),
          Text(
            item.shortDescription!,
            style: const TextStyle(fontSize: 12, color: AppTheme.outline),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.champagne,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});
  final String hex;

  Color _parse() {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: _parse(),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.outlineVariant, width: 0.5),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.count,
    required this.allReady,
    required this.onConfirm,
  });
  final int count;
  final bool allReady;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: allReady ? onConfirm : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.dustyRose,
            disabledBackgroundColor: AppTheme.outlineVariant.withValues(alpha: 0.3),
            foregroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            allReady
                ? 'Add $count item${count == 1 ? '' : 's'} to Closet'
                : 'Waiting for classification…',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ─── Edit Item Bottom Sheet ───────────────────────────────────────────────────

class _EditItemSheet extends StatefulWidget {
  const _EditItemSheet({required this.item, required this.onSave});
  final CaptureItem item;
  final Future<void> Function(CaptureItem) onSave;

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late ClothingType? _type;
  late ClothingPattern? _pattern;
  late String? _colorHex;
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.item.type;
    _pattern = widget.item.pattern;
    _colorHex = widget.item.colorHex;
    _nameCtrl = TextEditingController(text: widget.item.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.item.copyWith(
      type: _type,
      pattern: _pattern,
      colorHex: _colorHex,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
    );
    await widget.onSave(updated);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit Item',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(height: 16),
            // Name
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                labelText: 'Name (optional)',
                labelStyle: const TextStyle(color: AppTheme.outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            // Type
            DropdownButtonFormField<ClothingType>(
              initialValue: _type,
              decoration: InputDecoration(
                labelText: 'Type',
                labelStyle: const TextStyle(color: AppTheme.outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              items: ClothingType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),
            // Pattern
            DropdownButtonFormField<ClothingPattern>(
              initialValue: _pattern,
              decoration: InputDecoration(
                labelText: 'Pattern',
                labelStyle: const TextStyle(color: AppTheme.outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              items: ClothingPattern.values
                  .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.name[0].toUpperCase() +
                          p.name.substring(1))))
                  .toList(),
              onChanged: (v) => setState(() => _pattern = v),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.dustyRose,
                  foregroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primary))
                    : const Text('Save',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
