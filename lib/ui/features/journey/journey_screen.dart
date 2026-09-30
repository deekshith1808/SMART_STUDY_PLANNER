import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudyPlannerViewModel>();
    final progress = vm.journeyProgress;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Column(
          children: [
            // Top Duolingo Gamification Stats Header
            _buildGamificationHeader(context, progress, isDark),

            // Winding Learning Path Scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16, bottom: 40),
                child: Column(
                  children: [
                    // Unit Header Banner
                    _buildUnitHeader(progress, isDark),
                    const SizedBox(height: 24),

                    // Duolingo Stepping Stones Snake Trail
                    _buildSnakeTrail(context, vm, progress, isDark),

                    const SizedBox(height: 36),

                    // The Climax Obstacle / Hurdle: THE EXAM
                    _buildExamHurdleCastle(context, vm, progress, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamificationHeader(
      BuildContext context, JourneyProgress progress, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2835) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level Title & Avatar
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFC2410C).withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFC2410C).withAlpha(80),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('🦉', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${progress.level}',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF2D2620),
                    ),
                  ),
                  Text(
                    progress.levelTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Streak & Points Pills
          Row(
            children: [
              // Streak Pill
              _buildStatPill(
                icon: '🔥',
                text: '${progress.currentStreak} Days',
                color: const Color(0xFFEA580C),
                bg: const Color(0xFFFFEDD5),
                onTap: () => _showStreakInfo(context, progress),
              ),
              const SizedBox(width: 8),

              // Points / XP Pill
              _buildStatPill(
                icon: '⚡',
                text: '${progress.totalXp} XP',
                color: const Color(0xFFD97706),
                bg: const Color(0xFFFEF3C7),
                onTap: () => _showXpInfo(context, progress),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String icon,
    required String text,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(80), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(20),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitHeader(JourneyProgress progress, bool isDark) {
    final completedCount =
        progress.nodes.where((n) => n.status == NodeStatus.completed).length;
    final totalCount = progress.nodes.length;
    final progressFraction = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2835) : const Color(0xFFF3ECE0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UNIT 1 • SEMESTER ROADMAP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFFC2410C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF047857).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF047857).withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 13, color: Color(0xFF047857)),
                    const SizedBox(width: 4),
                    Text(
                      'Hurdle in ${progress.hurdle.daysRemaining}d',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Foundations & Core Practice',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF2D2620),
            ),
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 10,
              backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5DDD0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF047857)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalCount steps conquered',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF796F65),
                ),
              ),
              Text(
                '${(progressFraction * 100).toInt()}% Ready',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF047857),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSnakeTrail(BuildContext context, StudyPlannerViewModel vm,
      JourneyProgress progress, bool isDark) {
    final nodes = progress.nodes;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final nextNode = index + 1 < nodes.length ? nodes[index + 1] : null;

        return _DuolingoNodeItem(
          node: node,
          nextNode: nextNode,
          isDark: isDark,
          pulseAnimation: _pulseAnimation,
          onTap: () => _handleNodeTap(context, vm, node),
        );
      },
    );
  }

  Widget _buildExamHurdleCastle(BuildContext context, StudyPlannerViewModel vm,
      JourneyProgress progress, bool isDark) {
    final hurdle = progress.hurdle;
    final isUnlocked = hurdle.isUnlocked;

    return GestureDetector(
      onTap: () => _showExamHurdleModal(context, vm, progress),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isUnlocked
                ? [const Color(0xFFC2410C), const Color(0xFF9A3412)]
                : [
                    isDark ? const Color(0xFF283548) : const Color(0xFFEADFD2),
                    isDark ? const Color(0xFF1E2835) : const Color(0xFFDDD0C0),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: isUnlocked
                  ? const Color(0xFFC2410C).withAlpha(100)
                  : Colors.black.withAlpha(20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFFFDBA74)
                : (isDark ? Colors.white24 : const Color(0xFFD4C5B2)),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Floating Hurdle Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFFFEF3C7)
                    : (isDark ? Colors.black38 : Colors.white70),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUnlocked
                      ? const Color(0xFFD97706)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(isUnlocked ? '⚔️' : '🔒',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    isUnlocked
                        ? 'FIRST HURDLE UNLOCKED!'
                        : 'FIRST HURDLE: THE EXAM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: isUnlocked
                          ? const Color(0xFFB45309)
                          : (isDark ? Colors.white70 : const Color(0xFF5A524A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Castle Icon Container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? Colors.white.withAlpha(40)
                    : Colors.black.withAlpha(20),
                border: Border.all(
                  color: isUnlocked ? Colors.white70 : Colors.white24,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  isUnlocked ? '🏆' : '🏰',
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Title & Countdown
            Text(
              hurdle.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isUnlocked || isDark ? Colors.white : const Color(0xFF2D2620),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${hurdle.subjectName} • Target: ${hurdle.targetScore.toInt()}%+',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isUnlocked || isDark ? Colors.white70 : const Color(0xFF6B6258),
              ),
            ),
            const SizedBox(height: 16),

            // Readiness Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(isUnlocked ? 40 : 20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hurdle Readiness',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${hurdle.completedNodes}/${hurdle.requiredNodes} Conquered',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isUnlocked
                                    ? const Color(0xFFFEF08A)
                                    : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: hurdle.readiness,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isUnlocked
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // CTA Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isUnlocked ? Colors.white : Colors.black26,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isUnlocked
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isUnlocked
                        ? Icons.play_arrow_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: isUnlocked
                        ? const Color(0xFFC2410C)
                        : (isDark ? Colors.white70 : const Color(0xFF6B6258)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUnlocked ? 'Face the Exam Challenge' : 'Inspect Hurdle Details',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked
                          ? const Color(0xFFC2410C)
                          : (isDark ? Colors.white70 : const Color(0xFF6B6258)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNodeTap(
      BuildContext context, StudyPlannerViewModel vm, JourneyNode node) {
    if (node.status == NodeStatus.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔒 Conquer the previous level to unlock "${node.title}"!',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF2D2620),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _showNodeModal(context, vm, node);
  }

  void _showNodeModal(
      BuildContext context, StudyPlannerViewModel vm, JourneyNode node) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = node.status == NodeStatus.completed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2835) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Type Tag and XP Reward
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2410C).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${node.subjectName.toUpperCase()} • STAGE ${node.stage}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: const Color(0xFFC2410C),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          '+${node.xpReward} XP',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                node.title,
                style: GoogleFonts.lora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF2D2620),
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                node.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF6B6258),
                ),
              ),
              const SizedBox(height: 20),

              // Completion Status Pill
              if (isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF059669)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF059669), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Mastered! 3/3 Stars Earned ⭐️⭐️⭐️',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 22),

              // Action 1: Launch Pomodoro Sprint
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Switch to Pomodoro Tab (index 2)
                  vm.setTabIndex(2);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2410C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.timer_rounded, size: 20),
                label: Text(
                  'Launch 25m Focus Sprint',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Action 2: Quick Quiz or Mark Mastered
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await vm.completeJourneyNode(node.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Step Conquered! +${node.xpReward} XP added to your Streak!',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF047857),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFE8DFD3),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.verified_rounded,
                    size: 18, color: Color(0xFF047857)),
                label: Text(
                  isCompleted ? 'Practice Again (+10 XP)' : 'Mark Mastered (+${node.xpReward} XP)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2D2620),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExamHurdleModal(
      BuildContext context, StudyPlannerViewModel vm, JourneyProgress progress) {
    final hurdle = progress.hurdle;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E2835) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hurdle Trophy Badge
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                  ),
                  child: const Center(
                    child: Text('🏰', style: TextStyle(fontSize: 36)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Center(
                child: Text(
                  hurdle.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF2D2620),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'The Final Obstacle of this Cycle • Target: ${hurdle.targetScore.toInt()}%',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF796F65),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Countdown Metric Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF283548)
                      : const Color(0xFFF3ECE0),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCountdownUnit(
                        '${hurdle.daysRemaining}', 'Days Left', const Color(0xFFC2410C)),
                    Container(
                        height: 30,
                        width: 1,
                        color: isDark ? Colors.white24 : Colors.black12),
                    _buildCountdownUnit(
                        '${(hurdle.readiness * 100).toInt()}%', 'Readiness', const Color(0xFF047857)),
                    Container(
                        height: 30,
                        width: 1,
                        color: isDark ? Colors.white24 : Colors.black12),
                    _buildCountdownUnit(
                        '${progress.currentStreak}🔥', 'Streak', const Color(0xFFD97706)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Syllabus Pre-requisites:',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF2D2620),
                ),
              ),
              const SizedBox(height: 8),

              ...progress.nodes.take(3).map((n) {
                final isDone = n.status == NodeStatus.completed;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isDone
                            ? const Color(0xFF047857)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          n.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: isDone
                                ? (isDark ? Colors.white : const Color(0xFF2D2620))
                                : const Color(0xFF9CA3AF),
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 22),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  vm.addXp(50);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '⚡ Diagnostic Practice Test simulated! +50 XP bonus earned!',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700),
                      ),
                      backgroundColor: const Color(0xFFC2410C),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.fitness_center_rounded, size: 20),
                label: Text(
                  'Launch Exam Readiness Drill (+50 XP)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCountdownUnit(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF796F65),
          ),
        ),
      ],
    );
  }

  void _showStreakInfo(BuildContext context, JourneyProgress progress) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              '${progress.currentStreak}-Day Streak!',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Keep your streak alive until your first obstacle (the Midterm Exam in ${progress.hurdle.daysRemaining} days)! Each day you complete at least 1 study session or milestone, the flame stays burning.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showXpInfo(BuildContext context, JourneyProgress progress) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('⚡', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'Study Sparks (${progress.totalXp} XP)',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need ${progress.xpForNextLevel} more XP to reach Level ${progress.level + 1}!',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.levelProgress,
                minHeight: 8,
                backgroundColor: const Color(0xFFE5DDD0),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class _DuolingoNodeItem extends StatelessWidget {
  final JourneyNode node;
  final JourneyNode? nextNode;
  final bool isDark;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;

  const _DuolingoNodeItem({
    required this.node,
    this.nextNode,
    required this.isDark,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Map horizontal offset (-0.6 to 0.6) to fractional alignment
    final alignmentX = node.horizontalOffset;

    return Column(
      children: [
        // Node Widget with optional Duolingo speech bubble
        Align(
          alignment: Alignment(alignmentX, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Duolingo Speech Flag for Active Node
              if (node.status == NodeStatus.active)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2410C),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC2410C).withAlpha(80),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'START',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_downward_rounded,
                          size: 12, color: Colors.white),
                    ],
                  ),
                ),

              // The Stepping Stone Circle
              GestureDetector(
                onTap: onTap,
                child: node.status == NodeStatus.active
                    ? ScaleTransition(
                        scale: pulseAnimation,
                        child: _buildCircleNode(),
                      )
                    : _buildCircleNode(),
              ),

              const SizedBox(height: 6),
              // Node Label
              Container(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  node.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: node.status == NodeStatus.locked
                        ? (isDark ? Colors.white38 : const Color(0xFF9CA3AF))
                        : (isDark ? Colors.white : const Color(0xFF2D2620)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Connector Trail to next node
        if (nextNode != null)
          SizedBox(
            height: 48,
            width: double.infinity,
            child: CustomPaint(
              painter: _TrailConnectorPainter(
                fromX: node.horizontalOffset,
                toX: nextNode!.horizontalOffset,
                isCompleted: node.status == NodeStatus.completed,
                isDark: isDark,
              ),
            ),
          )
        else
          const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCircleNode() {
    final isCompleted = node.status == NodeStatus.completed;
    final isActive = node.status == NodeStatus.active;
    final isLocked = node.status == NodeStatus.locked;

    // Distinct colors per status (Duolingo 3D button feel with thick bottom border)
    Color surfaceColor;
    Color bottomBorderColor;
    IconData iconData;

    if (isCompleted) {
      surfaceColor = const Color(0xFF047857); // Sage Green
      bottomBorderColor = const Color(0xFF064E3B);
      iconData = Icons.check_rounded;
    } else if (isActive) {
      surfaceColor = const Color(0xFFC2410C); // Terracotta
      bottomBorderColor = const Color(0xFF9A3412);
      iconData = Icons.play_arrow_rounded;
    } else {
      surfaceColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
      bottomBorderColor =
          isDark ? const Color(0xFF1E293B) : const Color(0xFF94A3B8);
      iconData = Icons.lock_rounded;
    }

    if (node.type == NodeType.chest) {
      iconData = Icons.card_giftcard_rounded;
    } else if (node.type == NodeType.quiz) {
      iconData = isCompleted ? Icons.check_rounded : Icons.bolt_rounded;
    }

    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        color: surfaceColor,
        shape: BoxShape.circle,
        border: Border(
          bottom: BorderSide(color: bottomBorderColor, width: 5),
          top: BorderSide(
              color: Colors.white.withAlpha(isCompleted || isActive ? 70 : 30),
              width: 2),
          left: BorderSide(
              color: Colors.white.withAlpha(isCompleted || isActive ? 50 : 20),
              width: 1),
          right: BorderSide(
              color: Colors.black.withAlpha(isCompleted || isActive ? 30 : 20),
              width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: surfaceColor.withAlpha(isActive ? 110 : 40),
            blurRadius: isActive ? 14 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          iconData,
          size: 30,
          color: isLocked ? const Color(0xFF64748B) : Colors.white,
        ),
      ),
    );
  }
}

class _TrailConnectorPainter extends CustomPainter {
  final double fromX;
  final double toX;
  final bool isCompleted;
  final bool isDark;

  _TrailConnectorPainter({
    required this.fromX,
    required this.toX,
    required this.isCompleted,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startX = (size.width / 2) + (fromX * (size.width / 2) * 0.7);
    final endX = (size.width / 2) + (toX * (size.width / 2) * 0.7);

    final path = Path();
    path.moveTo(startX, 0);
    path.cubicTo(
      startX,
      size.height * 0.5,
      endX,
      size.height * 0.5,
      endX,
      size.height,
    );

    final paint = Paint()
      ..color = isCompleted
          ? const Color(0xFF047857).withAlpha(120)
          : (isDark ? Colors.white12 : const Color(0xFFE0D5C7))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    // Draw solid or dotted trail
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailConnectorPainter oldDelegate) {
    return oldDelegate.fromX != fromX ||
        oldDelegate.toX != toX ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isDark != isDark;
  }
}
