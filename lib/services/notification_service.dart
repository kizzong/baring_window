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

  // ── 매일 반복 알림 (할일 알림) ──

  static const int _morningNotifId = 999901;
  static const int _eveningNotifId = 999902;

  /// 당일 할일 알림 예약 (사용자 지정 시간)
  static Future<void> scheduleDailyMorningNotification(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_todo_reminder',
      '할 일 일일 알림',
      channelDescription: '아침/저녁 할 일 알림',
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
      _morningNotifId,
      '오늘의 할 일',
      '오늘 할 일을 확인해보세요!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 다음날 할일 알림 예약 (사용자 지정 시간)
  static Future<void> scheduleDailyEveningNotification(int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_todo_reminder',
      '할 일 일일 알림',
      channelDescription: '아침/저녁 할 일 알림',
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
      _eveningNotifId,
      '내일의 할 일',
      '내일 할 일을 미리 확인해보세요!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 아침 알림 취소
  static Future<void> cancelMorningNotification() async {
    await _plugin.cancel(_morningNotifId);
  }

  /// 저녁 알림 취소
  static Future<void> cancelEveningNotification() async {
    await _plugin.cancel(_eveningNotifId);
  }

  // ── 루틴 반복 알림 ──

  /// 루틴 고유 알림 ID 생성
  static int generateRoutineId(String routineId) {
    return routineId.hashCode.abs() % 900000 + 100000;
  }

  /// 루틴용 반복 알림 스케줄
  static Future<void> scheduleRoutineNotification({
    required int id,
    required String title,
    required String time,
    required int notifyBefore,
    required String type,
    int? weekday,
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    ).subtract(Duration(minutes: notifyBefore));

    // 과거 시간이면 다음 날로
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // 특정 요일 루틴인 경우 해당 요일로 맞춤
    if (type == 'weekly' && weekday != null) {
      while (scheduled.weekday != weekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    final notifyLabel = notifyBefore >= 60
        ? '${notifyBefore ~/ 60}시간 전입니다.'
        : '$notifyBefore분 전입니다.';
    final body = '$time $title\n$notifyLabel';

    const androidDetails = AndroidNotificationDetails(
      'routine_reminder',
      '루틴 알림',
      channelDescription: '루틴 시간 전 알림',
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

    final matchComponents = type == 'weekly'
        ? DateTimeComponents.dayOfWeekAndTime
        : DateTimeComponents.time;

    await _plugin.zonedSchedule(
      id,
      '루틴 알림',
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 루틴 알림 취소
  static Future<void> cancelRoutineNotification(int id) async {
    await _plugin.cancel(id);
  }
}
