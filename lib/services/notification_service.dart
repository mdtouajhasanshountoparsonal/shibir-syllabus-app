import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../core/constants/app_constants.dart';
import 'local_store.dart';

/// Wraps local notifications for the daily revision reminder.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyId = 1001;
  static const String _channelId = 'revision_reminder';
  static const String _channelName = 'রিভিশন রিমাইন্ডার';
  static const String _channelDesc = 'মুখস্থ রিভিশনের দৈনিক স্মরণিকা';

  final _plugin = FlutterLocalNotificationsPlugin();
  final LocalStore _store = LocalStore.instance;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission() ?? true;
    return granted;
  }

  bool get enabled =>
      _store.getSetting<bool>(PrefKeys.reminderEnabled, fallback: false) ??
      false;

  TimeOfDay get time {
    final hour = _store.getSetting<int>(PrefKeys.reminderHour, fallback: 20) ?? 20;
    final minute =
        _store.getSetting<int>(PrefKeys.reminderMinute, fallback: 0) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Enables the daily reminder at the given [time].
  Future<void> enable(TimeOfDay time) async {
    await _store.setSetting(PrefKeys.reminderEnabled, true);
    await _store.setSetting(PrefKeys.reminderHour, time.hour);
    await _store.setSetting(PrefKeys.reminderMinute, time.minute);
    await _schedule(time);
  }

  Future<void> disable() async {
    await _store.setSetting(PrefKeys.reminderEnabled, false);
    await _plugin.cancel(_dailyId);
  }

  Future<void> _schedule(TimeOfDay time) async {
    await _plugin.cancel(_dailyId);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      _dailyId,
      'আজকের রিভিশন বাকি',
      'মুখস্থ আইটেমগুলো রিভিশন করে স্মৃতিতে ধরে রাখো।',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
