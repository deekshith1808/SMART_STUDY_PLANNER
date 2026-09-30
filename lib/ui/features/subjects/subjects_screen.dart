import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/services/social_media_blocker_service.dart';
import 'package:smart_study_planner/domain/utils/subject_validator.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();
        final subjects = vm.profile?.subjects ?? [];
        final highCount = vm.highPrioritySubjects.length;
        final medCount = vm.mediumPrioritySubjects.length;
        final lowCount = vm.lowPrioritySubjects.length;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF030712) : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF030712) : AppColors.background,
            elevation: 0,
            title: Text(
              'Priority Subjects & Notes 📚',
              style: GoogleFonts.lora(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(70),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  tooltip: 'Add Subject',
                  onPressed: () => _showAddSubjectDialog(context, vm),
                ),
              ),
            ],
          ),
          body: subjects.isEmpty
              ? _EmptySubjects(onAdd: () => _showAddSubjectDialog(context, vm))
              : CustomScrollView(
                  slivers: [
                    // Priority Summary Header
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.borderLight, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(6),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Student Priority Breakdown',
                                        style: GoogleFonts.lora(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          await vm.recalculateFutureSchedule();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('✨ Future timetable recalculated using current priorities!'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withAlpha(20),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.sync_rounded, size: 14, color: AppColors.primary),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Sync Schedule',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _PriorityStatBadge(
                                          emoji: '🔥',
                                          count: highCount,
                                          label: 'High Priority',
                                          color: const Color(0xFFC2410C),
                                          bgTint: const Color(0xFFFFEDD5),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _PriorityStatBadge(
                                          emoji: '⚡',
                                          count: medCount,
                                          label: 'Medium',
                                          color: const Color(0xFFD97706),
                                          bgTint: const Color(0xFFFEF3C7),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _PriorityStatBadge(
                                          emoji: '🌱',
                                          count: lowCount,
                                          label: 'Low Priority',
                                          color: const Color(0xFF047857),
                                          bgTint: const Color(0xFFD1FAE5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Your Enrolled Courses (${subjects.length})',
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Subject Cards List
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _SubjectCard(
                              subject: subjects[i],
                              onEdit: () => _showEditSubjectDialog(context, vm, subjects[i]),
                              onDelete: () => vm.deleteSubject(subjects[i].id),
                              onPriorityChanged: (newPriority) {
                                vm.updateSubjectPriority(subjects[i].id, newPriority);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${subjects[i].name} priority set to ${newPriority.label}. Schedule updated!'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              onToggleTopic: (topic) => vm.toggleTopicCompletion(subjects[i].id, topic),
                              onManageMaterials: () => _showMaterialsSheet(context, vm, subjects[i]),
                            ),
                          ),
                          childCount: subjects.length,
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _showAddSubjectDialog(BuildContext context, StudyPlannerViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SubjectForm(
        onSave: (subject) => vm.addSubject(subject),
        colorIndex: vm.profile?.subjects.length ?? 0,
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, StudyPlannerViewModel vm, Subject subject) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SubjectForm(
        subject: subject,
        onSave: (s) => vm.updateSubject(s),
        colorIndex: 0,
      ),
    );
  }

  void _showMaterialsSheet(BuildContext context, StudyPlannerViewModel vm, Subject subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SubjectMaterialsSheet(subjectId: subject.id, vm: vm),
    );
  }
}

class _PriorityStatBadge extends StatelessWidget {
  final String emoji;
  final int count;
  final String label;
  final Color color;
  final Color bgTint;

  const _PriorityStatBadge({
    required this.emoji,
    required this.count,
    required this.label,
    required this.color,
    required this.bgTint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<SubjectPriority> onPriorityChanged;
  final ValueChanged<String> onToggleTopic;
  final VoidCallback onManageMaterials;

  const _SubjectCard({
    required this.subject,
    required this.onEdit,
    required this.onDelete,
    required this.onPriorityChanged,
    required this.onToggleTopic,
    required this.onManageMaterials,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard> {
  bool _isExpanded = false;
  int _selectedTab = 0; // 0: Lessons, 1: To-Do, 2: Notes, 3: History

  @override
  Widget build(BuildContext context) {
    final studyVm = context.watch<StudyPlannerViewModel>();
    final subject = widget.subject;
    final color = _colorFromHex(subject.color);
    final progress = (subject.marks / 100).clamp(0.0, 1.0);
    final isAboveTarget = subject.marks >= subject.targetMarks;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final subjectTasks = studyVm.tasks.where((t) =>
        t.subjectId == subject.id ||
        t.subjectName.toLowerCase() == subject.name.toLowerCase()).toList();
    final subjectNotes = studyVm.notes.where((n) =>
        n.subjectId == subject.id ||
        n.subjectName.toLowerCase() == subject.name.toLowerCase()).toList();
    final subjectSessions = studyVm.sessions.where((s) =>
        s.subjectId == subject.id ||
        s.subjectName.toLowerCase() == subject.name.toLowerCase()).toList();

    final priorityColor = subject.priority == SubjectPriority.high
        ? const Color(0xFFC2410C)
        : subject.priority == SubjectPriority.medium
            ? const Color(0xFFD97706)
            : const Color(0xFF047857);

    final priorityBg = isDark
        ? priorityColor.withAlpha(35)
        : (subject.priority == SubjectPriority.high
            ? const Color(0xFFFFEDD5)
            : subject.priority == SubjectPriority.medium
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFD1FAE5));

    final daysLeft = subject.daysUntilExam;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: AppColors.glassCardDecoration(
        isDark: isDark,
        borderRadius: 20,
        borderColor: isDark ? color.withAlpha(120) : color.withAlpha(90),
        glowColor: color.withAlpha(isDark ? 30 : 15),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Icon, Name, Study Hours, Score, Menu
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.auto_stories_rounded, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: GoogleFonts.lora(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${subject.studyHours}h logged • ${subject.difficulty.label} difficulty',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : AppColors.textSecondary,
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
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAboveTarget ? AppColors.secondary.withAlpha(25) : AppColors.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isAboveTarget ? '✓ Target on track' : 'Need focus',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isAboveTarget ? AppColors.secondary : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white60 : AppColors.textSecondary, size: 20),
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'materials', child: Text('📁 Study Materials & Upload')),
                          const PopupMenuItem(value: 'edit', child: Text('Edit Subject')),
                          const PopupMenuItem(value: 'high', child: Text('🔥 Set High Priority')),
                          const PopupMenuItem(value: 'medium', child: Text('⚡ Set Medium Priority')),
                          const PopupMenuItem(value: 'low', child: Text('🌱 Set Low Priority')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                        ],
                        onSelected: (v) {
                          if (v == 'materials') widget.onManageMaterials();
                          if (v == 'edit') widget.onEdit();
                          if (v == 'high') widget.onPriorityChanged(SubjectPriority.high);
                          if (v == 'medium') widget.onPriorityChanged(SubjectPriority.medium);
                          if (v == 'low') widget.onPriorityChanged(SubjectPriority.low);
                          if (v == 'delete') widget.onDelete();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tags row: Priority Badge, Difficulty Badge, Exam Countdown
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: priorityColor.withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              subject.priority == SubjectPriority.high
                                  ? '🔥'
                                  : subject.priority == SubjectPriority.medium
                                      ? '⚡'
                                      : '🌱',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${subject.priority.label.toUpperCase()} PRIORITY',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: priorityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF243040) : const Color(0xFFF3ECE0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${subject.difficulty.label} Level',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE2E8F0) : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (daysLeft != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: daysLeft <= 3
                                ? const Color(0xFFFFE4E6)
                                : const Color(0xFFE0E7FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: daysLeft <= 3
                                  ? const Color(0xFFF43F5E).withAlpha(80)
                                  : const Color(0xFF6366F1).withAlpha(80),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_rounded, size: 12, color: Color(0xFF4338CA)),
                              const SizedBox(width: 4),
                              Text(
                                daysLeft == 0
                                    ? 'Exam Today!'
                                    : daysLeft < 0
                                        ? 'Exam completed'
                                        : 'Exam in $daysLeft day${daysLeft == 1 ? '' : 's'}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: daysLeft <= 3
                                      ? const Color(0xFFBE123C)
                                      : const Color(0xFF4338CA),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Priority Selector Pill
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151E28) : const Color(0xFFF8F5F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        _PriorityOptionTab(
                          label: '🔥 High',
                          isSelected: subject.priority == SubjectPriority.high,
                          activeColor: const Color(0xFFC2410C),
                          onTap: () => widget.onPriorityChanged(SubjectPriority.high),
                        ),
                        _PriorityOptionTab(
                          label: '⚡ Medium',
                          isSelected: subject.priority == SubjectPriority.medium,
                          activeColor: const Color(0xFFD97706),
                          onTap: () => widget.onPriorityChanged(SubjectPriority.medium),
                        ),
                        _PriorityOptionTab(
                          label: '🌱 Low',
                          isSelected: subject.priority == SubjectPriority.low,
                          activeColor: const Color(0xFF047857),
                          onTap: () => widget.onPriorityChanged(SubjectPriority.low),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Study Materials Quick Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF151E28) : const Color(0xFFFBF8F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.folder_shared_rounded, size: 16, color: color),
                                const SizedBox(width: 6),
                                Text(
                                  'Study Materials (${subject.materials.length})',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: widget.onManageMaterials,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_rounded, size: 13, color: isDark ? Colors.white : AppColors.textPrimary),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Upload / View',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subject.materials.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: subject.materials.take(3).map((m) {
                              return GestureDetector(
                                onTap: widget.onManageMaterials,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF222E3C) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? Colors.white12 : AppColors.borderLight),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_getMaterialIcon(m.type), size: 12, color: _getMaterialColor(m.type)),
                                      const SizedBox(width: 4),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 120),
                                        child: Text(
                                          m.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.white : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Progress bar
                  Row(
                    children: [
                      Text(
                        'Target Score Goal',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '${subject.marks.toStringAsFixed(0)}% / ${subject.targetMarks.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearPercentIndicator(
                    percent: progress,
                    lineHeight: 8,
                    backgroundColor: color.withAlpha(30),
                    progressColor: color,
                    barRadius: const Radius.circular(8),
                    padding: EdgeInsets.zero,
                  ),

                  // Topics list with completion checkboxes
                  if (subject.topics.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Topics (${subject.completedTopics.length}/${subject.topics.length} finished)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${subject.unfinishedTopicsCount} pending',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: subject.unfinishedTopicsCount > 0 ? AppColors.primary : AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: subject.topics.map((topic) {
                        final isDone = subject.completedTopics.contains(topic);
                        return GestureDetector(
                          onTap: () => widget.onToggleTopic(topic),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.secondary.withAlpha(20)
                                  : color.withAlpha(15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDone
                                    ? AppColors.secondary.withAlpha(60)
                                    : color.withAlpha(50),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  size: 12,
                                  color: isDone ? AppColors.secondary : color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  topic,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDone ? AppColors.secondary : (isDark ? Colors.white : color),
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Hub Action & Expansion Toggle Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131B24) : const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(_isExpanded ? 0 : 20)),
                border: Border(top: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5DDD0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Quick Pomodoro Launch Button
                  TextButton.icon(
                    onPressed: () {
                      context.read<PomodoroViewModel>().selectSubject(subject.id, subject.name);
                      context.read<StudyPlannerViewModel>().setTabIndex(2);
                    },
                    icon: Icon(Icons.timer_outlined, size: 16, color: color),
                    label: Text(
                      'Pomodoro Focus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  // Expand / Collapse Hub Toggle
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            _isExpanded ? 'Hide Hub' : 'Explore Hub (${subject.topics.length} topics)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF5A524A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF5A524A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Expanded Subject Hub Content
            if (_isExpanded) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18222E) : const Color(0xFFFBF8F4),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prominent Launch Pomodoro Action Bar
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.read<PomodoroViewModel>().selectSubject(subject.id, subject.name);
                          context.read<StudyPlannerViewModel>().setTabIndex(2);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                        label: Text(
                          'Start 25m Focus Session for ${subject.name}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),

                    // Exam Date Banner & Change Date Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_available_rounded, size: 16, color: Color(0xFFB45309)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Target Exam Date',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF78350F),
                                    ),
                                  ),
                                  Text(
                                    subject.examDate != null
                                        ? '${_formatSubjectDate(subject.examDate!)} (${_subjectDaysLeft(subject.examDate!)})'
                                        : 'No exam date set yet',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _pickExamDate(context, studyVm),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              subject.examDate != null ? 'Edit Date' : 'Set Date',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Hub Segment Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildTabChip(0, '📚 Lessons (${subject.topics.length})', color),
                          _buildTabChip(1, '✅ To-Do (${subjectTasks.length})', color),
                          _buildTabChip(2, '📝 Notes (${subjectNotes.length})', color),
                          _buildTabChip(3, '📊 History (${subjectSessions.length})', color),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab 0: Lessons
                    if (_selectedTab == 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Syllabus Lessons & Topics',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddTopicDialog(context, studyVm),
                            icon: const Icon(Icons.add_rounded, size: 14),
                            label: const Text('Add Topic'),
                            style: TextButton.styleFrom(
                              foregroundColor: color,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (subject.topics.isEmpty)
                        Text(
                          'No topics in syllabus yet. Tap "+ Add Topic" to add one.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : Colors.black54),
                        )
                      else
                        ...subject.topics.map((t) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131B24) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5DDD0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF047857)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  context.read<PomodoroViewModel>().selectSubject(subject.id, subject.name);
                                  context.read<PomodoroViewModel>().selectTopic(t);
                                  context.read<StudyPlannerViewModel>().setTabIndex(2);
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.timer_outlined, size: 12, color: color),
                                      const SizedBox(width: 3),
                                      Text('Focus', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                onPressed: () => studyVm.removeSubjectTopic(subject.id, t),
                              ),
                            ],
                          ),
                        )),
                    ],

                    // Tab 1: To-Do
                    if (_selectedTab == 1) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${subject.name} Tasks',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddTaskDialog(context, studyVm),
                            icon: const Icon(Icons.add_task_rounded, size: 14),
                            label: const Text('Add Task'),
                            style: TextButton.styleFrom(
                              foregroundColor: color,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (subjectTasks.isEmpty)
                        Text(
                          'No tasks scheduled for ${subject.name}. Tap "+ Add Task" to create one.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : Colors.black54),
                        )
                      else
                        ...subjectTasks.map((task) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131B24) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5DDD0)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: task.isCompleted,
                                activeColor: const Color(0xFF047857),
                                onChanged: (_) => studyVm.toggleTaskComplete(task.id),
                              ),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                onPressed: () => studyVm.deleteTask(task.id),
                              ),
                            ],
                          ),
                        )),
                    ],

                    // Tab 2: Notes
                    if (_selectedTab == 2) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${subject.name} Notes',
                            style: GoogleFonts.lora(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showAddNoteDialog(context, studyVm),
                            icon: const Icon(Icons.post_add_rounded, size: 14),
                            label: const Text('Add Note'),
                            style: TextButton.styleFrom(
                              foregroundColor: color,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (subjectNotes.isEmpty)
                        Text(
                          'No sticky notes for ${subject.name} yet.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : Colors.black54),
                        )
                      else
                        ...subjectNotes.map((n) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131B24) : const Color(0xFFFEF9C3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE047).withAlpha(100)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    n.title,
                                    style: GoogleFonts.lora(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF854D0E)),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(Icons.delete_outline_rounded, size: 14, color: isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E)),
                                    onPressed: () => studyVm.deleteNote(n.id),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.content,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF713F12)),
                              ),
                            ],
                          ),
                        )),
                    ],

                    // Tab 3: History
                    if (_selectedTab == 3) ...[
                      Text(
                        'Learning History (${subjectSessions.length} sessions)',
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (subjectSessions.isEmpty)
                        Text(
                          'No past Pomodoro sessions recorded for ${subject.name}. Tap "Start 25m Focus Session" above!',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? const Color(0xFFCBD5E1) : Colors.black54),
                        )
                      else
                        ...subjectSessions.take(4).map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131B24) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5DDD0)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 16, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${s.durationMinutes} min Session${s.notes != null ? " • ${s.notes}" : ""}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                _formatSubjectDate(s.startTime),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF78716C),
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(int index, String label, Color color) {
    final isSelected = _selectedTab == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF131B24) : const Color(0xFFEFE8DD)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF4A423A)),
          ),
        ),
      ),
    );
  }

  void _pickExamDate(BuildContext context, StudyPlannerViewModel studyVm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.subject.examDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      await studyVm.updateSubjectExamDate(widget.subject.id, picked);
      setState(() {});
    }
  }

  void _showAddTopicDialog(BuildContext context, StudyPlannerViewModel studyVm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Syllabus Topic', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Electromagnetism, Cell Division, Calculus',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final topic = controller.text.trim();
              if (topic.isNotEmpty) {
                await studyVm.addSubjectTopic(widget.subject.id, topic);
                await studyVm.addCustomJourneyTopic(
                  topicTitle: topic,
                  subjectName: widget.subject.name,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, StudyPlannerViewModel studyVm) {
    final titleController = TextEditingController();
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
            Text('Schedule Task for ${widget.subject.name}', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'e.g. Solve Chapter 3 Exercises, Revise Formulas',
              ),
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
                      subjectId: widget.subject.id,
                      subjectName: widget.subject.name,
                      scheduledDate: DateTime.now(),
                      startTime: '4:00 PM',
                      endTime: '5:00 PM',
                      isCompleted: false,
                      priority: 'medium',
                    );
                    await studyVm.addTask(task);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, StudyPlannerViewModel studyVm) {
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
            Text('Sticky Note for ${widget.subject.name}', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Formula, Important Concept'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contentController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes', hintText: 'Type your notes...'),
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
                      subjectId: widget.subject.id,
                      subjectName: widget.subject.name,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    await studyVm.addNote(note);
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Note'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityOptionTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _PriorityOptionTab({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Study Materials Modal Sheet ───────────────────────────────────────────────
class _SubjectMaterialsSheet extends StatefulWidget {
  final String subjectId;
  final StudyPlannerViewModel vm;

  const _SubjectMaterialsSheet({required this.subjectId, required this.vm});

  @override
  State<_SubjectMaterialsSheet> createState() => _SubjectMaterialsSheetState();
}

class _SubjectMaterialsSheetState extends State<_SubjectMaterialsSheet> {
  Future<void> _pickAndUploadLocalFile(Subject subject) async {
    try {
      final files = await FilePickerPlatform.instance.pickFiles(
        type: FileType.any,
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final extension = file.extension ?? '';
        final size = file.lengthSync() ?? await file.length();
        final material = StudyMaterial(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: file.name,
          fileName: file.name,
          filePath: file.path ?? file.uri.toString(),
          fileSizeBytes: size,
          type: StudyMaterialType.fromExtension(extension),
          uploadedAt: DateTime.now(),
        );

        await widget.vm.addMaterial(widget.subjectId, material);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Attached "${file.name}" to ${subject.name}!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showAddLinkDialog(Subject subject) {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Attach Web Link / Drive 🔗',
          style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Material Title (e.g. Unit 3 Slides)',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL / Web Link (https://...)',
                prefixIcon: Icon(Icons.link_rounded, color: AppColors.secondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty && urlCtrl.text.trim().isNotEmpty) {
                final material = StudyMaterial(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim(),
                  fileUrl: urlCtrl.text.trim(),
                  type: StudyMaterialType.link,
                  uploadedAt: DateTime.now(),
                );
                await widget.vm.addMaterial(widget.subjectId, material);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Attach Link'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(Subject subject) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Quick Reference / Cheat Sheet 📝',
          style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Note Title (e.g. Key Theorems & Formulae)',
                prefixIcon: Icon(Icons.title_rounded, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Cheat Sheet Content / Summary',
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.secondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isNotEmpty) {
                final material = StudyMaterial(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtrl.text.trim(),
                  content: contentCtrl.text.trim(),
                  type: StudyMaterialType.note,
                  uploadedAt: DateTime.now(),
                );
                await widget.vm.addMaterial(widget.subjectId, material);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _viewMaterial(StudyMaterial material) {
    if (material.type == StudyMaterialType.note) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.sticky_note_2_rounded, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  material.title,
                  style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              material.content ?? 'No content',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else if (material.fileUrl != null && material.fileUrl!.isNotEmpty) {
      final pomodoroVm = context.read<PomodoroViewModel>();
      SocialMediaBlockerService().tryLaunchUrlGuarded(
        context: context,
        url: material.fileUrl!,
        pomodoroVm: pomodoroVm,
      );
    } else if (material.filePath != null && material.filePath!.isNotEmpty) {
      final pomodoroVm = context.read<PomodoroViewModel>();
      SocialMediaBlockerService().tryLaunchUrlGuarded(
        context: context,
        url: 'file://${material.filePath!}',
        pomodoroVm: pomodoroVm,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attached: ${material.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.vm.profile?.subjects.firstWhere((s) => s.id == widget.subjectId);
    if (subject == null) return const SizedBox();

    final materials = subject.materials;
    final color = _colorFromHex(subject.color);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD6CBC0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.folder_shared_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subject.name} Study Materials',
                        style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${materials.length} uploaded files & study notes',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action buttons row: File Upload, Web Link, Reference Note
            Row(
              children: [
                Expanded(
                  child: _MaterialActionCard(
                    icon: Icons.upload_file_rounded,
                    label: 'Pick File\n(PDF/Slides)',
                    color: const Color(0xFFC2410C),
                    bgTint: const Color(0xFFFFEDD5),
                    onTap: () => _pickAndUploadLocalFile(subject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MaterialActionCard(
                    icon: Icons.link_rounded,
                    label: 'Attach Link\n(Drive/Web)',
                    color: const Color(0xFF0284C7),
                    bgTint: const Color(0xFFE0F2FE),
                    onTap: () => _showAddLinkDialog(subject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MaterialActionCard(
                    icon: Icons.sticky_note_2_rounded,
                    label: 'Write Note\n(Cheat Sheet)',
                    color: const Color(0xFF0D9488),
                    bgTint: const Color(0xFFCCFBF1),
                    onTap: () => _showAddNoteDialog(subject),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Attached Materials',
              style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            if (materials.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        'No materials attached yet',
                        style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upload PDF textbooks, lecture slides, diagrams, or web notes for ${subject.name}.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...materials.map((m) {
                final typeColor = _getMaterialColor(m.type);
                final typeIcon = _getMaterialIcon(m.type);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(typeIcon, color: typeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _viewMaterial(m),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.title,
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
                                    m.type.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: typeColor,
                                    ),
                                  ),
                                  if (m.formattedSize.isNotEmpty) ...[
                                    Text(' • ', style: TextStyle(color: AppColors.textSecondary.withAlpha(120))),
                                    Text(
                                      m.formattedSize,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                  Text(' • ', style: TextStyle(color: AppColors.textSecondary.withAlpha(120))),
                                  Text(
                                    DateFormat('MMM d').format(m.uploadedAt),
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                        tooltip: 'Open Material',
                        onPressed: () => _viewMaterial(m),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                        tooltip: 'Delete',
                        onPressed: () => widget.vm.deleteMaterial(widget.subjectId, m.id),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MaterialActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgTint;
  final VoidCallback onTap;

  const _MaterialActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgTint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _getMaterialColor(StudyMaterialType type) {
  switch (type) {
    case StudyMaterialType.pdf:
      return const Color(0xFFDC2626);
    case StudyMaterialType.image:
      return const Color(0xFF7C3AED);
    case StudyMaterialType.document:
      return const Color(0xFF2563EB);
    case StudyMaterialType.link:
      return const Color(0xFFD97706);
    case StudyMaterialType.note:
      return const Color(0xFF0D9488);
  }
}

IconData _getMaterialIcon(StudyMaterialType type) {
  switch (type) {
    case StudyMaterialType.pdf:
      return Icons.picture_as_pdf_rounded;
    case StudyMaterialType.image:
      return Icons.image_rounded;
    case StudyMaterialType.document:
      return Icons.description_rounded;
    case StudyMaterialType.link:
      return Icons.link_rounded;
    case StudyMaterialType.note:
      return Icons.sticky_note_2_rounded;
  }
}

class _EmptySubjects extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptySubjects({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No subjects added yet',
            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your current semester courses, upload study files, and set priorities.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: const Text('Add First Subject'),
          ),
        ],
      ),
    );
  }
}

class _SubjectForm extends StatefulWidget {
  final Subject? subject;
  final ValueChanged<Subject> onSave;
  final int colorIndex;

  const _SubjectForm({this.subject, required this.onSave, required this.colorIndex});

  @override
  State<_SubjectForm> createState() => _SubjectFormState();
}

class _SubjectFormState extends State<_SubjectForm> {
  late TextEditingController _nameCtrl;
  late TextEditingController _topicCtrl;
  late double _marks;
  late double _targetMarks;
  late int _studyHours;
  late SubjectPriority _priority;
  late SubjectDifficulty _difficulty;
  late DateTime? _examDate;
  late int _selectedColorIndex;
  late List<String> _topics;
  late List<String> _completedTopics;
  String? _streamFilter;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.subject?.name ?? '');
    _topicCtrl = TextEditingController();
    _marks = widget.subject?.marks ?? 0;
    _targetMarks = widget.subject?.targetMarks ?? 85;
    _studyHours = widget.subject?.studyHours ?? 0;
    _priority = widget.subject?.priority ?? SubjectPriority.medium;
    _difficulty = widget.subject?.difficulty ?? SubjectDifficulty.medium;
    _examDate = widget.subject?.examDate;
    _topics = List<String>.from(widget.subject?.topics ?? []);
    _completedTopics = List<String>.from(widget.subject?.completedTopics ?? []);
    _selectedColorIndex = widget.colorIndex % AppColors.subjectColors.length;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.96,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD6CBC0), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(
              widget.subject == null ? 'Add Subject 📖' : 'Edit Subject',
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(labelText: 'Subject Name', prefixIcon: Icon(Icons.book_rounded, color: AppColors.primary)),
            ),
            if (widget.subject == null) ...[
              const SizedBox(height: 10),
              Text(
                'Recommended Presets (Tap to use):',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Builder(
                builder: (context) {
                  final profile = context.read<StudyPlannerViewModel>().profile;
                  final edType = profile?.educationType ?? 'college';
                  final defaultStream = profile?.branch ?? 'Medical & Health';
                  
                  final Map<String, List<String>> collegeStreamPresets = {
                    'Medical & Health': [
                      'Anatomy', 'Human Physiology', 'Biochemistry', 'Pharmacology',
                      'Pathology', 'Microbiology', 'Forensic Medicine', 'Clinical Medicine'
                    ],
                    'Arts & Humanities': [
                      'English Literature', 'World History', 'Political Science', 'Sociology',
                      'Psychology', 'Philosophy', 'Economics', 'Journalism & Mass Comm'
                    ],
                    'Engineering & Tech': [
                      'Data Structures', 'Operating Systems', 'DBMS', 'Computer Networks',
                      'Engineering Maths', 'Software Engineering', 'Digital Electronics'
                    ],
                    'Commerce & Mgmt': [
                      'Financial Accounting', 'Business Law', 'Microeconomics', 'Macroeconomics',
                      'Corporate Finance', 'Marketing Management', 'Cost Accounting'
                    ],
                    'Natural Sciences': [
                      'Advanced Calculus', 'Classical Mechanics', 'Organic Chemistry',
                      'Inorganic Chemistry', 'Molecular Biology', 'Applied Statistics'
                    ],
                    'Law & Governance': [
                      'Constitutional Law', 'Criminal Law & IPC', 'Law of Contracts',
                      'Jurisprudence', 'Administrative Law', 'International Law'
                    ],
                  };

                  if (edType == 'school') {
                    final presets = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'Computer Science', 'Social Studies'];
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: presets.map((p) => ActionChip(
                        label: Text(p, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          setState(() {
                            _nameCtrl.text = p;
                          });
                        },
                      )).toList(),
                    );
                  }

                  // College: Show active stream with switcher
                  _streamFilter ??= (collegeStreamPresets.containsKey(defaultStream) ? defaultStream : 'Medical & Health');
                  final streamPresets = collegeStreamPresets[_streamFilter] ?? collegeStreamPresets.values.first;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: collegeStreamPresets.keys.map((st) {
                            final isSel = _streamFilter == st;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(st, style: const TextStyle(fontSize: 10)),
                                selected: isSel,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? Colors.white : AppColors.textPrimary,
                                ),
                                onSelected: (sel) {
                                  if (sel) setState(() => _streamFilter = st);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: streamPresets.map((p) => ActionChip(
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _nameCtrl.text = p;
                            });
                          },
                        )).toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 18),

            // Priority Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Student Priority Rating', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_priority.weightMultiplier.toStringAsFixed(0)}x study weight',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _PrioritySelectCard(
                  emoji: '🔥',
                  title: 'HIGH',
                  subtitle: 'More study time',
                  isSelected: _priority == SubjectPriority.high,
                  activeColor: const Color(0xFFC2410C),
                  onTap: () => setState(() => _priority = SubjectPriority.high),
                ),
                const SizedBox(width: 8),
                _PrioritySelectCard(
                  emoji: '⚡',
                  title: 'MEDIUM',
                  subtitle: 'Balanced time',
                  isSelected: _priority == SubjectPriority.medium,
                  activeColor: const Color(0xFFD97706),
                  onTap: () => setState(() => _priority = SubjectPriority.medium),
                ),
                const SizedBox(width: 8),
                _PrioritySelectCard(
                  emoji: '🌱',
                  title: 'LOW',
                  subtitle: 'Maintenance',
                  isSelected: _priority == SubjectPriority.low,
                  activeColor: const Color(0xFF047857),
                  onTap: () => setState(() => _priority = SubjectPriority.low),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Difficulty Selector
            Text('Subject Difficulty', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _DifficultySelectCard(
                  label: 'Hard (1.5x)',
                  isSelected: _difficulty == SubjectDifficulty.hard,
                  onTap: () => setState(() => _difficulty = SubjectDifficulty.hard),
                ),
                const SizedBox(width: 8),
                _DifficultySelectCard(
                  label: 'Medium (1.2x)',
                  isSelected: _difficulty == SubjectDifficulty.medium,
                  onTap: () => setState(() => _difficulty = SubjectDifficulty.medium),
                ),
                const SizedBox(width: 8),
                _DifficultySelectCard(
                  label: 'Easy (1.0x)',
                  isSelected: _difficulty == SubjectDifficulty.easy,
                  onTap: () => setState(() => _difficulty = SubjectDifficulty.easy),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Upcoming Exam Date Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Upcoming Exam Date (Optional)', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (_examDate != null)
                  GestureDetector(
                    onTap: () => setState(() => _examDate = null),
                    child: Text(
                      'Clear',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _examDate ?? DateTime.now().add(const Duration(days: 14)),
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) {
                  setState(() => _examDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight, width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _examDate != null
                            ? DateFormat('EEEE, MMM d, yyyy').format(_examDate!)
                            : 'Tap to select upcoming exam date...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: _examDate != null ? FontWeight.w700 : FontWeight.w500,
                          color: _examDate != null ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Color Palette
            Text('Palette Tag', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppColors.subjectColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final color = AppColors.subjectColors[i];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColorIndex == i ? AppColors.textPrimary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _selectedColorIndex == i ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            _buildSlider('Current Marks', _marks, 0, 100, '%', (v) => setState(() => _marks = v), AppColors.primary),
            _buildSlider('Target Goal', _targetMarks, 0, 100, '%', (v) => setState(() => _targetMarks = v), AppColors.secondary),
            _buildSlider('Study Time Logged', _studyHours.toDouble(), 0, 60, 'h', (v) => setState(() => _studyHours = v.round()), AppColors.accent),
            Row(
              children: [
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _studyHours = (_studyHours + 1).clamp(0, 60)),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('+1h', style: TextStyle(fontSize: 11)),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _studyHours = (_studyHours + 5).clamp(0, 60)),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('+5h', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Topics list
            Text('Key Topics / Chapters', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topicCtrl,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: const InputDecoration(hintText: 'e.g. Thermodynamics, Chapter 3'),
                    onSubmitted: _addTopic,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTopic(_topicCtrl.text),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ],
            ),
            if (_topics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _topics.asMap().entries.map((e) {
                  final topic = e.value;
                  final isDone = _completedTopics.contains(topic);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isDone) {
                          _completedTopics.remove(topic);
                        } else {
                          _completedTopics.add(topic);
                        }
                      });
                    },
                    child: Chip(
                      avatar: Icon(
                        isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: isDone ? AppColors.secondary : AppColors.primary,
                      ),
                      label: Text(
                        topic,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => setState(() {
                        _topics.removeAt(e.key);
                        _completedTopics.remove(topic);
                      }),
                      backgroundColor: AppColors.subjectColors[_selectedColorIndex].withAlpha(25),
                      side: BorderSide(color: AppColors.subjectColors[_selectedColorIndex].withAlpha(60)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.subject == null ? 'Save Subject' : 'Update Subject',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, String unit, ValueChanged<double> onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text('${value.toStringAsFixed(0)}$unit', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: color,
            inactiveColor: color.withAlpha(40),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _addTopic(String value) {
    if (value.trim().isNotEmpty && !_topics.contains(value.trim())) {
      setState(() => _topics.add(value.trim()));
      _topicCtrl.clear();
    }
  }

  void _save() {
    final rawName = _nameCtrl.text.trim();
    if (rawName.isEmpty) return;

    if (!AcademicSubjectValidator.isAcademicSubject(rawName)) {
      _showAcademicWarningDialog(rawName);
      return;
    }

    _commitSave(rawName);
  }

  void _commitSave(String subjectName) {
    final color = AppColors.subjectColors[_selectedColorIndex % AppColors.subjectColors.length];
    final subject = Subject(
      id: widget.subject?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: subjectName,
      marks: _marks,
      targetMarks: _targetMarks,
      studyHours: _studyHours,
      color: '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      topics: _topics,
      completedTopics: _completedTopics,
      materials: widget.subject?.materials ?? const [],
      priority: _priority,
      difficulty: _difficulty,
      examDate: _examDate,
    );
    widget.onSave(subject);
    Navigator.pop(context);
  }

  void _showAcademicWarningDialog(String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isDark ? const BorderSide(color: Color(0xFF38BDF8), width: 1.2) : BorderSide.none,
        ),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Non-Academic Topic Warning',
                style: GoogleFonts.lora(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '"$name" does not appear to be a recognized academic subject or educational course. Non-educational entries can dilute your syllabus analytics and learning journey.\n\nWould you like to continue anyway?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.45,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(
              'Change Name',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dlgCtx);
              _commitSave(name);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC2410C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Continue Anyway',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrioritySelectCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _PrioritySelectCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.borderLight,
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? activeColor.withAlpha(40) : Colors.black.withAlpha(5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white.withAlpha(220) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultySelectCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultySelectCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.borderLight),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatSubjectDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _subjectDaysLeft(DateTime d) {
  final diff = d.difference(DateTime.now()).inDays;
  if (diff < 0) return 'Passed';
  if (diff == 0) return 'Today!';
  if (diff == 1) return 'Tomorrow';
  return '$diff days left';
}

Color _colorFromHex(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return AppColors.primary;
  }
}
