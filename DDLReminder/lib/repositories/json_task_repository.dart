import '../models/task.dart';
import '../services/storage_service.dart';
import 'task_repository.dart';

class JsonTaskRepository implements TaskRepository {
  JsonTaskRepository(this._storage);

  final StorageService _storage;

  @override
  Future<List<Task>> readTasks() => _storage.readTasks();

  @override
  Future<void> writeTasks(List<Task> tasks) => _storage.writeTasks(tasks);
}
