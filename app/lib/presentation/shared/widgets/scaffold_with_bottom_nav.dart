import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _ClosetBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _ClosetBottomNav extends StatelessWidget {
  const _ClosetBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.checkroom_outlined),
      activeIcon: Icon(Icons.checkroom),
      label: 'Closet',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.auto_awesome_outlined),
      activeIcon: Icon(Icons.auto_awesome),
      label: 'Suggest',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.favorite_border),
      activeIcon: Icon(Icons.favorite),
      label: 'Saved',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF36454F).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: _items,
      ),
    );
  }
}
