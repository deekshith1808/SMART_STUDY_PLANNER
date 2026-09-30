import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../domain/models/focus_shield.dart';
import '../../core/app_theme.dart';
import '../home/study_planner_view_model.dart';

class SocialMediaBlockedDialog extends StatefulWidget {
  final String url;
  final BlockedApp? blockedApp;
  final PomodoroViewModel pomodoroVm;

  const SocialMediaBlockedDialog({
    super.key,
    required this.url,
    this.blockedApp,
    required this.pomodoroVm,
  });

  @override
  State<SocialMediaBlockedDialog> createState() => _SocialMediaBlockedDialogState();
}

class _SocialMediaBlockedDialogState extends State<SocialMediaBlockedDialog> {
  bool _isEmergencyUnlocking = false;
  int _unlockCountdown = 10;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startEmergencyUnlock() {
    setState(() {
      _isEmergencyUnlocking = true;
      _unlockCountdown = widget.pomodoroVm.shieldConfig.strictMode ? 10 : 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_unlockCountdown > 1) {
        setState(() => _unlockCountdown--);
      } else {
        timer.cancel();
        _proceedWithEmergencyUnlock();
      }
    });
  }

  void _cancelEmergencyUnlock() {
    _countdownTimer?.cancel();
    setState(() {
      _isEmergencyUnlocking = false;
      _unlockCountdown = 10;
    });
  }

  Future<void> _proceedWithEmergencyUnlock() async {
    widget.pomodoroVm.pause();
    if (mounted) {
      Navigator.of(context).pop(true);
    }
    try {
      await launchUrlString(widget.url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final appName = widget.blockedApp?.name ?? 'Social Media & Apps';
    final emoji = widget.blockedApp?.iconEmoji ?? '🛡️';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Shield Icon with Glow
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withAlpha(40),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 38),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 22),
                const SizedBox(width: 6),
                Text(
                  'Focus Shield Active',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Block Description
            Text(
              '$appName is blocked to protect your deep focus flow.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF991B1B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Live Timer pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.pomodoroVm.formattedTime} Remaining in Sprint',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subject context if selected
            if (widget.pomodoroVm.selectedSubjectName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '🎯 Focus Topic: ${widget.pomodoroVm.selectedSubjectName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Motivational quote / Mindful prompt
            if (!_isEmergencyUnlocking) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  '💡 "Distraction is the enemy of mastery. Finish this session first!"',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                  label: Text(
                    'Stay in Flow & Focus',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _startEmergencyUnlock,
                child: Text(
                  'Emergency Pass (Pause Timer)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ] else ...[
              // Emergency unlocking countdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  children: [
                    Text(
                      '🧘 Take a slow, conscious breath...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unlocking in $_unlockCountdown seconds',
                      style: GoogleFonts.lora(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelEmergencyUnlock,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Cancel & Keep Studying',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
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
