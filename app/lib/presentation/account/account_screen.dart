import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/di/service_locator.dart';
import '../../core/notifiers/user_profile_notifier.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/auth/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _authService = sl<AuthService>();
  final _profileNotifier = sl<UserProfileNotifier>();
  final _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (xfile == null || !mounted) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _uploading = true);
    try {
      final file = File(xfile.path);
      final ref = FirebaseStorage.instance
          .ref('users/${user.id}/profile.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set({'profilePhotoUrl': url}, SetOptions(merge: true));
      _profileNotifier.updateProfilePhoto(user.id, url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _profileNotifier,
      builder: (context, _) => StreamBuilder(
        stream: _authService.userStream,
        builder: (context, snapshot) {
          final user = snapshot.data;
          return Scaffold(
            appBar: AppBar(title: const Text('Account')),
            body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Stack(
                  children: [
                    _ProfileAvatar(
                      photoUrl: user?.photoUrl,
                      displayName: user?.displayName,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: _uploading ? null : _pickAndUploadPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: _uploading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (user?.displayName != null)
                Center(
                  child: Text(
                    user!.displayName!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              if (user?.email != null)
                Center(
                  child: Text(
                    user!.email!,
                    style: const TextStyle(color: AppTheme.outline),
                  ),
                ),
              const SizedBox(height: 40),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Change profile photo'),
                subtitle: const Text(
                    'Used as a reference in outfit generation'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickAndUploadPhoto,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.accessibility_new_outlined),
                title: const Text('Body type'),
                subtitle: Text(
                  _profileNotifier.bodyType != null
                      ? _bodyTypeLabel(_profileNotifier.bodyType!)
                      : 'Not set — tap to choose',
                  style: TextStyle(
                    color: _profileNotifier.bodyType != null
                        ? AppTheme.outline
                        : AppTheme.dustyRose,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  AppConstants.routeOnboarding,
                  extra: {'fromAccount': true},
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Sign out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _signOut,
              ),
            ],
          ),
        );
      },
    ),
  );
  }
}

String _bodyTypeLabel(String key) {
  const labels = {
    'F_Hourglass': 'Hourglass',
    'F_Pear_Triangle': 'Pear / Triangle',
    'F_Apple_Oval': 'Apple / Oval',
    'F_Rectangle_Athletic': 'Rectangle',
    'F_Inverted_Triangle': 'Inverted Triangle',
    'F_Petite_Slim': 'Petite / Slim',
    'M_Athletic_Mesomorph': 'Athletic',
    'M_Trapezoid': 'Trapezoid',
    'M_Rectangle_Average': 'Rectangle',
    'M_Oval_DadBod': 'Oval / Dad Bod',
    'M_Slim_Ectomorph': 'Slim',
    'M_Stocky_Endomorph': 'Stocky',
  };
  return labels[key] ?? key;
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.photoUrl, this.displayName});

  final String? photoUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 56,
      backgroundColor: AppTheme.champagne,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              (displayName?.isNotEmpty == true)
                  ? displayName![0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 36,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}
