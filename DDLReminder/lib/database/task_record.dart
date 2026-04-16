import 'package:isar_community/isar.dart';

part 'task_record.g.dart';

@collection
class TaskRecord {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String taskId;

  late String payloadJson;
}
