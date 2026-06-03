import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/notifiers/mass_capture_notifier.dart';
import '../../../core/services/background_removal_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth/auth_service.dart';

class MassCameraScreen extends StatefulWidget {
  const MassCameraScreen({super.key});

  @override
  State<MassCameraScreen> createState() => _MassCameraScreenState();
}

class _MassCameraScreenState extends State<MassCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _isTaking = false;
  String? _permissionError;

  final _bgRemoval = BackgroundRemovalService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _permissionError = 'No camera found on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = ctrl;
      _initFuture = ctrl.initialize().then((_) {
        if (mounted) setState(() {});
      });
    } on CameraException catch (e) {
      setState(() {
        _permissionError = e.code == 'cameraPermission'
            ? 'Camera permission is required. Please allow it in Settings.'
            : 'Could not open camera: ${e.description}';
      });
    }
  }

  Future<void> _takePhoto() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isTaking) return;

    setState(() => _isTaking = true);
    HapticFeedback.lightImpact();

    try {
      final xFile = await ctrl.takePicture();
      final file = File(xFile.path);

      final notifier = sl<MassCaptureNotifier>();
      final userId = sl<AuthService>().currentUser?.id ?? '';

      // Remove background first so the cleaned image is what gets uploaded.
      final bgRemovedFile = await _bgRemoval.removeBackground(file);

      await notifier.captureItem(
        userId: userId,
        imageFile: bgRemovedFile,
        backgroundRemovedFile: (f) => f,
      );
    } on CameraException catch (e) {
      debugPrint('[Camera] takePicture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture: ${e.description}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  void _onDone() {
    final sessionId = sl<MassCaptureNotifier>().captureSessionId;
    if (sessionId == null) {
      context.pop();
      return;
    }
    context.pushReplacement(
      AppConstants.routeMassReview,
      extra: {'sessionId': sessionId},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionError != null) {
      return _ErrorView(message: _permissionError!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _CameraPreviewLayer(
            initFuture: _initFuture,
            controller: _controller,
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _TopBar(
                count: ListenableBuilder(
                  listenable: sl<MassCaptureNotifier>(),
                  builder: (context, _) =>
                      Text('${sl<MassCaptureNotifier>().capturedCount} photos',
                          style: const TextStyle(color: Colors.white)),
                ),
                onClose: () => context.pop(),
              ),
            ),
          ),
          // Thumbnail strip + shutter + done
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _BottomBar(
                notifier: sl<MassCaptureNotifier>(),
                isTaking: _isTaking,
                onCapture: _takePhoto,
                onDone: _onDone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewLayer extends StatelessWidget {
  const _CameraPreviewLayer(
      {required this.initFuture, required this.controller});
  final Future<void>? initFuture;
  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    if (initFuture == null || controller == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    return FutureBuilder<void>(
      future: initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Camera error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white)),
            );
          }
          return CameraPreview(controller!);
        }
        return const Center(
            child: CircularProgressIndicator(color: Colors.white));
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.count, required this.onClose});
  final Widget count;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
          count,
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.notifier,
    required this.isTaking,
    required this.onCapture,
    required this.onDone,
  });
  final MassCaptureNotifier notifier;
  final bool isTaking;
  final VoidCallback onCapture;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notifier.thumbnails.isNotEmpty) ...[
                _ThumbnailStrip(thumbnails: notifier.thumbnails),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Done button
                  TextButton(
                    onPressed:
                        notifier.capturedCount > 0 ? onDone : null,
                    child: Text(
                      notifier.capturedCount > 0
                          ? 'Done (${notifier.capturedCount})'
                          : 'Done',
                      style: TextStyle(
                        color: notifier.capturedCount > 0
                            ? Colors.white
                            : Colors.white38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Shutter button
                  GestureDetector(
                    onTap: isTaking ? null : onCapture,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isTaking
                            ? AppTheme.outlineVariant
                            : Colors.white,
                        border: Border.all(
                          color: AppTheme.dustyRose,
                          width: 3,
                        ),
                      ),
                      child: isTaking
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 80), // balance with Done
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({required this.thumbnails});
  final List<File> thumbnails;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: thumbnails.length,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              thumbnails[i],
              width: 52,
              height: 60,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white54, size: 64),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go back',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
