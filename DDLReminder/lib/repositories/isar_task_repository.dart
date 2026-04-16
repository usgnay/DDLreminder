import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../database/app_database.dart';
import '../database/task_record.dart';
import '../models/task.dart';
import 'task_repository.dart';

class IsarTaskRepository implements TaskRepository {
  IsarTaskRepository(this._database);

  final AppDatabase _database;

  @override
  Future<List<Task>> readTasks() async {
    final query = _database.isar.taskRecords.where().anyId();
    final records = await QueryExecute<TaskRecord, TaskRecord>(query).findAll();
    return records
        .map(
          (record) => Task.fromJson(
            Map<String, dynamic>.from(jsonDecode(record.payloadJson) as Map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> writeTasks(List<Task> tasks) async {
    final isar = _database.isar;
    await isar.writeTxn(() async {
      await isar.taskRecords.clear();
      final records = tasks
          .map((task) {
            final record = TaskRecord()
              ..taskId = task.id
              ..payloadJson = jsonEncode(task.toJson());
            return record;
          })
          .toList(growable: false);
      await isar.taskRecords.putAll(records);
    });
  }
}
