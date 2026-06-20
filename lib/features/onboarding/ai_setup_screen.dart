import 'package:flutter/material.dart';
import '../../services/profile_service.dart';

import '../navigation/main_navigation_screen.dart';

class AiSetupScreen extends StatefulWidget {
  final String fullName;
  final String college;
  final String year;
  final String branch;
  final String careerGoal;
  final String gfgLink;
  final String leetcodeLink;
  final String githubLink;
  final String linkedinLink;

  const AiSetupScreen({
    super.key,
    required this.fullName,
    required this.college,
    required this.year,
    required this.branch,
    required this.careerGoal,
    required this.gfgLink,
    required this.leetcodeLink,
    required this.githubLink,
    required this.linkedinLink,
  });

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  final companyController = TextEditingController();
  final hoursController = TextEditingController();

  String coachMode = "Balanced";
  final ProfileService profileService = ProfileService();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text(
          "Step 4 of 4 🤖",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Train Nova AI Coach 🦊",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Help Nova understand your goals and coaching preference.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),
          TextField(
            controller: companyController,
            decoration: InputDecoration(
              labelText: "Dream Company",
              prefixIcon: const Icon(Icons.business),
              filled: true,
              fillColor: const Color(0xFF161B22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
            const SizedBox(height: 20),
          TextField(
            controller: hoursController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Daily Study Hours",
              prefixIcon: const Icon(Icons.schedule),
              filled: true,
              fillColor: const Color(0xFF161B22),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
            const SizedBox(height: 20),
            const Text(
              "Coach Mode",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),
            DropdownButton<String>(
              value: coachMode,
              isExpanded: true,
              items: ["Strict", "Balanced", "Chill"]
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
                  .toList(),
              onChanged: (v) => setState(() => coachMode = v!),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                "Strict 😤 → Pushes hard daily\nBalanced ⚖️ → Smart realistic goals\nChill 😌 → Light pressure coaching",
                style: TextStyle(fontSize: 15),
              ),
            ),
            const Spacer(),

        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
              onPressed: () async {
                if (hoursController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter daily study hours"),
                    ),
                  );
                  return;
                }

                try {

                  if (companyController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Dream company is required"),
                      ),
                    );
                    return;
                  }

                  await profileService.saveProfile(
                    fullName: widget.fullName,
                    college: widget.college,
                    year: widget.year,
                    branch: widget.branch,
                    goal: widget.careerGoal,
                    dreamCompany: companyController.text.trim(),
                    studyHours: int.parse(hoursController.text.trim()),
                    coachMode: coachMode,
                    gfgLink: widget.gfgLink,
                    leetcodeLink: widget.leetcodeLink,
                    githubLink: widget.githubLink,
                    linkedinLink: widget.linkedinLink,
                  );

                  if (!mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainNavigationScreen()
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: const Text("Finish Setup 🚀"),
            )
        ),
          ],
        ),
      ),
    );
  }
}