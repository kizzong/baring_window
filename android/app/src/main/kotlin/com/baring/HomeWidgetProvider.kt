package com.baring

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // 선택된 프리셋에 따라 배경 변경
                val selectedPreset = widgetData.getInt("selected_preset", 0)
                val backgroundResId = when (selectedPreset) {
                    0 -> R.drawable.widget_background_0
                    1 -> R.drawable.widget_background_1
                    2 -> R.drawable.widget_background_2
                    3 -> R.drawable.widget_background_3
                    4 -> R.drawable.widget_background_4
                    5 -> R.drawable.widget_background_5
                    6 -> R.drawable.widget_background_6
                    7 -> R.drawable.widget_background_7
                    8 -> R.drawable.widget_background_8
                    9 -> R.drawable.widget_background_9
                    else -> R.drawable.widget_background_0
                }
                
                setInt(R.id.widget_container, "setBackgroundResource", backgroundResId)
                
                // D-Day 텍스트
                val ddayText = widgetData.getString("dday_text", "D-0") ?: "D-0"
                setTextViewText(R.id.dday_text, ddayText)
                
                // 제목
                val titleText = widgetData.getString("title_text", "목표 설정") ?: "목표 설정"
                setTextViewText(R.id.title_text, titleText)
                
                // 퍼센트
                val percentText = widgetData.getString("percent_text", "0%") ?: "0%"
                setTextViewText(R.id.percent_text, percentText)
                
                // 프로그레스 바
                val progress = widgetData.getInt("progress", 0)
                setProgressBar(R.id.progress_bar, 100, progress, false)
                
                // 시작일
                val startDate = widgetData.getString("start_date", "2024/01/01") ?: "2024/01/01"
                setTextViewText(R.id.start_date_text, startDate)
                
                // 목표일
                val targetDate = widgetData.getString("target_date", "2024/12/31") ?: "2024/12/31"
                setTextViewText(R.id.target_date_text, targetDate)
                
                // 클릭 시 앱 열기 ⭐
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}