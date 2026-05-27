import 'package:equatable/equatable.dart';

enum Mood { casual, work, brunch, night, active }

extension MoodX on Mood {
  String get label {
    switch (this) {
      case Mood.casual:
        return 'Casual';
      case Mood.work:
        return 'Work';
      case Mood.brunch:
        return 'Brunch';
      case Mood.night:
        return 'Night Out';
      case Mood.active:
        return 'Active';
    }
  }

  String get emoji {
    switch (this) {
      case Mood.casual:
        return '☀️';
      case Mood.work:
        return '💼';
      case Mood.brunch:
        return '🥂';
      case Mood.night:
        return '✨';
      case Mood.active:
        return '🏃';
    }
  }
}

class Outfit extends Equatable {
  final String id;
  final List<String> itemIds;
  final Mood mood;
  final bool saved;
  final DateTime createdAt;
  final String? batchId;

  const Outfit({
    required this.id,
    required this.itemIds,
    required this.mood,
    this.saved = false,
    required this.createdAt,
    this.batchId,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id: json['id'] as String,
        itemIds: List<String>.from(json['itemIds'] as List),
        mood: Mood.values.byName(json['mood'] as String),
        saved: (json['saved'] as bool?) ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        batchId: json['batchId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemIds': itemIds,
        'mood': mood.name,
        'saved': saved,
        'createdAt': createdAt.toIso8601String(),
        'batchId': batchId,
      };

  Outfit copyWith({
    String? id,
    List<String>? itemIds,
    Mood? mood,
    bool? saved,
    DateTime? createdAt,
    String? batchId,
  }) =>
      Outfit(
        id: id ?? this.id,
        itemIds: itemIds ?? this.itemIds,
        mood: mood ?? this.mood,
        saved: saved ?? this.saved,
        createdAt: createdAt ?? this.createdAt,
        batchId: batchId ?? this.batchId,
      );

  @override
  List<Object?> get props => [id, itemIds, mood, saved, createdAt, batchId];
}
