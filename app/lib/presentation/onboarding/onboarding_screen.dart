import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/notifiers/user_profile_notifier.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth/auth_service.dart';

/// Body type definitions shown in the picker.
class _BodyType {
  const _BodyType(this.key, this.label, this.gender);
  final String key;
  final String label;
  final String gender; // 'fem' | 'masc'
}

const _femTypes = [
  _BodyType('F_Hourglass', 'Hourglass', 'fem'),
  _BodyType('F_Pear_Triangle', 'Pear / Triangle', 'fem'),
  _BodyType('F_Apple_Oval', 'Apple / Oval', 'fem'),
  _BodyType('F_Rectangle_Athletic', 'Rectangle', 'fem'),
  _BodyType('F_Inverted_Triangle', 'Inv. Triangle', 'fem'),
  _BodyType('F_Petite_Slim', 'Petite / Slim', 'fem'),
];

const _mascTypes = [
  _BodyType('M_Athletic_Mesomorph', 'Athletic', 'masc'),
  _BodyType('M_Trapezoid', 'Trapezoid', 'masc'),
  _BodyType('M_Rectangle_Average', 'Rectangle', 'masc'),
  _BodyType('M_Oval_DadBod', 'Oval / Dad Bod', 'masc'),
  _BodyType('M_Slim_Ectomorph', 'Slim', 'masc'),
  _BodyType('M_Stocky_Endomorph', 'Stocky', 'masc'),
];

enum _Step { welcome, bodyType }

/// Onboarding screen shown once after first login, or pushed from Account
/// when `fromAccount: true` (skips welcome, goes straight to body type picker).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.fromAccount = false});

  final bool fromAccount;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late _Step _step;
  String _selectedGender = 'fem';
  String? _selectedBodyType;
  bool _saving = false;

  final _authService = sl<AuthService>();
  final _profileNotifier = sl<UserProfileNotifier>();
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _step = widget.fromAccount ? _Step.bodyType : _Step.welcome;
  }

  Future<void> _pickAndUploadPhoto() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      final file = File(xfile.path);
      final ref =
          FirebaseStorage.instance.ref('users/${user.id}/profile.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _profileNotifier.completeOnboarding(
        user.id,
        profilePhotoUrl: url,
      );
      if (mounted) context.go(AppConstants.routeWardrobe);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveBodyType() async {
    if (_selectedBodyType == null) return;
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      if (widget.fromAccount) {
        await _profileNotifier.updateBodyType(user.id, _selectedBodyType!);
        if (mounted) context.pop();
      } else {
        await _profileNotifier.completeOnboarding(
          user.id,
          bodyType: _selectedBodyType,
        );
        if (mounted) context.go(AppConstants.routeWardrobe);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skip() async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _profileNotifier.completeOnboarding(user.id);
    if (mounted) context.go(AppConstants.routeWardrobe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.fromAccount
          ? AppBar(title: const Text('Body Type'))
          : null,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _step == _Step.welcome
              ? _WelcomeStep(
                  key: const ValueKey('welcome'),
                  onChooseBodyType: () =>
                      setState(() => _step = _Step.bodyType),
                  onUploadPhoto: _pickAndUploadPhoto,
                  onSkip: _skip,
                  saving: _saving,
                )
              : _BodyTypeStep(
                  key: const ValueKey('bodyType'),
                  selectedGender: _selectedGender,
                  selectedBodyType: _selectedBodyType,
                  saving: _saving,
                  fromAccount: widget.fromAccount,
                  onGenderChanged: (g) =>
                      setState(() {
                        _selectedGender = g;
                        _selectedBodyType = null;
                      }),
                  onBodyTypeSelected: (key) =>
                      setState(() => _selectedBodyType = key),
                  onConfirm: _saveBodyType,
                  onBack: widget.fromAccount
                      ? null
                      : () => setState(() => _step = _Step.welcome),
                  onSkip: widget.fromAccount ? null : _skip,
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome step
// ---------------------------------------------------------------------------

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    super.key,
    required this.onChooseBodyType,
    required this.onUploadPhoto,
    required this.onSkip,
    required this.saving,
  });

  final VoidCallback onChooseBodyType;
  final VoidCallback onUploadPhoto;
  final VoidCallback onSkip;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'How would you like to\npreview your outfits?',
            style: theme.textTheme.headlineMedium
                ?.copyWith(color: AppTheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We use this as a reference when generating\nyour outfit looks.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.outline),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _OptionCard(
            icon: Icons.person_outline,
            title: 'Use a photo of me',
            subtitle: 'Upload a photo from your gallery',
            onTap: saving ? null : onUploadPhoto,
          ),
          const SizedBox(height: 16),
          _OptionCard(
            icon: Icons.accessibility_new_outlined,
            title: 'Choose a body type',
            subtitle: 'Select a silhouette that matches your shape',
            onTap: saving ? null : onChooseBodyType,
          ),
          const Spacer(),
          if (saving)
            const Center(child: CircularProgressIndicator())
          else
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip for now'),
            ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.champagne,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.outline),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body type step
// ---------------------------------------------------------------------------

class _BodyTypeStep extends StatelessWidget {
  const _BodyTypeStep({
    super.key,
    required this.selectedGender,
    required this.selectedBodyType,
    required this.saving,
    required this.fromAccount,
    required this.onGenderChanged,
    required this.onBodyTypeSelected,
    required this.onConfirm,
    required this.onBack,
    required this.onSkip,
  });

  final String selectedGender;
  final String? selectedBodyType;
  final bool saving;
  final bool fromAccount;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<String> onBodyTypeSelected;
  final VoidCallback onConfirm;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final types =
        selectedGender == 'fem' ? _femTypes : _mascTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!fromAccount) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Choose your body type',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Gender toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _GenderToggle(
            selected: selectedGender,
            onChanged: onGenderChanged,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              itemCount: types.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, idx) {
                final t = types[idx];
                final selected = selectedBodyType == t.key;
                return _BodyTypeCard(
                  bodyType: t,
                  selected: selected,
                  onTap: () => onBodyTypeSelected(t.key),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (saving)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton(
                  onPressed: selectedBodyType != null ? onConfirm : null,
                  child: Text(fromAccount ? 'Save' : 'Continue'),
                ),
                if (onSkip != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSkip,
                    child: const Text('Skip for now'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderToggle extends StatelessWidget {
  const _GenderToggle({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.champagne,
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Feminine',
            active: selected == 'fem',
            onTap: () => onChanged('fem'),
          ),
          _ToggleOption(
            label: 'Masculine',
            active: selected == 'masc',
            onTap: () => onChanged('masc'),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.dustyRose : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppTheme.primary,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _BodyTypeCard extends StatelessWidget {
  const _BodyTypeCard({
    required this.bodyType,
    required this.selected,
    required this.onTap,
  });

  final _BodyType bodyType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppTheme.dustyRose.withValues(alpha: 0.15) : AppTheme.surface,
          border: Border.all(
            color: selected ? AppTheme.dustyRose : AppTheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/mannequins/${bodyType.key}.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => _PlaceholderShape(
                      gender: bodyType.gender,
                      selected: selected,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                bodyType.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppTheme.dustyRose : AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback shape rendered when the mannequin asset PNG is missing.
class _PlaceholderShape extends StatelessWidget {
  const _PlaceholderShape({required this.gender, required this.selected});

  final String gender;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        gender == 'fem'
            ? Icons.accessibility_new
            : Icons.accessibility,
        size: 56,
        color: selected ? AppTheme.dustyRose : AppTheme.outline,
      ),
    );
  }
}
