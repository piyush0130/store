import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pin_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/inventory/presentation/screens/product_list_screen.dart';
import '../../features/inventory/presentation/screens/add_edit_product_screen.dart';
import '../../features/inventory/presentation/screens/scanner_screen.dart';
import '../../features/customers/presentation/screens/customer_list_screen.dart';
import '../../features/customers/presentation/screens/add_edit_customer_screen.dart';
import '../../features/customers/presentation/screens/customer_detail_screen.dart';
import '../../features/customers/domain/entities/customer_entity.dart';
import '../../features/billing/presentation/screens/pos_screen.dart';
import '../../features/purchases/presentation/screens/supplier_list_screen.dart';
import '../../features/purchases/presentation/screens/purchase_entry_screen.dart';
import '../../features/reports/presentation/screens/reports_hub_screen.dart';
import '../../features/reports/presentation/screens/report_detail_screen.dart';
import '../../features/admin/presentation/screens/employee_list_screen.dart';
import '../../features/admin/presentation/screens/settings_screen.dart';
import '../widgets/responsive_layout.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref.read(authProvider.notifier).stream),
    redirect: (context, state) {
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToPin = state.matchedLocation == '/pin' || state.matchedLocation == '/pin_setup';

      if (authState.status == AuthStatus.initial) {
        return '/'; // Splash
      }

      if (authState.status == AuthStatus.unauthenticated && !isGoingToLogin) {
        return '/login';
      }

      if (authState.status == AuthStatus.locked && !isGoingToPin) {
        return '/pin';
      }

      if (authState.status == AuthStatus.authenticated) {
        if (isGoingToLogin || state.matchedLocation == '/pin') {
          // RBAC logic here
          if (authState.user?.isCashier == true) {
            return '/billing';
          }
          return '/dashboard';
        }
      }

      return null;
    },
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/pin',
        builder: (context, state) => const PinScreen(isSetupMode: false),
      ),
      GoRoute(
        path: '/pin_setup',
        builder: (context, state) => const PinScreen(isSetupMode: true),
      ),
      ShellRoute(
        builder: (context, state, child) => ResponsiveLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/billing',
            builder: (context, state) => const PosScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const ProductListScreen(),
          ),
          GoRoute(
            path: '/product/add',
            builder: (context, state) => const AddEditProductScreen(),
          ),
          GoRoute(
            path: '/customers',
            builder: (context, state) => const CustomerListScreen(),
          ),
          GoRoute(
            path: '/customer/add',
            builder: (context, state) {
              final customer = state.extra as CustomerEntity?;
              return AddEditCustomerScreen(customer: customer);
            },
          ),
          GoRoute(
            path: '/customer/detail',
            builder: (context, state) {
              final customer = state.extra as CustomerEntity;
              return CustomerDetailScreen(customer: customer);
            },
          ),
          GoRoute(
            path: '/purchases',
            builder: (context, state) => const SupplierListScreen(),
          ),
          GoRoute(
            path: '/purchase/entry',
            builder: (context, state) => const PurchaseEntryScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsHubScreen(),
          ),
          GoRoute(
            path: '/reports/detail',
            builder: (context, state) => const ReportDetailScreen(),
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeeListScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const ScannerScreen(),
          ),
        ],
      ),
  );
});

// Helper class to convert StateNotifier stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
