import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';

class ParentNudgeDialog extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ParentNudgeDialog({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  static void showIfAvailable(BuildContext context, StudyPlannerViewModel vm) {
    final nudge = vm.parentalConfig.lastParentNudge;
    if (nudge != null && nudge.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ParentNudgeDialog(
          message: nudge,
          onDismiss: () => vm.dismissNudge(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_chat_unread_rounded,
                size: 36,
                color: Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Message from Guardian 👨‍👩‍👧',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8DFD3)),
              ),
              child: Text(
                '"$message"',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  onDismiss();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text('I\'m on it! Start Studying 📖'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
