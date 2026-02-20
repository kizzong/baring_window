import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:baring_windows/theme/app_colors.dart';
import '../services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  Box baringBox = Hive.box("baring");

  bool morningTodoAlert = false;
  bool eveningTodoAlert = false;
  TimeOfDay morningTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay eveningTime = const TimeOfDay(hour: 21, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      morningTodoAlert =
          baringBox.get("morningTodoAlert", defaultValue: false);
      eveningTodoAlert =
          baringBox.get("eveningTodoAlert", defaultValue: false);
      morningTime = TimeOfDay(
        hour: baringBox.get("morningTimeHour", defaultValue: 8),
        minute: baringBox.get("morningTimeMinute", defaultValue: 0),
      );
      eveningTime = TimeOfDay(
        hour: baringBox.get("eveningTimeHour", defaultValue: 21),
        minute: baringBox.get("eveningTimeMinute", defaultValue: 0),
      );
    });
  }

  String _formatTime(TimeOfDay t) {
    final period = t.hour < 12 ? '오전' : '오후';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$period $h:$m';
  }

  Future<TimeOfDay?> _pickNotificationTime(TimeOfDay initial) async {
    final c = context.colors;
    TimeOfDay selected = initial;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: c.scaffoldBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.textPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: c.textPrimary.withOpacity(0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '알림 시간 설정',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Text(
                        '완료',
                        style: TextStyle(
                          color: c.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: c.brightness,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: c.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: false,
                    initialDateTime: DateTime(
                      2000, 1, 1, initial.hour, initial.minute,
                    ),
                    onDateTimeChanged: (dt) {
                      selected =
                          TimeOfDay(hour: dt.hour, minute: dt.minute);
                    },
                  ),
                ),
              ),
              SizedBox(
                  height: MediaQuery.of(ctx).padding.bottom + 16),
            ],
          ),
        );
      },
    );

    if (confirmed == true) return selected;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.scaffoldBg,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: c.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '할일 알림',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CardBox(
                child: Column(
                  children: [
                    // 아침 할일 알림
                    _SwitchRow(
                      title: '아침 할일 알림',
                      desc:
                          '매일 ${_formatTime(morningTime)}에 오늘의 할 일을 알려줘요.',
                      value: morningTodoAlert,
                      onChanged: (v) async {
                        if (v) {
                          final picked =
                              await _pickNotificationTime(morningTime);
                          if (picked == null) return;
                          setState(() {
                            morningTodoAlert = true;
                            morningTime = picked;
                          });
                          baringBox.put("morningTodoAlert", true);
                          baringBox.put("morningTimeHour", picked.hour);
                          baringBox.put(
                              "morningTimeMinute", picked.minute);
                          NotificationService
                              .refreshDailyNotifications();
                        } else {
                          setState(() => morningTodoAlert = false);
                          baringBox.put("morningTodoAlert", false);
                          NotificationService
                              .cancelMorningNotification();
                        }
                      },
                    ),
                    if (morningTodoAlert) ...[
                      const SizedBox(height: 6),
                      _TimeChip(
                        time: _formatTime(morningTime),
                        primary: c.primary,
                        onTap: () async {
                          final picked =
                              await _pickNotificationTime(morningTime);
                          if (picked == null) return;
                          setState(() => morningTime = picked);
                          baringBox.put(
                              "morningTimeHour", picked.hour);
                          baringBox.put(
                              "morningTimeMinute", picked.minute);
                          NotificationService
                              .refreshDailyNotifications();
                        },
                      ),
                    ],
                    const SizedBox(height: 6),
                    // 저녁 할일 알림
                    _SwitchRow(
                      title: '저녁 할일 알림',
                      desc:
                          '매일 ${_formatTime(eveningTime)}에 내일의 할 일을 알려줘요.',
                      value: eveningTodoAlert,
                      onChanged: (v) async {
                        if (v) {
                          final picked =
                              await _pickNotificationTime(eveningTime);
                          if (picked == null) return;
                          setState(() {
                            eveningTodoAlert = true;
                            eveningTime = picked;
                          });
                          baringBox.put("eveningTodoAlert", true);
                          baringBox.put("eveningTimeHour", picked.hour);
                          baringBox.put(
                              "eveningTimeMinute", picked.minute);
                          NotificationService
                              .refreshDailyNotifications();
                        } else {
                          setState(() => eveningTodoAlert = false);
                          baringBox.put("eveningTodoAlert", false);
                          NotificationService
                              .cancelEveningNotification();
                        }
                      },
                    ),
                    if (eveningTodoAlert) ...[
                      const SizedBox(height: 6),
                      _TimeChip(
                        time: _formatTime(eveningTime),
                        primary: c.primary,
                        onTap: () async {
                          final picked =
                              await _pickNotificationTime(eveningTime);
                          if (picked == null) return;
                          setState(() => eveningTime = picked);
                          baringBox.put(
                              "eveningTimeHour", picked.hour);
                          baringBox.put(
                              "eveningTimeMinute", picked.minute);
                          NotificationService
                              .refreshDailyNotifications();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBox extends StatelessWidget {
  final Widget child;
  const _CardBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.borderColor),
      ),
      child: child,
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String desc;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.desc,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.textPrimary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.textPrimary.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    color: c.subtle,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: c.primary,
            inactiveThumbColor: c.textPrimary.withOpacity(0.9),
            inactiveTrackColor: c.textPrimary.withOpacity(0.20),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final Color primary;
  final VoidCallback onTap;

  const _TimeChip({
    required this.time,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time_rounded, color: primary, size: 18),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit_rounded,
              color: primary.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
