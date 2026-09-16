import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/data/models/menu_item_model.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final role = ref.watch(currentUserRoleProvider);
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final menuItems = _getMenuItems(role);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        user?.resident?.fullName
                                .substring(0, 1)
                                .toUpperCase() ??
                            'A',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.resident?.fullName ?? 'Warga',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (user?.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user?.phone ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                  if (user?.roles.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: user!.roles.map<Widget>((r) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            r.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  final isActive = _isActive(item.route, currentRoute);
                  return _DrawerItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: isActive,
                    onTap: () {
                      Navigator.pop(context);
                      if (!isActive) context.push(item.route);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isActive(String route, String current) {
    if (route == '/dashboard') return current == '/dashboard';
    return current == route || current.startsWith('$route/');
  }

  List<MenuItemModel> _getMenuItems(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return MenuConfig.rt;
      case UserRole.bendahara:
        return MenuConfig.bendahara;
      case UserRole.warga:
      case UserRole.unknown:
        return MenuConfig.warga;
    }
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final defaultColor = AppColors.dark.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? activeColor : defaultColor,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeColor : AppColors.dark,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        onTap: onTap,
      ),
    );
  }
}
