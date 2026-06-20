import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../roadmap/roadmap_screen.dart';
import '../ai_coach/ai_coach_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int selectedIndex = 0;

  // ─── Design tokens (matches Dashboard/Profile) ──────────────
  static const _bg      = Color(0xFF07080D);
  static const _card    = Color(0xFF111320);
  static const _border  = Color(0xFF1A1D2E);
  static const _violet  = Color(0xFF8B5CF6);
  static const _indigo  = Color(0xFF6366F1);
  static const _muted   = Color(0xFF5A6080);
  static const _white   = Color(0xFFF1F3FA);

  final screens = const [
    DashboardScreen(),
    RoadmapScreen(),
    AICoachScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: "Home"),
    _NavItem(icon: Icons.route_rounded, outlineIcon: Icons.route_outlined, label: "Roadmap"),
    _NavItem(icon: Icons.smart_toy_rounded, outlineIcon: Icons.smart_toy_outlined, label: "AI Coach"),
    _NavItem(icon: Icons.person_rounded, outlineIcon: Icons.person_outline_rounded, label: "Profile"),
  ];

  void _onTap(int index) {
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: _card.withOpacity(0.97),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: _violet.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item     = _items[i];
            final selected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: selected
                        ? const LinearGradient(
                      colors: [_violet, _indigo],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color: _violet.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: child,
                        ),
                        child: Icon(
                          selected ? item.icon : item.outlineIcon,
                          key: ValueKey(selected),
                          size: 21,
                          color: selected ? Colors.white : _muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? Colors.white : _muted,
                          fontSize: 10.5,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  const _NavItem({required this.icon, required this.outlineIcon, required this.label});
}