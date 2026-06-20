import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ai_service.dart';
import '../../models/user_progress.dart';
import '../../services/task_progress_service.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  Map<String, dynamic>? roadmap;
  Map<String, dynamic>? profile;
  bool loading = true;
  String? loadError;
  Set<String> completedTasks = {};

  UserProgress progress = UserProgress(
    xp: 0,
    streak: 1,
  );

  @override
  void initState() {
    super.initState();
    initializeScreen();
  }

  Future<void> initializeScreen() async {
    await _loadProfile();
    await loadRoadmap();
    await loadCompletedTasks();
  }

  Future<void> _loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data =
      await supabase.from('profiles').select().eq('id', user.id).single();
      setState(() => profile = data);
    } catch (e) {
      print("PROFILE LOAD ERROR (roadmap): $e");
    }
  }

  Future<void> loadCompletedTasks() async {
    final tasks = await TaskProgressService.loadCompletedTasks();
    print("Loaded tasks from Supabase: $tasks");
    setState(() {
      completedTasks = tasks.toSet();
      progress.xp = completedTasks.length * 50;
    });
  }

  void toggleTask(String task) async {
    bool completed = false;

    setState(() {
      if (completedTasks.contains(task)) {
        completedTasks.remove(task);
        progress.xp -= 50;
        completed = false;
      } else {
        completedTasks.add(task);
        progress.xp += 50;
        completed = true;
      }
    });

    print("Saving task: $task -> $completed");
    await TaskProgressService.saveTask(task, completed);
  }

  Future<void> loadRoadmap({bool forceRegenerate = false}) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        loading = false;
        loadError = "Not signed in";
      });
      return;
    }

    try {
      // 1. Try cached roadmap first, unless forced to regenerate.
      if (!forceRegenerate) {
        final cached = await supabase
            .from('roadmap_cache')
            .select('roadmap_json')
            .eq('user_id', userId)
            .maybeSingle();

        if (cached != null) {
          setState(() {
            roadmap = cached['roadmap_json'];
            loading = false;
          });
          return;
        }
      }

      // 2. No cache (or forced) — build dynamic inputs from real profile data.
      if (profile == null) {
        setState(() {
          loading = false;
          loadError = "Profile not loaded yet";
        });
        return;
      }

      final leetcodeLink = (profile?['leetcode_link'] ?? '').toString();
      List<String> weakTopics = [];
      List<String> strongTopics = [];

      // 3. Pull real weak/strong topics from LeetCode if it's linked.
      if (leetcodeLink.isNotEmpty) {
        final platformData = await AIService.fetchPlatformData(
          leetcode: leetcodeLink,
        );
        final leetcode = platformData['leetcode'] as Map<String, dynamic>?;
        if (leetcode != null && leetcode['available'] == true) {
          weakTopics = List<String>.from(leetcode['weak_topics'] ?? []);
          strongTopics = List<String>.from(leetcode['strong_topics'] ?? []);
        }
      }

      // 4. No source yet for skills/projects — empty until profile collects them.
      final skills = <String>[];
      final projects = <String>[];

      final result = await AIService.generateRoadmap({
        "full_name": profile?['full_name'] ?? "Student",
        "goal": profile?['goal'] ?? "Software Engineer",
        "dream_company": profile?['dream_company'] ?? "Top Tech Company",
        "study_hours": profile?['study_hours'] ?? 2,
        "branch": profile?['branch'] ?? "",
        "year": profile?['year'] ?? "",
        "skills": skills,
        "projects": projects,
        "weak_topics": weakTopics,
        "strong_topics": strongTopics,
      });

      if (result.containsKey('error')) {
        print("API error: ${result['error']}");
        setState(() {
          roadmap = null;
          loading = false;
          loadError = result['error'].toString();
        });
        return;
      }

      // 5. Cache it so the same roadmap persists across logout/login.
      await supabase.from('roadmap_cache').upsert({
        'user_id': userId,
        'roadmap_json': result,
      });

      setState(() {
        roadmap = result;
        loading = false;
      });
    } catch (e, stack) {
      print("ROADMAP ERROR: $e");
      print(stack);
      setState(() {
        loading = false;
        loadError = e.toString();
      });
    }
  }

  Widget roadmapCard(String title, String focus, List tasks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            focus,
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ...tasks.map(
                (task) => CheckboxListTile(
              value: completedTasks.contains(task),
              onChanged: (_) => toggleTask(task),
              title: Text(
                task,
                style: TextStyle(
                  color: Colors.white,
                  decoration: completedTasks.contains(task)
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              activeColor: Colors.blue,
              checkColor: Colors.white,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget listCard(String title, List items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                "• $item",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget statsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Level ${progress.level} • ${progress.xp} XP",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (progress.xp % 500) / 500,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 12),
          Text(
            "🔥 ${progress.streak} Day Streak",
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget xpInfoButton() {
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("How XP Works"),
            content: const Text(
              "Complete 1 roadmap task = +50 XP\n"
                  "Uncheck task = -50 XP\n"
                  "Study 1 hour = +20 XP (future feature)\n"
                  "Daily routine complete = +30 XP\n"
                  "7-day streak bonus = +500 XP",
            ),
          ),
        );
      },
      icon: const Icon(Icons.info),
      label: const Text("How XP Works?"),
    );
  }

  Widget regenerateButton() {
    return TextButton.icon(
      onPressed: () {
        setState(() => loading = true);
        loadRoadmap(forceRegenerate: true);
      },
      icon: const Icon(Icons.refresh, color: Colors.white70),
      label: const Text(
        "Regenerate Roadmap",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (roadmap == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Center(
          child: Text(
            loadError ?? "Failed to load roadmap",
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Your AI Roadmap 🚀"),
        backgroundColor: const Color(0xFF161B22),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            statsCard(),
            xpInfoButton(),
            regenerateButton(),
            const SizedBox(height: 20),
            roadmapCard(
              roadmap!["day_30"]["title"],
              roadmap!["day_30"]["focus"],
              roadmap!["day_30"]["tasks"],
            ),
            roadmapCard(
              roadmap!["day_60"]["title"],
              roadmap!["day_60"]["focus"],
              roadmap!["day_60"]["tasks"],
            ),
            roadmapCard(
              roadmap!["day_90"]["title"],
              roadmap!["day_90"]["focus"],
              roadmap!["day_90"]["tasks"],
            ),
            listCard("🔥 Daily Routine", roadmap!["daily_routine"]),
            listCard("📚 Must Know Topics", roadmap!["must_know_topics"]),
            listCard("🎯 Resources", roadmap!["resources"]),
          ],
        ),
      ),
    );
  }
}