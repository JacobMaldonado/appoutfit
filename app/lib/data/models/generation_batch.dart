import 'package:equatable/equatable.dart';
import 'outfit.dart';

enum GenerationStatus { pending, complete, failed }

class GenerationBatch extends Equatable {
  final String id;
  final Mood mood;
  final GenerationStatus status;
  final List<String> outfitIds;
  final DateTime createdAt;

  const GenerationBatch({
    required this.id,
    required this.mood,
    required this.status,
    required this.outfitIds,
    required this.createdAt,
  });

  factory GenerationBatch.fromJson(Map<String, dynamic> json) =>
      GenerationBatch(
        id: json['id'] as String,
        mood: Mood.values.byName(json['mood'] as String),
        status: GenerationStatus.values.byName(
          (json['status'] as String?) ?? 'pending',
        ),
        outfitIds: List<String>.from(json['outfitIds'] as List? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'mood': mood.name,
        'status': status.name,
        'outfitIds': outfitIds,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [id, mood, status, outfitIds, createdAt];
}
