package com.baring

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar

class MidnightWidgetUpdateReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        recalculateDDay(context)
        clearTodoWidget(context)
        notifyAllWidgets(context)
        scheduleMidnightAlarm(context)
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val REQUEST_CODE = 9999

        fun scheduleMidnightAlarm(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, MidnightWidgetUpdateReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
                    // 정확한 알람 권한이 없으면 비정확 알람 사용
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        midnight.timeInMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        midnight.timeInMillis,
                        pendingIntent
                    )
                }
            } catch (e: SecurityException) {
                // 권한 없을 때 비정확 알람으로 fallback
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    midnight.timeInMillis,
                    pendingIntent
                )
            }
        }

        private fun recalculateDDay(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val startDateStr = prefs.getString("start_date", null) ?: return
            val targetDateStr = prefs.getString("target_date", null) ?: return

            // start_date, target_date are in "yyyy/MM/dd" format
            val startParts = startDateStr.split("/")
            val targetParts = targetDateStr.split("/")
            if (startParts.size != 3 || targetParts.size != 3) return

            val startYear = startParts[0].toIntOrNull() ?: return
            val startMonth = startParts[1].toIntOrNull() ?: return
            val startDay = startParts[2].toIntOrNull() ?: return
            val targetYear = targetParts[0].toIntOrNull() ?: return
            val targetMonth = targetParts[1].toIntOrNull() ?: return
            val targetDay = targetParts[2].toIntOrNull() ?: return

            val today = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val startCal = Calendar.getInstance().apply {
                set(startYear, startMonth - 1, startDay, 0, 0, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val targetCal = Calendar.getInstance().apply {
                set(targetYear, targetMonth - 1, targetDay, 0, 0, 0)
                set(Calendar.MILLISECOND, 0)
            }

            val daysRemaining = ((targetCal.timeInMillis - today.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()

            val ddayText = when {
                daysRemaining > 0 -> "D-$daysRemaining"
                daysRemaining == 0 -> "D-DAY"
                else -> "완료"
            }

            val totalDays = ((targetCal.timeInMillis - startCal.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
            val passedDays = ((today.timeInMillis - startCal.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
            val percent = if (totalDays <= 0) {
                100
            } else {
                ((passedDays.toDouble() / totalDays) * 100).toInt().coerceIn(0, 100)
            }

            prefs.edit().apply {
                putString("dday_text", ddayText)
                putString("percent_text", "$percent%")
                putInt("progress", percent)
                apply()
            }
        }

        private fun clearTodoWidget(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString("widget_items_json", "[]")
                putInt("widget_items_count", 0)
                putInt("widget_items_total", 0)
                apply()
            }
        }

        private fun notifyAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)

            val homeIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, HomeWidgetProvider::class.java)
            )
            if (homeIds.isNotEmpty()) {
                val intent = Intent(context, HomeWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, homeIds)
                }
                context.sendBroadcast(intent)
            }

            val smallIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, SmallHomeWidgetProvider::class.java)
            )
            if (smallIds.isNotEmpty()) {
                val intent = Intent(context, SmallHomeWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, smallIds)
                }
                context.sendBroadcast(intent)
            }

            val todoIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TodoWidgetProvider::class.java)
            )
            if (todoIds.isNotEmpty()) {
                val intent = Intent(context, TodoWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, todoIds)
                }
                context.sendBroadcast(intent)
            }
        }
    }
}
