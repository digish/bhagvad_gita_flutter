package org.komal.bhagvadgeeta

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class DailyShlokaWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val shlokaText = widgetData.getString("shloka_text", "Open App to see Daily Shloka")
                val translation = widgetData.getString("translation", "")
                val footer = widgetData.getString("chapter_shloka", "")
                
                setTextViewText(R.id.widget_shloka_text, shlokaText)
                setTextViewText(R.id.widget_translation, translation)
                setTextViewText(R.id.widget_footer, footer)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
