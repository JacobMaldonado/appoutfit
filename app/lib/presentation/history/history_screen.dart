import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/generation_batch.dart';
import '../../data/models/outfit.dart';
import '../../data/repositories/outfit_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../../data/services/generation/generation_service.dart';
import '../shared/widgets/hanger_divider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = sl<AuthService>();
    final outfitRepo = sl<OutfitRepository>();
    final userId = authService.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: HangerDivider(),
          ),
          Expanded(
            child: FutureBuilder<List<GenerationBatch>>(
              future: outfitRepo.getHistory(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final batches = snapshot.data ?? [];
                if (batches.isEmpty) {
                  return const _EmptyHistory();
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: batches.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _BatchTile(batch: batches[index], userId: userId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({required this.batch, required this.userId});

  final GenerationBatch batch;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('MMM d, y · h:mm a').format(batch.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36454F).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.champagne,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                batch.mood.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.mood.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.outline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${batch.outfitIds.length} outfits',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.outline,
                  ),
                ),
              ],
            ),
          ),
          _RedoButton(batch: batch, userId: userId),
        ],
      ),
    );
  }
}

class _RedoButton extends StatefulWidget {
  const _RedoButton({required this.batch, required this.userId});
  final GenerationBatch batch;
  final String userId;

  @override
  State<_RedoButton> createState() => _RedoButtonState();
}

class _RedoButtonState extends State<_RedoButton> {
  bool _loading = false;

  Future<void> _redo() async {
    setState(() => _loading = true);
    try {
      await sl<GenerationService>().triggerGeneration(
        userId: widget.userId,
        mood: widget.batch.mood.name,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _loading ? null : _redo,
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, color: AppTheme.primary),
      tooltip: 'Redo this session',
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: AppTheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No history yet',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your suggestion sessions will appear here',
            style: TextStyle(color: AppTheme.outline),
          ),
        ],
      ),
    );
  }
}
