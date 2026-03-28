import 'package:flutter/material.dart';

import 'package:kuchtik/features/recipes/data/recipe_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecipeService _recipeService = RecipeService();

  @override
  Widget build(BuildContext context) {
    // TODO: Wire up recipes via a ViewModel (Riverpod later).
    // ignore: unused_local_variable
    final service = _recipeService;

    return Scaffold(
      appBar: AppBar(title: const Text('Vítej, kuchtíku!')),
      body: GridView.count(
        crossAxisCount: 2,
        children: const [],
      ),
    );
  }
}
