import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../home/study_planner_view_model.dart';

class FocusSanctuaryDialog extends StatelessWidget {
  final PomodoroViewModel vm;
  const FocusSanctuaryDialog({super.key, required this.vm});

  static void show(BuildContext context, PomodoroViewModel vm) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FocusSanctuaryDialog(vm: vm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final enabledCount = vm.shieldConfig.blockedApps.where((a) => a.isEnabled).length;
        final blockedAppEmojis = vm.shieldConfig.blockedApps
            .where((a) => a.isEnabled)
            .take(6)
            .map((a) => a.iconEmoji)
            .join(' ');

        return Scaffold(
          backgroundColor: const Color(0xFF181512),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDC2626).withAlpha(100)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_rounded, color: Color(0xFFF87171), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'SHIELD ACTIVE • $enabledCount BLOCKED',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFFCA5A5),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_fullscreen_rounded, color: Color(0xFFD6CBC0)),
                        tooltip: 'Exit Sanctuary View',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Subject Badge
                  if (vm.selectedSubjectName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A231C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF43382D)),
                      ),
                      child: Text(
                        '📚 ${vm.selectedSubjectName}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE6D7C3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Massive Circular Timer
                  CircularPercentIndicator(
                    radius: 140,
                    lineWidth: 14,
                    animation: false,
                    percent: vm.progress,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vm.formattedTime,
                          style: GoogleFonts.lora(
                            fontSize: 58,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vm.isRunning ? 'DEEP STUDY SPRINT' : 'PAUSED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: vm.isRunning ? const Color(0xFFFB923C) : const Color(0xFFA8A29E),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    progressColor: const Color(0xFFEA580C),
                    backgroundColor: const Color(0xFF2A231C),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 32),

                  // Blocked Apps Emojis Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF231E18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF382E24)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🚫 Blocked: ', style: TextStyle(color: Color(0xFFA8A29E), fontSize: 12)),
                        Text(blockedAppEmojis, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: vm.reset,
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFFA8A29E), size: 28),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: vm.isRunning ? vm.pause : vm.start,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEA580C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEA580C).withAlpha(120),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            vm.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        onPressed: vm.skipPhase,
                        icon: const Icon(Icons.skip_next_rounded, color: Color(0xFFA8A29E), size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
