import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kuchtik/main.dart';
import 'package:kuchtik/models/photo_ingredient.dart';
import 'package:kuchtik/screens/fridge_screen/image_result_screen.dart';

class AddIngredientWidget extends StatelessWidget {
  const AddIngredientWidget({super.key});

  Future<List<PhotoIngredient>> _pickImage(String imageType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (pickedFile == null) return [];

    final bytes = await pickedFile.readAsBytes();
    final imageBase64 = base64Encode(bytes);

    final mimeType =
        pickedFile.mimeType ??
        (pickedFile.path.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg');

    final session = supabase.auth.currentSession;
    print(session?.accessToken);

    //matched ingrdients list from edge function
    final supabaseResult = await supabase.functions.invoke(
      'send-image',
      body: {
        'imageBase64': imageBase64,
        'imageType': imageType,
        'mimeType': mimeType,
      },
    );

    final ingredientsData = supabaseResult.data['ingredients'] as List<dynamic>;

    return ingredientsData
        .map((e) => PhotoIngredient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How you wanna add an item?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Add manually')));
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manually'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final rootNav = Navigator.of(context, rootNavigator: true);

                final results = await _pickImage('receipt'); // or 'groceries'
                if (!context.mounted) return;

                // optional: close the bottom sheet first
                Navigator.of(context).pop();

                rootNav.push(
                  MaterialPageRoute(
                    builder: (_) => ImageResultsScreen(ingredientsFromImage: results),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Scan'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final rootNav = Navigator.of(context, rootNavigator: true);

                final results = await _pickImage('groceries');
                if (!context.mounted) return;

                // optional: close the bottom sheet first
                Navigator.of(context).pop();

                rootNav.push(
                  MaterialPageRoute(
                    builder: (_) => ImageResultsScreen(ingredientsFromImage: results),
                  ),
                );
              },
              icon: const Icon(Icons.camera),
              label: const Text('Photo'),
            ),
          ],
        ),
        SizedBox(height: 38),
      ],
    );
  }
}
