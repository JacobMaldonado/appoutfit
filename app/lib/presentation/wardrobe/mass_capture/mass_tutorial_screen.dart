import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/notifiers/mass_capture_notifier.dart';
import '../../../core/theme/app_theme.dart';

class MassTutorialScreen extends StatefulWidget {
  const MassTutorialScreen({super.key});

  @override
  State<MassTutorialScreen> createState() => _MassTutorialScreenState();
}

class _MassTutorialScreenState extends State<MassTutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _steps = [
    _TutorialStep(
      icon: Icons.camera_alt_outlined,
      title: 'Tap to capture',
      description:
          'Point your camera at one clothing item at a time and tap the shutter. '
          'Keep the item flat on a surface or hang it for best results.',
      color: AppTheme.dustyRose,
    ),
    _TutorialStep(
      icon: Icons.auto_fix_high_outlined,
      title: 'Auto-classify',
      description:
          'Each photo is processed automatically. Clo·set removes the background '
          'and identifies the garment type, color, and pattern using AI.',
      color: AppTheme.champagne,
    ),
    _TutorialStep(
      icon: Icons.checklist_outlined,
      title: 'Review & confirm',
      description:
          'When you\'re done shooting, review the detected details for each item. '
          'Edit anything that doesn\'t look right, then add them all at once.',
      color: AppTheme.primaryContainer,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStart() {
    sl<MassCaptureNotifier>().startSession();
    context.push(AppConstants.routeMassCamera);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Mass Upload'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _steps.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, i) => _TutorialPage(step: _steps[i]),
            ),
          ),
          _PageIndicator(current: _currentPage, count: _steps.length),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: _currentPage < _steps.length - 1
                  ? OutlinedButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Next'),
                    )
                  : FilledButton(
                      onPressed: _onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.dustyRose,
                        foregroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Start Capturing',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  const _TutorialPage({required this.step});
  final _TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedIcon(icon: step.icon, color: step.color),
          const SizedBox(height: 40),
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryContainer,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AnimatedIcon extends StatefulWidget {
  const _AnimatedIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(widget.icon, size: 64, color: widget.color),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.current, required this.count});
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppTheme.dustyRose : AppTheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String description;
  final Color color;
}
