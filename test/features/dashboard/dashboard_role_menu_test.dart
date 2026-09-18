import 'package:flutter_test/flutter_test.dart';
import 'package:astina/features/auth/providers/auth_provider.dart';
import 'package:astina/features/dashboard/data/models/menu_item_model.dart';

void main() {
  List<MenuItemModel> getMenusForRole(UserRole role) {
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

  group('Dashboard role menu access', () {
    group('warga menu access', () {
      test('warga does not have access to user administration', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/users'), false);
      });

      test('warga does not have access to residents admin', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/residents'), false);
      });

      test('warga does not have access to households admin', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/households'), false);
      });

      test('warga does not have access to inventory', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/inventory'), false);
      });

      test(
        'warga does not have access to payment verification (bendahara)',
        () {
          final menus = getMenusForRole(UserRole.warga);
          final routes = menus.map((m) => m.route).toList();

          expect(routes.contains('/finance/payments/pending'), false);
        },
      );

      test('warga has access to complaints', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/complaints'), true);
      });

      test('warga has access to letters', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/letters'), true);
      });

      test('warga has access to finance/iuran', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/finance'), true);
      });

      test('warga has access to activities', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/activities'), true);
      });

      test('warga has access to dashboard', () {
        final menus = getMenusForRole(UserRole.warga);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/dashboard'), true);
      });
    });

    group('RT menu access', () {
      test('RT has access to user administration', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/users'), true);
      });

      test('RT has access to residents admin', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/residents'), true);
      });

      test('RT has access to households admin', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/households'), true);
      });

      test('RT has access to inventory', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/inventory'), true);
      });

      test('RT does not have access to bendahara payment verification', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/finance/payments/pending'), false);
      });

      test('RT has access to activities', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/activities'), true);
      });

      test('RT has access to finance', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/finance'), true);
      });

      test('RT has access to dashboard', () {
        final menus = getMenusForRole(UserRole.rt);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/dashboard'), true);
      });
    });

    group('bendahara menu access', () {
      test('bendahara has access to payment verification', () {
        final menus = getMenusForRole(UserRole.bendahara);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/finance/payments/pending'), true);
      });

      test('bendahara has access to finance/kas', () {
        final menus = getMenusForRole(UserRole.bendahara);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/finance'), true);
      });

      test('bendahara does not have access to user administration', () {
        final menus = getMenusForRole(UserRole.bendahara);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/users'), false);
      });

      test('bendahara does not have access to residents admin', () {
        final menus = getMenusForRole(UserRole.bendahara);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/residents'), false);
      });

      test('bendahara does not have access to households admin', () {
        final menus = getMenusForRole(UserRole.bendahara);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/households'), false);
      });

      test('bendahara does not have access to inventory', () {
        final menus = getMenusForRole(UserRole.bendahara);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/inventory'), false);
      });

      test('bendahara has access to dashboard', () {
        final menus = getMenusForRole(UserRole.bendahara);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/dashboard'), true);
      });
    });

    group('unknown role fallback', () {
      test('unknown role falls back to warga menus', () {
        final wargaMenus = getMenusForRole(UserRole.warga);
        final unknownMenus = getMenusForRole(UserRole.unknown);

        expect(unknownMenus.length, wargaMenus.length);
      });

      test('unknown role does not have access to admin menus', () {
        final menus = getMenusForRole(UserRole.unknown);
        final routes = menus.map((m) => m.route).toList();

        expect(routes.contains('/users'), false);
        expect(routes.contains('/residents'), false);
        expect(routes.contains('/households'), false);
        expect(routes.contains('/inventory'), false);
      });
    });

    group('menu item uniqueness', () {
      test('RT menu has no duplicate routes', () {
        final routes = MenuConfig.rt.map((m) => m.route).toList();
        expect(routes.toSet().length, routes.length);
      });

      test('warga menu has no duplicate routes', () {
        final routes = MenuConfig.warga.map((m) => m.route).toList();
        expect(routes.toSet().length, routes.length);
      });

      test('bendahara menu has no duplicate routes', () {
        final routes = MenuConfig.bendahara.map((m) => m.route).toList();
        expect(routes.toSet().length, routes.length);
      });
    });

    group('common shared menus', () {
      test('dashboard is available for all roles', () {
        expect(MenuConfig.rt.any((m) => m.route == '/dashboard'), true);
        expect(MenuConfig.warga.any((m) => m.route == '/dashboard'), true);
        expect(MenuConfig.bendahara.any((m) => m.route == '/dashboard'), true);
      });

      test('SOS is available for all roles', () {
        expect(MenuConfig.rt.any((m) => m.route == '/sos'), true);
        expect(MenuConfig.warga.any((m) => m.route == '/sos'), true);
        expect(MenuConfig.bendahara.any((m) => m.route == '/sos'), true);
      });

      test('notifications is available for all roles', () {
        expect(MenuConfig.rt.any((m) => m.route == '/notifications'), true);
        expect(MenuConfig.warga.any((m) => m.route == '/notifications'), true);
        expect(
          MenuConfig.bendahara.any((m) => m.route == '/notifications'),
          true,
        );
      });

      test('profile is available for all roles', () {
        expect(MenuConfig.rt.any((m) => m.route == '/profile'), true);
        expect(MenuConfig.warga.any((m) => m.route == '/profile'), true);
        expect(MenuConfig.bendahara.any((m) => m.route == '/profile'), true);
      });
    });
  });
}
