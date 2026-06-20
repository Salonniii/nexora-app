import 'package:flutter/material.dart';
import 'coding_links_screen.dart';

class CareerGoalScreen extends StatefulWidget {
  final String fullName;
  final String college;
  final String year;
  final String branch;

  const CareerGoalScreen({
    super.key,
    required this.fullName,
    required this.college,
    required this.year,
    required this.branch,
  });

  @override
  State<CareerGoalScreen> createState() => _CareerGoalScreenState();
}

class _CareerGoalScreenState extends State<CareerGoalScreen> {
  String selectedGoal = "SDE";
  final goals = [
    "SDE",
    "AI Engineer",
    "Android Developer",
    "Flutter Developer",
    "Web Developer",
    "Backend Developer",
    "Data Scientist",
    "DevOps Engineer",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text(
          "Step 2 of 4 🎯",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Career Goal 🚀",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Nova will use this to build your personalized roadmap.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              "What is your dream role?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 30),
        Expanded(
          child: ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final isSelected = selectedGoal == goal;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedGoal = goal;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withOpacity(0.2)
                        : const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    goal,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
            const SizedBox(height: 20),


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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CodingLinksScreen(
                    fullName: widget.fullName,
                    college: widget.college,
                    year: widget.year,
                    branch: widget.branch,
                    careerGoal: selectedGoal,
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
          ),
        ),
      ],
      ),
      ),
    );
  }
}