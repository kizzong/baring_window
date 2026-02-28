package com.baring

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.text.Spannable
import android.text.SpannableString
import android.text.SpannableStringBuilder
import android.text.style.AbsoluteSizeSpan
import android.text.style.ForegroundColorSpan
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import org.json.JSONArray

class TodoWidgetProvider : es.antonborri.home_widget.HomeWidgetProvider() {

    private val itemIds = intArrayOf(
        R.id.todo_item_0,
        R.id.todo_item_1,
        R.id.todo_item_2,
        R.id.todo_item_3,
        R.id.todo_item_4,
        R.id.todo_item_5,
        R.id.todo_item_6
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.todo_widget_layout).apply {
                val jsonStr = widgetData.getString("widget_items_json", "[]") ?: "[]"
                val count = widgetData.getInt("widget_items_count", 0)
                val total = widgetData.getInt("widget_items_total", 0)

                // 모든 아이템 숨기기
                for (id in itemIds) {
                    setViewVisibility(id, View.GONE)
                }
                setViewVisibility(R.id.todo_more_text, View.GONE)
                setViewVisibility(R.id.todo_empty_text, View.GONE)

                if (count == 0) {
                    setViewVisibility(R.id.todo_empty_text, View.VISIBLE)
                    setTextViewText(R.id.todo_count_text, "")
                } else {
                    setTextViewText(R.id.todo_count_text, "${count}/${total}")

                    try {
                        val items = JSONArray(jsonStr)
                        val maxSlots = itemIds.size // 7
                        val hasMore = items.length() > maxSlots
                        val showCount = if (hasMore) maxSlots - 1 else minOf(items.length(), maxSlots)

                        for (i in 0 until showCount) {
                            val item = items.getJSONObject(i)
                            val type = item.getString("type")
                            val title = item.getString("title")
                            val time = if (item.has("time")) item.getString("time") else null
                            val icon = "☐ "

                            val builder = SpannableStringBuilder("$icon $title")
                            if (type == "routine") {
                                builder.setSpan(
                                    ForegroundColorSpan(Color.parseColor("#34D399")),
                                    0, icon.length,
                                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                                )
                            }
                            if (time != null && time.isNotEmpty() && type == "todo") {
                                val padding = "      "
                                builder.append("\n$padding$time")
                                val timeStart = builder.length - time.length
                                builder.setSpan(
                                    AbsoluteSizeSpan(10, true),
                                    timeStart, builder.length,
                                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                                )
                                builder.setSpan(
                                    ForegroundColorSpan(Color.parseColor("#66FFFFFF")),
                                    timeStart, builder.length,
                                    Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                                )
                            }
                            setTextViewText(itemIds[i], builder)
                            setViewVisibility(itemIds[i], View.VISIBLE)

                            // 아이템별 클릭 → 백그라운드 콜백으로 완료 처리
                            val toggleUri = if (type == "routine") {
                                val routineId = item.optString("routineId", "")
                                Uri.parse("baringWidget://toggle?type=routine&routineId=$routineId")
                            } else {
                                val todoIndex = item.optInt("todoIndex", -1)
                                Uri.parse("baringWidget://toggle?type=todo&todoIndex=$todoIndex")
                            }
                            val toggleIntent = HomeWidgetBackgroundIntent.getBroadcast(
                                context, toggleUri
                            )
                            setOnClickPendingIntent(itemIds[i], toggleIntent)
                        }

                        if (hasMore) {
                            val remaining = items.length() - showCount
                            setTextViewText(R.id.todo_more_text, "... 외 ${remaining}개")
                            setViewVisibility(R.id.todo_more_text, View.VISIBLE)
                        }
                    } catch (e: Exception) {
                        // ignore
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
                setOnClickPendingIntent(R.id.todo_widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
