import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';

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
                              'Keep your routine peaceful & focused.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddTaskDialog(context, vm),
                              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              label: const Text('Add Study Task'),
                            ),
                          ],
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
}

class _ScheduleTaskCard extends StatelessWidget {
  final ScheduledTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ScheduleTaskCard({required this.task, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priorityColor = task.priority == 'high'
        ? AppColors.error
        : task.priority == 'medium'
            ? AppColors.warning
            : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppColors.glassCardDecoration(
        isDark: isDark,
        borderRadius: 18,
        borderColor: isDark ? AppColors.darkBorderAccent.withAlpha(40) : null,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: task.isCompleted ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.primary
                      : (isDark ? Colors.white38 : const Color(0xFFC7BCAD)),
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
                        ? (isDark ? Colors.white38 : AppColors.textSecondary)
                        : (isDark ? Colors.white : AppColors.textPrimary),
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.subjectName,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${task.startTime} - ${task.endTime}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: priorityColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: priorityColor.withAlpha(60)),
            ),
            child: Text(
              task.priority.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: priorityColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
            onPressed: onDelete,
          ),
        ],
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
    final subjects = widget.vm.profile?.subjects ?? [];

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
            Text(
              'Add Study Session 🗓️',
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                    _selectedSubjectName = subjects.firstWhere((s) => s.id == id).name;
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
            Text('Priority', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: ['low', 'medium', 'high'].map((p) {
                final isSelected = _priority == p;
                final color = p == 'high' ? AppColors.error : p == 'medium' ? AppColors.warning : AppColors.secondary;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? color : AppColors.borderLight),
                        ),
                        child: Text(
                          p.toUpperCase(),
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
