import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _tabs = [
    (path: '/home', icon: Icons.home_rounded, label: 'Home'),
    (path: '/workouts', icon: Icons.fitness_center_rounded, label: 'Workouts'),
    (path: '/nutrition', icon: Icons.restaurant_rounded, label: 'Nutrition'),
    (path: '/community', icon: Icons.group_rounded, label: 'Community'),
    (path: '/profile', icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _onTap(int i) {
    context.go(_tabs[i].path);
  }

  @override
  Widget build(BuildContext context) {
    // Determine selected tab based on current route
    final String location =
        GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    final int selectedIndex =
        _tabs.indexWhere((t) => location.startsWith(t.path));
    final int effectiveIndex = selectedIndex >= 0 ? selectedIndex : 0;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.bgSurface, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.asMap().entries.map((e) {
                final i = e.key;
                final t = e.value;
                final selected = effectiveIndex == i;
                return GestureDetector(
                  onTap: () => _onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 16 : 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected ? AppColors.primaryGradient : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          t.icon,
                          size: 22,
                          color:
                              selected ? AppColors.bgDark : AppColors.textMuted,
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          Text(
                            t.label,
                            style: const TextStyle(
                              color: AppColors.bgDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
