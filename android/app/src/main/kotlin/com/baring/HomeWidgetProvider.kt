package com.baring

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_layout)

                // 배경 설정
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
                views.setInt(R.id.widget_container, "setBackgroundResource", backgroundResId)

                // all_goals_json 파싱
                val allGoalsJson = widgetData.getString("all_goals_json", "[]") ?: "[]"
                val goalsList = try {
                    val jsonArray = JSONArray(allGoalsJson)
                    (0 until minOf(jsonArray.length(), 3)).map { i ->
                        val obj = jsonArray.getJSONObject(i)
                        mapOf(
                            "title" to obj.optString("title", "목표"),
                            "dday_text" to obj.optString("dday_text", "D-0"),
                            "percent" to obj.optInt("percent", 0)
                        )
                    }
                } catch (e: Exception) {
                    emptyList()
                }

                // 헤더 (날짜 + 날씨) - 항상 표시
                views.setViewVisibility(R.id.header_container, View.VISIBLE)

                // 날짜와 날씨 데이터 설정
                val dateText = widgetData.getString("date_text", "") ?: ""
                val weatherText = widgetData.getString("weather_text", "") ?: ""

                if (dateText.isNotEmpty()) {
                    views.setTextViewText(R.id.date_text, dateText)
                }
                if (weatherText.isNotEmpty()) {
                    views.setTextViewText(R.id.weather_text, weatherText)
                }

                // 목표 개수에 따라 표시
                when {
                    goalsList.isEmpty() -> {
                        // 기본값 (하위 호환성) - 큰 스타일
                        views.setViewVisibility(R.id.single_goal_container, View.VISIBLE)
                        views.setViewVisibility(R.id.goal_1_container, View.GONE)
                        views.setViewVisibility(R.id.goal_2_container, View.GONE)
                        views.setViewVisibility(R.id.goal_3_container, View.GONE)

                        val titleText = widgetData.getString("title_text", "목표") ?: "목표"
                        val ddayText = widgetData.getString("dday_text", "D-0") ?: "D-0"
                        val percentText = widgetData.getString("percent_text", "0%") ?: "0%"
                        val progress = widgetData.getInt("progress", 0)
                        val startDate = widgetData.getString("start_date", "2024/01/01") ?: "2024/01/01"
                        val targetDate = widgetData.getString("target_date", "2024/12/31") ?: "2024/12/31"

                        views.setTextViewText(R.id.title_text, titleText)
                        views.setTextViewText(R.id.dday_text, ddayText)
                        views.setTextViewText(R.id.percent_text, percentText)
                        views.setProgressBar(R.id.progress_bar, 100, progress, false)
                        views.setTextViewText(R.id.start_date_text, startDate)
                        views.setTextViewText(R.id.target_date_text, targetDate)
                    }
                    goalsList.size == 1 -> {
                        // 1개만 표시 - 큰 스타일 (기존 위젯)
                        views.setViewVisibility(R.id.single_goal_container, View.VISIBLE)
                        views.setViewVisibility(R.id.goal_1_container, View.GONE)
                        views.setViewVisibility(R.id.goal_2_container, View.GONE)
                        views.setViewVisibility(R.id.goal_3_container, View.GONE)

                        val goal = goalsList[0]
                        views.setTextViewText(R.id.title_text, goal["title"] as? String ?: "목표")
                        views.setTextViewText(R.id.dday_text, goal["dday_text"] as? String ?: "D-0")
                        val percent = goal["percent"] as? Int ?: 0
                        views.setTextViewText(R.id.percent_text, "$percent%")
                        views.setProgressBar(R.id.progress_bar, 100, percent, false)
                        views.setTextViewText(R.id.start_date_text, goal["start_date"] as? String ?: "2024/01/01")
                        views.setTextViewText(R.id.target_date_text, goal["target_date"] as? String ?: "2024/12/31")
                    }
                    goalsList.size == 2 -> {
                        // 2개 표시 - 간결한 스타일
                        views.setViewVisibility(R.id.single_goal_container, View.GONE)
                        views.setViewVisibility(R.id.goal_1_container, View.VISIBLE)
                        views.setViewVisibility(R.id.goal_2_container, View.VISIBLE)
                        views.setViewVisibility(R.id.goal_3_container, View.GONE)

                        // 첫 번째 목표
                        val goal1 = goalsList[0]
                        views.setTextViewText(R.id.title_text_1, goal1["title"] as? String ?: "목표 1")
                        views.setTextViewText(R.id.dday_text_1, goal1["dday_text"] as? String ?: "D-0")
                        val percent1 = goal1["percent"] as? Int ?: 0
                        views.setTextViewText(R.id.percent_text_1, "$percent1%")
                        views.setProgressBar(R.id.progress_bar_1, 100, percent1, false)

                        // 두 번째 목표
                        val goal2 = goalsList[1]
                        views.setTextViewText(R.id.title_text_2, goal2["title"] as? String ?: "목표 2")
                        views.setTextViewText(R.id.dday_text_2, goal2["dday_text"] as? String ?: "D-0")
                        val percent2 = goal2["percent"] as? Int ?: 0
                        views.setTextViewText(R.id.percent_text_2, "$percent2%")
                        views.setProgressBar(R.id.progress_bar_2, 100, percent2, false)
                    }
                    else -> {
                        // 3개 표시 - 간결한 스타일
                        views.setViewVisibility(R.id.single_goal_container, View.GONE)
                        views.setViewVisibility(R.id.goal_1_container, View.VISIBLE)
                        views.setViewVisibility(R.id.goal_2_container, View.VISIBLE)
                        views.setViewVisibility(R.id.goal_3_container, View.VISIBLE)

                        // 첫 번째 목표
                        val goal1 = goalsList[0]
                        views.setTextViewText(R.id.title_text_1, goal1["title"] as? String ?: "목표 1")
                        views.setTextViewText(R.id.dday_text_1, goal1["dday_text"] as? String ?: "D-0")
                        val percent1 = goal1["percent"] as? Int ?: 0
                        views.setTextViewText(R.id.percent_text_1, "$percent1%")
                        views.setProgressBar(R.id.progress_bar_1, 100, percent1, false)

                        // 두 번째 목표
                        val goal2 = goalsList[1]
                        views.setTextViewText(R.id.title_text_2, goal2["title"] as? String ?: "목표 2")
                        views.setTextViewText(R.id.dday_text_2, goal2["dday_text"] as? String ?: "D-0")
                        val percent2 = goal2["percent"] as? Int ?: 0
                        views.setTextViewText(R.id.percent_text_2, "$percent2%")
                        views.setProgressBar(R.id.progress_bar_2, 100, percent2, false)

                        // 세 번째 목표
                        val goal3 = goalsList[2]
                        views.setTextViewText(R.id.title_text_3, goal3["title"] as? String ?: "목표 3")
                        views.setTextViewText(R.id.dday_text_3, goal3["dday_text"] as? String ?: "D-0")
                        val percent3 = goal3["percent"] as? Int ?: 0
                        views.setTextViewText(R.id.percent_text_3, "$percent3%")
                        views.setProgressBar(R.id.progress_bar_3, 100, percent3, false)
                    }
                }

                // 클릭 시 앱 열기
                val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                appWidgetManager.updateAppWidget(widgetId, views)

            } catch (e: Exception) {
                android.util.Log.e("HomeWidgetProvider", "Widget error: ${e.message}", e)
            }
        }
    }
}
