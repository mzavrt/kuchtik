import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/ui/fridge_screen.dart';
import 'package:kuchtik/core/services/notification_service.dart';
import 'package:kuchtik/features/dashboard/ui/dashboard_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const FridgeScreen(),
    const DashboardScreen(),
    const Center(child: Text('My Recipes Page')),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Text(widget.title),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
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
            label: 'Moje recepty',
          ),
        ],
      ),
    );
  }
}
