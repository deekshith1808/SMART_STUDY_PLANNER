import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/services/timetable_generator.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();
        final tasks = vm.tasks;

        // Group tasks by date
        final Map<DateTime, List<ScheduledTask>> events = {};
        for (final task in tasks) {
          final date = DateTime(task.scheduledDate.year, task.scheduledDate.month, task.scheduledDate.day);
          events.putIfAbsent(date, () => []).add(task);
        }

        final selectedTasks = _selectedDay == null
            ? <ScheduledTask>[]
            : events[DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF030712) : AppColors.background,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF030712) : AppColors.background,
            elevation: 0,
            title: Text(
              'Study Timetable 🗓️',
              style: GoogleFonts.lora(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            actions: [
              // Smart Timetable Generator Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showGenerateTimetableDialog(context, vm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC2410C),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                  label: Text(
                    'Auto Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
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
                  tooltip: 'Add Manual Task',
                  onPressed: () => _showAddTaskDialog(context, vm),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Calendar Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: AppColors.glassCardDecoration(
                  isDark: isDark,
                  borderRadius: 20,
                  borderColor: isDark ? AppColors.darkBorderAccent.withAlpha(50) : null,
                  glowColor: isDark ? AppColors.darkSecondary.withAlpha(20) : null,
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return events[key] ?? [];
                  },
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    defaultTextStyle: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonDecoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    titleTextStyle: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Tasks for selected day
              Expanded(
                child: selectedTasks.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withAlpha(20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.event_available_rounded, size: 44, color: AppColors.secondary),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No sessions planned for this day',
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Generate a balanced timetable based on your subject priorities.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showGenerateTimetableDialog(context, vm),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFC2410C),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                                    label: const Text('Smart Timetable'),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    onPressed: () => _showAddTaskDialog(context, vm),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Add Task'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemCount: selectedTasks.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _ScheduleTaskCard(
                          task: selectedTasks[i],
                          onToggle: () => vm.toggleTaskComplete(selectedTasks[i].id),
                          onDelete: () => vm.deleteTask(selectedTasks[i].id),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(BuildContext context, StudyPlannerViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddTaskForm(vm: vm, initialDate: _selectedDay ?? DateTime.now()),
    );
  }

  void _showGenerateTimetableDialog(BuildContext context, StudyPlannerViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GenerateTimetableSheet(vm: vm),
    );
  }
}

class _ScheduleTaskCard extends StatelessWidget {
  final ScheduledTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ScheduleTaskCard({required this.task, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priority = task.priority.toLowerCase();
    final priorityColor = priority == 'high'
        ? const Color(0xFFC2410C)
        : priority == 'medium'
            ? const Color(0xFFD97706)
            : const Color(0xFF047857);

    final priorityBg = isDark
        ? priorityColor.withAlpha(35)
        : (priority == 'high'
            ? const Color(0xFFFFEDD5)
            : priority == 'medium'
                ? const Color(0xFFFEF3C7)
                : const Color(0xFFD1FAE5));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.glassCardDecoration(
        isDark: isDark,
        borderRadius: 18,
        borderColor: isDark ? AppColors.darkBorderAccent.withAlpha(40) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 2),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: task.isCompleted ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFFC7BCAD)),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
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
                    fontWeight: FontWeight.w700,
                    color: task.isCompleted
                        ? (isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary)
                        : (isDark ? Colors.white : AppColors.textPrimary),
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    task.description!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkPrimary : AppColors.primary).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.subjectName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.startTime} - ${task.endTime}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: priorityColor.withAlpha(60)),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: priorityColor),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenerateTimetableSheet extends StatefulWidget {
  final StudyPlannerViewModel vm;
  const _GenerateTimetableSheet({required this.vm});

  @override
  State<_GenerateTimetableSheet> createState() => _GenerateTimetableSheetState();
}

class _GenerateTimetableSheetState extends State<_GenerateTimetableSheet> {
  double _dailyHours = 3.0;
  int _days = 7;
  int _slotDuration = 60;
  String _startTime = '09:00';
  bool _preserveCompleted = true;

