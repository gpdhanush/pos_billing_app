import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:line_icons/line_icons.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/features/backup/backup_screen.dart';
import 'package:pos_billing/features/billing/billing_screen.dart';
import 'package:pos_billing/features/billing/checkout_screen.dart';
import 'package:pos_billing/features/billing/order_checkout_screen.dart';
import 'package:pos_billing/features/billing/scanner_screen.dart';
import 'package:pos_billing/features/customers/customer_form_screen.dart';
import 'package:pos_billing/features/customers/customers_screen.dart';
import 'package:pos_billing/features/dashboard/dashboard_screen.dart';
import 'package:pos_billing/features/expenses/expense_form_screen.dart';
import 'package:pos_billing/features/expenses/expenses_screen.dart';
import 'package:pos_billing/features/inventory/inventory_screen.dart';
import 'package:pos_billing/features/more/more_screen.dart';
import 'package:pos_billing/features/onboarding/language_screen.dart';
import 'package:pos_billing/features/onboarding/onboarding_screen.dart';
import 'package:pos_billing/features/onboarding/permissions_screen.dart';
import 'package:pos_billing/features/onboarding/security_setup_screen.dart';
import 'package:pos_billing/features/onboarding/theme_screen.dart';
import 'package:pos_billing/features/printer/printer_screen.dart';
import 'package:pos_billing/features/products/categories_screen.dart';
import 'package:pos_billing/features/products/category_form_screen.dart';
import 'package:pos_billing/features/products/product_form_screen.dart';
import 'package:pos_billing/features/products/products_screen.dart';
import 'package:pos_billing/features/reports/reports_screen.dart';
import 'package:pos_billing/features/sales/invoice_detail_screen.dart';
import 'package:pos_billing/features/settings/settings_screen.dart';
import 'package:pos_billing/features/setup/store_setup_screen.dart';
import 'package:pos_billing/features/shell/app_shell.dart';
import 'package:pos_billing/features/splash/splash_screen.dart';

final _refresh = ValueNotifier(0);

final routerProvider = Provider<GoRouter>((ref) {
  ref.listen(appSettingsProvider, (_, _) => _refresh.value++);
  ref.listen(storeProfileProvider, (_, _) => _refresh.value++);
  ref.listen(unlockedProvider, (_, _) => _refresh.value++);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash' || loc == '/permissions') return null;
      final settings = ref.read(appSettingsProvider).valueOrNull;
      final store = ref.read(storeProfileProvider).valueOrNull;
      if (settings == null) return '/splash';
      if (!settings.onboardingComplete &&
          !loc.startsWith('/onboarding') &&
          !loc.startsWith('/setup')) {
        return '/onboarding';
      }
      if (settings.onboardingComplete &&
          store == null &&
          !loc.startsWith('/setup')) {
        return '/setup/language';
      }
      if (settings.onboardingComplete &&
          store != null &&
          !store.isSetupCompleted &&
          !loc.startsWith('/setup') &&
          loc != '/settings/store') {
        return '/setup/store';
      }
      final needsLock =
          settings.biometricEnabled && !ref.read(unlockedProvider);
      if (needsLock &&
          loc != '/lock' &&
          loc != '/setup/security' &&
          store != null &&
          store.isSetupCompleted) {
        return '/lock';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(
        path: '/permissions',
        builder: (c, s) => const PermissionsScreen(),
      ),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/setup/language',
        builder: (c, s) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/setup/theme',
        builder: (c, s) => const ThemePickerScreen(),
      ),
      GoRoute(
        path: '/setup/store',
        builder: (c, s) => const StoreSetupScreen(),
      ),
      GoRoute(
        path: '/setup/security',
        builder: (c, s) => const SecuritySetupScreen(),
      ),
      GoRoute(path: '/lock', builder: (c, s) => const PinLockScreen()),
      GoRoute(
        path: '/checkout',
        builder: (c, s) => const OrderCheckoutScreen(),
      ),
      GoRoute(path: '/payment', builder: (c, s) => const CheckoutScreen()),
      GoRoute(
        path: '/scan',
        builder: (c, s) {
          final purpose = ScanPurpose.values.firstWhere(
            (e) => e.name == (s.uri.queryParameters['purpose'] ?? 'addToCart'),
            orElse: () => ScanPurpose.addToCart,
          );
          return ScannerScreen(purpose: purpose);
        },
      ),
      GoRoute(path: '/products', builder: (c, s) => const ProductsScreen()),
      GoRoute(
        path: '/products/edit',
        builder: (c, s) {
          final id = int.tryParse(s.uri.queryParameters['id'] ?? '');
          final barcode = s.uri.queryParameters['barcode'];
          return ProductFormScreen(productId: id, initialBarcode: barcode);
        },
      ),
      GoRoute(
        path: '/categories',
        builder: (c, s) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/categories/edit',
        builder: (c, s) => CategoryFormScreen(
          categoryId: int.tryParse(s.uri.queryParameters['id'] ?? ''),
          initialName: s.uri.queryParameters['name'],
        ),
      ),
      GoRoute(path: '/customers', builder: (c, s) => const CustomersScreen()),
      GoRoute(
        path: '/customers/edit',
        builder: (c, s) => CustomerFormScreen(
          customerId: int.tryParse(s.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/sales/:id',
        builder: (c, s) =>
            InvoiceDetailScreen(invoiceId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/reports', builder: (c, s) => const ReportsScreen()),
      GoRoute(path: '/expenses', builder: (c, s) => const ExpensesScreen()),
      GoRoute(
        path: '/expenses/edit',
        builder: (c, s) => ExpenseFormScreen(
          expenseId: int.tryParse(s.uri.queryParameters['id'] ?? ''),
        ),
      ),
      GoRoute(path: '/printer', builder: (c, s) => const PrinterScreen()),
      GoRoute(path: '/backup', builder: (c, s) => const BackupScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
      GoRoute(
        path: '/settings/store',
        builder: (c, s) => const StoreSetupScreen(editing: true),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (c, s) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/sales', builder: (c, s) => const SalesScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/billing',
                builder: (c, s) => const BillingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stock',
                builder: (c, s) => const InventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (c, s) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

int navIndexFor(String location) {
  if (location.startsWith('/sales')) return 1;
  if (location.startsWith('/billing')) return 2;
  if (location.startsWith('/stock')) return 3;
  if (location.startsWith('/more')) return 4;
  return 0;
}

List<NavigationDestination> navDestinations(AppLocalizations l10n) => [
  NavigationDestination(
    icon: const Icon(LineIcons.home),
    selectedIcon: const Icon(LineIcons.home),
    label: l10n.navHome,
  ),
  NavigationDestination(
    icon: const Icon(LineIcons.history),
    selectedIcon: const Icon(LineIcons.history),
    label: 'History',
  ),
  NavigationDestination(
    icon: const Icon(LineIcons.cashRegister),
    selectedIcon: const Icon(LineIcons.cashRegister),
    label: l10n.navBilling,
  ),
  NavigationDestination(
    icon: const Icon(LineIcons.boxes),
    selectedIcon: const Icon(LineIcons.boxes),
    label: l10n.navStock,
  ),
  NavigationDestination(
    icon: const Icon(LineIcons.horizontalEllipsis),
    selectedIcon: const Icon(LineIcons.horizontalEllipsis),
    label: l10n.navMore,
  ),
];
