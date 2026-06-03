import 'clothing_item.dart';

/// Represents a wardrobe item while it is being processed during mass capture.
///
/// Items are created immediately when a photo is taken (status: classifying)
/// and updated in real-time as the classification service processes them
/// (status: ready). Once the user confirms the batch, status becomes confirmed
/// and [pendingReview] is set to false.
class CaptureItem {
  CaptureItem({
    required this.id,
    required this.captureSessionId,
    required this.createdAt,
    this.photoUrl,
    this.status = CaptureStatus.classifying,
    this.type,
    this.colorHex,
    this.pattern,
    this.name,
    this.shortDescription,
  });

  final String id;
  final String captureSessionId;
  final DateTime createdAt;
  final String? photoUrl;
  final CaptureStatus status;
  final ClothingType? type;
  final String? colorHex;
  final ClothingPattern? pattern;
  final String? name;
  final String? shortDescription;

  bool get isClassifying => status == CaptureStatus.classifying;
  bool get isReady => status == CaptureStatus.ready;

  factory CaptureItem.fromFirestore(Map<String, dynamic> data, String id) {
    return CaptureItem(
      id: id,
      captureSessionId: data['captureSessionId'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']),
      photoUrl: data['photoUrl'] as String?,
      status: CaptureStatus.fromString(data['status'] as String? ?? 'classifying'),
      type: _parseType(data['type'] as String?),
      // Service writes colorHex; tolerate legacy 'color' field too
      colorHex: data['colorHex'] as String? ?? data['color'] as String?,
      pattern: _parsePattern(data['pattern'] as String?),
      name: data['name'] as String?,
      shortDescription: data['shortDescription'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'captureSessionId': captureSessionId,
        'pendingReview': true,
        'status': status.value,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (type != null) 'type': type!.name,
        if (colorHex != null) 'colorHex': colorHex,
        if (pattern != null) 'pattern': pattern!.name,
        if (name != null) 'name': name,
        if (shortDescription != null) 'shortDescription': shortDescription,
        'createdAt': createdAt.toIso8601String(),
      };

  CaptureItem copyWith({
    String? photoUrl,
    CaptureStatus? status,
    ClothingType? type,
    String? colorHex,
    ClothingPattern? pattern,
    String? name,
    String? shortDescription,
  }) =>
      CaptureItem(
        id: id,
        captureSessionId: captureSessionId,
        createdAt: createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
        status: status ?? this.status,
        type: type ?? this.type,
        colorHex: colorHex ?? this.colorHex,
        pattern: pattern ?? this.pattern,
        name: name ?? this.name,
        shortDescription: shortDescription ?? this.shortDescription,
      );

  /// Convert to a confirmed [ClothingItem] ready to be displayed in the wardrobe.
  ClothingItem toClothingItem() => ClothingItem(
        id: id,
        name: name,
        type: type ?? ClothingType.shirt,
        colorHex: colorHex ?? '#808080',
        pattern: pattern ?? ClothingPattern.solid,
        photoUrl: photoUrl,
        createdAt: createdAt,
      );

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    // Firestore Timestamp — access via dynamic to avoid direct firebase import
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  static ClothingType? _parseType(String? value) {
    if (value == null) return null;
    try {
      return ClothingType.values.byName(value);
    } catch (_) {
      return null;
    }
  }

  static ClothingPattern? _parsePattern(String? value) {
    if (value == null) return null;
    try {
      return ClothingPattern.values.byName(value);
    } catch (_) {
      return null;
    }
  }
}

enum CaptureStatus {
  classifying,
  ready,
  confirmed;

  static CaptureStatus fromString(String s) => switch (s) {
        'ready' => CaptureStatus.ready,
        'confirmed' => CaptureStatus.confirmed,
        _ => CaptureStatus.classifying,
      };

  String get value => name;
}
