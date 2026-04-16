package com.example.ddl_reminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class DdlWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        appWidgetIds.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val PREFS_NAME = "ddl_widget_prefs"
        private const val KEY_HEADER = "header"
        private const val KEY_SLOGAN = "slogan"
        private const val KEY_EMPTY_TITLE = "empty_title"
        private const val KEY_EMPTY_SUBTITLE = "empty_subtitle"
        private const val KEY_TITLE_1 = "title_1"
        private const val KEY_SUBTITLE_1 = "subtitle_1"
        private const val KEY_TITLE_2 = "title_2"
        private const val KEY_SUBTITLE_2 = "subtitle_2"

        fun saveTasks(
            context: Context,
            headerTitle: String,
            slogan: String,
            emptyTitle: String,
            emptySubtitle: String,
            tasks: List<Map<String, String>>
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_HEADER, headerTitle)
                .putString(KEY_SLOGAN, slogan)
                .putString(KEY_EMPTY_TITLE, emptyTitle)
                .putString(KEY_EMPTY_SUBTITLE, emptySubtitle)
                .putString(KEY_TITLE_1, tasks.getOrNull(0)?.get("title").orEmpty())
                .putString(KEY_SUBTITLE_1, tasks.getOrNull(0)?.get("subtitle").orEmpty())
                .putString(KEY_TITLE_2, tasks.getOrNull(1)?.get("title").orEmpty())
                .putString(KEY_SUBTITLE_2, tasks.getOrNull(1)?.get("subtitle").orEmpty())
                .apply()

            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, DdlWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            ids.forEach { updateAppWidget(context, manager, it) }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val header = prefs.getString(KEY_HEADER, "DDL Reminder").orEmpty()
            val slogan = prefs.getString(KEY_SLOGAN, "").orEmpty()
            val emptyTitle = prefs.getString(KEY_EMPTY_TITLE, "No tasks").orEmpty()
            val emptySubtitle = prefs.getString(
                KEY_EMPTY_SUBTITLE,
                "Open the app to add tasks."
            ).orEmpty()
            val title1 = prefs.getString(KEY_TITLE_1, "").orEmpty()
            val subtitle1 = prefs.getString(KEY_SUBTITLE_1, "").orEmpty()
            val title2 = prefs.getString(KEY_TITLE_2, "").orEmpty()
            val subtitle2 = prefs.getString(KEY_SUBTITLE_2, "").orEmpty()

            val views = RemoteViews(context.packageName, R.layout.ddl_widget).apply {
                setTextViewText(R.id.widget_header, header)
                setTextViewText(R.id.widget_slogan, slogan)
                setViewVisibility(
                    R.id.widget_slogan,
                    if (slogan.isNotEmpty()) android.view.View.VISIBLE else android.view.View.GONE
                )
                setOnClickPendingIntent(R.id.widget_root, buildLaunchIntent(context))

                val hasFirst = title1.isNotEmpty()
                val hasSecond = title2.isNotEmpty()

                setViewVisibility(R.id.widget_empty_group, if (!hasFirst) android.view.View.VISIBLE else android.view.View.GONE)
                setViewVisibility(R.id.widget_task_one, if (hasFirst) android.view.View.VISIBLE else android.view.View.GONE)
                setViewVisibility(R.id.widget_task_two, if (hasSecond) android.view.View.VISIBLE else android.view.View.GONE)

                setTextViewText(R.id.widget_empty_title, emptyTitle)
                setTextViewText(R.id.widget_empty_subtitle, emptySubtitle)

                setTextViewText(R.id.widget_task_one_title, title1)
                setTextViewText(R.id.widget_task_one_subtitle, subtitle1)
                setTextViewText(R.id.widget_task_two_title, title2)
                setTextViewText(R.id.widget_task_two_subtitle, subtitle2)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun buildLaunchIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
