import 'package:flutter/material.dart';
import 'ai_setup_screen.dart';

class CodingLinksScreen extends StatefulWidget {
  final String fullName;
  final String college;
  final String year;
  final String branch;
  final String careerGoal;

  const CodingLinksScreen({
    super.key,
    required this.fullName,
    required this.college,
    required this.year,
    required this.branch,
    required this.careerGoal,
  });

  @override
  State<CodingLinksScreen> createState() => _CodingLinksScreenState();
}

class _CodingLinksScreenState extends State<CodingLinksScreen> {
  final gfg = TextEditingController();
  final lc = TextEditingController();
  final github = TextEditingController();
  final linkedin = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text(
          "Step 3 of 4 🔗",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Connect Your Coding Universe 🌌",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Nova will analyze these profiles to detect weak topics, consistency and progress.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),
            TextField(
              controller: gfg,
              decoration: InputDecoration(
                labelText: "GFG Profile Link",
                prefixIcon: const Icon(Icons.code),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: lc,
              decoration: InputDecoration(
                labelText: "LeetCode Profile Link",
                prefixIcon: const Icon(Icons.bolt),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: github,
              decoration: InputDecoration(
                labelText: "GitHub Profile Link",
                prefixIcon: const Icon(Icons.storage),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: linkedin,
              decoration: InputDecoration(
                labelText: "LinkedIn Profile Link",
                prefixIcon: const Icon(Icons.business_center),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "🦊 Example AI Insight:\nYou solved 120 Array problems but only 8 Graph problems.",
                style: TextStyle(fontSize: 15),
              ),
            ),

            const SizedBox(height: 20),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiSetupScreen(
                      fullName: widget.fullName,
                      college: widget.college,
                      year: widget.year,
                      branch: widget.branch,
                      careerGoal: widget.careerGoal,
                      gfgLink: gfg.text.trim(),
                      leetcodeLink: lc.text.trim(),
                      githubLink: github.text.trim(),
                      linkedinLink: linkedin.text.trim(),
                    ),
                  ),
                );
              },
              child: const Text("Next ➜"),
            )
          ],
        ),
      ),
    );
  }
}