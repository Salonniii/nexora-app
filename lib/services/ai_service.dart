import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AIService {
  static String get baseUrl {
    return "https://nexora-backend-h8xr.onrender.com";
  }

  // ==================== EXISTING ENDPOINTS ====================

  static Future<Map<String, dynamic>> analyzeProfile(
      Map<String, dynamic> profile) async {
    final response = await http.post(
      Uri.parse("$baseUrl/analyze-profile"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": profile['full_name'] ?? "",
        "college": profile['college'] ?? "",
        "goal": profile['goal'] ?? "",
        "github": profile['github_link'] ?? "",
        "linkedin": profile['linkedin_link'] ?? "",
        "gfg": profile['gfg_link'] ?? "",
        "leetcode": profile['leetcode_link'] ?? "",
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Backend failed");
    }
  }

  static Future<Map<String, dynamic>> generateRoadmap(
      Map<String, dynamic> data) async {
    print("Calling roadmap API...");

    final response = await http.post(
      Uri.parse("$baseUrl/generate-roadmap"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "full_name": data["full_name"],
        "goal": data["goal"],
        "dream_company": data["dream_company"],
        "study_hours": data["study_hours"],
        "branch": data["branch"],
        "year": data["year"],
        "skills": data["skills"],
        "projects": data["projects"],
        "weak_topics": data["weak_topics"],
        "strong_topics": data["strong_topics"],
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Roadmap generation failed");
    }
  }

  // ==================== NEW SMART ENDPOINTS ====================

  /// Fetch REAL data from GitHub, LeetCode, GFG
  static Future<Map<String, dynamic>> fetchPlatformData({
    String? github,
    String? leetcode,
    String? gfg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/fetch-platform-data"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "github": github ?? "",
          "leetcode": leetcode ?? "",
          "gfg": gfg ?? "",
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Failed to fetch platform data"};
      }
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  /// Smart analyze — fetches REAL platform data then AI analyzes it
  /// This is the main powerful function
  static Future<Map<String, dynamic>> smartAnalyze({
    required String fullName,
    String? college,
    String? goal,
    String? dreamCompany,
    String? github,
    String? leetcode,
    String? gfg,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/smart-analyze"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName,
          "college": college ?? "",
          "goal": goal ?? "",
          "dream_company": dreamCompany ?? "",
          "github": github ?? "",
          "leetcode": leetcode ?? "",
          "gfg": gfg ?? "",
        }),
      ).timeout(const Duration(seconds: 60)); // longer timeout for real fetching

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {"error": "Smart analysis failed: ${response.statusCode}"};
      }
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  // ==================== LOCAL INSIGHT (offline fallback) ====================

  static Map<String, dynamic> generateInsight(Map<String, dynamic> profile) {
    int score = 40;
    final List<String> strengths = [];
    final List<String> weaknesses = [];
    final List<String> recommendations = [];

    if ((profile['gfg_link'] ?? '').toString().isNotEmpty) {
      score += 10;
      strengths.add('Active on GeeksForGeeks');
    } else {
      weaknesses.add('No GFG profile linked');
      recommendations.add('Create a GFG profile and start solving problems');
    }

    if ((profile['leetcode_link'] ?? '').toString().isNotEmpty) {
      score += 10;
      strengths.add('LeetCode profile present');
    } else {
      weaknesses.add('No LeetCode profile linked');
      recommendations.add('Start LeetCode — even 2 problems/day matters');
    }

    if ((profile['github_link'] ?? '').toString().isNotEmpty) {
      score += 15;
      strengths.add('GitHub profile connected');
    } else {
      weaknesses.add('GitHub not linked');
      recommendations.add('Push projects to GitHub to show recruiters real work');
    }

    if ((profile['linkedin_link'] ?? '').toString().isNotEmpty) {
      score += 15;
      strengths.add('LinkedIn presence established');
    } else {
      weaknesses.add('LinkedIn missing');
      recommendations.add('Build your LinkedIn — many recruiters find candidates there');
    }

    final studyHours = (profile['study_hours'] ?? 0);
    final hoursInt = studyHours is int ? studyHours : int.tryParse(studyHours.toString()) ?? 0;
    if (hoursInt >= 4) {
      score += 10;
      strengths.add('Strong study discipline (${hoursInt}h/day)');
    } else {
      weaknesses.add('Low daily study hours');
      recommendations.add('Aim for at least 4 hours of focused prep daily');
    }

    if (score > 100) score = 100;

    return {
      'readinessScore': score,
      'readinessLevel': score >= 75 ? 'High' : score >= 50 ? 'Medium' : 'Low',
      'strengths': strengths,
      'weaknesses': weaknesses,
      'recommendations': recommendations,
    };
  }

  static Future<String> chatWithNova({
    required String message,
    String? fullName,
    String? goal,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/chat-with-nova"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": message,
        "full_name": fullName ?? "",
        "goal": goal ?? "",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["reply"] ?? "No response";
    } else {
      return "Nova is unavailable right now.";
    }
  }
}