import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/clothing_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../shared/widgets/clothing_item_card.dart';
import '../shared/widgets/hanger_divider.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  ClothingType? _filterType;
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClothingItem> _filtered(List<ClothingItem> items) {
    return items.where((item) {
      final matchesType = _filterType == null || item.type == _filterType;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (item.name?.toLowerCase().contains(q) ?? false) ||
          item.type.label.toLowerCase().contains(q);
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = sl<AuthService>();
    final wardrobeRepo = sl<WardrobeRepository>();
    final userId = authService.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search by name or type...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('My Closet'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            tooltip: _showSearch ? 'Close search' : 'Search',
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchQuery = '';
              }
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: HangerDivider(),
          ),
          _CategoryChips(
            selected: _filterType,
            onChanged: (t) => setState(() => _filterType = t),
          ),
          Expanded(
            child: StreamBuilder<List<ClothingItem>>(
              stream: wardrobeRepo.watchItems(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('[Wardrobe] Stream error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined,
                              size: 48, color: AppTheme.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load wardrobe',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.outline),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final allItems = snapshot.data ?? [];
                if (allItems.isEmpty) {
                  return _EmptyWardrobe(
                    onAdd: () => context.go(AppConstants.routeAddItem),
                  );
                }
                final items = _filtered(allItems);
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items match your filter.',
                      style: TextStyle(color: AppTheme.outline),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => ClothingItemCard(
                    item: items[index],
                    onTap: () => context.push(
                      AppConstants.routeItemDetail,
                      extra: items[index],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppConstants.routeAddItem),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onChanged});

  final ClothingType? selected;
  final ValueChanged<ClothingType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          ...ClothingType.values.map((t) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(t.label),
                  selected: selected == t,
                  onSelected: (_) => onChanged(selected == t ? null : t),
                ),
              )),
        ],
      ),
    );
  }
}

class _EmptyWardrobe extends StatelessWidget {
  const _EmptyWardrobe({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.checkroom_outlined,
            size: 72,
            color: AppTheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Your closet is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add your first item to get started',
            style: TextStyle(color: AppTheme.outline),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('ADD FIRST ITEM'),
          ),
        ],
      ),
    );
  }
}
