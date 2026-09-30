import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/ui/features/parental/parent_pin_dialog.dart';

class ExamLockdownBanner extends StatelessWidget {
  const ExamLockdownBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudyPlannerViewModel>();
    if (!vm.isExamLockdownActive) return const SizedBox.shrink();

    final exam = vm.activeOrUpcomingExam;
    final isEmergency = vm.parentalConfig.isEmergencyLockActive;

    String headline;
    String subline;

    if (isEmergency) {
      headline = 'Emergency Guardian Lockdown Active 🔒';
      subline = 'Distracting apps restricted by parent. Focus on your revision!';
    } else if (exam != null) {
      final title = exam['title'] ?? 'Upcoming Exam';
      final isTomorrow = exam['isTomorrow'] == true;
      final isToday = exam['isToday'] == true;
      headline = isToday
          ? '🎯 $title is TODAY!'
          : (isTomorrow ? '⏳ $title is TOMORROW!' : '📅 $title in ${exam['daysRemaining']} Days');
      subline = 'Guardian Distraction Shield engaged: Social media & entertainment locked.';
    } else {
      headline = 'Exam Preparation Lockdown Active 🛡️';
      subline = 'Focus mode enforced by parent controller.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF991B1B), Color(0xFFC2410C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  headline,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subline,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white.withAlpha(220),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final verified = await ParentPinDialog.show(
                context,
                title: 'Guardian Unlock',
                subtitle: 'Enter Parent Security PIN to temporarily adjust lockdown',
                onVerify: (pin) => vm.verifyParentPin(pin),
              );
              if (verified && context.mounted) {
                vm.toggleEmergencyLock(false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lockdown adjusted with parent approval.'),
                    backgroundColor: Color(0xFF047857),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Parent PIN',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
