import 'package:flutter/material.dart';
import 'career_goal_screen.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final nameController = TextEditingController();
  final collegeController = TextEditingController();

  String year = "1st Year";
  String branch = "CSE";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text(
          "Step 1 of 4 👤",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0D1117),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tell us about yourself ✨",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "This helps Nova personalize your career roadmap.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),
            TextField(
              controller: collegeController,
              decoration: InputDecoration(
                labelText: "College",
                prefixIcon: const Icon(Icons.school),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Year of Study",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: year,
              isExpanded: true,
              items: [
                "1st Year",
                "2nd Year",
                "3rd Year",
                "4th Year"
              ]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => year = v!),
            ),
            const SizedBox(height: 20),
            const Text(
              "Branch",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: branch,
              isExpanded: true,
              items: ["CSE", "IT", "ECE", "AI/ML"]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => branch = v!),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Full name is required")),
                  );
                  return;
                }

                if (collegeController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("College name is required")),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareerGoalScreen(
                      fullName: nameController.text.trim(),
                      college: collegeController.text.trim(),
                      year: year,
                      branch: branch,
                    ),
                  ),
                );
              },
              child: const Text(
                "Continue ➜",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}