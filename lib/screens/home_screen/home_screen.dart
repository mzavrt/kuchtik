import 'package:flutter/material.dart';

imort 'package:kuchtik/services/recipe_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});



  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  var receipesBasedOnIngredients = 


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vítej, kuchtíku!')),
      body: GridView.count(
        crossAxisCount: 2,
        children: [

         ])
    );
  }
}