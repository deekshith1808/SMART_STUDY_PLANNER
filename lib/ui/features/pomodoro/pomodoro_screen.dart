import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.watch<PomodoroViewModel>(),
      builder: (context, _) {
        final vm = context.read<PomodoroViewModel>();
        final studyVm = context.read<StudyPlannerViewModel>();
        final subjects = studyVm.profile?.subjects ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Mindful Pomodoro ⏱️',
              style: GoogleFonts.lora(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 20),
                  onPressed: () => _showSettings(context, vm),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Phase selector
                _PhaseSelector(vm: vm),
                const SizedBox(height: 28),
                // Circular timer
                _CircularTimer(vm: vm),
                const SizedBox(height: 28),
                // Subject selector
                _SubjectSelector(vm: vm, subjects: subjects),
                const SizedBox(height: 24),
                // Control buttons
                _ControlButtons(vm: vm),
                const SizedBox(height: 24),
                // Session count
                _SessionDots(vm: vm),
                const SizedBox(height: 24),
                // Tips
                _PomodoroTips(phase: vm.phase),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context, PomodoroViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PomodoroSettings(vm: vm),
    );
  }
}

class _PhaseSelector extends StatelessWidget {
  final PomodoroViewModel vm;
  const _PhaseSelector({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
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
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (!vm.isRunning) vm.skipPhase();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? vm.phaseColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: vm.phaseColor.withAlpha(80),
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
                        color: isSelected ? Colors.white : AppColors.textSecondary,
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

class _CircularTimer extends StatelessWidget {
  final PomodoroViewModel vm;
  const _CircularTimer({required this.vm});

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 125,
      lineWidth: 12,
      animation: false,
      percent: vm.progress,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: vm.phaseColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              vm.phaseLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: vm.phaseColor,
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
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
            ),
          ),
          Text(
            vm.isRunning ? 'Active session' : 'Paused',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: vm.isRunning ? AppColors.secondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
      progressColor: vm.phaseColor,
      backgroundColor: vm.phaseColor.withAlpha(30),
      circularStrokeCap: CircularStrokeCap.round,
    );
  }
}

class _SubjectSelector extends StatelessWidget {
  final PomodoroViewModel vm;
  final List subjects;

  const _SubjectSelector({required this.vm, required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.selectedSubjectId,
          hint: Text(
            'Attribution: Select subject',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.textSecondary),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text('General Focus (No Subject)', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            ),
            ...subjects.map((s) => DropdownMenuItem(
              value: s.id,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(s.name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
          ],
          onChanged: (id) {
            final name = subjects.firstWhere((s) => s.id == id, orElse: () => subjects.first).name;
            vm.selectSubject(id, id == null ? null : name);
          },
        ),
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final PomodoroViewModel vm;
  const _ControlButtons({required this.vm});

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
              color: vm.phaseColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: vm.phaseColor.withAlpha(100),
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

  const _CircleButton({required this.icon, required this.onTap, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderLight, width: 1.2),
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
  const _SessionDots({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cycle ${vm.completedSessions % vm.sessionsBeforeLongBreak + 1} of ${vm.sessionsBeforeLongBreak}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textPrimary,
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
                  color: isDone ? AppColors.primary : Colors.white,
                  border: Border.all(color: isDone ? AppColors.primary : const Color(0xFFD6CBC0)),
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

class _PomodoroTips extends StatelessWidget {
  final PomodoroPhase phase;
  const _PomodoroTips({required this.phase});

  @override
  Widget build(BuildContext context) {
    final tips = phase == PomodoroPhase.work
        ? ['📵 Keep phone away or on silent', '☕ One study objective at a time', '💧 Drink water between sessions']
        : ['🚶 Step away from screens and stretch', '🧘 Take 3 slow, deep conscious breaths', '🌿 Rest your eyes on distant objects'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                phase == PomodoroPhase.work ? '💡 Mindful Study Focus' : '☕ Rest & Restore',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tip,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
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
