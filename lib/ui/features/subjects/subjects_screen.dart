import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();
        final subjects = vm.profile?.subjects ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Subjects & Marks 📚',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
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
                  onPressed: () => _showAddSubjectDialog(context, vm),
                ),
              ),
            ],
          ),
          body: subjects.isEmpty
              ? _EmptySubjects(onAdd: () => _showAddSubjectDialog(context, vm))
              : ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: subjects.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, i) => _SubjectCard(
                    subject: subjects[i],
                    onEdit: () => _showEditSubjectDialog(context, vm, subjects[i]),
                    onDelete: () => vm.deleteSubject(subjects[i].id),
                  ),
                ),
        );
      },
    );
  }

  void _showAddSubjectDialog(BuildContext context, StudyPlannerViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SubjectForm(
        onSave: (subject) => vm.addSubject(subject),
        colorIndex: vm.profile?.subjects.length ?? 0,
      ),
    );
  }

  void _showEditSubjectDialog(BuildContext context, StudyPlannerViewModel vm, Subject subject) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _SubjectForm(
        subject: subject,
        onSave: (s) => vm.updateSubject(s),
        colorIndex: 0,
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final Subject subject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubjectCard({required this.subject, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _colorFromHex(subject.color);
    final progress = (subject.marks / 100).clamp(0.0, 1.0);
    final isAboveTarget = subject.marks >= subject.targetMarks;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${subject.studyHours}h focus time',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
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
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Subject')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                      ],
                      onSelected: (v) {
                        if (v == 'edit') onEdit();
                        if (v == 'delete') onDelete();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                Row(
                  children: [
                    Text(
                      'Score Progress',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      'Target: ${subject.targetMarks.toStringAsFixed(0)}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                const SizedBox(height: 12),
                // Priority stars
                Row(
                  children: [
                    Text('Priority: ', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
                    ...List.generate(5, (i) => Icon(
                      i < subject.priority ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 16,
                      color: i < subject.priority ? AppColors.accent : AppColors.textSecondary.withAlpha(60),
                    )),
                  ],
                ),
                if (subject.topics.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: subject.topics.take(4).map((topic) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withAlpha(50)),
                      ),
                      child: Text(
                        topic,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
                ],
                if (subject.examDate != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFF59E0B).withAlpha(120)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_rounded, size: 14, color: Color(0xFFB45309)),
                        const SizedBox(width: 5),
                        Text(
                          'Exam: ${_formatSubjectDate(subject.examDate!)} • ${_subjectDaysLeft(subject.examDate!)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
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
            'Add your current semester courses to begin tracking.',
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
  late int _priority;
  late int _selectedColorIndex;
  late List<String> _topics;
  DateTime? _examDate;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.subject?.name ?? '');
    _topicCtrl = TextEditingController();
    _marks = widget.subject?.marks ?? 0;
    _targetMarks = widget.subject?.targetMarks ?? 85;
    _studyHours = widget.subject?.studyHours ?? 0;
    _priority = widget.subject?.priority ?? 3;
    _topics = List<String>.from(widget.subject?.topics ?? []);
    _selectedColorIndex = widget.colorIndex % AppColors.subjectColors.length;
    _examDate = widget.subject?.examDate;
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
            const SizedBox(height: 18),
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
            _buildSlider('Study Time Logged', _studyHours.toDouble(), 0, 500, 'h', (v) => setState(() => _studyHours = v.round()), AppColors.accent),
            const SizedBox(height: 10),
            Text('Priority Rating', style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _priority = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    i < _priority ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 32,
                    color: i < _priority ? AppColors.accent : const Color(0xFFD6CBC0),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 20),
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
                children: _topics.asMap().entries.map((e) => Chip(
                  label: Text(e.value, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14),
                  onDeleted: () => setState(() => _topics.removeAt(e.key)),
                  backgroundColor: AppColors.subjectColors[_selectedColorIndex].withAlpha(25),
                  side: BorderSide(color: AppColors.subjectColors[_selectedColorIndex].withAlpha(60)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                )).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Target Exam Date',
                    style: GoogleFonts.lora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                if (_examDate != null)
                  TextButton(
                    onPressed: () => setState(() => _examDate = null),
                    child: const Text('Clear',
                        style: TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _examDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) {
                  setState(() => _examDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8DFD3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _examDate != null
                            ? '${_formatSubjectDate(_examDate!)} (${_subjectDaysLeft(_examDate!)})'
                            : 'Set Subject Exam Date (Optional)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: _examDate != null
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _examDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textSecondary),
                  ],
                ),
              ),
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
    if (_nameCtrl.text.trim().isEmpty) return;
    final color = AppColors.subjectColors[_selectedColorIndex % AppColors.subjectColors.length];
    final subject = Subject(
      id: widget.subject?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      marks: _marks,
      targetMarks: _targetMarks,
      studyHours: _studyHours,
      color: '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      topics: _topics,
      priority: _priority,
      examDate: _examDate,
    );
    widget.onSave(subject);
    Navigator.pop(context);
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
