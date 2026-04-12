export 'app/ui/app.dart' show MyApp;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kuchtik/app/ui/app.dart';
import 'package:kuchtik/core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: '.env');

  //supabase initialization
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_PROJECT_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  //init notification service
  final notificationService = NotificationService();
  await notificationService.init();


  runApp(ProviderScope(overrides: [
    notificationServiceProvider.overrideWithValue(notificationService),
      ],child: MyApp()));
}

