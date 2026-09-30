import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _selectedGoalIndex = 0;
  final List<Map<String, String>> _focusGoals = [
    {'emoji': '☕', 'label': 'Deep Focus'},
    {'emoji': '🎯', 'label': 'Score 90%+'},
    {'emoji': '📅', 'label': 'Daily Routine'},
    {'emoji': '📝', 'label': 'Exam Prep'},
  ];

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.timer_outlined,
      'title': 'Mindful Pomodoro',
      'tag': 'FOCUS',
      'stat': '25m Sprint',
      'desc': 'Customizable focus & break intervals with live subject focus hub.',
      'color': Color(0xFFD97706),
      'bg': Color(0xFFFEF3C7),
    },
    {
      'icon': Icons.castle_rounded,
      'title': 'Exam Quest Hurdles',
      'tag': 'QUEST',
      'stat': 'Levels & XP',
      'desc': 'Overcome exam date hurdles through interactive topic levels.',
      'color': Color(0xFF2563EB),
      'bg': Color(0xFFDBEAFE),
    },
    {
      'icon': Icons.calendar_today_rounded,
      'title': 'Smart Timetable',
      'tag': 'ROUTINE',
      'stat': 'Auto Remind',
      'desc': 'Interactive timetable with task reminders and hurdle sync.',
      'color': Color(0xFF059669),
      'bg': Color(0xFFD1FAE5),
    },
    {
      'icon': Icons.sticky_note_2_outlined,
      'title': 'Quick Sticky Notes',
      'tag': 'NOTES',
      'stat': 'Fast Cues',
      'desc': 'Pin formulas, revision cues, and exam summaries in seconds.',
      'color': Color(0xFF7C3AED),
      'bg': Color(0xFFEDE9FE),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final warmBg = isDark ? const Color(0xFF161514) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF242220) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF3ECE4) : const Color(0xFF2D2620);
    final textSecondary = isDark ? const Color(0xFFA69E96) : const Color(0xFF796F65);
    final accentTerracotta = isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C);
    final sageGreen = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);

    return Scaffold(
      backgroundColor: warmBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Brand Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentTerracotta.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accentTerracotta.withAlpha(50),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              size: 22,
                              color: accentTerracotta,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Spark',
                            style: GoogleFonts.lora(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: sageGreen.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sageGreen.withAlpha(60),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.eco_rounded, size: 14, color: sageGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Sparkle your Schedule',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sageGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Headline & Editorial Subtitle
                  Text(
                    'Focus Today,\nShape your Tomorrow.',
                    style: GoogleFonts.lora(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your handcrafted companion for purposeful schedules, marks tracking, and mindful deep focus sessions.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      height: 1.45,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Central Handcrafted Art Illustration with Badge Overlays
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Cozy Illustration Container
                        Container(
                          width: double.infinity,
                          height: 230,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(isDark ? 50 : 20),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8DFD3),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/study_hero.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFFAF2E6),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.menu_book_rounded,
                                          size: 54,
                                          color: accentTerracotta,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Cozy Study Corner',
                                          style: GoogleFonts.lora(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // Floating Badge Top-Right: Focus Streak
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2E2721).withAlpha(230)
                                  : Colors.white.withAlpha(240),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withAlpha(100),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🔥', style: TextStyle(fontSize: 13)),
                                SizedBox(width: 4),
                                Text(
                                  '5-Day Streak',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Floating Badge Bottom-Left: Target Grade
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E2835).withAlpha(230)
                                  : Colors.white.withAlpha(240),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withAlpha(100),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🎯', style: TextStyle(fontSize: 13)),
                                SizedBox(width: 4),
                                Text(
                                  'Target: 95%+',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Interactive "Choose Your Main Focus"
                  Text(
                    'What is your main goal this semester?',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_focusGoals.length, (index) {
                      final item = _focusGoals[index];
                      final isSelected = _selectedGoalIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGoalIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentTerracotta
                                : (isDark
                                    ? const Color(0xFF22201E)
                                    : const Color(0xFFEFE8DD)),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? accentTerracotta
                                  : (isDark
                                      ? Colors.white12
                                      : const Color(0xFFDDD2C2)),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(item['emoji']!,
                                  style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                item['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),

                  // Features Grid (Handcrafted cards)
                  Text(
                    'Crafted for real students',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.98,
                    ),
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      final f = _features[index];
                      final color = f['color'] as Color;
                      final bg = f['bg'] as Color;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? color.withAlpha(50)
                                : const Color(0xFFEBE3D7),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(isDark ? 25 : 12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bg.withAlpha(isDark ? 45 : 255),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: color.withAlpha(40),
                                    ),
                                  ),
                                  child: Icon(
                                    f['icon'] as IconData,
                                    size: 18,
                                    color: color,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(isDark ? 30 : 20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    f['tag'] as String,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              f['title'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              f['desc'] as String,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 1.25,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(10)
                                    : const Color(0xFFF5EFE6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      size: 12, color: color),
                                  const SizedBox(width: 3),
                                  Text(
                                    f['stat'] as String,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Call to Action Button
                  ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentTerracotta,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: accentTerracotta.withAlpha(120),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Learning 📖',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Already have an account? Sign In',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accentTerracotta,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

