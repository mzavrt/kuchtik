import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';



class NotificationService {
 
  final _notificationsPlugin =
      FlutterLocalNotificationsPlugin();


  bool get _notificationsEnabled {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS;
}
  
  Future<void> init() async {
    
    if (!_notificationsEnabled) {
      return;
    }

    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings: initSettings);
  }

  /// Call this from your UI to prompt the user for permissions
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
    
      // This makes the "Allow app to send you notifications?" prompt appear
      await androidImplementation.requestNotificationsPermission();

     
      // This is needed for Android 12+ to allow scheduling exact alarms
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

 //Planning of notifications (called when user adds a new item with expiration date)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    
    if (!_notificationsEnabled) {
      return;
    }

    //If the scheduled time is in the past, we should not schedule the notification.
    if (scheduledTime.isBefore(DateTime.now())) {
      debugPrint('Ignoruji notifikaci do minulosti pro ID: $id');
      return;
    }

    
    final scheduledDate = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pantry_expiration_channel', 
          'Expirace surovin',          
          channelDescription: 'Upozorní tě, když se ti kazí jídlo v lednici.',
          importance: Importance.max, 
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      //Android 12+ requires this to allow scheduling exact alarms, otherwise the system may delay the notification to save battery.
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    
    );
  }

  /// When user deletes an item, we should also cancel its notification to avoid confusion.
  Future<void> cancelNotification(int id) async {
    if (!_notificationsEnabled) {
      return;
    }

    await _notificationsPlugin.cancel(id: id);
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Initialize this in main.dart');
});