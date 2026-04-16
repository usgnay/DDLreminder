import '../models/task.dart';

abstract class TaskRepository {
  Future<List<Task>> readTasks();
  Future<void> writeTasks(List<Task> tasks);
}
