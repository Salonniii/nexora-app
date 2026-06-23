import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/ai_service.dart';
import '../../models/chat_message.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? analysisResult;
  Map<String, dynamic>? platformData;

  final TextEditingController messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  // FIX 1: Start with empty messages, will be set dynamically after profile loads
  List<ChatMessage> messages = [];

  bool isSending = false;
  bool isLoading = false;
  bool hasAnalyzed = false;
  bool isLoadingProfile = true;
  String? errorMessage;

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _loadProfile();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isLoadingProfile = false);
      return;
    }
    try {
      final data = await supabase.from('profiles').select().eq('id', user.id).single();

      // FIX 2: Dynamic greeting using actual profile name
      final firstName = (data['full_name'] as String? ?? 'there').split(' ')[0];

      setState(() {
        profile = data;
        isLoadingProfile = false;
      });

      // Restore saved chat history (or create+save the first greeting).
      await _loadChatHistory(user.id, firstName);

      // Load any previously-saved analysis so it survives logout/login.
      await _loadCachedAnalysis(user.id);
    } catch (e) {
      setState(() {
        isLoadingProfile = false;
        messages = [
          ChatMessage(
            text: "Hey 👋 I'm Nova, your AI mentor 🦊\nTell me what you studied today.",
            isUser: false,
          ),
        ];
      });
    }
  }

  Future<void> _loadChatHistory(String userId, String firstName) async {
    try {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('chat_history')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      if (rows.isNotEmpty) {
        // Returning user — restore the full saved conversation, including greeting.
        setState(() {
          messages = rows
              .map<ChatMessage>(
                  (r) => ChatMessage(text: r['text'], isUser: r['is_user']))
              .toList();
        });
      } else {
        // First time ever — create and save the greeting.
        final greeting = ChatMessage(
          text: "Hey $firstName 👋 I'm Nova, your AI mentor 🦊\nTell me what you studied today.",
          isUser: false,
        );
        setState(() => messages = [greeting]);
        await _saveMessageToHistory(greeting);
      }
    } catch (e) {
      print("CHAT HISTORY LOAD ERROR: $e");
      // Fall back to a fresh greeting if history fails to load.
      setState(() {
        messages = [
          ChatMessage(
            text: "Hey $firstName 👋 I'm Nova, your AI mentor 🦊\nTell me what you studied today.",
            isUser: false,
          ),
        ];
      });
    }
  }

  Future<void> _saveMessageToHistory(ChatMessage msg) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('chat_history').insert({
        'user_id': userId,
        'text': msg.text,
        'is_user': msg.isUser,
      });
    } catch (e) {
      print("CHAT HISTORY SAVE ERROR: $e");
      // Non-fatal — message still shows in this session even if save fails.
    }
  }

  Future<void> _loadCachedAnalysis(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final cached = await supabase
          .from('analysis_cache')
          .select('analysis_result')
          .eq('user_id', userId)
          .maybeSingle();

      if (cached != null && cached['analysis_result'] != null) {
        final result = cached['analysis_result'] as Map<String, dynamic>;
        setState(() {
          analysisResult = result;
          platformData = result['platform_data'];
          hasAnalyzed = true;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      print("ANALYSIS CACHE LOAD ERROR: $e");
      // Non-fatal — just means no cached analysis to show yet.
    }
  }

  Future<void> _saveAnalysisToCache(Map<String, dynamic> result) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('analysis_cache').upsert({
        'user_id': userId,
        'analysis_result': result,
      });
    } catch (e) {
      print("ANALYSIS CACHE SAVE ERROR: $e");
      // Non-fatal — the analysis still shows for this session even if save fails.
    }
  }

  Future<void> _runSmartAnalysis() async {
    if (profile == null) return;

    // BUG FIX: previously, on re-analyze, old `analysisResult`/`platformData`
    // stayed populated while a NEW request was in flight. If that new request
    // failed (e.g. Gemini quota error), the screen kept silently showing the
    // OLD GitHub/LeetCode/GFG stats underneath a fresh error message — making
    // it look like "re-analyze doesn't show my repos" when actually it was
    // showing stale data from the last successful run, not the new one.
    //
    // Fix: clear old results immediately when a new analysis starts, so the
    // UI honestly reflects "no result yet" while loading, instead of showing
    // possibly-stale data next to a new error.
    setState(() {
      isLoading = true;
      errorMessage = null;
      hasAnalyzed = false;
      analysisResult = null;
      platformData = null;
    });

    try {
      final result = await AIService.smartAnalyze(
        fullName: profile!['full_name'] ?? '',
        college: profile!['college'],
        goal: profile!['goal'],
        dreamCompany: profile!['dream_company'],
        github: profile!['github_link'],
        leetcode: profile!['leetcode_link'],
        gfg: profile!['gfg_link'],
      );

      if (result.containsKey('error')) {
        setState(() {
          errorMessage = 'Analysis failed: ${result['error']}';
          isLoading = false;
          // Still show GitHub/LeetCode/GFG stats if the backend returned them
          // even though the Gemini text-analysis step failed.
          if (result['platform_data'] != null) {
            platformData = result['platform_data'];
            hasAnalyzed = true;
          }
        });
        return;
      }

      setState(() {
        analysisResult = result;
        platformData = result['platform_data'];
        hasAnalyzed = true;
        isLoading = false;
      });
      _fadeController.forward(from: 0);

      // Persist so this result survives logout/login — only overwritten
      // when the user explicitly re-analyzes successfully.
      await _saveAnalysisToCache(result);
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Map<String, String> _parseSections(String raw) {
    final sections = <String, String>{};
    final patterns = {
      'score': RegExp(r'1\.\s*CAREER SCORE.*?(?=2\.|$)', dotAll: true),
      'strengths': RegExp(r'2\.\s*STRENGTHS.*?(?=3\.|$)', dotAll: true),
      'weaknesses': RegExp(r'3\.\s*WEAKNESSES.*?(?=4\.|$)', dotAll: true),
      'missing': RegExp(r'4\.\s*MISSING TOPICS.*?(?=5\.|$)', dotAll: true),
      'company': RegExp(r'5\.\s*COMPANY-SPECIFIC.*?(?=6\.|$)', dotAll: true),
      'action': RegExp(r'6\.\s*DAILY ACTION PLAN.*?(?=7\.|$)', dotAll: true),
      'recommendations': RegExp(r'7\.\s*RECOMMENDATIONS.*', dotAll: true),
    };

    for (final entry in patterns.entries) {
      final match = entry.value.firstMatch(raw);
      if (match != null) {
        sections[entry.key] = match.group(0)!.replaceAll('**', '').trim();
      }
    }
    if (sections.isEmpty) sections['raw'] = raw.replaceAll('**', '').trim();
    return sections;
  }

  int _extractScore(String raw) {
    final match = RegExp(r'(\d{1,3})\s*/\s*100').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '0') ?? 0;
  }

  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);

    setState(() {
      messages.add(userMsg);
      isSending = true;
    });

    messageController.clear();
    await _saveMessageToHistory(userMsg);

    // Auto-scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    final reply = await AIService.chatWithNova(
      message: text,
      fullName: profile?['full_name'] ?? "User",
      goal: profile?['goal'] ?? "",
    );

    final novaMsg = ChatMessage(text: reply, isUser: false);

    setState(() {
      messages.add(novaMsg);
      isSending = false;
    });
    await _saveMessageToHistory(novaMsg);

    // Auto-scroll after reply arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D1117), Color(0xFF0D1117), Color(0xFF1A0A2E)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                if (profile != null) _buildPlatformChips(),
                const SizedBox(height: 20),
                _buildHeroCard(),
                if (errorMessage != null) _buildError(),
                if (hasAnalyzed && analysisResult != null) ...[
                  const SizedBox(height: 28),
                  FadeTransition(opacity: _fadeAnim, child: _buildResults()),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text('🦊', style: TextStyle(fontSize: 26)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nova AI Coach',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Powered by real platform data',
                style: TextStyle(color: Colors.purple.shade300, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _buildPlatformChips() {
    final github = (profile!['github_link'] ?? '').toString().isNotEmpty;
    final leetcode = (profile!['leetcode_link'] ?? '').toString().isNotEmpty;
    final gfg = (profile!['gfg_link'] ?? '').toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Connected Platforms',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _platformChip('GitHub', github, '🐙'),
            _platformChip('LeetCode', leetcode, '🟨'),
            _platformChip('GFG', gfg, '🟩'),
          ],
        ),
        if (!github && !leetcode && !gfg)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              '⚠️ No platforms linked! Go to Profile → Edit to add your links.',
              style: TextStyle(color: Colors.orange.shade300, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _platformChip(String label, bool connected, String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: connected ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: connected ? Colors.green.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: connected ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(width: 4),
          Icon(connected ? Icons.check_circle : Icons.cancel,
              color: connected ? Colors.green : Colors.grey, size: 14),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          ),
          boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.35), blurRadius: 30, spreadRadius: 2)],
        ),
        child: Column(
          children: [
            const Text('🦊', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              hasAnalyzed ? 'Analysis Complete! 🎯' : 'Nova fetches your REAL\ncoding data and analyzes it',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnalyzed
                  ? 'Tap below to re-analyze'
                  : 'Fetches GitHub repos, GFG score,\nLeetCode stats — then AI analyzes everything',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: isLoading ? null : _runSmartAnalysis,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: isLoading ? Colors.white.withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: isLoading
                    ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Fetching real data...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF7C3AED), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      hasAnalyzed ? 'Re-analyze Profile' : 'Analyze My Profile',
                      style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final raw = analysisResult!['analysis'] as String? ?? '';
    final sections = _parseSections(raw);
    final score = _extractScore(raw);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (platformData != null) _buildPlatformStats(),
        const SizedBox(height: 20),
        _buildScoreCard(score),
        const SizedBox(height: 16),
        if (sections.containsKey('strengths'))
          _buildSection('💪 Strengths', sections['strengths']!, const Color(0xFF064E3B), Colors.greenAccent),
        if (sections.containsKey('weaknesses'))
          _buildSection('⚡ Areas to Improve', sections['weaknesses']!, const Color(0xFF7C2D12), Colors.orangeAccent),
        if (sections.containsKey('missing'))
          _buildSection('📚 Missing Topics', sections['missing']!, const Color(0xFF1E1B4B), Colors.purpleAccent),
        if (sections.containsKey('company'))
          _buildSection('🏢 Company Questions', sections['company']!, const Color(0xFF0C4A6E), Colors.cyanAccent),
        if (sections.containsKey('action'))
          _buildSection('🎯 Today\'s Action Plan', sections['action']!, const Color(0xFF3B0764), Colors.pinkAccent),
        if (sections.containsKey('recommendations'))
          _buildSection('🚀 Recommendations', sections['recommendations']!, const Color(0xFF1A2E05), Colors.lightGreenAccent),
        if (sections.containsKey('raw'))
          _buildSection('🦊 Nova\'s Analysis', sections['raw']!, const Color(0xFF1E1B4B), Colors.purpleAccent),
        _buildChatSection(),
      ],
    );
  }

  Widget _buildPlatformStats() {
    final github = platformData!['github'] as Map<String, dynamic>?;
    final leetcode = platformData!['leetcode'] as Map<String, dynamic>?;
    final gfg = platformData!['gfg'] as Map<String, dynamic>?;

    final List<Widget> statWidgets = [];

    if (github?['available'] == true) {
      statWidgets.add(_statBox('🐙 GitHub', [
        '${github!['public_repos']} repos',
        '${github['total_stars']} stars',
        (github['top_languages'] as List).isNotEmpty
            ? (github['top_languages'] as List).take(2).join(', ')
            : 'No languages',
      ], Colors.blue));
    }

    if (gfg?['available'] == true) {
      statWidgets.add(_statBox('🟩 GFG', [
        '${gfg!['total_solved']} solved',
        'Score: ${gfg['coding_score']}',
        '🔥 ${gfg['streak']} day streak',
      ], Colors.green));
    }

    if (leetcode?['available'] == true) {
      statWidgets.add(_statBox('🟨 LeetCode', [
        '${leetcode!['total_solved']} solved',
        'Easy: ${leetcode['easy_solved']}',
        'Medium: ${leetcode['medium_solved']}',
      ], Colors.orange));
    }

    if (statWidgets.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Real Platform Data ✅',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statWidgets
                .map((w) => Padding(padding: const EdgeInsets.only(right: 12), child: w))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String title, List<String> items, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          )),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int score) {
    final scoreColor = score >= 75
        ? Colors.greenAccent
        : score >= 50
        ? Colors.orangeAccent
        : Colors.redAccent;
    final label = score >= 75
        ? 'Placement Ready 🎯'
        : score >= 50
        ? 'Getting There 📈'
        : 'Needs Work 💪';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 85,
            width: 85,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
                Text('$score',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Career Score', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('$score / 100',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label,
                      style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Chat with Nova 🦊",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // FIX 3: Single ListView (duplicate removed), with scroll controller
          SizedBox(
            height: 300,
            child: ListView.builder(
              controller: _chatScrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: msg.isUser
                          ? const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF7B61FF)],
                      )
                          : null,
                      color: msg.isUser ? null : const Color(0xFF2A2F3E),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),

          if (isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nova is typing... 🦊",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => sendMessage(),
                  decoration: InputDecoration(
                    hintText: "Ask Nova anything...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    filled: true,
                    fillColor: const Color(0xFF1A1F2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFF3B82F6)],
                  ),
                ),
                child: IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, Color bgColor, Color accentColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Text(
            content.isEmpty ? 'No data available' : content,
            style: TextStyle(color: Colors.white.withOpacity(0.85), height: 1.7, fontSize: 14),
          ),
        ],
      ),
    );
  }
}