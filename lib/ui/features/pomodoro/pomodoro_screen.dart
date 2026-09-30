import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';

Color _colorFromHex(String hexColor) {
  var hex = hexColor.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  try {
    return Color(int.parse(hex, radix: 16));
  } catch (_) {
    return const Color(0xFFC2410C);
  }
}

String _formatDate(DateTime dt) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _daysRemainingText(DateTime dt) {
  final now = DateTime.now();
  final target = DateTime(dt.year, dt.month, dt.day);
  final current = DateTime(now.year, now.month, now.day);
  final diff = target.difference(current).inDays;
  if (diff < 0) return 'Concluded';
  if (diff == 0) return 'Today!';
  if (diff == 1) return 'Tomorrow';
  return '$diff Days Left';
}

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PomodoroViewModel>();
    final studyVm = context.watch<StudyPlannerViewModel>();
    final subjects = studyVm.profile?.subjects ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve selected subject
    Subject? selectedSubject;
    if (vm.selectedSubjectId != null) {
      selectedSubject = subjects.where((s) => s.id == vm.selectedSubjectId).firstOrNull;
    }
    if (selectedSubject == null && vm.selectedSubjectName != null) {
      selectedSubject = subjects.where((s) => s.name.toLowerCase() == vm.selectedSubjectName!.toLowerCase()).firstOrNull;
    }

    final accentColor = selectedSubject != null
        ? _colorFromHex(selectedSubject.color)
        : vm.phaseColor;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mindful Pomodoro ⏱️',
          style: GoogleFonts.lora(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2835) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : AppColors.borderLight,
              ),
            ),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () => _showSettings(context, vm),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Phase selector (Focus / Short Rest / Long Rest)
            _PhaseSelector(vm: vm, accentColor: accentColor),
            const SizedBox(height: 20),

            // Subject selector strip & dropdown
            _SubjectSelector(
              vm: vm,
              subjects: subjects,
              selectedSubject: selectedSubject,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Circular timer with active subject & topic badge
            _CircularTimer(
              vm: vm,
              selectedSubject: selectedSubject,
              accentColor: accentColor,
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Control buttons (Reset, Play/Pause, Skip)
            _ControlButtons(vm: vm, accentColor: accentColor),
            const SizedBox(height: 20),

            // Session cycle dots
            _SessionDots(vm: vm, accentColor: accentColor, isDark: isDark),
            const SizedBox(height: 26),

            // Subject Deep-Dive Hub (Lessons, Exam Date, To-Do List, Notes, History)
            if (selectedSubject != null)
              _SubjectFocusHub(
                subject: selectedSubject,
                vm: vm,
                studyVm: studyVm,
                accentColor: accentColor,
                isDark: isDark,
              )
            else
              _GeneralFocusCard(
                subjects: subjects,
                onSelectSubject: (s) => vm.selectSubject(s.id, s.name),
                phase: vm.phase,
                isDark: isDark,
              ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  void _showSettings(BuildContext context, PomodoroViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PomodoroSettings(vm: vm),
    );
  }
}

class _PhaseSelector extends StatelessWidget {
  final PomodoroViewModel vm;
  final Color accentColor;

  const _PhaseSelector({required this.vm, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2835) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: PomodoroPhase.values.map((phase) {
          final isSelected = vm.phase == phase;
          final label = phase == PomodoroPhase.work
              ? 'Focus'
              : phase == PomodoroPhase.shortBreak
                  ? 'Short Rest'
                  : 'Long Rest';
          final emoji = phase == PomodoroPhase.work
              ? '🔥'
              : phase == PomodoroPhase.shortBreak
                  ? '☕'
                  : '🌿';
          final phaseColor = phase == PomodoroPhase.work ? accentColor : vm.phaseColor;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!vm.isRunning) vm.skipPhase();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? phaseColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: phaseColor.withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white60 : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SubjectSelector extends StatelessWidget {
  final PomodoroViewModel vm;
  final List<Subject> subjects;
  final Subject? selectedSubject;
  final bool isDark;

  const _SubjectSelector({
    required this.vm,
    required this.subjects,
    required this.selectedSubject,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subject Attribution',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : const Color(0xFF5A524A),
              ),
            ),
            if (selectedSubject != null)
              GestureDetector(
                onTap: () => vm.selectSubject(null, null),
                child: Text(
                  'Switch to General',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC2410C),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Horizontal Subject Choice Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // General Focus Chip
              _buildSubjectChip(
                isSelected: selectedSubject == null,
                label: 'General Focus',
                color: const Color(0xFF78716C),
                examDate: null,
                onTap: () => vm.selectSubject(null, null),
              ),
              const SizedBox(width: 8),

              // Subject Chips
              ...subjects.map((sub) {
                final isSelected = selectedSubject?.id == sub.id;
                final subColor = _colorFromHex(sub.color);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildSubjectChip(
                    isSelected: isSelected,
                    label: sub.name,
                    color: subColor,
                    examDate: sub.examDate,
                    onTap: () => vm.selectSubject(sub.id, sub.name),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectChip({
    required bool isSelected,
    required String label,
    required Color color,
    required DateTime? examDate,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E2835) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : color.withAlpha(80),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textPrimary),
              ),
            ),
            if (examDate != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withAlpha(50)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _daysRemainingText(examDate),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CircularTimer extends StatelessWidget {
  final PomodoroViewModel vm;
  final Subject? selectedSubject;
  final Color accentColor;
  final bool isDark;

  const _CircularTimer({
    required this.vm,
    required this.selectedSubject,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Active Subject & Topic Focus Banner above timer
        if (selectedSubject != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withAlpha(80), width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedSubject!.name.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Target: ${selectedSubject!.targetMarks.toStringAsFixed(0)}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF6B6258),
                  ),
                ),
                if (selectedSubject!.examDate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Exam in ${_daysRemainingText(selectedSubject!.examDate!)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Active Topic Banner if student picked a specific topic
        if (vm.selectedTopic != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF047857).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF047857).withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bookmark_added_rounded, size: 14, color: Color(0xFF047857)),
                const SizedBox(width: 6),
                Text(
                  'Target Lesson: ${vm.selectedTopic!}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF047857),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => vm.selectTopic(null),
                  child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
        ],

        // The Circular Percent Timer
        CircularPercentIndicator(
          radius: 125,
          lineWidth: 13,
          animation: false,
          percent: vm.progress,
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vm.phaseLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                vm.formattedTime,
                style: GoogleFonts.lora(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -1.5,
                ),
              ),
              Text(
                vm.isRunning ? 'Active Focus Session' : 'Paused',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: vm.isRunning
                      ? const Color(0xFF047857)
                      : (isDark ? Colors.white60 : AppColors.textSecondary),
                ),
              ),
            ],
          ),
          progressColor: accentColor,
          backgroundColor: accentColor.withAlpha(30),
          circularStrokeCap: CircularStrokeCap.round,
        ),
      ],
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final PomodoroViewModel vm;
  final Color accentColor;

  const _ControlButtons({required this.vm, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        _CircleButton(
          icon: Icons.refresh_rounded,
          onTap: vm.reset,
          color: AppColors.textSecondary,
          size: 48,
        ),
        const SizedBox(width: 20),
        // Play / Pause (large warm button)
        GestureDetector(
          onTap: vm.isRunning ? vm.pause : vm.start,
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(100),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              vm.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Skip
        _CircleButton(
          icon: Icons.skip_next_rounded,
          onTap: vm.skipPhase,
          color: AppColors.textSecondary,
          size: 48,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2835) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? Colors.white12 : AppColors.borderLight,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

class _SessionDots extends StatelessWidget {
  final PomodoroViewModel vm;
  final Color accentColor;
  final bool isDark;

  const _SessionDots({
    required this.vm,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2835) : const Color(0xFFF3ECE0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cycle ${vm.completedSessions % vm.sessionsBeforeLongBreak + 1} of ${vm.sessionsBeforeLongBreak}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(vm.sessionsBeforeLongBreak, (i) {
              final isDone = i < vm.completedSessions % vm.sessionsBeforeLongBreak;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isDone ? accentColor : Colors.white,
                  border: Border.all(
                    color: isDone ? accentColor : const Color(0xFFD6CBC0),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Comprehensive Subject Hub directly in Pomodoro Screen!
class _SubjectFocusHub extends StatefulWidget {
  final Subject subject;
  final PomodoroViewModel vm;
  final StudyPlannerViewModel studyVm;
  final Color accentColor;
  final bool isDark;

  const _SubjectFocusHub({
    required this.subject,
    required this.vm,
    required this.studyVm,
    required this.accentColor,
    required this.isDark,
  });

  @override
  State<_SubjectFocusHub> createState() => _SubjectFocusHubState();
}

class _SubjectFocusHubState extends State<_SubjectFocusHub> {
  int _selectedTab = 0; // 0: Lessons, 1: Exam Date, 2: To-Do List, 3: Notes, 4: History

  @override
  Widget build(BuildContext context) {
    final sub = widget.subject;
    final subjectTasks = widget.studyVm.tasks.where((t) =>
        t.subjectId == sub.id ||
        t.subjectName.toLowerCase() == sub.name.toLowerCase()).toList();
    final subjectNotes = widget.studyVm.notes.where((n) =>
        n.subjectId == sub.id ||
        n.subjectName.toLowerCase() == sub.name.toLowerCase()).toList();
    final subjectSessions = widget.studyVm.sessions.where((s) =>
        s.subjectId == sub.id ||
        s.subjectName.toLowerCase() == sub.name.toLowerCase()).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E2835) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.accentColor.withAlpha(90),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withAlpha(20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Subject Title & Exam Date Quick Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: widget.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Target Marks: ${sub.targetMarks.toStringAsFixed(0)}% • Current: ${sub.marks.toStringAsFixed(1)}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Exam Date Badge with date change trigger
                GestureDetector(
                  onTap: () => _pickExamDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF59E0B).withAlpha(120)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_note_rounded, size: 13, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Text(
                              sub.examDate != null
                                  ? _daysRemainingText(sub.examDate!)
                                  : 'Set Exam',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                        if (sub.examDate != null)
                          Text(
                            _formatDate(sub.examDate!),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tabs: 0: Lessons, 1: To-Do List, 2: Notes, 3: Learning History
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildTabButton(0, '📚 Lessons (${sub.topics.length})'),
                _buildTabButton(1, '✅ To-Do (${subjectTasks.length})'),
                _buildTabButton(2, '📝 Notes (${subjectNotes.length})'),
                _buildTabButton(3, '📊 History (${subjectSessions.length})'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content per Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTabContent(
              sub: sub,
              tasks: subjectTasks,
              notes: subjectNotes,
              sessions: subjectSessions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? widget.accentColor
              : (widget.isDark ? const Color(0xFF131B24) : const Color(0xFFF3ECE0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (widget.isDark ? Colors.white70 : const Color(0xFF5A524A)),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required Subject sub,
    required List<ScheduledTask> tasks,
    required List<QuickNote> notes,
    required List<StudySession> sessions,
  }) {
    switch (_selectedTab) {
      case 0:
        return _buildLessonsTab(sub);
      case 1:
        return _buildTasksTab(sub, tasks);
      case 2:
        return _buildNotesTab(sub, notes);
      case 3:
        return _buildHistoryTab(sub, sessions);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- TAB 1: Lessons / Topics to be Completed ---
  Widget _buildLessonsTab(Subject sub) {
    final journeyNodes = widget.studyVm.journeyProgress.nodes
        .where((n) => n.subjectName.toLowerCase() == sub.name.toLowerCase())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Syllabus Lessons & Topics to Learn',
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddTopicDialog(context, sub),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Topic'),
              style: TextButton.styleFrom(
                foregroundColor: widget.accentColor,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (sub.topics.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No syllabus topics added yet. Tap "+ Add Topic" to add your lessons!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sub.topics.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final topic = sub.topics[idx];
              final isFocused = widget.vm.selectedTopic == topic;
              // Check if topic is completed in journey progress
              final matchingNode = journeyNodes.where((n) =>
                  n.title.toLowerCase() == topic.toLowerCase()).firstOrNull;
              final isCompleted = matchingNode?.status == NodeStatus.completed;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isFocused
                      ? widget.accentColor.withAlpha(20)
                      : (widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? widget.accentColor
                        : (widget.isDark ? Colors.white12 : const Color(0xFFE5DDD0)),
                    width: isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: isCompleted
                          ? const Color(0xFF047857)
                          : (widget.isDark ? Colors.white38 : const Color(0xFFA8A29E)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            topic,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark ? Colors.white : AppColors.textPrimary,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (matchingNode != null)
                            Text(
                              'Stage ${matchingNode.stage} • ${matchingNode.type.name.toUpperCase()} (+${matchingNode.xpReward} XP)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFC2410C),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Focus Target Button
                    ElevatedButton.icon(
                      onPressed: () {
                        if (isFocused) {
                          widget.vm.selectTopic(null);
                        } else {
                          widget.vm.selectTopic(topic);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFocused
                            ? widget.accentColor
                            : (widget.isDark ? const Color(0xFF1E2835) : Colors.white),
                        foregroundColor: isFocused
                            ? Colors.white
                            : widget.accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: widget.accentColor.withAlpha(80)),
                        ),
                      ),
                      icon: Icon(
                        isFocused ? Icons.check_rounded : Icons.timer_outlined,
                        size: 14,
                      ),
                      label: Text(
                        isFocused ? 'Focused' : 'Set Goal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      onPressed: () => widget.studyVm.removeSubjectTopic(sub.id, topic),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 2: To-Do List for this Subject ---
  Widget _buildTasksTab(Subject sub, List<ScheduledTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${sub.name} To-Do List',
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddTaskDialog(context, sub),
              icon: const Icon(Icons.add_task_rounded, size: 16),
              label: const Text('Add Task'),
              style: TextButton.styleFrom(
                foregroundColor: widget.accentColor,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No tasks scheduled for ${sub.name}. Tap "+ Add Task" to schedule one!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final task = tasks[idx];
              final priorityColor = task.priority == 'high'
                  ? const Color(0xFFEF4444)
                  : task.priority == 'medium'
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF10B981);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: task.isCompleted
                        ? const Color(0xFF047857).withAlpha(40)
                        : (widget.isDark ? Colors.white12 : const Color(0xFFE5DDD0)),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: task.isCompleted,
                      activeColor: const Color(0xFF047857),
                      onChanged: (_) => widget.studyVm.toggleTaskComplete(task.id),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark ? Colors.white : AppColors.textPrimary,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: priorityColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.priority.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${task.startTime} - ${task.endTime}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                      onPressed: () => widget.studyVm.deleteTask(task.id),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 3: Subject Notes ---
  Widget _buildNotesTab(Subject sub, List<QuickNote> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${sub.name} Study Notes & Insights',
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddNoteDialog(context, sub),
              icon: const Icon(Icons.post_add_rounded, size: 16),
              label: const Text('Add Note'),
              style: TextButton.styleFrom(
                foregroundColor: widget.accentColor,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (notes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No sticky notes taken for ${sub.name} yet. Jot down key formulas & chapter notes!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final note = notes[idx];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFDE047).withAlpha(120),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          note.title,
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF854D0E),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF854D0E)),
                          onPressed: () => widget.studyVm.deleteNote(note.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: widget.isDark ? Colors.white70 : const Color(0xFF713F12),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(note.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFA16207),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  // --- TAB 4: Previous Learning History ---
  Widget _buildHistoryTab(Subject sub, List<StudySession> sessions) {
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final displayHours = sub.studyHours + (totalMinutes ~/ 60);
    final displayRemainingMinutes = totalMinutes % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${sub.name} Study History & Analytics',
          style: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // Lifetime summary metrics card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.accentColor.withAlpha(50)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatUnit('Total Time', '${displayHours}h ${displayRemainingMinutes}m', widget.accentColor),
              Container(width: 1, height: 30, color: widget.accentColor.withAlpha(50)),
              _buildStatUnit('Sessions', '${sessions.length} logged', const Color(0xFF047857)),
              Container(width: 1, height: 30, color: widget.accentColor.withAlpha(50)),
              _buildStatUnit('Target', '${sub.targetMarks.toStringAsFixed(0)}%', const Color(0xFFD97706)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'No study sessions logged for ${sub.name} yet. Hit Start above to record your first Pomodoro!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.take(6).length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final sess = sessions[idx];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isDark ? Colors.white12 : const Color(0xFFE5DDD0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.timer_outlined, size: 16, color: widget.accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sess.durationMinutes} min Focus Session',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          if (sess.notes != null && sess.notes!.isNotEmpty)
                            Text(
                              sess.notes!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF047857),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDate(sess.startTime),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatUnit(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lora(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white60 : const Color(0xFF78716C),
          ),
        ),
      ],
    );
  }

  void _pickExamDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.subject.examDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      await widget.studyVm.updateSubjectExamDate(widget.subject.id, picked);
      setState(() {});
    }
  }

  void _showAddTopicDialog(BuildContext context, Subject sub) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Syllabus Topic', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Thermodynamics, Optics, Wave Mechanics',
            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final topic = controller.text.trim();
              if (topic.isNotEmpty) {
                await widget.studyVm.addSubjectTopic(sub.id, topic);
                await widget.studyVm.addCustomJourneyTopic(
                  topicTitle: topic,
                  subjectName: sub.name,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, Subject sub) {
    final titleController = TextEditingController();
    String priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Schedule Task for ${sub.name}', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g. Solve Chapter 3 Exercises, Revise Formulas',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: ['low', 'medium', 'high'].map((p) {
                  final isSelected = priority == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) => setModalState(() => priority = p),
                      selectedColor: widget.accentColor,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isNotEmpty) {
                      final task = ScheduledTask(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text.trim(),
                        subjectId: sub.id,
                        subjectName: sub.name,
                        scheduledDate: DateTime.now(),
                        startTime: '4:00 PM',
                        endTime: '5:00 PM',
                        isCompleted: false,
                        priority: priority,
                      );
                      await widget.studyVm.addTask(task);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
                  child: const Text('Add Task to Timetable'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, Subject sub) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Sticky Note for ${sub.name}', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Key Formula, Important Derivation'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes', hintText: 'Type your thoughts or key concepts...'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.trim().isNotEmpty && contentController.text.trim().isNotEmpty) {
                    final note = QuickNote(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      content: contentController.text.trim(),
                      subjectId: sub.id,
                      subjectName: sub.name,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await widget.studyVm.addNote(note);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
                child: const Text('Save Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneralFocusCard extends StatelessWidget {
  final List<Subject> subjects;
  final ValueChanged<Subject> onSelectSubject;
  final PomodoroPhase phase;
  final bool isDark;

  const _GeneralFocusCard({
    required this.subjects,
    required this.onSelectSubject,
    required this.phase,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2835) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : AppColors.borderLight,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Subject Deep-Dive Mode',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a subject from the chips above (e.g. Physics, Chemistry, Math) to unlock its full syllabus lessons, target exam date, to-do list, notes, and study history right on this screen!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF78716C),
              height: 1.4,
            ),
          ),
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subjects.map((sub) {
                final color = _colorFromHex(sub.color);
                return ActionChip(
                  backgroundColor: color.withAlpha(25),
                  side: BorderSide(color: color.withAlpha(80)),
                  label: Text(
                    'Study ${sub.name}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  onPressed: () => onSelectSubject(sub),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PomodoroSettings extends StatefulWidget {
  final PomodoroViewModel vm;
  const _PomodoroSettings({required this.vm});

  @override
  State<_PomodoroSettings> createState() => _PomodoroSettingsState();
}

class _PomodoroSettingsState extends State<_PomodoroSettings> {
  late int _work;
  late int _shortBreak;
  late int _longBreak;
  late int _sessionsBefore;

  @override
  void initState() {
    super.initState();
    _work = widget.vm.workMinutes;
    _shortBreak = widget.vm.shortBreakMinutes;
    _longBreak = widget.vm.longBreakMinutes;
    _sessionsBefore = widget.vm.sessionsBeforeLongBreak;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD6CBC0), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Timer Durations (Minutes)',
            style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 16),
          _SettingSlider(
            label: 'Focus Interval',
            value: _work,
            min: 5,
            max: 60,
            color: AppColors.primary,
            onChanged: (v) => setState(() => _work = v),
          ),
          _SettingSlider(
            label: 'Short Break',
            value: _shortBreak,
            min: 1,
            max: 15,
            color: AppColors.secondary,
            onChanged: (v) => setState(() => _shortBreak = v),
          ),
          _SettingSlider(
            label: 'Long Break',
            value: _longBreak,
            min: 5,
            max: 45,
            color: AppColors.accent,
            onChanged: (v) => setState(() => _longBreak = v),
          ),
          _SettingSlider(
            label: 'Sessions before Long Break',
            value: _sessionsBefore,
            min: 2,
            max: 8,
            color: const Color(0xFF7C3AED),
            onChanged: (v) => setState(() => _sessionsBefore = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.vm.updateSettings(
                  work: _work,
                  shortBreak: _shortBreak,
                  longBreak: _longBreak,
                  sessionsBefore: _sessionsBefore,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save Timer Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const _SettingSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value min',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: color,
          inactiveColor: color.withAlpha(40),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
