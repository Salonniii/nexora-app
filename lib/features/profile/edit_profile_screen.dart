import 'package:flutter/material.dart';
import 'package:nexora/services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService profileService = ProfileService();

  late TextEditingController collegeController;
  late TextEditingController yearController;
  late TextEditingController branchController;
  late TextEditingController goalController;
  late TextEditingController dreamCompanyController;
  late TextEditingController studyHoursController;
  late TextEditingController gfgController;
  late TextEditingController leetcodeController;
  late TextEditingController githubController;
  late TextEditingController linkedinController;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    collegeController =
        TextEditingController(text: widget.profile['college'] ?? '');
    yearController =
        TextEditingController(text: widget.profile['year'] ?? '');
    branchController =
        TextEditingController(text: widget.profile['branch'] ?? '');
    goalController =
        TextEditingController(text: widget.profile['goal'] ?? '');
    dreamCompanyController =
        TextEditingController(text: widget.profile['dream_company'] ?? '');
    studyHoursController = TextEditingController(
      text: (widget.profile['study_hours'] ?? 0).toString(),
    );
    gfgController =
        TextEditingController(text: widget.profile['gfg_link'] ?? '');
    leetcodeController =
        TextEditingController(text: widget.profile['leetcode_link'] ?? '');
    githubController =
        TextEditingController(text: widget.profile['github_link'] ?? '');
    linkedinController =
        TextEditingController(text: widget.profile['linkedin_link'] ?? '');
  }

  Future<void> saveChanges() async {
    setState(() => loading = true);

    await profileService.updateProfile({
      'college': collegeController.text.trim(),
      'year': yearController.text.trim(),
      'branch': branchController.text.trim(),
      'goal': goalController.text.trim(),
      'dream_company': dreamCompanyController.text.trim(),
      'study_hours': int.tryParse(studyHoursController.text) ?? 0,
      'gfg_link': gfgController.text.trim(),
      'leetcode_link': leetcodeController.text.trim(),
      'github_link': githubController.text.trim(),
      'linkedin_link': linkedinController.text.trim(),
    });

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFF161B22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildField("College", collegeController),
            buildField("Year", yearController),
            buildField("Branch", branchController),
            buildField("Goal", goalController),
            buildField("Dream Company", dreamCompanyController),
            buildField("Study Hours", studyHoursController),
            buildField("GFG Link", gfgController),
            buildField("LeetCode Link", leetcodeController),
            buildField("GitHub Link", githubController),
            buildField("LinkedIn Link", linkedinController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : saveChanges,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Save Changes"),
            )
          ],
        ),
      ),
    );
  }
}