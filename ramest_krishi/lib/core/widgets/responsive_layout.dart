import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile Layout (Standard push navigation, no persistent rail)
        if (constraints.maxWidth < 800) {
          return child;
        }

        // Desktop / Web Admin Layout (Persistent Navigation Rail)
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: constraints.maxWidth > 1000,
                backgroundColor: Colors.grey.shade900,
                unselectedIconTheme: const IconThemeData(color: Colors.white70),
                unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
                selectedIconTheme: const IconThemeData(color: Colors.greenAccent),
                selectedLabelTextStyle: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('Billing / POS')),
                  NavigationRailDestination(icon: Icon(Icons.inventory), label: Text('Products')),
                  NavigationRailDestination(icon: Icon(Icons.people), label: Text('Customers')),
                  NavigationRailDestination(icon: Icon(Icons.local_shipping), label: Text('Suppliers')),
                  NavigationRailDestination(icon: Icon(Icons.analytics), label: Text('Reports')),
                  NavigationRailDestination(icon: Icon(Icons.badge), label: Text('Employees')),
                  NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
                ],
                selectedIndex: _calculateSelectedIndex(context),
                onDestinationSelected: (int index) {
                  switch (index) {
                    case 0: context.go('/'); break;
                    case 1: context.go('/billing'); break;
                    case 2: context.go('/inventory'); break;
                    case 3: context.go('/customers'); break;
                    case 4: context.go('/purchases'); break;
                    case 5: context.go('/reports'); break;
                    case 6: context.go('/employees'); break;
                    case 7: context.go('/settings'); break;
                  }
                },
              ),
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/billing')) return 1;
    if (location.startsWith('/inventory')) return 2;
    if (location.startsWith('/customer')) return 3;
    if (location.startsWith('/purchase')) return 4;
    if (location.startsWith('/report')) return 5;
    if (location.startsWith('/employee')) return 6;
    if (location.startsWith('/settings')) return 7;
    return 0; // Dashboard
  }
}
