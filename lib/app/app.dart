import 'package:flutter/material.dart';

import 'package:kuchtik/app/main_page.dart';
import 'package:kuchtik/core/data/supabase_client.dart';
import 'package:kuchtik/features/auth/presentation/login/login_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuchtík',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: supabase.auth.currentSession == null
          ? const LoginPage()
          : const MainPage(title: 'Test'),
    );
  }
}
