package com.baring

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            // 재부팅 후 자정 알람 재등록
            MidnightWidgetUpdateReceiver.scheduleMidnightAlarm(context)

            // 꺼져있는 동안 날짜가 변경되었을 수 있으므로 즉시 D-Day 재계산
            val recalcIntent = Intent(context, MidnightWidgetUpdateReceiver::class.java)
            context.sendBroadcast(recalcIntent)
        }
    }
}
