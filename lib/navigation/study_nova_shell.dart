import 'package:flutter/material.dart';

import '../screens/course_maker/my_courses_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/labs/labs_home_screen.dart';
import '../screens/missions/my_missions_screen.dart';
import '../screens/study_from_photo/study_from_photo_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class StudyNovaShell extends StatefulWidget {
  const StudyNovaShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  static const List<_StudyNovaNavItem> _items = [
    _StudyNovaNavItem(
      title: 'Home',
      icon: Icons.home_rounded,
      selectedIcon: Icons.home,
      route: '/home',
    ),
    _StudyNovaNavItem(
      title: 'Labs',
      icon: Icons.science_rounded,
      selectedIcon: Icons.science,
      route: '/labs',
    ),
    _StudyNovaNavItem(
      title: 'My Courses',
      icon: Icons.library_books_rounded,
      selectedIcon: Icons.library_books,
      route: '/my-courses',
    ),
    _StudyNovaNavItem(
      title: 'Study Photo',
      icon: Icons.photo_camera_rounded,
      selectedIcon: Icons.photo_camera,
      route: '/study-from-photo',
    ),
    _StudyNovaNavItem(
      title: 'Mission Mode',
      icon: Icons.flag_rounded,
      selectedIcon: Icons.flag,
      route: '/missions',
    ),
  ];

  @override
  State<StudyNovaShell> createState() => _StudyNovaShellState();
}

class _StudyNovaShellState extends State<StudyNovaShell> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    final route = StudyNovaShell._items[index].route;
    if (route == ModalRoute.of(context)?.settings.name) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1100;
        final isMobile = constraints.maxWidth < 700;

        final pages = <Widget>[
          const HomeScreen(),
          const LabsHomeScreen(),
          const MyCoursesScreen(),
          const StudyFromPhotoScreen(),
          const MyMissionsScreen(),
        ];

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  _DesktopSidebar(
                    selectedIndex: _selectedIndex,
                    onSelect: _onDestinationSelected,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (!isMobile)
                        _TopHeader(
                          selectedIndex: _selectedIndex,
                          onActionTap: () =>
                              Navigator.of(context).pushNamed('/about'),
                        ),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: pages,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isMobile
              ? NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: StudyNovaShell._items
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.title,
                        ),
                      )
                      .toList(),
                )
              : null,
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.premiumGradient,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StudyNova',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Learning platform',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Navigation',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(StudyNovaShell._items.length, (index) {
              final item = StudyNovaShell._items[index];
              final isSelected = index == selectedIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Material(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                    title: Text(
                      item.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    selected: isSelected,
                    onTap: () => onSelect(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning mode',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Keep momentum with guided study sessions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.selectedIndex, required this.onActionTap});

  final int selectedIndex;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    final item = StudyNovaShell._items[selectedIndex];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'StudyNova dashboard',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onActionTap,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About Study Nova',
          ),
        ],
      ),
    );
  }
}

class _StudyNovaNavItem {
  const _StudyNovaNavItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}
