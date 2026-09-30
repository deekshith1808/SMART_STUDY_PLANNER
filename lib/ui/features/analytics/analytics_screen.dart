import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF030712) : AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Insights & AI Coach',
                  style: GoogleFonts.lora(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              labelColor: isDark ? AppColors.darkPrimary : AppColors.primary,
              unselectedLabelColor:
                  isDark ? Colors.white60 : AppColors.textSecondary,
              indicatorColor:
                  isDark ? AppColors.darkPrimary : AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Subject Mastery'),
                Tab(text: 'AI Study Coach 🤖'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(vm: vm, isDark: isDark),
              _SubjectMasteryTab(
                vm: vm,
                isDark: isDark,
                onNavigateToTimer: () => vm.setTabIndex(2),
              ),
              _AICoachTab(vm: vm, isDark: isDark),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// TAB 1: OVERVIEW & RHYTHM
// ==========================================
class _OverviewTab extends StatelessWidget {
  final StudyPlannerViewModel vm;
  final bool isDark;
  const _OverviewTab({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final totalTasks = vm.tasks.length;
    final completedTasks = vm.tasks.where((t) => t.isCompleted).length;
    final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final totalMinutes =
        vm.sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final avgSession =
        vm.sessions.isEmpty ? 0 : totalMinutes ~/ vm.sessions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 Highlight Cards
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.32,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _AnalyticsCard(
                icon: '⏱️',
                label: 'Total Focus Hours',
                value: '${totalMinutes ~/ 60}h ${totalMinutes % 60}m',
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                bg: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                isDark: isDark,
              ),
              _AnalyticsCard(
                icon: '✅',
                label: 'Tasks Completed',
                value: '$completedTasks of $totalTasks',
                color: isDark ? const Color(0xFF34D399) : AppColors.secondary,
                bg: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                isDark: isDark,
              ),
              _AnalyticsCard(
                icon: '🔥',
                label: 'Pomodoro Cycles',
                value:
                    '${vm.sessions.where((s) => s.sessionType == 'pomodoro').length}',
                color: isDark ? const Color(0xFFFB923C) : AppColors.accent,
                bg: isDark ? const Color(0xFF451A03) : const Color(0xFFFFEDD5),
                isDark: isDark,
              ),
              _AnalyticsCard(
                icon: '⚡',
                label: 'Avg Session Length',
                value: '${avgSession}m',
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                bg: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE),
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Goal Completion Progress Card
          Text(
            'Goal Completion Rate',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(completionRate * 100).toStringAsFixed(0)}% Finished',
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$completedTasks done / $totalTasks total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionRate,
                    backgroundColor: isDark ? Colors.white12 : AppColors.secondary.withAlpha(25),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDark ? const Color(0xFF34D399) : AppColors.secondary,
                    ),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Weekly Rhythm Bar Chart
          Text(
            'Weekly Rhythm (Last 7 Days)',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 210,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                width: 1.2,
              ),
            ),
            child: _WeeklyBarChart(vm: vm, isDark: isDark),
          ),
          const SizedBox(height: 20),

          // Peak Focus Hours & Momentum
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1B4B).withAlpha(80)
                  : const Color(0xFFFEF3C7).withAlpha(50),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkSecondary.withAlpha(80) : const Color(0xFFF59E0B).withAlpha(80),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSecondary.withAlpha(40) : const Color(0xFFF59E0B).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🧠', style: TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peak Retention Window',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Your highest concentration sessions happen in the evening. Schedule difficult problem sets between 6:00 PM – 9:00 PM.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          height: 1.4,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 2: SUBJECT MASTERY & KNOWLEDGE RADAR
// ==========================================
class _SubjectMasteryTab extends StatefulWidget {
  final StudyPlannerViewModel vm;
  final bool isDark;
  final VoidCallback onNavigateToTimer;

  const _SubjectMasteryTab({
    required this.vm,
    required this.isDark,
    required this.onNavigateToTimer,
  });

  @override
  State<_SubjectMasteryTab> createState() => _SubjectMasteryTabState();
}

class _SubjectMasteryTabState extends State<_SubjectMasteryTab> {
  String? _expandedSubjectName;

  static const Map<String, List<String>> _subjectFormulas = {
    'physics': [
      '⚡ Newton\'s Second Law: F = m · a',
      '🔋 Kinetic Energy: KE = ½ · m · v²',
      '💡 Ohm\'s Law: V = I · R  (Power: P = V · I)',
      '🎯 Work-Energy: W = F · d · cos(θ)',
    ],
    'math': [
      '📐 Quadratic Formula: x = (-b ± √(b² - 4ac)) / (2a)',
      '📊 Derivative of sin(x) = cos(x) | cos(x) = -sin(x)',
      '📏 Pythagorean Theorem: a² + b² = c²',
      '🎲 Probability: P(A ∪ B) = P(A) + P(B) - P(A ∩ B)',
    ],
    'maths': [
      '📐 Quadratic Formula: x = (-b ± √(b² - 4ac)) / (2a)',
      '📊 Derivative of sin(x) = cos(x) | cos(x) = -sin(x)',
      '📏 Pythagorean Theorem: a² + b² = c²',
      '🎲 Probability: P(A ∪ B) = P(A) + P(B) - P(A ∩ B)',
    ],
    'chemistry': [
      '🧪 Ideal Gas Equation: P · V = n · R · T',
      '💧 Molarity (M): moles of solute / liters of solution',
      '⚖️ pH Definition: pH = -log₁₀[H⁺]',
      '🔥 Enthalpy Change: ΔH = ΔU + P · ΔV',
    ],
    'computer science': [
      '⚡ Binary Search: Time Complexity O(log n)',
      '📚 Stack: LIFO (Last In First Out) | Queue: FIFO',
      '🌲 Binary Search Tree: Left < Root < Right',
      '🔄 Recursion: Base case + recursive leap of faith',
    ],
    'biology': [
      '🧬 DNA Base Pairs: Adenine-Thymine (A-T), Guanine-Cytosine (G-C)',
      '🌿 Photosynthesis: 6CO₂ + 6H₂O + light → C₆H₁₂O₆ + 6O₂',
      '⚡ Cellular Respiration: Glycolysis → Krebs Cycle → ETC',
      '🔬 Mitochondria: ATP synthase cellular powerhouse',
    ],
  };

  List<String> _getFormulasForSubject(String subjectName) {
    final lower = subjectName.toLowerCase();
    for (final entry in _subjectFormulas.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return [
      '🧠 Active Recall: Test yourself with closed books',
      '⏳ Spaced Repetition: Review at 1d, 3d, 7d intervals',
      '📝 Feynman Technique: Teach concepts in simple terms',
      '⏱️ Pomodoro: 25 minutes laser focus, 5 min rest',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.vm.profile?.subjects ?? [];
    final isDark = widget.isDark;

    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No subjects enrolled yet',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add subjects from Home or Settings to unlock subject mastery cards.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final sections = subjects.asMap().entries.map((e) {
      final color = _colorFromHex(e.value.color);
      return PieChartSectionData(
        color: color,
        value: e.value.marks > 0 ? e.value.marks : 1,
        title: '${e.value.marks.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: GoogleFonts.lora(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      );
    }).toList();

    final sortedSubjects = [...subjects]..sort((a, b) => b.marks.compareTo(a.marks));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distribution Pie Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subject Score Distribution',
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sections: sections,
                            sectionsSpace: 3,
                            centerSpaceRadius: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: subjects.asMap().entries.map((e) {
                            final color = _colorFromHex(e.value.color);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    e.value.name,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Interactive Subject Knowledge Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interactive Subject Mastery',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                'Tap for Key Formulas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...sortedSubjects.asMap().entries.map((e) {
            final rank = e.key + 1;
            final subject = e.value;
            final color = _colorFromHex(subject.color);
            final rankEmoji = rank == 1
                ? '🥇'
                : rank == 2
                    ? '🥈'
                    : rank == 3
                        ? '🥉'
                        : '📖';
            final isExpanded = _expandedSubjectName == subject.name;
            final formulas = _getFormulasForSubject(subject.name);
            final progressFraction = subject.targetMarks > 0
                ? (subject.marks / subject.targetMarks).clamp(0.0, 1.0)
                : 0.5;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isExpanded ? color : color.withAlpha(isDark ? 60 : 70),
                  width: isExpanded ? 1.8 : 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    setState(() {
                      if (_expandedSubjectName == subject.name) {
                        _expandedSubjectName = null;
                      } else {
                        _expandedSubjectName = subject.name;
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Text(rankEmoji, style: const TextStyle(fontSize: 22)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject.name,
                                    style: GoogleFonts.lora(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${subject.studyHours}h logged • Target: ${subject.targetMarks.toInt()}%',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${subject.marks.toStringAsFixed(1)}%',
                                  style: GoogleFonts.lora(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Progress Bar to Target
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            backgroundColor: isDark
                                ? Colors.white12
                                : color.withAlpha(25),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 7,
                          ),
                        ),

                        // Expandable Formula / Knowledge Cheat Sheet
                        if (isExpanded) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : color.withAlpha(15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withAlpha(50),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('💡', style: TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'KEY KNOWLEDGE DRILLS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...formulas.map((f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        f,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white.withAlpha(220)
                                              : const Color(0xFF2D2620),
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: widget.onNavigateToTimer,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.timer_outlined,
                                          size: 14),
                                      label: Text(
                                        'Start Focus Timer',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 3: ENHANCED AI STUDY COACH & PREDICTIVE RADAR
// ==========================================
class _AICoachTab extends StatefulWidget {
  final StudyPlannerViewModel vm;
  final bool isDark;
  const _AICoachTab({required this.vm, required this.isDark});

  @override
  State<_AICoachTab> createState() => _AICoachTabState();
}

class _AICoachTabState extends State<_AICoachTab> {
  String _selectedStrategy = 'Sprint'; // 'Sprint', 'Mastery', 'Weakness'
  String _selectedTopicExplainer = "Newton's 3rd Law";

  static const Map<String, Map<String, String>> _conceptExplanations = {
    "Newton's 3rd Law": {
      "subject": "Physics",
      "summary": "Every action has an equal & opposite reaction.",
      "feynman": "When you push against a wall with 50N of force, the wall pushes back against your hands with exactly 50N in the opposite direction. Forces always come in matched interaction pairs!",
      "examTip": "Never draw action-reaction pairs on the same free-body diagram—they act on two different bodies!",
    },
    "Binary Search & O(log n)": {
      "subject": "Computer Science",
      "summary": "Divide-and-conquer search on sorted collections.",
      "feynman": "Think of guessing a secret number from 1 to 100. Guess 50 first. If too high, search 1 to 49. By cutting the search space in half each step, even 1,000,000 items takes only 20 comparisons!",
      "examTip": "Array MUST be sorted. Corner cases: empty array, single element, duplicates, and integer overflow with (low + high) / 2.",
    },
    "Mitochondria & ATP": {
      "subject": "Biology",
      "summary": "Cellular respiration & energy synthesis.",
      "feynman": "Mitochondria are the rechargeable batteries of cells. They take digested glucose + oxygen and recharge ADP into ATP (the cellular currency that powers muscle contraction & brain signals).",
      "examTip": "Occurs in inner mitochondrial membrane (cristae) with ATP synthase. Produces ~30-32 ATP per glucose molecule.",
    },
    "Integration by Parts": {
      "subject": "Mathematics",
      "summary": "Reverse product rule: ∫ u dv = u v - ∫ v du.",
      "feynman": "When integrating two functions multiplied together (like x · sin(x)), let u be the one that becomes simpler when differentiated, and dv be the one easy to integrate.",
      "examTip": "Remember the LIATE acronym for picking 'u': Logarithmic, Inverse trig, Algebraic, Trigonometric, Exponential.",
    },
    "Acid-Base Neutralization": {
      "subject": "Chemistry",
      "summary": "H⁺(aq) + OH⁻(aq) → H₂O(l) with salt formation.",
      "feynman": "An acid is like an eager proton donor (H⁺), and a base is a proton receiver (OH⁻). When mixed, they neutralize into harmless water and salt, releasing heat (exothermic).",
      "examTip": "Equivalence point pH is 7 ONLY for strong acid + strong base. Strong acid + weak base yields acidic pH < 7.",
    },
  };

  void _generateRevisionPlan(String subjectName) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final tasks = [
      ScheduledTask(
        id: 'ai_task_${DateTime.now().millisecondsSinceEpoch}_1',
        title: '[$subjectName] Formula & Definition Recall',
        subjectId: 'ai_sub_$subjectName',
        subjectName: subjectName,
        scheduledDate: today,
        startTime: '09:00',
        endTime: '09:30',
        isCompleted: false,
        priority: 'high',
        description: 'AI Coach revision sprint',
      ),
      ScheduledTask(
        id: 'ai_task_${DateTime.now().millisecondsSinceEpoch}_2',
        title: '[$subjectName] Solve 5 High-Yield Exam Problems',
        subjectId: 'ai_sub_$subjectName',
        subjectName: subjectName,
        scheduledDate: today.add(const Duration(days: 1)),
        startTime: '10:00',
        endTime: '10:45',
        isCompleted: false,
        priority: 'high',
        description: 'AI Coach revision drill',
      ),
      ScheduledTask(
        id: 'ai_task_${DateTime.now().millisecondsSinceEpoch}_3',
        title: '[$subjectName] Feynman 5-Minute Blind Explanation Drill',
        subjectId: 'ai_sub_$subjectName',
        subjectName: subjectName,
        scheduledDate: today.add(const Duration(days: 2)),
        startTime: '11:00',
        endTime: '11:20',
        isCompleted: false,
        priority: 'medium',
        description: 'AI Coach recall drill',
      ),
    ];

    for (final task in tasks) {
      await widget.vm.addTask(task);
    }
    await widget.vm.addXp(15);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '✨ Generated 3 custom AI revision tasks for $subjectName! +15 XP awarded.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final hurdles = widget.vm.journeyProgress.sortedHurdles;
    final activeHurdle = widget.vm.journeyProgress.activeHurdle;
    final totalFocusHours = widget.vm.sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes) / 60.0;
    final readinessPct = activeHurdle != null ? (activeHurdle.readiness * 100).toInt() : 80;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Coach Banner with Glassmorphism
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppColors.glassCardDecoration(
              isDark: isDark,
              borderRadius: 24,
              borderColor: isDark ? AppColors.darkBorderAccent.withAlpha(80) : const Color(0xFF6366F1).withAlpha(80),
              glowColor: isDark ? AppColors.darkSecondary.withAlpha(40) : const Color(0xFF6366F1).withAlpha(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkPrimary.withAlpha(35)
                                  : const Color(0xFF6366F1).withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🤖', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Cognitive Study Coach',
                                  style: GoogleFonts.lora(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Autonomous Syllabus & Exam Intelligence',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkPrimary : const Color(0xFF6366F1),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ONLINE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Based on ${totalFocusHours.toStringAsFixed(1)}h logged study time and ${widget.vm.journeyProgress.succeededLevelsCount} completed quest levels, your overall exam readiness index is $readinessPct%.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? Colors.white70 : const Color(0xFF4B433B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Strategy Selector Pills
          Text(
            'Active AI Preparation Strategy',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStrategyChip('Sprint', '⚡ 3-Day Sprint', isDark),
              const SizedBox(width: 8),
              _buildStrategyChip('Mastery', '🧠 Deep Mastery', isDark),
              const SizedBox(width: 8),
              _buildStrategyChip('Weakness', '🎯 Attack Weakness', isDark),
            ],
          ),
          const SizedBox(height: 14),

          // Strategy Directive Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x331E1B4B) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorderAccent.withAlpha(50) : const Color(0xFFBAE6FD),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedStrategy == 'Sprint'
                        ? 'Sprint Protocol: Focus 80% of study blocks on formula memory, past exam patterns, and closed-book retrieval. Avoid reading textbook chapters from scratch.'
                        : _selectedStrategy == 'Mastery'
                            ? 'Deep Mastery Protocol: Connect every formula to its underlying first principles. Use the Feynman technique to teach every concept out loud.'
                            : 'Weakness Attack Protocol: Target subjects with lowest recorded marks. Spend your first 45 minutes of each day tackling only your most avoided topics.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      height: 1.45,
                      color: isDark ? Colors.white70 : const Color(0xFF0369A1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Predictive Exam Hurdles & One-Tap Revision Plan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Predictive Exam Radar',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                '${hurdles.length} Registered',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (hurdles.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppColors.glassCardDecoration(isDark: isDark),
              child: Center(
                child: Text(
                  'No exam hurdles configured yet. Add them in the Quest or Subjects tab!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...hurdles.map((hurdle) {
              final isUrgent = hurdle.daysRemaining <= 3 && hurdle.daysRemaining >= 0;
              final hurdlePct = (hurdle.readiness * 100).toInt();

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: AppColors.glassCardDecoration(
                  isDark: isDark,
                  borderRadius: 20,
                  borderColor: isUrgent
                      ? const Color(0xFFEF4444).withAlpha(120)
                      : (isDark ? AppColors.darkBorderAccent.withAlpha(60) : null),
                  glowColor: isUrgent
                      ? const Color(0xFFEF4444).withAlpha(35)
                      : (isDark ? AppColors.darkSecondary.withAlpha(25) : null),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(isUrgent ? '🚨' : '🏰', style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              hurdle.subjectName,
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUrgent
                                ? const Color(0xFFEF4444).withAlpha(25)
                                : const Color(0xFF059669).withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF059669),
                            ),
                          ),
                          child: Text(
                            hurdle.daysRemainingText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Forecasted Readiness: $hurdlePct%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                        Text(
                          'Exam Goal: ${hurdle.targetScore.toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: hurdle.readiness,
                        backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isUrgent ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _generateRevisionPlan(hurdle.subjectName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.darkSecondary : const Color(0xFFC2410C),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: Text(
                        'Generate 3-Step AI Revision Plan (+15 XP)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 24),

          // Interactive AI Concept Explainer / Feynman Drill
          Text(
            'Interactive Concept Deep-Dive 🧠',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap a core concept or test your understanding with instant Feynman explanations:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Concept Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _conceptExplanations.keys.map((title) {
                final isSelected = title == _selectedTopicExplainer;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(title),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedTopicExplainer = title);
                    },
                    selectedColor: isDark ? AppColors.darkSecondary : AppColors.primary,
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF4B433B)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Explainer Result Card
          Builder(
            builder: (context) {
              final details = _conceptExplanations[_selectedTopicExplainer] ??
                  _conceptExplanations.values.first;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: AppColors.glassCardDecoration(
                  isDark: isDark,
                  borderRadius: 20,
                  borderColor: isDark ? AppColors.darkBorderAccent.withAlpha(70) : null,
                  glowColor: isDark ? AppColors.darkSecondary.withAlpha(25) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTopicExplainer,
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.darkPrimary : AppColors.primary).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            details['subject']!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '🗣️ The 10-Year-Old Explanation:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details['feynman']!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.45,
                        color: isDark ? Colors.white70 : const Color(0xFF2D2620),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD97706).withAlpha(40)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Exam Trap & Pro-Tip: ${details['examTip']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                              ),
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

          // High Yield Study Tactics Card
          Text(
            'High-Yield Cognitive Techniques',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          _buildTacticCard(
            emoji: '🔁',
            title: 'Spaced Retrieval Practice',
            description:
                'Review material 24 hours after learning, then 3 days, then 7 days. This locks information into long-term hippocampus memory.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildTacticCard(
            emoji: '🗣️',
            title: 'The Feynman Explanation Drill',
            description:
                'Pretend you are explaining the topic to a 10-year-old without jargon. Where you get stuck reveals your exact conceptual blind spot.',
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildTacticCard(
            emoji: '⏱️',
            title: '25/5 Pomodoro Cycle with Closed Books',
            description:
                'Spend 20 minutes studying, and the final 5 minutes writing down everything remembered from memory on a blank sheet.',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyChip(String id, String label, bool isDark) {
    final isSelected = _selectedStrategy == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStrategy = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkSecondary : AppColors.primary)
                : (isDark ? const Color(0xFF1E2835) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? (isDark ? AppColors.darkBorderAccent : AppColors.primary)
                  : (isDark ? Colors.white12 : AppColors.borderLight),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: (isDark ? AppColors.darkSecondary : AppColors.primary).withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTacticCard({
    required String emoji,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.glassCardDecoration(
        isDark: isDark,
        borderRadius: 16,
        borderColor: isDark ? AppColors.darkBorder : AppColors.borderLight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    height: 1.4,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ==========================================
// SHARED WIDGETS
// ==========================================
class _WeeklyBarChart extends StatelessWidget {
  final StudyPlannerViewModel vm;
  final bool isDark;
  const _WeeklyBarChart({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final bars = days.map((day) {
      final minutes = vm.sessions
          .where((s) =>
              s.startTime.year == day.year &&
              s.startTime.month == day.month &&
              s.startTime.day == day.day)
          .fold<int>(0, (sum, s) => sum + s.durationMinutes);
      return minutes / 60.0;
    }).toList();

    final maxY = bars.reduce((a, b) => a > b ? a : b);
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BarChart(
      BarChartData(
        maxY: maxY > 0 ? maxY + 1 : 5,
        barGroups: List.generate(7, (i) {
          final isToday = days[i].day == now.day;
          final barColor = isToday
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isDark
                  ? AppColors.darkPrimary.withAlpha(70)
                  : AppColors.primary.withAlpha(70));
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: bars[i],
                color: barColor,
                width: 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  dayLabels[value.toInt() % 7],
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final bool isDark;

  const _AnalyticsCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.lora(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _colorFromHex(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}
