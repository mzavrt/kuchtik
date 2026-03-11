import 'package:flutter/material.dart';
import 'package:kuchtik/pages/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {

  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.env['PROJECT_URL']!,
    anonKey: dotenv.env['ANON_KEY']!,
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.green),
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
    const Center(child: Text('My Fridge Page')),
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
