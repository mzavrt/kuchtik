import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:kuchtik/features/recipes/ui/view_models/recipes_view_model.dart';
import 'package:kuchtik/features/recipes/ui/recipe_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vítej, kuchtíku!')),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('Error loading recipes')),
        data: (recipes) {
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: recipes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 2,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85, // tweak for your card layout
            ),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                elevation: 4,             
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                ),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipeId: recipe.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:[
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: CachedNetworkImage(
              imageUrl: recipe.imageUrl,
              height: 100, 
              width: double.infinity,
              fit: BoxFit.cover, // Image fills the card width and maintains aspect ratio
              placeholder: (context, url) => Container(
                height: 100,
                color: Colors.grey.shade200, // light placeholder background
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 100,
                color: Colors.grey.shade100,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                    SizedBox(height: 8),
                    Text('Obrázek není dostupný', style: TextStyle(color: Colors.grey)),
                  ],
                        )
              ), ), ),
                        const SizedBox(height: 8),
                        Text(recipe.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const Spacer(),                     

                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}