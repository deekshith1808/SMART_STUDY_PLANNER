import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/ui/features/pomodoro/pomodoro_screen.dart';
import 'package:smart_study_planner/ui/features/journey/journey_screen.dart';
import 'package:smart_study_planner/ui/features/subjects/subjects_screen.dart';
import 'package:smart_study_planner/ui/features/schedule/schedule_screen.dart';
import 'package:smart_study_planner/ui/features/analytics/analytics_screen.dart';
import 'package:smart_study_planner/ui/features/settings/settings_screen.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';
import 'package:smart_study_planner/ui/features/auth/supabase_sync_sheet.dart';
import 'package:smart_study_planner/ui/features/parental/parent_dashboard_screen.dart';
import 'package:smart_study_planner/ui/features/parental/exam_lockdown_overlay.dart';
import 'package:smart_study_planner/ui/features/parental/parent_nudge_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = context.read<StudyPlannerViewModel>();
        ParentNudgeDialog.showIfAvailable(context, vm);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;
    final vm = context.read<StudyPlannerViewModel>();
    if (state == AppLifecycleState.paused) {
      if (vm.isExamLockdownActive || vm.isCurrentlyStudying) {
        final reason = vm.isExamLockdownActive
            ? 'Child minimized study app during Exam Lockdown'
            : 'Left study app during active focus session';
        vm.recordDistractionBreach(
          reason: reason,
          subject: vm.liveCurrentSubject ?? 'Active Study',
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      ParentNudgeDialog.showIfAvailable(context, vm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();
        final pages = [
          const _DashboardTab(),
          const JourneyScreen(),
          const PomodoroScreen(),
          const SubjectsScreen(),
          const ScheduleScreen(),
          const AnalyticsScreen(),
        ];

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
          body: Column(
            children: [
              const ExamLockdownBanner(),
              Expanded(
                child: IndexedStack(
                  index: vm.selectedTabIndex,
                  children: pages,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: vm.selectedTabIndex,
            onTap: vm.setTabIndex,
          ),
          floatingActionButton: vm.selectedTabIndex == 0
              ? FloatingActionButton.extended(
                  onPressed: () => _showQuickActions(context),
                  backgroundColor: AppColors.primary,
                  elevation: 3,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: Text(
                    'Quick Add',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QuickActionsSheet(),
    );
  }
}

class _QuickActionsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(Icons.explore_rounded, 'Study Quest', const Color(0xFFC2410C), () {
        Navigator.pop(context);
        context.read<StudyPlannerViewModel>().setTabIndex(1);
      }),
      _QuickAction(Icons.timer_outlined, 'Pomodoro', AppColors.primary, () {
        Navigator.pop(context);
        context.read<StudyPlannerViewModel>().setTabIndex(2);
      }),
      _QuickAction(Icons.calendar_today_rounded, 'Add Task', AppColors.secondary, () {
        Navigator.pop(context);
        context.read<StudyPlannerViewModel>().setTabIndex(4);
      }),
      _QuickAction(Icons.sticky_note_2_outlined, 'Quick Note', AppColors.accent, () {
        Navigator.pop(context);
        showDialog(context: context, builder: (_) => _QuickNoteDialog());
      }),
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Quick Actions',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('✨ Fast', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions.map((a) => _QuickActionButton(action: a)).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: action.color.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: action.color.withAlpha(60), width: 1.2),
            ),
            child: Icon(action.icon, color: action.color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _QuickNoteDialog extends StatefulWidget {
  const _QuickNoteDialog();

  @override
  State<_QuickNoteDialog> createState() => _QuickNoteDialogState();
}

class _QuickNoteDialogState extends State<_QuickNoteDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _contentCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<StudyPlannerViewModel>();
    final subjects = vm.profile?.subjects ?? [];
    if (_selectedSubjectId == null && subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
      _selectedSubjectName = subjects.first.name;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('📌', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Text(
            'Quick Sticky Note',
            style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subjects.isNotEmpty) ...[
              Text(
                'Subject Tag',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('General / Miscellaneous')),
                  ...subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedSubjectId = val;
                    if (val == null || val.isEmpty) {
                      _selectedSubjectName = 'General';
                    } else {
                      final found = subjects.firstWhere((s) => s.id == val, orElse: () => subjects.first);
                      _selectedSubjectName = found.name;
                    }
                  });
                },
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'Note title (e.g. Formula recall)',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write your thought, insight or reminder...',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.accent),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.isNotEmpty) {
              final note = QuickNote(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleCtrl.text.trim(),
                content: _contentCtrl.text.trim(),
                subjectId: _selectedSubjectId ?? '',
                subjectName: _selectedSubjectName ?? 'General',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              vm.addNote(note);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Pin Note 📌'),
        ),
      ],
    );
  }
}

// ─── Dashboard Tab ───────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<StudyPlannerViewModel>();
    final profile = vm.profile;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 164,
          floating: false,
          pinned: true,
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [
                          Color(0xFF1E1B4B), // Deep Indigo / Purple
                          Color(0xFF030712), // OLED Midnight Black
                        ]
                      : const [
                          Color(0xFFC2410C), // Warm Terracotta
                          Color(0xFF9A3412), // Deep Sienna Clay
                        ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(40),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _greeting(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                profile?.name ?? 'Mindful Student',
                                style: GoogleFonts.lora(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.sticky_note_2_outlined, color: Colors.white, size: 20),
                                  onPressed: () => showDialog(context: context, builder: (_) => _NotesOverlay()),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  tooltip: 'Supabase Cloud Sync',
                                  icon: const Icon(Icons.cloud_sync_outlined, color: Colors.white, size: 20),
                                  onPressed: () => SupabaseSyncSheet.show(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (vm.isParentDevice) ...[
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(35),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Parent App Controller',
                                    icon: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                                    onPressed: () => ParentDashboardScreen.open(context),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                                  onPressed: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                    ),
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Duolingo Exam Quest Hurdle Banner & Urgent Alert
                _ExamJourneyBanner(vm: vm),
                const SizedBox(height: 14),
                // Upcoming Exam Schedule & Wizard Strip
                _UpcomingExamsStrip(vm: vm),
                const SizedBox(height: 20),
                // Quick stats row
                _StatsRow(vm: vm),
                const SizedBox(height: 24),
                // Prominent Sticky Notes Pinboard
                _StickyNotesPinboardSection(vm: vm),
                const SizedBox(height: 24),
                // Subjects quick view
                _SubjectCardsSection(vm: vm),
                const SizedBox(height: 24),
                // Today's tasks
                _TodayTasksSection(vm: vm),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }
}

class _ExamJourneyBanner extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _ExamJourneyBanner({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = vm.journeyProgress;
    final hurdle = progress.hurdle;
    final isUrgent = hurdle.daysRemaining <= 2;

    final bannerColors = isDark
        ? (isUrgent
            ? const [Color(0xEE7F1D1D), Color(0xEE1E1B4B)]
            : const [Color(0xEE2E1065), Color(0xEE0F172A)])
        : (isUrgent
            ? const [Color(0xFFB91C1C), Color(0xFF991B1B)]
            : const [Color(0xFFC2410C), Color(0xFF9A3412)]);

    final bannerBorder = isDark
        ? Border.all(
            color: isUrgent ? const Color(0xFFEF4444) : const Color(0xFFA855F7),
            width: 1.2,
          )
        : null;

    final glowColor = isDark
        ? (isUrgent ? const Color(0x40EF4444) : const Color(0x408B5CF6))
        : (isUrgent ? const Color(0xFFB91C1C) : const Color(0xFFC2410C)).withAlpha(90);

    return GestureDetector(
      onTap: () => vm.setTabIndex(1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bannerColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: bannerBorder,
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isUrgent ? 55 : 40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(isUrgent ? '🚨' : '🎯', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        isUrgent
                            ? 'EXAM ${hurdle.daysRemaining == 0 ? "TODAY" : hurdle.daysRemaining == 1 ? "TOMORROW" : "IN 2 DAYS"}: ${hurdle.subjectName.toUpperCase()}'
                            : 'NEXT HURDLE: ${hurdle.daysRemaining} DAYS LEFT',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '${progress.currentStreak}d Streak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hurdle.title,
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hurdle.subjectName} • Target: ${hurdle.targetScore.toInt()}% • Level ${progress.level} • ${hurdle.completedNodes}/${hurdle.requiredNodes} Done • ${progress.totalXp} XP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: Colors.white.withAlpha(230),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: hurdle.readiness,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFEF08A)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingExamsStrip extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _UpcomingExamsStrip({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hurdles = vm.journeyProgress.sortedHurdles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('📅', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Upcoming Exam Schedule',
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => _ExamScheduleWizardDialog(vm: vm),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      'Add Exam',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hurdles.isEmpty)
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => _ExamScheduleWizardDialog(vm: vm),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: isDark
                  ? AppColors.glassCardDecoration(
                      isDark: true,
                      borderColor: const Color(0x338B5CF6),
                      borderRadius: 14,
                    )
                  : BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
              child: Row(
                children: [
                  Icon(Icons.event_note_rounded, size: 18, color: isDark ? AppColors.darkPrimary : AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No exam dates set yet. Tap to add your exam schedule!',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hurdles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final hurdle = hurdles[i];
                final isUrgent = hurdle.daysRemaining <= 2;
                final bg = isDark
                    ? (isUrgent ? const Color(0x40B91C1C) : const Color(0x401E1B4B))
                    : (isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));
                final border = isDark
                    ? (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF8B5CF6))
                    : (isUrgent ? const Color(0xFFF87171) : const Color(0xFFFCD34D));
                final textColor = isDark
                    ? (isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFDDD6FE))
                    : (isUrgent ? const Color(0xFF991B1B) : const Color(0xFF92400E));

                return GestureDetector(
                  onTap: () => _showHurdleQuickOptions(context, hurdle),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isUrgent ? '🚨' : '🎯', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hurdle.subjectName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${hurdle.formattedExamDate} (${hurdle.daysRemainingText})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: textColor.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showHurdleQuickOptions(BuildContext context, ExamHurdle hurdle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hurdle.title,
                        style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${hurdle.subjectName} • Exam on ${hurdle.formattedExamDate} (${hurdle.daysRemainingText})',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.explore_rounded, color: Color(0xFFC2410C)),
              title: Text('View in Quest Journey', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              subtitle: const Text('Conquer prerequisite topic levels for this hurdle'),
              onTap: () {
                Navigator.pop(ctx);
                vm.setTabIndex(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined, color: AppColors.primary),
              title: Text('Launch Focus Timer for ${hurdle.subjectName}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              subtitle: const Text('Start an immediate Pomodoro session'),
              onTap: () {
                Navigator.pop(ctx);
                vm.setTabIndex(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Delete Hurdle', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(ctx);
                await vm.deleteExamHurdle(hurdle.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamScheduleWizardDialog extends StatefulWidget {
  final StudyPlannerViewModel vm;
  const _ExamScheduleWizardDialog({required this.vm});

  @override
  State<_ExamScheduleWizardDialog> createState() => _ExamScheduleWizardDialogState();
}

class _ExamScheduleWizardDialogState extends State<_ExamScheduleWizardDialog> {
  final _titleCtrl = TextEditingController();
  final _customSubjectCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedSubject;
  bool _isCustom = false;
  double _targetScore = 95.0;
  bool _createStudyTask = true;

  @override
  void initState() {
    super.initState();
    final subjects = widget.vm.profile?.subjects ?? [];
    if (subjects.isNotEmpty) {
      _selectedSubject = subjects.first.name;
      _titleCtrl.text = '${subjects.first.name} Final Exam';
    } else {
      _isCustom = true;
      _titleCtrl.text = 'Semester Final Exam';
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _customSubjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.vm.profile?.subjects ?? [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFC2410C).withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('🎯', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Exam Hurdle', style: GoogleFonts.lora(fontWeight: FontWeight.w700, fontSize: 17)),
                Text(
                  'Auto-notifies on home & sets quest target',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (subjects.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...subjects.map((s) {
                    final isSel = !_isCustom && _selectedSubject == s.name;
                    return ChoiceChip(
                      label: Text(s.name),
                      selected: isSel,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _isCustom = false;
                            _selectedSubject = s.name;
                            _titleCtrl.text = '${s.name} Exam';
                          });
                        }
                      },
                    );
                  }),
                  ChoiceChip(
                    label: const Text('+ Custom'),
                    selected: _isCustom,
                    onSelected: (sel) {
                      setState(() {
                        _isCustom = true;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (_isCustom) ...[
              TextField(
                controller: _customSubjectCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter subject name (e.g. Physics, Data Structures)',
                  prefixIcon: Icon(Icons.book_rounded),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text('Hurdle Title', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. Midterm Physics Exam, Finals',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
            ),
            const SizedBox(height: 14),
            Text('Exam Date', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Color(0xFFC2410C), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Text(
                      'Change',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFC2410C), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target Score: ${_targetScore.toInt()}%', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                Text('High Distinction', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w700)),
              ],
            ),
            Slider(
              value: _targetScore,
              min: 50,
              max: 100,
              divisions: 10,
              activeColor: const Color(0xFFC2410C),
              onChanged: (v) => setState(() => _targetScore = v),
            ),
            CheckboxListTile(
              value: _createStudyTask,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Auto-create study preparation tasks in Schedule',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onChanged: (v) => setState(() => _createStudyTask = v ?? true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            final subjectName = _isCustom
                ? (_customSubjectCtrl.text.trim().isNotEmpty ? _customSubjectCtrl.text.trim() : 'General Subject')
                : (_selectedSubject ?? 'General Subject');
            final title = _titleCtrl.text.trim().isNotEmpty ? _titleCtrl.text.trim() : '$subjectName Exam';

            final hurdle = ExamHurdle(
              id: 'hurdle_${DateTime.now().millisecondsSinceEpoch}',
              title: title,
              subjectName: subjectName,
              examDate: _selectedDate,
              targetScore: _targetScore,
              requiredNodes: 4,
              completedNodes: 0,
            );

            await widget.vm.addExamHurdle(hurdle);

            if (_createStudyTask) {
              final subjects = widget.vm.profile?.subjects ?? [];
              final found = subjects.where((s) => s.name.toLowerCase() == subjectName.toLowerCase()).firstOrNull;
              final task = ScheduledTask(
                id: 'exam_prep_${DateTime.now().millisecondsSinceEpoch}',
                title: 'Revise & Prep for $title',
                subjectId: found?.id ?? '',
                subjectName: subjectName,
                scheduledDate: _selectedDate.subtract(const Duration(days: 1)),
                startTime: '10:00 AM',
                endTime: '11:30 AM',
                priority: 'high',
                isCompleted: false,
              );
              await widget.vm.addTask(task);
            }

            nav.pop();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  '🎯 Assigned "$title" on ${_selectedDate.day}/${_selectedDate.month}! Added to Quest & Home alerts.',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                ),
                backgroundColor: const Color(0xFFC2410C),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFC2410C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Set Exam & Hurdle'),
        ),
      ],
    );
  }
}

class _StickyNotesPinboardSection extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _StickyNotesPinboardSection({required this.vm});

  static const _pastelBgs = [
    Color(0xFFFEF3C7), // warm amber/yellow
    Color(0xFFD1FAE5), // soft emerald mint
    Color(0xFFEDE9FE), // lavender
    Color(0xFFFFEDD5), // soft peach
    Color(0xFFCFFAFE), // sky aqua
  ];

  static const _pastelBorders = [
    Color(0xFFFDE68A),
    Color(0xFFA7F3D0),
    Color(0xFFDDD6FE),
    Color(0xFFFED7AA),
    Color(0xFFA5F3FC),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = vm.notes;

    const darkBorders = [
      Color(0x6038BDF8),
      Color(0x608B5CF6),
      Color(0x60A855F7),
      Color(0x60818CF8),
      Color(0x6006B6D4),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('📌', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  'Quick Sticky Notes Pinboard',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => showDialog(context: context, builder: (_) => const _QuickNoteDialog()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkAccent : AppColors.accent).withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (isDark ? AppColors.darkAccent : AppColors.accent).withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 14, color: isDark ? AppColors.darkAccent : AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      'New Note',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? AppColors.darkAccent : AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (notes.isEmpty)
          GestureDetector(
            onTap: () => showDialog(context: context, builder: (_) => const _QuickNoteDialog()),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: isDark
                  ? AppColors.glassCardDecoration(
                      isDark: true,
                      borderColor: const Color(0x408B5CF6),
                      glowColor: const Color(0x208B5CF6),
                      borderRadius: 18,
                    )
                  : BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                    ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x338B5CF6) : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('📝', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No sticky notes pinned yet!',
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap here to pin formulas, rapid takeaways, and study reminders.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.add_circle_outline_rounded, color: isDark ? AppColors.darkPrimary : const Color(0xFFD97706)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 165,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final note = notes[i];
                final bg = _pastelBgs[i % _pastelBgs.length];
                final border = _pastelBorders[i % _pastelBorders.length];
                final darkBorder = darkBorders[i % darkBorders.length];

                return GestureDetector(
                  onTap: () => _showNoteDetail(context, note, vm),
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.all(14),
                    decoration: isDark
                        ? AppColors.glassCardDecoration(
                            isDark: true,
                            borderColor: darkBorder,
                            glowColor: darkBorder.withAlpha(25),
                            borderRadius: 18,
                          )
                        : BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: border, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(8),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0x3338BDF8) : Colors.white.withAlpha(160),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    note.subjectName.isNotEmpty ? note.subjectName : 'General',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Text('📌', style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note.title,
                              style: GoogleFonts.lora(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.content,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                height: 1.35,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatNoteDate(note.createdAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                              ),
                            ),
                            InkWell(
                              onTap: () => vm.deleteNote(note.id),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.delete_outline_rounded, size: 16, color: isDark ? AppColors.darkTextSecondary : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showNoteDetail(BuildContext context, QuickNote note, StudyPlannerViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('📌', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note.title,
                style: GoogleFonts.lora(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                note.subjectName.isNotEmpty ? note.subjectName : 'General',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              note.content,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            Text(
              'Created on ${_formatNoteDate(note.createdAt)}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              vm.deleteNote(note.id);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
            label: Text('Delete', style: GoogleFonts.plusJakartaSans(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatNoteDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _StatsRow extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _StatsRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.timer_outlined,
            value: '${vm.totalStudyHoursThisWeek}h',
            label: 'This Week',
            color: AppColors.primary,
            bgTint: const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline_rounded,
            value: '${vm.todayTasks.where((t) => t.isCompleted).length}/${vm.todayTasks.length}',
            label: 'Tasks Done',
            color: AppColors.secondary,
            bgTint: const Color(0xFFD1FAE5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.auto_stories_rounded,
            value: '${vm.profile?.subjects.length ?? 0}',
            label: 'Subjects',
            color: AppColors.accent,
            bgTint: const Color(0xFFFFEDD5),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bgTint;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bgTint,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: isDark
          ? AppColors.glassCardDecoration(
              isDark: true,
              borderColor: color.withAlpha(80),
              glowColor: color.withAlpha(20),
              borderRadius: 18,
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? color.withAlpha(35) : bgTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isDark ? (color == AppColors.primary ? const Color(0xFF38BDF8) : color) : color,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCardsSection extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _SubjectCardsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = vm.profile?.subjects ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enrolled Subjects',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => vm.setTabIndex(3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkPrimary : AppColors.primary).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Manage →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (subjects.isEmpty)
          _EmptyState(icon: Icons.book_rounded, message: 'No subjects added yet')
        else
          SizedBox(
            height: 136,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _SubjectMiniCard(subject: subjects[i]),
            ),
          ),
      ],
    );
  }
}

class _SubjectMiniCard extends StatelessWidget {
  final Subject subject;
  const _SubjectMiniCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _colorFromHex(subject.color);
    final pColor = subject.priority == SubjectPriority.high
        ? const Color(0xFFC2410C)
        : subject.priority == SubjectPriority.medium
            ? const Color(0xFFD97706)
            : const Color(0xFF047857);

    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: isDark
          ? AppColors.glassCardDecoration(
              isDark: true,
              borderColor: color.withAlpha(120),
              glowColor: color.withAlpha(25),
              borderRadius: 18,
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withAlpha(90), width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_stories_rounded, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: pColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subject.priority == SubjectPriority.high
                      ? '🔥 High'
                      : subject.priority == SubjectPriority.medium
                          ? '⚡ Med'
                          : '🌱 Low',
                  style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w700, color: pColor),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${subject.marks.toStringAsFixed(0)}%',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFF38BDF8) : color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${subject.targetMarks.toStringAsFixed(0)}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayTasksSection extends StatelessWidget {
  final StudyPlannerViewModel vm;
  const _TodayTasksSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = vm.todayTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Routine',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => vm.setTabIndex(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkSecondary : AppColors.secondary).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Calendar →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tasks.isEmpty)
          _EmptyState(icon: Icons.check_circle_outline_rounded, message: 'All caught up for today! 🌻')
        else
          ...tasks.take(4).map((task) => _TaskItem(task: task, onToggle: () => vm.toggleTaskComplete(task.id))),
      ],
    );
  }
}

class _TaskItem extends StatelessWidget {
  final ScheduledTask task;
  final VoidCallback onToggle;

  const _TaskItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = task.priority == 'high'
        ? AppColors.error
        : task.priority == 'medium'
            ? AppColors.warning
            : (isDark ? AppColors.darkPrimary : AppColors.secondary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: isDark
          ? AppColors.glassCardDecoration(
              isDark: true,
              borderColor: const Color(0x338B5CF6),
              glowColor: const Color(0x188B5CF6),
              borderRadius: 16,
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.isCompleted
                    ? (isDark ? AppColors.darkSecondary : AppColors.primary)
                    : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? (isDark ? AppColors.darkSecondary : AppColors.primary)
                      : (isDark ? const Color(0xFF475569) : const Color(0xFFC7BCAD)),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: task.isCompleted
                        ? (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)
                        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.subjectName} · ${task.startTime}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: priorityColor.withAlpha(60)),
            ),
            child: Text(
              task.priority.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<StudyPlannerViewModel>(
      builder: (context, vm, _) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Quick Sticky Notes 📌',
            style: GoogleFonts.lora(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: vm.notes.isEmpty
                ? Center(
                    child: Text(
                      'No notes yet',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: vm.notes.length,
                    itemBuilder: (context, i) {
                      final note = vm.notes[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: isDark
                            ? AppColors.glassCardDecoration(
                                isDark: true,
                                borderColor: const Color(0x408B5CF6),
                                glowColor: const Color(0x208B5CF6),
                                borderRadius: 14,
                              )
                            : BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                        child: ListTile(
                          title: Text(
                            note.title,
                            style: GoogleFonts.lora(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () => vm.deleteNote(note.id),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: GoogleFonts.plusJakartaSans(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: isDark
          ? AppColors.glassCardDecoration(
              isDark: true,
              borderColor: const Color(0x338B5CF6),
              borderRadius: 18,
            )
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 36,
            color: isDark ? AppColors.darkTextSecondary.withAlpha(120) : AppColors.textSecondary.withAlpha(120),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
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

// ─── Bottom Navigation ────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xEE030712) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0x338B5CF6) : AppColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x408B5CF6) : Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home', index: 0, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Quest', index: 1, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.timer_outlined, activeIcon: Icons.timer_rounded, label: 'Focus', index: 2, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Subjects', index: 3, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today_rounded, label: 'Schedule', index: 4, current: currentIndex, onTap: onTap),
              _NavItem(icon: Icons.insights_outlined, activeIcon: Icons.insights_rounded, label: 'Analytics', index: 5, current: currentIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = index == current;
    final selectedColor = isDark ? const Color(0xFF38BDF8) : AppColors.primary;
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0x338B5CF6) : AppColors.primary.withAlpha(20))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 21,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
