import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/features/pantry/ui/image_results_page.dart';

import 'package:image_picker/image_picker.dart';

class AddIngredientWidget extends ConsumerWidget {
  const AddIngredientWidget({super.key});


  Future<XFile?> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return pickedFile;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }     
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'How you wanna add an item?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
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
                // Let user take photo of receipt
                final pickedFile = await _pickImage();

                if (pickedFile == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No image selected')),
                  );
                  return;
                }

                if (!context.mounted) return;
                Navigator.of(context).pop(); // close the bottom sheet

                // Navigate immediately; results page shows loading while scanning.
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageResultsScreen(
                      imageType: 'receipt',
                      imageFile: pickedFile,
                    ),
                  ),
                );
                    },
              icon: const Icon(Icons.receipt_long),
              label: const Text('Scan'),
            ),
            ElevatedButton.icon(
              onPressed: ()
                  async  {
                // Let user take photo of the groceries they want to add
                final pickedFile = await _pickImage();

                if (pickedFile == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No image selected')),
                  );
                  return;
                }

                if (!context.mounted) return;
                Navigator.of(context).pop(); // close the bottom sheet

                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ImageResultsScreen(
                      imageType: 'photo',
                      imageFile: pickedFile,
                    ),
                  ),
                );
                  },
              icon: const Icon(Icons.camera),
              label: const Text('Photo'),
            ),
          ],
        ),
        const SizedBox(height: 38),
      ],
    );
  }
}
