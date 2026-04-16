import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../repositories/task_repository.dart';

class TaskService extends ChangeNotifier {
  TaskService(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final TaskRepository _repository;
  final DateTime Function() _clock;
  List<Task> _tasks = const [];

  UnmodifiableListView<Task> get tasks => UnmodifiableListView(_tasks);

  Future<void> load() async {
    _tasks = await _repository.readTasks();
    _sort();
  }

  Future<void> add(Task task) async {
    _tasks = [..._tasks, task];
    _sort();
    await _persist();
  }

  Future<void> importMany(List<Task> incoming) async {
    final merged = {for (final task in _tasks) task.id: task};
    for (final task in incoming) {
      merged[task.id] = task;
    }
    _tasks = merged.values.toList(growable: false);
    _sort();
    await _persist();
  }

  Future<void> toggle(String taskId) async {
    _tasks = _tasks
        .map(
          (task) => task.id == taskId
              ? task.copyWith(completed: !task.completed)
              : task,
        )
        .toList(growable: false);
    _sort();
    await _persist();
  }

  Future<void> update(Task updated) async {
    _tasks = _tasks
        .map((task) => task.id == updated.id ? updated : task)
        .toList(growable: false);
    _sort();
    await _persist();
  }

  Future<void> remove(String taskId) async {
    _tasks = _tasks.where((task) => task.id != taskId).toList(growable: false);
    _sort();
    await _persist();
  }

  Future<void> refreshRecurring() async {
    _sort();
  }

  Future<void> _persist() => _repository.writeTasks(_tasks);

  void _sort() {
    final now = _clock();
    _tasks.sort((a, b) {
      final canUseCompletedOrder = !a.isRecurring && !b.isRecurring;
      if (canUseCompletedOrder && a.completed != b.completed) {
        return a.completed ? 1 : -1;
      }
      return a.nextDueDate(now).compareTo(b.nextDueDate(now));
    });
    notifyListeners();
  }
}
