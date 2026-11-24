import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermissions();
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });
  Future<void> scheduleOneTimeMedicationReminder({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  });
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  });
  Future<void> cancelReminder(int id);
  Future<void> cancelAllReminders();
}

class NotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  NotificationServiceImpl({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationServiceImpl.initialize error: $e');
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosImpl != null) {
        final result = await iosImpl.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return result ?? false;
      }

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final notifGranted = await androidImpl.requestNotificationsPermission() ?? false;
        try {
          await androidImpl.requestExactAlarmsPermission();
        } catch (_) {
          // Thiết bị Android < 12 hoặc bị hạn chế bởi OEM: sẽ fallback sang inexactAllowWhileIdle khi đặt lịch
        }
        return notifGranted;
      }

      return true;
    } catch (e) {
      debugPrint('NotificationServiceImpl.requestPermissions error: $e');
      return false;
    }
  }

  NotificationDetails _buildMedicationNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      'so_tay_y_te_medication_reminders',
      'Lịch Uống Thuốc & Nhắc Nhở Y Tế',
      channelDescription: 'Thông báo đổ chuông nhắc uống thuốc theo cữ trong ngày',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  @override
  Future<void> scheduleDailyMedicationReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _buildMedicationNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } on PlatformException {
      // Fallback sang inexactAllowWhileIdle trên Android 12-14+ nếu người dùng chưa bật quyền Exact Alarm
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: _buildMedicationNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (fallbackErr) {
        debugPrint('NotificationServiceImpl inexact fallback error: $fallbackErr');
      }
    } catch (e) {
      debugPrint('NotificationServiceImpl.scheduleDailyMedicationReminder error: $e');
    }
  }

  @override
  Future<void> scheduleOneTimeMedicationReminder({
    required int id,
    required String title,
    required String body,
    required Duration delay,
  }) async {
    await initialize();
    final scheduledDate = tz.TZDateTime.now(tz.local).add(delay);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _buildMedicationNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on PlatformException {
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: _buildMedicationNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('NotificationServiceImpl.scheduleOneTimeMedicationReminder error: $e');
    }
  }

  @override
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _buildMedicationNotificationDetails(),
      );
    } catch (e) {
      debugPrint('NotificationServiceImpl.showInstantNotification error: $e');
    }
  }

  @override
  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }
}
