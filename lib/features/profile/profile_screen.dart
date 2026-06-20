import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_profile_screen.dart';
import '../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? profile;
  bool loading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Design Tokens (distinct palette from Dashboard) ─────────────
  static const _bg = Color(0xFF07080D);
  static const _card = Color(0xFF12141C);
  static const _border = Color(0x14FFFFFF);
  static const _coverStart = Color(0xFF1E1147);
  static const _coverEnd = Color(0xFF0B1430);
  static const _accentGold = Color(0xFFE8B84B);
  static const _accentTeal = Color(0xFF2DD4BF);
  static const _textPrimary = Color(0xFFF0F2F8);
  static const _textSecondary = Color(0xFF8892A4);
  // ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final data =
    await supabase.from('profiles').select().eq('id', user.id).single();
    setState(() {
      profile = data;
      loading = false;
    });
    _animController.forward();
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;

    // Ensure the URL has a scheme — Uri.parse alone won't add one.
    final normalized = urlString.startsWith('http://') || urlString.startsWith('https://')
        ? urlString
        : 'https://$urlString';

    final Uri url = Uri.parse(normalized);

    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open $normalized")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open link: $e")),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    debugPrint('LOGOUT: button tapped');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 20),
              const Text("Log Out?",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary)),
              const SizedBox(height: 8),
              Text("You'll need to sign in again to access your profile.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSecondary, fontSize: 13.5, height: 1.5)),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        debugPrint('LOGOUT: cancel tapped');
                        Navigator.pop(ctx, false);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Cancel",
                          style: TextStyle(color: _textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('LOGOUT: confirm tapped');
                        Navigator.pop(ctx, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text("Log Out",
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );

    debugPrint('LOGOUT: dialog closed, confirmed = $confirmed');

    if (confirmed == true) {
      try {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Couldn't log out: $e")),
          );
        }
      }
    }
  }

  int calculateCareerScore() {
    int score = 40;
    if ((profile?['gfg_link'] ?? '').toString().isNotEmpty) score += 10;
    if ((profile?['leetcode_link'] ?? '').toString().isNotEmpty) score += 10;
    if ((profile?['github_link'] ?? '').toString().isNotEmpty) score += 15;
    if ((profile?['linkedin_link'] ?? '').toString().isNotEmpty) score += 15;
    score += ((profile?['study_hours'] ?? 0) as int) * 2;
    return score.clamp(0, 100);
  }

  double getProfileCompletion() {
    List<dynamic> fields = [
      profile?['full_name'], profile?['college'], profile?['year'],
      profile?['branch'], profile?['goal'], profile?['dream_company'],
      profile?['study_hours'], profile?['gfg_link'],
      profile?['leetcode_link'], profile?['github_link'],
    ];
    int filled =
        fields.where((f) => f != null && f.toString().trim().isNotEmpty).length;
    return filled / 10;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _accentGold, strokeWidth: 2),
        ),
      );
    }

    final careerScore = calculateCareerScore();
    final completion = (getProfileCompletion() * 100).toInt();
    final initials = (profile?['full_name'] ?? 'U').toString().isNotEmpty
        ? (profile?['full_name'] as String)
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── Cover header with avatar overlap ───────────────────
            SliverToBoxAdapter(
              child: _buildCoverHeader(initials),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52), // space for overlapping avatar
                    Center(
                      child: Text(
                        profile?['full_name'] ?? "Your Name",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accentTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _accentTeal.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          profile?['goal'] ?? "Set your goal",
                          style: const TextStyle(
                              color: _accentTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Two stat cards side by side (distinct from Dashboard's score ring)
                    Row(
                      children: [
                        Expanded(child: _metricCard("$careerScore", "Career Score", _accentGold, careerScore / 100)),
                        const SizedBox(width: 12),
                        Expanded(child: _metricCard("$completion%", "Profile Done", _accentTeal, completion / 100)),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _sectionLabel("ABOUT"),
                    const SizedBox(height: 12),

                    // 2-column details grid (distinct from Dashboard's stacked rows)
                    _detailsGrid(),

                    const SizedBox(height: 28),

                    _sectionLabel("CODING PROFILES"),
                    const SizedBox(height: 12),
                    _buildCodingProfiles(),

                    SizedBox(height: 100 + MediaQuery.of(context).padding.bottom),


                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Cover header ───────────────────────────────────────────────
  Widget _buildCoverHeader(String initials) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 168,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_coverStart, _coverEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Decorative dotted texture
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentGold.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                left: 30,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accentTeal.withValues(alpha: 0.08),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Profile",
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: _textPrimary)),
                      Row(
                        children: [
                          _coverIcon(Icons.edit_rounded, () async {
                            if (await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EditProfileScreen(profile: profile!))) ==
                                true) {
                              loadProfile();
                            }
                          }),
                          const SizedBox(width: 8),
                          _coverIcon(Icons.logout_rounded, _handleLogout,
                              color: Colors.redAccent.withValues(alpha: 0.85)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Overlapping avatar
        Positioned(
          top: 168 - 44,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bg,
                border: Border.all(color: _bg, width: 4),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_accentGold, Color(0xFFB8860B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverIcon(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: color ?? Colors.white.withValues(alpha: 0.85)),
      ),
    );
  }

  // ── Metric Card (pill-style, distinct from Dashboard's ring) ───
  Widget _metricCard(String val, String label, Color accent, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(val,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: accent)),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(accent),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: _textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Details list (compact rows, distinct styling from Dashboard) ─
  Widget _detailsGrid() {
    final items = [
      (Icons.school_rounded, "College", profile?['college'] ?? "—"),
      (Icons.calendar_today_rounded, "Year", profile?['year'] ?? "—"),
      (Icons.account_tree_rounded, "Branch", profile?['branch'] ?? "—"),
      (Icons.business_center_rounded, "Dream Company", profile?['dream_company'] ?? "—"),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _accentTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.$1, size: 15, color: _accentTeal),
                    ),
                    const SizedBox(width: 12),
                    Text(item.$2,
                        style: const TextStyle(
                            color: _textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Flexible(
                      child: Text(item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: _textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) Divider(color: _border, height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Coding Profiles List ───────────────────────────────────────
  Widget _buildCodingProfiles() {
    final items = [
      {
        'label': 'LeetCode',
        'url': profile?['leetcode_link'] ?? '',
        'icon': Icons.code_rounded,
        'color': const Color(0xFFFFA116),
        'sub': 'leetcode.com',
      },
      {
        'label': 'GitHub',
        'url': profile?['github_link'] ?? '',
        'icon': Icons.hub_rounded,
        'color': const Color(0xFFD0D7DE),
        'sub': 'github.com',
      },
      {
        'label': 'GeeksforGeeks',
        'url': profile?['gfg_link'] ?? '',
        'icon': Icons.eco_rounded,
        'color': const Color(0xFF2F8D46),
        'sub': 'geeksforgeeks.org',
      },
      {
        'label': 'LinkedIn',
        'url': profile?['linkedin_link'] ?? '',
        'icon': Icons.work_rounded,
        'color': const Color(0xFF0A66C2),
        'sub': 'linkedin.com',
      },
    ];

    return Column(
      children: items.map((p) {
        final hasLink = (p['url'] as String).isNotEmpty;
        final accent = p['color'] as Color;

        return GestureDetector(
          onTap: hasLink ? () => _launchURL(p['url'] as String) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: hasLink ? accent.withValues(alpha: 0.07) : _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasLink ? accent.withValues(alpha: 0.28) : _border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: hasLink
                        ? accent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    p['icon'] as IconData,
                    size: 20,
                    color: hasLink ? accent : _textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: hasLink ? _textPrimary : _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasLink ? p['sub'] as String : "Not linked",
                        style: TextStyle(
                          fontSize: 12,
                          color: hasLink
                              ? accent.withValues(alpha: 0.75)
                              : _textSecondary.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  hasLink
                      ? Icons.arrow_outward_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 18,
                  color: hasLink
                      ? accent.withValues(alpha: 0.7)
                      : _textSecondary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }



  // ── Helpers ────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
        color: _textSecondary),
  );
}