  @override
  Widget build(BuildContext context) {
    final subjects = widget.vm.profile?.subjects ?? [];
    final allocations = TimetableGenerator.computeAllocations(
      subjects: subjects,
      daysCount: _days,
      dailyStudyHours: _dailyHours,
      slotDurationMinutes: _slotDuration,
    );

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2410C).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFC2410C), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Timetable Generator',
                        style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Priority-weighted schedule optimizer',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daily study hours slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Available Study Time',
                  style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  '${_dailyHours.toStringAsFixed(1)} hours / day',
                  style: GoogleFonts.lora(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFFC2410C)),
                ),
              ],
            ),
            Slider(
              value: _dailyHours,
              min: 1.0,
              max: 8.0,
              divisions: 14,
              activeColor: const Color(0xFFC2410C),
              inactiveColor: const Color(0xFFC2410C).withAlpha(40),
              onChanged: (v) => setState(() => _dailyHours = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2.0, 3.0, 4.0, 6.0].map((h) {
                final isSelected = (_dailyHours - h).abs() < 0.1;
                return GestureDetector(
                  onTap: () => setState(() => _dailyHours = h),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFC2410C) : const Color(0xFFF3ECE0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${h.toInt()} hrs',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Schedule Range and Slot Duration
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan Horizon', style: GoogleFonts.lora(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [7, 14].map((d) {
                          final isSelected = _days == d;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() => _days = d),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.borderLight),
                                  ),
                                  child: Text(
                                    '$d Days',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Slot Length', style: GoogleFonts.lora(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [45, 60].map((m) {
                          final isSelected = _slotDuration == m;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap: () => setState(() => _slotDuration = m),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.secondary : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSelected ? AppColors.secondary : AppColors.borderLight),
                                  ),
                                  child: Text(
                                    '$m min',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Start Time Picker
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label: 'Daily Schedule Starts At',
                    value: _startTime,
                    onChanged: (v) => setState(() => _startTime = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preserve Completed Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_added_rounded, color: AppColors.secondary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keep Completed Sessions',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Only future uncompleted tasks will be rescheduled.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _preserveCompleted,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withAlpha(80),
                    onChanged: (v) => setState(() => _preserveCompleted = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Priority & Difficulty Distribution Preview
            Text(
              'Dynamic Study Allocation Preview',
              style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Calculated from student priority (High/Med/Low), difficulty, unfinished topics & exams:',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            if (allocations.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Add subjects in the Subjects tab first to generate a timetable.'),
              )
            else
              ...allocations.map((a) {
                final color = _colorFromHex(a.subject.color);
                final pColor = a.subject.priority == SubjectPriority.high
                    ? const Color(0xFFC2410C)
                    : a.subject.priority == SubjectPriority.medium
                        ? const Color(0xFFD97706)
                        : const Color(0xFF047857);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withAlpha(70)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                a.subject.name,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: pColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  a.subject.priority.label.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: pColor),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(a.totalMinutes / 60).toStringAsFixed(1)} hrs (${(a.percentage * 100).toStringAsFixed(0)}%)',
                            style: GoogleFonts.lora(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: a.percentage,
                          minHeight: 6,
                          backgroundColor: color.withAlpha(30),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.rationale,
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await widget.vm.generateTimetable(
                    days: _days,
                    dailyHours: _dailyHours,
                    slotDurationMinutes: _slotDuration,
                    dailyStartTime: _startTime,
                    preserveCompleted: _preserveCompleted,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✨ Generated smart timetable for next $_days days!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2410C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Apply Smart Schedule ($_days Days)',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
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
}

class _AddTaskForm extends StatefulWidget {
  final StudyPlannerViewModel vm;
  final DateTime initialDate;

  const _AddTaskForm({required this.vm, required this.initialDate});

  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  String _startTime = '09:00';
  String _endTime = '10:00';
  String _priority = 'medium';
  late DateTime _scheduledDate;

  @override
  void initState() {
    super.initState();
    _scheduledDate = widget.initialDate;
    final subjects = widget.vm.profile?.subjects ?? [];
    if (subjects.isNotEmpty) {
      _selectedSubjectId = subjects.first.id;
      _selectedSubjectName = subjects.first.name;
      _priority = subjects.first.priority.name;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjects = widget.vm.profile?.subjects ?? [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          controller: ctrl,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFD6CBC0), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(
                'Add Study Session 🗓️',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary),
              ),
              const SizedBox(height: 18),
            TextField(
              controller: _titleCtrl,
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(labelText: 'Task Title (e.g. Chapter 4 Practice)', prefixIcon: Icon(Icons.assignment_rounded, color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: const InputDecoration(labelText: 'Notes / Objectives (optional)', prefixIcon: Icon(Icons.notes_rounded, color: AppColors.accent)),
            ),
            const SizedBox(height: 16),
            if (subjects.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.book_rounded, color: AppColors.secondary)),
                items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)))).toList(),
                onChanged: (id) {
                  setState(() {
                    _selectedSubjectId = id;
                    final s = subjects.firstWhere((sub) => sub.id == id);
                    _selectedSubjectName = s.name;
                    _priority = s.priority.name;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],
            // Time pickers
            Row(
              children: [
                Expanded(child: _TimePicker(label: 'Start Time', value: _startTime, onChanged: (v) => setState(() => _startTime = v))),
                const SizedBox(width: 12),
                Expanded(child: _TimePicker(label: 'End Time', value: _endTime, onChanged: (v) => setState(() => _endTime = v))),
              ],
            ),
            const SizedBox(height: 18),
            Text('Priority', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;
                final color = p == 'high' ? const Color(0xFFC2410C) : p == 'medium' ? const Color(0xFFD97706) : const Color(0xFF047857);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color : (isDark ? const Color(0xFF1E2835) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? color : (isDark ? Colors.white12 : AppColors.borderLight)),
                        ),
                        child: Text(
                          p.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
                child: const Text('Add to Schedule'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final task = ScheduledTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      subjectId: _selectedSubjectId ?? '',
      subjectName: _selectedSubjectName ?? 'General',
      scheduledDate: _scheduledDate,
      startTime: _startTime,
      endTime: _endTime,
      isCompleted: false,
      priority: _priority,
    );
    widget.vm.addTask(task);
    Navigator.pop(context);
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimePicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = value.split(':');
        final current = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(context: context, initialTime: current);
        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          onChanged('$h:$m');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
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
