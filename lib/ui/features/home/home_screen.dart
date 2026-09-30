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
          backgroundColor: AppColors.background,
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

class _QuickNoteDialog extends StatelessWidget {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  _QuickNoteDialog();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<StudyPlannerViewModel>();
    final subjects = vm.profile?.subjects ?? [];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Quick Sticky Note 📝',
        style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Write your thought, insight or reminder...',
              prefixIcon: Icon(Icons.notes_rounded, color: AppColors.accent),
            ),
          ),
        ],
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
                subjectId: subjects.isNotEmpty ? subjects.first.id : '',
                subjectName: subjects.isNotEmpty ? subjects.first.name : 'General',
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
          child: const Text('Save Note'),
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
    final vm = context.watch<StudyPlannerViewModel>();
    final profile = vm.profile;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 164,
          floating: false,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
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
                // Duolingo Exam Quest Hurdle Banner
                _ExamJourneyBanner(vm: vm),
                const SizedBox(height: 20),
                // Quick stats row
                _StatsRow(vm: vm),
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
    final progress = vm.journeyProgress;
    final hurdle = progress.hurdle;

    return GestureDetector(
      onTap: () => vm.setTabIndex(1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC2410C), Color(0xFF9A3412)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC2410C).withAlpha(80),
              blurRadius: 12,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'FIRST HURDLE: ${hurdle.daysRemaining} DAYS LEFT',
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
                        'Level ${progress.level} • ${hurdle.completedNodes}/${hurdle.requiredNodes} Conquered • ${progress.totalXp} XP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white.withAlpha(220),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
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
              color: bgTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
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
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => vm.setTabIndex(3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Manage →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.primary,
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
    final color = _colorFromHex(subject.color);
    return Container(
      width: 138,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_stories_rounded, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${subject.targetMarks.toStringAsFixed(0)}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => vm.setTabIndex(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Calendar →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.secondary,
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
    final priorityColor = task.priority == 'high'
        ? AppColors.error
        : task.priority == 'medium'
            ? AppColors.warning
            : AppColors.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
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
                color: task.isCompleted ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted ? AppColors.primary : const Color(0xFFC7BCAD),
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
                    color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.subjectName} · ${task.startTime}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
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
    return Consumer<StudyPlannerViewModel>(
      builder: (context, vm, _) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Quick Sticky Notes 📌', style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: vm.notes.isEmpty
                ? const Center(child: Text('No notes yet'))
                : ListView.builder(
                    itemCount: vm.notes.length,
                    itemBuilder: (context, i) {
                      final note = vm.notes[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: ListTile(
                          title: Text(
                            note.title,
                            style: GoogleFonts.lora(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Text(
                            note.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
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
              child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.w700)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textSecondary.withAlpha(120)),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.borderLight, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
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
    final isSelected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 21,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
