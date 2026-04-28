import 'package:flutter/material.dart';

import 'package:kuchtik/app/ui/main_screen.dart';
import 'package:kuchtik/core/providers/supabase_client.dart';
import 'package:kuchtik/features/auth/presentation/login/login_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuchtík',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : const MainScreen(title: 'Test'),
    );
  }
}
