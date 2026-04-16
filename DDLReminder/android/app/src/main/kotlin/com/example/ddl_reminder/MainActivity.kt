package com.example.ddl_reminder

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "ddlreminder/mobile_widget"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncTasks" -> {
                    val headerTitle = call.argument<String>("headerTitle").orEmpty()
                    val slogan = call.argument<String>("slogan").orEmpty()
                    val emptyTitle = call.argument<String>("emptyTitle").orEmpty()
                    val emptySubtitle = call.argument<String>("emptySubtitle").orEmpty()
                    val tasks = mutableListOf<Map<String, String>>()
                    val rawTasks = call.argument<List<Map<String, Any?>>>("tasks").orEmpty()
                    rawTasks.forEach { task ->
                        tasks.add(
                            mapOf(
                                "title" to (task["title"]?.toString() ?: ""),
                                "subtitle" to (task["subtitle"]?.toString() ?: "")
                            )
                        )
                    }
                    DdlWidgetProvider.saveTasks(
                        context = applicationContext,
                        headerTitle = headerTitle,
                        slogan = slogan,
                        emptyTitle = emptyTitle,
                        emptySubtitle = emptySubtitle,
                        tasks = tasks
                    )
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}
