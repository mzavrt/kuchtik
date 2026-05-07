import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/ui/pantry_screen.dart';
import 'package:kuchtik/core/services/notification_service.dart';
import 'package:kuchtik/features/dashboard/ui/dashboard_screen.dart';
import 'package:kuchtik/features/recipes/ui/favorite_recipes_screen.dart';
import 'package:kuchtik/features/pantry/ui/widgets/pantry_app_bar_menu.dart';

enum MainScreenTab {
  pantry,
  dashboard,
  favorites,
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = MainScreenTab.dashboard.index;

  MainScreenTab get _selectedTab => MainScreenTab.values[_selectedIndex];

  void _openPantryTab() {
    setState(() {
      _selectedIndex = MainScreenTab.pantry.index;
    });
  }

  List<Widget> get _pages => [
        const PantryScreen(),
        DashboardScreen(
          onOpenPantry: _openPantryTab,
        ),
        const FavoriteRecipesScreen(),
      ];

  String _titleForTab(MainScreenTab tab) {
    switch (tab) {
      case MainScreenTab.pantry:
        return 'Moje zásoby';
      case MainScreenTab.dashboard:
        return 'Vítej, kuchtíku!';
      case MainScreenTab.favorites:
        return 'Oblíbené';
    }
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = _selectedTab;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(_titleForTab(selectedTab)),
        actions: [
          if (selectedTab == MainScreenTab.pantry) const PantryAppBarMenu(),
        ],
      ),
      body: _pages[selectedTab.index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab.index,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.kitchen_outlined),
            selectedIcon: Icon(Icons.kitchen),
            label: 'Moje zásoby',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Domů',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Oblíbené',
          ),
        ],
      ),
    );
  }
}