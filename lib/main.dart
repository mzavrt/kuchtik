import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kuchtik/pages/fridge_page.dart';
import 'package:kuchtik/pages/login_page.dart';


void main() async {

  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_PROJECT_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuchtík',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: supabase.auth.currentSession == null
      ? const LoginPage()
      : const MainPage(title: "Test"),
    );
  }
}

class MainPage extends StatefulWidget {

  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  int _selectedIndex = 1;

  final List<Widget> _pages = [
    const FridgePage(),
    const Center(child: Text('Home Page')),
    const Center(child: Text('My Recipes Page')),
  ];


  @override
  Widget build(BuildContext build) {
    return Scaffold(
      appBar: AppBar( backgroundColor: Theme.of(context).colorScheme.primary,
		                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      title: const Text('Kuchtik')),
      body: _pages[_selectedIndex],
        
      
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.kitchen),
              onPressed: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.book),
              onPressed: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
}
