import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/di/service_locator.dart';
import '../../core/services/background_removal_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/clothing_item.dart';
import '../../data/repositories/wardrobe_repository.dart';
import '../../data/services/auth/auth_service.dart';
import '../../data/services/storage/storage_service.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  ClothingType? _selectedType;
  ClothingPattern? _selectedPattern;
  String _selectedColorHex = '#36454F';
  File? _photoFile;
  bool _photoRequired = false; // shows error if user tried to save without photo
  bool _typeRequired = false;  // shows error if user tried to save without type
  bool _loading = false;
  bool _processingPhoto = false; // true while bg removal ONNX model runs

  final _nameController = TextEditingController();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  static const _colorOptions = [
    '#36454F', '#ECBDA4', '#F0E0C8', '#FFFFFF',
    '#000000', '#C9778A', '#7A9E9F', '#D4A5A5',
    '#8B7355', '#F5DEB3', '#708090', '#E8D5C4',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() {
      _processingPhoto = true;
      _photoRequired = false;
    });
    try {
      final rawFile = File(xfile.path);
      final bgRemovedFile =
          await sl<BackgroundRemovalService>().removeBackground(rawFile);
      if (mounted) {
        setState(() {
          _photoFile = bgRemovedFile;
          _processingPhoto = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _photoFile = File(xfile.path);
          _processingPhoto = false;
        });
      }
    }
  }

  Future<void> _save() async {
    // Validate required fields
    if (_photoFile == null) {
      setState(() => _photoRequired = true);
      return;
    }
    if (_selectedType == null) {
      setState(() => _typeRequired = true);
      return;
    }
    setState(() => _loading = true);
    bool photoFailed = false;
    try {
      final authService = sl<AuthService>();
      final wardrobeRepo = sl<WardrobeRepository>();
      final storageService = sl<StorageService>();
      final userId = authService.currentUser?.id ?? '';
      final itemId = _uuid.v4();

      String? photoUrl;
      if (_photoFile != null) {
        try {
          photoUrl = await storageService.uploadClothingPhoto(
            userId: userId,
            itemId: itemId,
            file: _photoFile!,
          );
        } catch (e) {
          debugPrint('[AddItem] Photo upload failed: $e');
          photoFailed = true;
        }
      }

      final item = ClothingItem(
        id: itemId,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        type: _selectedType!,
        colorHex: _selectedColorHex,
        pattern: _selectedPattern ?? ClothingPattern.solid,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await wardrobeRepo.addItem(userId, item);

      if (mounted) {
        final msg = photoFailed
            ? 'Item added! (photo skipped — enable Firebase Storage to upload photos)'
            : 'Item added to your closet!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('[AddItem] Save failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Acquisition'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhotoPicker(
              photoFile: _photoFile,
              colorHex: _selectedColorHex,
              hasError: _photoRequired,
              processing: _processingPhoto,
              onTap: _processingPhoto ? null : _pickPhoto,
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'NAME (OPTIONAL)'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Favourite blue blouse',
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'CATEGORY *'),
            const SizedBox(height: 8),
            _TypeSelector(
              selected: _selectedType,
              hasError: _typeRequired,
              onChanged: (t) => setState(() {
                _selectedType = t;
                _typeRequired = false;
              }),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'PATTERN (OPTIONAL)'),
            const SizedBox(height: 8),
            _PatternSelector(
              selected: _selectedPattern,
              onChanged: (p) => setState(() => _selectedPattern = p),
            ),
            const SizedBox(height: 24),
            _SectionLabel(label: 'COLOR (OPTIONAL)'),
            const SizedBox(height: 8),
            _ColorSelector(
              colorOptions: _colorOptions,
              selected: _selectedColorHex,
              onChanged: (c) => setState(() => _selectedColorHex = c),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ADD TO COLLECTION'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photoFile,
    required this.colorHex,
    required this.onTap,
    this.hasError = false,
    this.processing = false,
  });

  final File? photoFile;
  final String colorHex;
  final VoidCallback? onTap;
  final bool hasError;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.champagne.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: hasError ? Colors.red : AppTheme.outlineVariant.withValues(alpha: 0.5),
                style: BorderStyle.solid,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            child: processing
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(height: 12),
                        Text(
                          'REMOVING BACKGROUND…',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  )
                : photoFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.file(photoFile!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: AppTheme.surfaceCard,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.photo_camera_outlined,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'UPLOAD PHOTO',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Required to add item',
                            style: TextStyle(fontSize: 11, color: AppTheme.outline),
                          ),
                        ],
                      ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              'Please add a photo',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
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

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.onChanged,
    this.hasError = false,
  });

  final ClothingType? selected;
  final ValueChanged<ClothingType> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ClothingType>(
      initialValue: selected,
      decoration: InputDecoration(
        hintText: 'Select category',
        errorText: hasError ? 'Please select a category' : null,
      ),
      items: ClothingType.values
          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

class _PatternSelector extends StatelessWidget {
  const _PatternSelector({required this.selected, required this.onChanged});

  final ClothingPattern? selected;
  final ValueChanged<ClothingPattern> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: ClothingPattern.values.map((p) {
        final isSelected = p == selected;
        return ChoiceChip(
          label: Text(p.name),
          selected: isSelected,
          onSelected: (_) => onChanged(p),
        );
      }).toList(),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({
    required this.colorOptions,
    required this.selected,
    required this.onChanged,
  });

  final List<String> colorOptions;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colorOptions.map((hex) {
        final isSelected = hex == selected;
        final color = _hexToColor(hex);
        return GestureDetector(
          onTap: () => onChanged(hex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: hex == '#FFFFFF' ? AppTheme.outlineVariant : color,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
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
    );
  }
}

Color _hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
