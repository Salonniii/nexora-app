import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final supabase = Supabase.instance.client;

  Future<void> saveProfile({
    required String fullName,
    required String college,
    required String year,
    required String branch,
    required String goal,
    required String dreamCompany,
    required int studyHours,
    required String coachMode,
    required String gfgLink,
    required String leetcodeLink,
    required String githubLink,
    required String linkedinLink,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await supabase.from('profiles').upsert({
      'id': user.id,
      'full_name': fullName,
      'college': college,
      'year': year,
      'branch': branch,
      'goal': goal,
      'dream_company': dreamCompany,
      'study_hours': studyHours,
      'coach_mode': coachMode,
      'gfg_link': gfgLink,
      'leetcode_link': leetcodeLink,
      'github_link': githubLink,
      'linkedin_link': linkedinLink,
    });
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await supabase
        .from('profiles')
        .update(data)
        .eq('id', user.id);
  }
}