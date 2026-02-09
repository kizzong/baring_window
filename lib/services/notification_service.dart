import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Android 13+ 알림 권한 요청
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// 고유 알림 ID 생성: 날짜 키 + 인덱스 기반
  static int generateId(String dayKey, int index) {
    return dayKey.hashCode.abs() % 100000 * 10 + index;
  }

  /// 예약 알림 스케줄
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String time,
    required int notifyBefore,
    required DateTime scheduledTime,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    // 과거 시간이면 스케줄하지 않음
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    final notifyLabel = notifyBefore >= 60
        ? '${notifyBefore ~/ 60}시간 전입니다.'
        : '$notifyBefore분 전입니다.';
    final body = '$time $title\n$notifyLabel';

    const androidDetails = AndroidNotificationDetails(
      'todo_reminder',
      '할 일 알림',
      channelDescription: '할 일 시간 전 알림',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      '할 일 알림',
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 알림 취소
  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

}
