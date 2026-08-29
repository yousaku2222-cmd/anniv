package com.annivapp.anniv

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Home-screen widget backing view. Data is pushed from Flutter via the
 * `home_widget` plugin (see AppHomeWidgetService); this class just renders
 * whatever keys are currently stored.
 */
class AnnivWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.anniv_widget).apply {
                val empty = widgetData.getBoolean("anniv_empty", true)
                val title = widgetData.getString("anniv_title", null) ?: "記念日を追加"
                val count = widgetData.getString("anniv_count", null) ?: "—"
                val unit = widgetData.getString("anniv_unit", null) ?: ""
                val caption = widgetData.getString("anniv_caption", null) ?: ""

                setTextViewText(R.id.anniv_widget_title, title)
                setTextViewText(R.id.anniv_widget_count, if (empty) "—" else count + unit)
                setTextViewText(R.id.anniv_widget_caption, caption)

                setOnClickPendingIntent(
                    R.id.anniv_widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
