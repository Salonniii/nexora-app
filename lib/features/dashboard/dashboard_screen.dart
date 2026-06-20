import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ai_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? profile;
  bool isLoading = true;
  Map<String, dynamic>? aiInsight;
  List<Map<String, dynamic>> topicProgress = [];

  late AnimationController _fadeCtrl;
  late AnimationController _staggerCtrl;
  late Animation<double> _fadeAnim;

  // ─── Design Tokens ──────────────────────────────────────────
  static const _bg       = Color(0xFF07080D);
  static const _surface  = Color(0xFF0D0F18);
  static const _card     = Color(0xFF111320);
  static const _cardAlt  = Color(0xFF0F1219);
  static const _border   = Color(0xFF1A1D2E);
  static const _violet   = Color(0xFF8B5CF6);
  static const _indigo   = Color(0xFF6366F1);
  static const _cyan     = Color(0xFF06B6D4);
  static const _pink     = Color(0xFFEC4899);
  static const _green    = Color(0xFF10B981);
  static const _amber    = Color(0xFFF59E0B);
  static const _white    = Color(0xFFF1F3FA);
  static const _muted    = Color(0xFF5A6080);
  static const _dim      = Color(0xFF2A2D45);



  @override
  void initState() {
    super.initState();
    _fadeCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _staggerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim   = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    loadProfile();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _staggerCtrl.dispose();
    super.dispose();
  }

  // ─── Computed values ────────────────────────────────────────
  int calculateXP() {
    int xp = 0;
    for (var t in topicProgress) {
      xp += (int.tryParse(t['score'].toString()) ?? 0) * 5;
    }
    return xp;
  }

  int calculateLevel() => (calculateXP() ~/ 500) + 1;

  int calculateStreak() {
    int streak = 0;
    for (var t in topicProgress) {
      if ((t['score'] ?? 0) > 0) streak++;
      else break;
    }
    return streak;
  }

  List<FlSpot> getMomentumSpots() {
    if (topicProgress.isEmpty) return [const FlSpot(0, 0)];
    return List.generate(topicProgress.length, (i) =>
        FlSpot(i.toDouble(), (topicProgress[i]['score'] ?? 0).toDouble()));
  }

  List<BarChartGroupData> getTopicBars() {
    return List.generate(topicProgress.length, (i) {
      final score = (topicProgress[i]['score'] ?? 0).toDouble();
      final color = score >= 75 ? _green : score >= 50 ? _amber : _pink;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: score,
          width: 12,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.5), color],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
      ]);
    });
  }

  Future<void> loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) { setState(() => isLoading = false); return; }

    final data        = await supabase.from('profiles').select().eq('id', user.id).single();
    final progressData = await supabase.from('topic_progress').select().eq('user_id', user.id);
    final aiResponse  = await AIService.analyzeProfile(data);

    setState(() {
      profile       = data;
      aiInsight     = aiResponse;
      topicProgress = List<Map<String, dynamic>>.from(progressData);
      isLoading     = false;
    });

    _fadeCtrl.forward();
    Future.delayed(const Duration(milliseconds: 150), () => _staggerCtrl.forward());
  }

  int calculateCareerScore() {
    int score = 40;
    if ((profile?['gfg_link'] ?? '').toString().isNotEmpty)      score += 10;
    if ((profile?['leetcode_link'] ?? '').toString().isNotEmpty)  score += 10;
    if ((profile?['github_link'] ?? '').toString().isNotEmpty)    score += 15;
    if ((profile?['linkedin_link'] ?? '').toString().isNotEmpty)  score += 15;
    score += ((profile?['study_hours'] ?? 0) as int) * 2;
    return score.clamp(0, 100);
  }

  double getProfileCompletion() {
    final fields = [
      profile?['full_name'], profile?['college'], profile?['year'],
      profile?['branch'], profile?['goal'], profile?['dream_company'],
      profile?['study_hours'], profile?['gfg_link'],
      profile?['leetcode_link'], profile?['github_link'],
    ];
    return fields.where((f) => f != null && f.toString().trim().isNotEmpty).length / fields.length;
  }

  List<String> getMissingFields() {
    final missing = <String>[];
    if ((profile?['college'] ?? '').toString().isEmpty)       missing.add('College');
    if ((profile?['dream_company'] ?? '').toString().isEmpty) missing.add('Dream Company');
    if ((profile?['linkedin_link'] ?? '').toString().isEmpty) missing.add('LinkedIn');
    if ((profile?['github_link'] ?? '').toString().isEmpty)   missing.add('GitHub');
    return missing;
  }

  String get _firstName => (profile?['full_name'] ?? 'User').toString().split(' ').first;

  // ─── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: const Text('🦊', style: TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 20),
              const SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(
                  color: _violet, strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final score      = calculateCareerScore();
    final completion = getProfileCompletion();
    final xp         = calculateXP();
    final level      = calculateLevel();
    final streak     = calculateStreak();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildGreetingBanner(score),
                const SizedBox(height: 16),
                _buildStatRow(xp, level, streak),
                const SizedBox(height: 16),
                _buildProfileBar(completion),
                const SizedBox(height: 16),
                _buildGithubActivityCard(),
                if (topicProgress.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMomentumCard(),
                  const SizedBox(height: 16),
                  _buildStrengthCard(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header bar ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_violet, _indigo]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: _violet.withOpacity(0.35), blurRadius: 18)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🦊', style: TextStyle(fontSize: 16)),
              SizedBox(width: 6),
              Text('NEXORA', style: TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w900, letterSpacing: 2.2,
              )),
            ],
          ),
        ),
        const Spacer(),
        // Logout lives only on the Profile screen now — removed from here
        // to avoid duplicate logout entry points across the app.
      ],
    );
  }

  // ─── Greeting + Score Hero ──────────────────────────────────
  Widget _buildGreetingBanner(int score) {
    final scoreColor = score >= 75 ? _green : score >= 50 ? _amber : _pink;
    final label      = score >= 75 ? 'Placement Ready 🎯'
        : score >= 50 ? 'Getting There 📈'
        : 'Needs Work 💪';
    final rankText   = score >= 75 ? '🚀 Top 20% of users'
        : score >= 50 ? '📊 Above average'
        : '🎯 Focus on basics';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: scoreColor.withOpacity(0.07), blurRadius: 32, spreadRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey, $_firstName 👋',
                      style: const TextStyle(
                        color: _white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep grinding 💪',
                      style: const TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor.withOpacity(0.25)),
                      ),
                      child: Text(label,
                        style: TextStyle(color: scoreColor, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _dim.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(rankText,
                        style: const TextStyle(color: _muted, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 96, height: 96,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.07),
                      valueColor: AlwaysStoppedAnimation(scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    children: [
                      Text('$score',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: scoreColor, height: 1),
                      ),
                      Text('/ 100', style: TextStyle(fontSize: 10, color: _muted)),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),
          _thinBar(score / 100, scoreColor),
          const SizedBox(height: 6),
          Text('Career Score', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  // ─── Stat Row ──────────────────────────────────────────────
  Widget _buildStatRow(int xp, int level, int streak) {
    return Row(
      children: [
        Expanded(child: _statTile('🔥', '$streak', 'Streak', _pink)),
        const SizedBox(width: 10),
        Expanded(child: _statTile('⚡', '$xp', 'Total XP', _amber)),
        const SizedBox(width: 10),
        Expanded(child: _statTile('🏆', 'Lv $level', 'Level', _violet)),
      ],
    );
  }

  Widget _statTile(String emoji, String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: accent.withOpacity(0.07), blurRadius: 16, spreadRadius: 1)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Profile Completion ─────────────────────────────────────
  Widget _buildProfileBar(double completion) {
    final pct      = (completion * 100).toInt();
    final barColor = pct >= 80 ? _green : pct >= 50 ? _amber : _pink;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile Completion',
                  style: TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$pct%',
                    style: TextStyle(color: barColor, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _thinBar(completion, barColor, height: 7),
          if (pct < 100) ...[
            const SizedBox(height: 9),
            Text('${100 - pct}% left — complete your profile for better AI insights',
                style: const TextStyle(color: _muted, fontSize: 11.5)),
          ],
        ],
      ),
    );
  }

  // ─── Nova AI Insight ────────────────────────────────────────
  // ─── GitHub Activity Card ───────────────────────────────────
  // NOTE: uses sample contribution data for now. Wire this up to the
  // GitHub REST/GraphQL API (using profile['github_link']) to show
  // real commit/contribution counts per day.
  Widget _buildGithubActivityCard() {
    final hasGithub = (profile?['github_link'] ?? '').toString().isNotEmpty;

    // Sample weekly contribution counts (replace with real API data)
    final List<int> weekly = [2, 5, 1, 8, 4, 6, 3, 9, 2, 0, 5, 7];
    final maxVal = weekly.reduce((a, b) => a > b ? a : b).toDouble().clamp(1, double.infinity);
    final totalContribs = weekly.fold<int>(0, (a, b) => a + b);

    return _sectionCard(
      title: 'GitHub Activity',
      icon: Icons.code_rounded,
      accentColor: _green,
      child: !hasGithub
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Link your GitHub in Profile to see real contribution activity here.',
            style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.5),
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$totalContribs',
                  style: const TextStyle(color: _green, fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('commits this week',
                    style: const TextStyle(color: _muted, fontSize: 12.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekly.map((v) {
                final heightFrac = v / maxVal;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: 8 + (heightFrac * 56),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [_green.withOpacity(0.4), _green],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Text('Last 12 weeks',
              style: const TextStyle(color: _muted, fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Momentum Line Chart ────────────────────────────────────
  Widget _buildMomentumCard() {
    return _sectionCard(
      title: 'Coding Momentum',
      icon: Icons.trending_up_rounded,
      accentColor: _cyan,
      child: SizedBox(
        height: 190,
        child: LineChart(LineChartData(
          minY: 0, maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i >= 0 && i < topicProgress.length) {
                    final t = topicProgress[i]['topic'].toString();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(t.length <= 3 ? t : t.substring(0, 3),
                          style: const TextStyle(color: _muted, fontSize: 10)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: getMomentumSpots(),
              isCurved: true,
              barWidth: 2.5,
              color: _cyan,
              dotData: FlDotData(
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 4, color: _cyan, strokeWidth: 2.5, strokeColor: _card,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_cyan.withOpacity(0.18), _cyan.withOpacity(0.0)],
                ),
              ),
            ),
          ],
        )),
      ),
    );
  }

  // ─── Strength Bar Chart ─────────────────────────────────────
  Widget _buildStrengthCard() {
    return _sectionCard(
      title: 'DSA Topic Strength',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 210,
        child: BarChart(
          BarChartData(
            maxY: 100,
            barGroups: getTopicBars(),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text('${v.toInt()}',
                      style: const TextStyle(color: _muted, fontSize: 10)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i >= 0 && i < topicProgress.length) {
                      final t = topicProgress[i]['topic'].toString();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(t.length <= 3 ? t : t.substring(0, 3),
                            style: const TextStyle(color: _muted, fontSize: 10)),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, _, rod, __) {
                  final topic = topicProgress[group.x]['topic'];
                  return BarTooltipItem('$topic\n${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600));
                },
              ),
            ),
          ),
          swapAnimationDuration: const Duration(milliseconds: 600),
          swapAnimationCurve: Curves.easeInOut,
        ),
      ),
    );
  }

  // ─── Reusable Section Card ──────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color accentColor = _indigo,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 15, color: accentColor),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(color: _white, fontWeight: FontWeight.w700, fontSize: 14.5)),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: _border),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ─── Thin progress bar ──────────────────────────────────────
  Widget _thinBar(double value, Color color, {double height = 4.5}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: Colors.white.withOpacity(0.07),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}