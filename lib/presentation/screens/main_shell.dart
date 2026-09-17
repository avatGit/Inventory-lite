import 'package:flutter/material.dart';

import 'package:inventory_lite/presentation/screens/home_screen.dart';
import 'package:inventory_lite/presentation/screens/catalog_screen.dart';
import 'package:inventory_lite/presentation/screens/add_movement_screen.dart';

/// The main shell of the app, hosting the bottom navigation bar.
///
/// It switches between the three main sections using an [IndexedStack],
/// which preserves the state of each screen when switching tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// Currently selected tab index.
  int _currentIndex = 0;

  /// The three screens managed by the bottom bar.
  /// Order: Dashboard, Catalog, Stock Movements.
  static const List<Widget> _screens = [
    HomeScreen(),
    CatalogScreen(),
    AddMovementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps all screens alive to preserve their state.
      body: IndexedStack(index: _currentIndex, children: _screens),

      // --- Material 3 Bottom Navigation Bar ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: const Color(0xFFFFFFFF),
        // Surface
        indicatorColor: const Color(0xFFDBEAFE),
        // Light Primary Blue
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_outlined),
            selectedIcon: Icon(Icons.swap_vert),
            label: 'Mouvements',
          ),
        ],
      ),
    );
  }
}
