import 'package:supabase_flutter/supabase_flutter.dart';

class TaskProgressService {
  static final supabase = Supabase.instance.client;

  static Future<void> saveTask(
      String taskName,
      bool completed,
      ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      print("No logged-in user");
      return;
    }

    await supabase.from('user_task_progress').upsert({
      "user_id": user.id,
      "task_name": taskName,
      "is_completed": completed,
    });
  }

  static Future<List<String>> loadCompletedTasks() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      print("No user found while loading");
      return [];
    }

    final response = await supabase
        .from('user_task_progress')
        .select()
        .eq('user_id', user.id)
        .eq('is_completed', true);

    print("Supabase response: $response");

    return response
        .map<String>((task) => task['task_name'] as String)
        .toList();
  }
}