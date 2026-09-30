import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';


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
    _tabController = TabController(length: 4, vsync: this);
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
              isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                const Text('📊', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Insights & Mastery Hub',
                  style: GoogleFonts.lora(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                  isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              indicatorColor:
                  isDark ? AppColors.darkPrimary : AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Subject Mastery'),
                Tab(text: 'Daily Quiz 🎯'),
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
              _DailyQuizTab(vm: vm, isDark: isDark),
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
// TAB 3: DAILY KNOWLEDGE CHECK MINI-QUIZ
// ==========================================
class _DailyQuizTab extends StatefulWidget {
  final StudyPlannerViewModel vm;
  final bool isDark;

  const _DailyQuizTab({required this.vm, required this.isDark});

  @override
  State<_DailyQuizTab> createState() => _DailyQuizTabState();
}

class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class _DailyQuizTabState extends State<_DailyQuizTab> {
  String _selectedSubject = 'Physics';
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  int _score = 0;
  bool _quizCompleted = false;
  bool _xpAwarded = false;

  static const Map<String, List<_QuizQuestion>> _quizBanks = {
    'Physics': [
      _QuizQuestion(
        question: 'What does Newton\'s Third Law of Motion state?',
        options: [
          'Force equals mass times acceleration',
          'For every action, there is an equal and opposite reaction',
          'Energy cannot be created or destroyed',
          'An object in motion remains in motion unless acted upon',
        ],
        correctIndex: 1,
        explanation:
            'Newton\'s Third Law states that forces always occur in matched pairs: whenever object A exerts a force on B, B exerts an equal and opposite force on A.',
      ),
      _QuizQuestion(
        question: 'What is the SI unit of Electric Potential Difference?',
        options: ['Ampere (A)', 'Joule (J)', 'Volt (V)', 'Ohm (Ω)'],
        correctIndex: 2,
        explanation:
            'Electric potential difference is measured in Volts (V), which represents energy per unit charge: 1 Volt = 1 Joule per Coulomb.',
      ),
      _QuizQuestion(
        question: 'In projectile motion, what happens to the horizontal velocity in the absence of air resistance?',
        options: [
          'It continuously decreases to zero',
          'It accelerates at 9.8 m/s²',
          'It remains constant throughout flight',
          'It doubles at maximum altitude',
        ],
        correctIndex: 2,
        explanation:
            'With no horizontal force acting on the projectile, horizontal acceleration is 0, so horizontal velocity stays completely constant.',
      ),
    ],
    'Maths': [
      _QuizQuestion(
        question: 'What is the derivative of sin(x) with respect to x?',
        options: ['-cos(x)', 'cos(x)', 'tan(x)', 'sec²(x)'],
        correctIndex: 1,
        explanation:
            'The derivative of sin(x) is cos(x). Note that the derivative of cos(x) is -sin(x).',
      ),
      _QuizQuestion(
        question: 'In a right-angled triangle, if legs are of length 3 and 4, what is the hypotenuse?',
        options: ['5', '6', '7', '√7'],
        correctIndex: 0,
        explanation:
            'By Pythagoras: 3² + 4² = 9 + 16 = 25. The square root of 25 is 5.',
      ),
      _QuizQuestion(
        question: 'What is the value of log₁₀(1000)?',
        options: ['1', '2', '3', '10'],
        correctIndex: 2,
        explanation:
            'Since 10³ = 1000, the logarithm base 10 of 1000 is precisely 3.',
      ),
    ],
    'Chemistry': [
      _QuizQuestion(
        question: 'What is the pH of pure neutral water at 25°C?',
        options: ['0', '1', '7', '14'],
        correctIndex: 2,
        explanation:
            'At 25°C, [H⁺] = 10⁻⁷ M, making pH = -log(10⁻⁷) = 7, which denotes exact neutrality.',
      ),
      _QuizQuestion(
        question: 'Which gas is released when dilute hydrochloric acid reacts with zinc metal?',
        options: ['Oxygen', 'Carbon Dioxide', 'Hydrogen', 'Chlorine'],
        correctIndex: 2,
        explanation:
            'Zn + 2HCl → ZnCl₂ + H₂↑. Active metals displace hydrogen from dilute mineral acids.',
      ),
      _QuizQuestion(
        question: 'What type of bond is formed when atoms share electron pairs?',
        options: ['Ionic Bond', 'Covalent Bond', 'Hydrogen Bond', 'Metallic Bond'],
        correctIndex: 1,
        explanation:
            'Covalent bonding involves the mutual sharing of valence electrons between non-metal atoms.',
      ),
    ],
    'Computer Science': [
      _QuizQuestion(
        question: 'What is the worst-case time complexity of Binary Search?',
        options: ['O(1)', 'O(n)', 'O(log n)', 'O(n log n)'],
        correctIndex: 2,
        explanation:
            'Binary Search cuts the search space in half at each step, yielding an O(log n) time complexity.',
      ),
      _QuizQuestion(
        question: 'Which data structure follows the LIFO (Last In First Out) principle?',
        options: ['Queue', 'Stack', 'Linked List', 'Binary Tree'],
        correctIndex: 1,
        explanation:
            'A Stack follows LIFO: elements are pushed and popped strictly from the top.',
      ),
      _QuizQuestion(
        question: 'What is the base of the hexadecimal numbering system?',
        options: ['2', '8', '10', '16'],
        correctIndex: 3,
        explanation:
            'Hexadecimal uses 16 digits: 0–9 followed by A–F.',
      ),
    ],
    'Biology': [
      _QuizQuestion(
        question: 'Which organelle is universally referred to as the powerhouse of the cell?',
        options: ['Nucleus', 'Ribosome', 'Mitochondria', 'Endoplasmic Reticulum'],
        correctIndex: 2,
        explanation:
            'Mitochondria produce the cellular chemical energy currency ATP via aerobic respiration.',
      ),
      _QuizQuestion(
        question: 'What is the primary gas absorbed by green plants during photosynthesis?',
        options: ['Oxygen (O₂)', 'Carbon Dioxide (CO₂)', 'Nitrogen (N₂)', 'Argon (Ar)'],
        correctIndex: 1,
        explanation:
            'Plants absorb CO₂ from the atmosphere through stomata and convert it into glucose during the Calvin Cycle.',
      ),
      _QuizQuestion(
        question: 'Which component in human blood is responsible for transporting oxygen?',
        options: ['Platelets', 'White Blood Cells', 'Hemoglobin in Red Blood Cells', 'Plasma proteins'],
        correctIndex: 2,
        explanation:
            'Hemoglobin molecules inside erythrocytes (RBCs) bind oxygen molecules reversibly in the lungs.',
      ),
    ],
  };

  List<_QuizQuestion> get _currentQuestions {
    return _quizBanks[_selectedSubject] ?? _quizBanks['Physics']!;
  }

  void _resetQuiz([String? newSubject]) {
    setState(() {
      if (newSubject != null) _selectedSubject = newSubject;
      _currentQuestionIndex = 0;
      _selectedOptionIndex = null;
      _score = 0;
      _quizCompleted = false;
      _xpAwarded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final questions = _currentQuestions;
    final currentQ = questions[_currentQuestionIndex];
    final availableSubjects = _quizBanks.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Subject Selector Strip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFFFEF3C7), const Color(0xFFF3ECE0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkSecondary.withAlpha(60) : const Color(0xFFF59E0B).withAlpha(60),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          'Daily Knowledge Check',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '+20 XP Drill',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Solve 3 high-yield questions daily to build crystal-clear conceptual clarity.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Subject Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: availableSubjects.map((subj) {
                      final isSelected = subj == _selectedSubject;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(subj),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) _resetQuiz(subj);
                          },
                          selectedColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : const Color(0xFF4B433B)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Completion Card or Question Card
          if (_quizCompleted)
            _buildCompletionCard(isDark)
          else ...[
            // Progress Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Score: $_score / ${_currentQuestionIndex + (_selectedOptionIndex != null ? 1 : 0)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / questions.length,
                backgroundColor: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),

            // Question Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.borderLight,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentQ.question,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option Tiles
                  ...List.generate(currentQ.options.length, (optIdx) {
                    final optionText = currentQ.options[optIdx];
                    final isAnswered = _selectedOptionIndex != null;
                    final isCorrect = optIdx == currentQ.correctIndex;
                    final isUserPick = optIdx == _selectedOptionIndex;

                    Color tileBorder = isDark ? AppColors.darkBorder : AppColors.borderLight;
                    Color tileBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB);
                    Color textColor = isDark ? Colors.white : const Color(0xFF2D2620);
                    Widget? trailingIcon;

                    if (isAnswered) {
                      if (isCorrect) {
                        tileBorder = const Color(0xFF059669);
                        tileBg = const Color(0xFF059669).withAlpha(isDark ? 35 : 20);
                        trailingIcon = const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF059669), size: 18);
                      } else if (isUserPick) {
                        tileBorder = const Color(0xFFDC2626);
                        tileBg = const Color(0xFFDC2626).withAlpha(isDark ? 35 : 20);
                        trailingIcon = const Icon(Icons.cancel_rounded,
                            color: Color(0xFFDC2626), size: 18);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isAnswered
                            ? null
                            : () {
                                setState(() {
                                  _selectedOptionIndex = optIdx;
                                  if (optIdx == currentQ.correctIndex) {
                                    _score++;
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: tileBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: tileBorder, width: isAnswered && (isCorrect || isUserPick) ? 1.8 : 1.1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isAnswered && isCorrect
                                      ? const Color(0xFF059669)
                                      : (isAnswered && isUserPick
                                          ? const Color(0xFFDC2626)
                                          : (isDark ? Colors.white12 : Colors.black12)),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + optIdx),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isAnswered && (isCorrect || isUserPick) ? Colors.white : textColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              ?trailingIcon,
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  // Explanation Insight
                  if (_selectedOptionIndex != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF047857).withAlpha(40)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              currentQ.explanation,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                height: 1.4,
                                color: isDark ? Colors.white70 : const Color(0xFF2D2620),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentQuestionIndex + 1 < questions.length) {
                            setState(() {
                              _currentQuestionIndex++;
                              _selectedOptionIndex = null;
                            });
                          } else {
                            setState(() {
                              _quizCompleted = true;
                            });
                            if (!_xpAwarded) {
                              _xpAwarded = true;
                              widget.vm.addXp(20);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _currentQuestionIndex + 1 < questions.length
                              ? 'Next Question →'
                              : 'Finish Quiz & Claim +20 XP 🏆',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF059669), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Center(child: Text('🏆', style: TextStyle(fontSize: 48))),
          const SizedBox(height: 12),
          Text(
            'Drill Completed!',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You scored $_score / ${_currentQuestions.length} on $_selectedSubject concepts.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Text(
                  '+20 XP Credited to your Profile!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resetQuiz(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Retry Same Subject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final keys = _quizBanks.keys.toList();
                    final nextIdx = (keys.indexOf(_selectedSubject) + 1) % keys.length;
                    _resetQuiz(keys[nextIdx]);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Try Another Subject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// TAB 4: AI STUDY COACH & EXAM READINESS
// ==========================================
class _AICoachTab extends StatelessWidget {
  final StudyPlannerViewModel vm;
  final bool isDark;
  const _AICoachTab({required this.vm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final hurdles = vm.journeyProgress.sortedHurdles;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Coach Introduction Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF312E81), const Color(0xFF0F172A)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkPrimary.withAlpha(60) : const Color(0xFF6366F1).withAlpha(60),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimary.withAlpha(30) : const Color(0xFF6366F1).withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Study Diagnostics',
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Real-time exam hurdle analysis & personalized cognitive retention recommendations.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Exam Readiness Index Cards
          Text(
            'Exam Hurdle Readiness Index',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          if (hurdles.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No exam hurdles scheduled yet. Add an exam hurdle from the Quest page or Home schedule wizard to see readiness forecasts.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
            )
          else
            ...hurdles.map((hurdle) {
              final days = hurdle.daysRemaining;
              final isUrgent = days <= 2;
              final readinessPct = (hurdle.readiness * 100).toInt();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isUrgent
                        ? const Color(0xFFEF4444)
                        : (isDark ? AppColors.darkBorder : AppColors.borderLight),
                    width: isUrgent ? 1.8 : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUrgent
                          ? const Color(0xFFEF4444).withAlpha(15)
                          : Colors.black.withAlpha(isDark ? 20 : 5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(isUrgent ? '🚨' : '🏰', style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              hurdle.subjectName,
                              style: GoogleFonts.lora(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isUrgent
                                ? const Color(0xFFEF4444).withAlpha(20)
                                : const Color(0xFF059669).withAlpha(20),
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
                          'Readiness: $readinessPct%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          ),
                        ),
                        Text(
                          'Target: ${hurdle.targetScore.toInt()}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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
                    const SizedBox(height: 10),
                    Text(
                      isUrgent
                          ? '🔥 Emergency Advice: Stop reading new chapters. Solve 2 full-length past papers and test all formulas.'
                          : '💡 Recommended Next Step: Conquer 2 more learning units in Quest to boost readiness to 90%.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : const Color(0xFF4B433B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 20),

          // High Yield Study Tactics Card
          Text(
            'High-Yield Cognitive Techniques',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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

  Widget _buildTacticCard({
    required String emoji,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderLight,
          width: 1.1,
        ),
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
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
