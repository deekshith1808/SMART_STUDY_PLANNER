import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/parental_control.dart';
import 'package:smart_study_planner/ui/features/parental/parent_pin_dialog.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  static Future<void> open(BuildContext context) async {
    final vm = context.read<StudyPlannerViewModel>();
    // Verify PIN if parental controls already have a PIN set
    final verified = await ParentPinDialog.show(
      context,
      onVerify: (pin) => vm.verifyParentPin(pin),
    );
    if (verified && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ParentDashboardScreen()),
      );
    }
  }

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudyPlannerViewModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final live = vm.effectiveLiveStatus;
    final config = vm.parentalConfig;
    final examInfo = vm.activeOrUpcomingExam;

    final bgColor = isDark ? const Color(0xFF161514) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF242220) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1D1B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_rounded, size: 20, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Text(
                  'Parent App Controller',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Guardian Command Center • Monitoring: ${live.studentName}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF92400E)),
                const SizedBox(width: 4),
                Text(
                  config.familyPairingCode,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.radar_rounded, size: 18), text: 'Live Monitor'),
            Tab(icon: Icon(Icons.block_rounded, size: 18), text: 'App Blocker'),
            Tab(icon: Icon(Icons.tune_rounded, size: 18), text: 'Rules & PIN'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveMonitorTab(context, vm, live, config, examInfo, cardBg, isDark),
          _buildAppBlockerTab(context, vm, live, config, examInfo, cardBg, isDark),
          _buildRulesAndPinTab(context, vm, live, config, cardBg, isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: LIVE MONITOR (Is My Child Studying?)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLiveMonitorTab(
    BuildContext context,
    StudyPlannerViewModel vm,
    ChildLiveStatus live,
    ParentalControlConfig config,
    Map<String, dynamic>? examInfo,
    Color cardBg,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. Live Pulse Study Status Card
        _buildLivePulseCard(live, examInfo, cardBg, isDark),
        const SizedBox(height: 14),

        // 2. Today's Study Hours vs Daily Goal
        _buildDailyProgressCard(live, cardBg, isDark),
        const SizedBox(height: 14),

        // 3. Quick Parent Encouragement / Nudge to Child's screen
        _buildParentNudgeCard(context, vm, cardBg, isDark),
        const SizedBox(height: 14),

        // 4. Distraction Breaches Log
        _buildBreachAuditCard(context, vm, live, cardBg, isDark),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLivePulseCard(
    ChildLiveStatus live,
    Map<String, dynamic>? examInfo,
    Color cardBg,
    bool isDark,
  ) {
    Color statusColor;
    String statusTitle;
    String statusDesc;
    IconData statusIcon;

    if (live.isLockdownActive && live.breachCount > 0 && !live.isStudyingNow) {
      statusColor = AppColors.error;
      statusTitle = '⚠️ DISTRACTION ALERT';
      statusDesc = 'Student attempted to leave study environment during exam prep!';
      statusIcon = Icons.warning_amber_rounded;
    } else if (live.isStudyingNow) {
      statusColor = const Color(0xFF047857);
      statusTitle = '🟢 STUDYING RIGHT NOW';
      statusDesc = live.currentSubject != null
          ? 'Deeply focused on: ${live.currentSubject}'
          : 'Active focus session in progress';
      statusIcon = Icons.menu_book_rounded;
    } else if (live.currentPhase == 'Break') {
      statusColor = const Color(0xFFD97706);
      statusTitle = '🟡 SCHEDULED RECOVERY BREAK';
      statusDesc = 'Taking a healthy recharge break between focus intervals';
      statusIcon = Icons.coffee_rounded;
    } else {
      statusColor = const Color(0xFF6B7280);
      statusTitle = '⚪ NOT STUDYING (IDLE)';
      statusDesc = 'Child is currently inactive. No active focus session running.';
      statusIcon = Icons.pause_circle_outline_rounded;
    }

    final minutes = live.sessionSecondsRemaining ~/ 60;
    final seconds = live.sessionSecondsRemaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withAlpha(80),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      statusTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (live.isLockdownActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_rounded, size: 12, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        'Shield Active',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            statusDesc,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (live.isStudyingNow && live.sessionSecondsRemaining > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1D1B) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF059669)),
                  const SizedBox(width: 10),
                  Text(
                    'Pomodoro Timer Remaining:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (examInfo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_note_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      live.activeExamReason ?? 'Upcoming Exam detected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyProgressCard(
    ChildLiveStatus live,
    Color cardBg,
    bool isDark,
  ) {
    final studyHours = (live.todayStudyMinutes / 60).toStringAsFixed(1);
    final targetHours = (live.todayTargetMinutes / 60).toStringAsFixed(1);
    final progress = live.todayProgress;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Focus Goal',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Met',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            lineHeight: 12,
            percent: progress,
            backgroundColor: isDark ? const Color(0xFF33312E) : const Color(0xFFEDE5DA),
            progressColor: AppColors.primary,
            barRadius: const Radius.circular(8),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$studyHours hrs studied',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Goal: $targetHours hrs/day',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParentNudgeCard(
    BuildContext context,
    StudyPlannerViewModel vm,
    Color cardBg,
    bool isDark,
  ) {
    final quickMessages = [
      'Focus now, exam is tomorrow! 📚',
      'Put down the phone and study! 📵',
      'Proud of your focus, keep going! ⭐',
      'Take a 5-min water break 💧',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send_rounded, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                'Send Live Nudge to Child\'s Screen',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Instantly pops up an unmissable alert on your child\'s screen.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: quickMessages.map((msg) {
              return ActionChip(
                backgroundColor: isDark ? const Color(0xFF2E2C29) : const Color(0xFFEFF6FF),
                side: BorderSide(color: const Color(0xFFBFDBFE)),
                label: Text(
                  msg,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D4ED8),
                  ),
                ),
                onPressed: () async {
                  await vm.sendParentNudge(msg);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nudge sent to child: "$msg"'),
                        backgroundColor: const Color(0xFF047857),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreachAuditCard(
    BuildContext context,
    StudyPlannerViewModel vm,
    ChildLiveStatus live,
    Color cardBg,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded, size: 18, color: AppColors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Distraction Audit Log',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: live.breachCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${live.breachCount} Infractions',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: live.breachCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (live.breachLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '✨ Clean focus streak! No app switches or breaches detected today.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            for (final log in live.breachLogs.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1D1B) : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.exit_to_app_rounded, size: 16, color: Color(0xFFC2410C)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.reason,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${DateFormat('hh:mm a').format(log.timestamp)} • Subject: ${log.subject}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (log.parentPhoneNumber != null && log.parentPhoneNumber!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.phonelink_ring_rounded, size: 11, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Alert routed to: ${log.parentPhoneNumber}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0284C7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => vm.clearBreachLogs(),
                child: Text(
                  'Clear Audit Log',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: APP BLOCKER & EXAM LOCKDOWN (Requirement 1)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAppBlockerTab(
    BuildContext context,
    StudyPlannerViewModel vm,
    ChildLiveStatus live,
    ParentalControlConfig config,
    Map<String, dynamic>? examInfo,
    Color cardBg,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1. Master Enable Parental Controls Switch
        _buildMasterSwitchCard(context, vm, config, cardBg),
        const SizedBox(height: 14),

        // 2. Exam-Eve Auto-Lockdown Switch (Requirement 1)
        _buildExamAutoLockCard(context, vm, config, examInfo, cardBg, isDark),
        const SizedBox(height: 14),

        // 3. Instant Emergency Lock Switch
        _buildEmergencyLockCard(context, vm, config, cardBg, isDark),
        const SizedBox(height: 14),

        // 4. Distracting Apps Blacklist
        _buildBlockedAppsCard(context, vm, config, cardBg, isDark),
        const SizedBox(height: 14),

        // 5. System-Level Lockdown Instructions (Android / iOS)
        _buildSystemGuidanceCard(context, cardBg, isDark),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMasterSwitchCard(
    BuildContext context,
    StudyPlannerViewModel vm,
    ParentalControlConfig config,
    Color cardBg,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: config.isEnabled ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: config.isEnabled ? const Color(0xFF047857) : const Color(0xFF9CA3AF),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parental Controls Master',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  config.isEnabled
                      ? 'Active • Guardian rules enforced'
                      : 'Disabled • Tap toggle to activate',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: config.isEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => vm.setParentalControlsEnabled(val),
          ),
        ],
      ),
    );
  }

  Widget _buildExamAutoLockCard(
    BuildContext context,
    StudyPlannerViewModel vm,
    ParentalControlConfig config,
    Map<String, dynamic>? examInfo,
    Color cardBg,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: examInfo != null ? const Color(0xFFF59E0B) : AppColors.borderLight,
          width: examInfo != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.alarm_on_rounded, size: 20, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Upcoming Exam Auto-Lockdown',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: config.autoLockOnExamDays,
                activeThumbColor: const Color(0xFFD97706),
                onChanged: config.isEnabled
                    ? (val) => vm.updateExamLockSettings(
                          autoLock: val,
                          daysBefore: config.lockDaysBeforeExam,
                        )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Automatically disables distracting apps and turns on strict study mode when an exam is tomorrow or in upcoming days.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Days Window Selector
          Text(
            'ACTIVATE LOCKDOWN WINDOW:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildWindowChip(
                label: '1 Day (Eve of Exam)',
                selected: config.lockDaysBeforeExam == 1,
                onTap: () => vm.updateExamLockSettings(
                  autoLock: config.autoLockOnExamDays,
                  daysBefore: 1,
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildWindowChip(
                label: '2 Days Before',
                selected: config.lockDaysBeforeExam == 2,
                onTap: () => vm.updateExamLockSettings(
                  autoLock: config.autoLockOnExamDays,
                  daysBefore: 2,
                ),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildWindowChip(
                label: '3 Days Before',
                selected: config.lockDaysBeforeExam == 3,
                onTap: () => vm.updateExamLockSettings(
                  autoLock: config.autoLockOnExamDays,
                  daysBefore: 3,
                ),
                isDark: isDark,
              ),
            ],
          ),

          // Live Exam Detected Notification
          if (examInfo != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notification_important_rounded,
                      size: 24, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${examInfo['title']} (${examInfo['subject']})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          examInfo['isToday'] == true
                              ? 'Exam is scheduled for TODAY! Distraction shield engaged.'
                              : (examInfo['isTomorrow'] == true
                                  ? 'Exam is TOMORROW! Distraction apps are restricted.'
                                  : 'Exam is in ${examInfo['daysRemaining']} days. Shield active.'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'ℹ️ No exams within your ${config.lockDaysBeforeExam}-day window. Shield will auto-engage when exam date approaches.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWindowChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFD97706)
                : (isDark ? const Color(0xFF2C2A28) : const Color(0xFFF4ECE1)),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyLockCard(
    BuildContext context,
    StudyPlannerViewModel vm,
    ParentalControlConfig config,
    Color cardBg,
    bool isDark,
  ) {
    final isLocked = config.isEmergencyLockActive;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLocked ? AppColors.error : AppColors.borderLight,
          width: isLocked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLocked ? const Color(0xFFFEE2E2) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
              color: isLocked ? AppColors.error : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Remote Lockdown',
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  isLocked
                      ? 'ACTIVATED • All distracting apps locked right now'
                      : 'Lock child\'s distracting apps instantly anytime',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: isLocked ? AppColors.error : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isLocked,
            activeThumbColor: AppColors.error,
            onChanged: config.isEnabled
                ? (val) => vm.toggleEmergencyLock(val)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsCard(
    BuildContext context,
    StudyPlannerViewModel vm,
    ParentalControlConfig config,
    Color cardBg,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Distracting Apps to Restrict',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                color: AppColors.primary,
                onPressed: () => _showAddAppDialog(context, vm),
              ),
            ],
          ),
          Text(
            'Targeted for restriction during study sessions and exam periods.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          for (final app in config.blockedApps)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: true,
              activeColor: AppColors.primary,
              title: Text(
                app,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              secondary: const Icon(Icons.app_blocking_rounded, size: 18, color: Color(0xFFC2410C)),
              onChanged: (_) => vm.toggleBlockedApp(app),
            ),
        ],
      ),
    );
  }

  void _showAddAppDialog(BuildContext context, StudyPlannerViewModel vm) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add App to Blocklist', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'e.g., Clash of Clans, WhatsApp',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.addBlockedApp(textController.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add App'),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemGuidanceCard(
    BuildContext context,
    Color cardBg,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1D1B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, size: 20, color: Color(0xFF059669)),
              const SizedBox(width: 8),
              Text(
                'Complete OS Kiosk Guide (Zero Loophole)',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'To make distraction blocking 100% unbreakable on your child\'s device during exam week:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF047857),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          _buildBullet(
            'Android: Enable "App Pinning" (Settings > Security > App Pinning). Pin StudySmart to lock the screen completely until Parent PIN is entered.',
          ),
          const SizedBox(height: 4),
          _buildBullet(
            'iOS / iPhone: Turn on "Guided Access" (Settings > Accessibility > Guided Access). Triple click the power button to lock phone to StudySmart.',
          ),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontSize: 14, color: Color(0xFF059669))),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF065F46),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: RULES, DAILY TARGET & PIN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRulesAndPinTab(
    BuildContext context,
    StudyPlannerViewModel vm,
    ChildLiveStatus live,
    ParentalControlConfig config,
    Color cardBg,
    bool isDark,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Daily Study Hours Goal Setting
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required Daily Study Goal',
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Current Target: ${(config.dailyStudyTargetMinutes / 60).toStringAsFixed(1)} hours/day',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
              ),
              Slider(
                value: config.dailyStudyTargetMinutes.toDouble(),
                min: 60,
                max: 480,
                divisions: 14,
                activeColor: AppColors.primary,
                label: '${(config.dailyStudyTargetMinutes / 60).toStringAsFixed(1)} hrs',
                onChanged: (val) => vm.setDailyTargetMinutes(val.toInt()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Security PIN Change
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.password_rounded, size: 20, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    'Parent Master Security PIN',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Required to enter Parent Controller and unlock apps during lockdown.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showChangePinDialog(context, vm),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Change 4-Digit PIN (Default: 1234)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Father / Parent Verified Identification & Alert Contacts ─────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (config.fatherPhone != null && config.fatherPhone!.isNotEmpty)
                  ? const Color(0xFF38BDF8)
                  : AppColors.borderLight,
              width: (config.fatherPhone != null && config.fatherPhone!.isNotEmpty) ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, size: 20, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Father / Guardian Verified Contact",
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Identifies who the father is. Real-time study pulse, exam lockdown statuses, and instant distraction breach alerts are dispatched to these contacts.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // 1. Mobile Number Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_iphone_rounded, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Father's Mobile Number",
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary),
                          ),
                          Text(
                            (config.fatherPhone != null && config.fatherPhone!.isNotEmpty)
                                ? config.fatherPhone!
                                : 'No Mobile Number Set',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: (config.fatherPhone != null && config.fatherPhone!.isNotEmpty)
                                  ? const Color(0xFF0369A1)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (config.fatherPhone != null && config.fatherPhone!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SMS & Push Active',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2. Email Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF261D3B) : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Father's Email ID",
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppColors.textSecondary),
                          ),
                          Text(
                            (config.fatherEmail != null && config.fatherEmail!.isNotEmpty)
                                ? config.fatherEmail!
                                : 'No Email ID Set',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: (config.fatherEmail != null && config.fatherEmail!.isNotEmpty)
                                  ? const Color(0xFF6D28D9)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (config.fatherEmail != null && config.fatherEmail!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Linked',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showChangePhoneDialog(context, vm),
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Update Contacts'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0284C7),
                        side: const BorderSide(color: Color(0xFF0284C7)),
                      ),
                    ),
                  ),
                  if (config.fatherPhone != null && config.fatherPhone!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await vm.sendTestParentAlert();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Test notification sent to: ${config.fatherPhone}'),
                              backgroundColor: const Color(0xFF047857),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.notifications_active_rounded, size: 16),
                      label: const Text('Test Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Family Pairing Code (for Separate Phone setup)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.phonelink_setup_rounded, size: 20, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    'Multi-Device Phone Pairing',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Install StudySmart on the parent\'s mobile phone and enter this Family Code to control and monitor remotely via Supabase Cloud Sync.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2A28) : const Color(0xFFF5F3EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      config.familyPairingCode,
                      style: GoogleFonts.spaceMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 2.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      onPressed: () {
                        final newCode = 'STUDY-${(1000 + (DateTime.now().millisecondsSinceEpoch % 9000))}';
                        vm.updateFamilyPairingCode(newCode);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Cloud Sync & Push Notifications to Parent ───────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: vm.isCloudSyncEnabled
                  ? const Color(0xFF34D399)
                  : AppColors.borderLight,
              width: vm.isCloudSyncEnabled ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    vm.isCloudSyncEnabled
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    size: 20,
                    color: vm.isCloudSyncEnabled
                        ? const Color(0xFF059669)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cloud Sync & Parent Notifications',
                      style: GoogleFonts.lora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: vm.isCloudSyncEnabled,
                    activeThumbColor: const Color(0xFF059669),
                    onChanged: config.isEnabled
                        ? (val) {
                            if (val) {
                              vm.enableCloudSync();
                            } else {
                              vm.disableCloudSync();
                            }
                          }
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vm.isCloudSyncEnabled
                    ? '✅ Cloud sync is ACTIVE. Parent\'s phone will receive '
                      'instant push notifications when your child leaves the '
                      'study app during exams or lockdown.'
                    : 'Enable to sync parental controls to the cloud. The '
                      'parent\'s phone will get push notifications when the '
                      'child tries to leave the app during study/exam time.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: vm.isCloudSyncEnabled
                      ? const Color(0xFF047857)
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (vm.isCloudSyncEnabled) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1D1B)
                        : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📱 How to setup on Parent\'s Phone:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildBullet(
                        '1. Install Smart Study Planner on parent\'s phone',
                      ),
                      const SizedBox(height: 2),
                      _buildBullet(
                        '2. Go to Settings → Parental Controls',
                      ),
                      const SizedBox(height: 2),
                      _buildBullet(
                        '3. Enter the Family Code: ${config.familyPairingCode}',
                      ),
                      const SizedBox(height: 2),
                      _buildBullet(
                        '4. Tap "I am the Parent" to activate parent mode',
                      ),
                      const SizedBox(height: 2),
                      _buildBullet(
                        '5. Parent will get instant notifications when child '
                        'leaves the app during exams! 🔔',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ─── Parent Device Mode (only shown on parent's phone) ───
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: vm.isParentDevice
                ? (isDark
                    ? const Color(0xFF1B2838)
                    : const Color(0xFFEFF6FF))
                : cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: vm.isParentDevice
                  ? const Color(0xFF3B82F6)
                  : AppColors.borderLight,
              width: vm.isParentDevice ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    vm.isParentDevice
                        ? Icons.phonelink_rounded
                        : Icons.phone_android_rounded,
                    size: 20,
                    color: vm.isParentDevice
                        ? const Color(0xFF2563EB)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'I am the Parent (Remote Control)',
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                vm.isParentDevice
                    ? '🟢 Parent Device Mode ACTIVE\n'
                      'You are receiving real-time alerts from your child\'s '
                      'phone. Push notifications will appear even when this '
                      'app is in the background.'
                    : 'Tap below if this is the PARENT\'S phone. This will '
                      'start receiving real-time push notifications whenever '
                      'your child leaves the study app during exam period.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: vm.isParentDevice
                      ? const Color(0xFF1D4ED8)
                      : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (vm.isParentDevice) ...[
                if (vm.unreadRemoteAlerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notification_important_rounded,
                            size: 20, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${vm.unreadRemoteAlerts.length} unread distraction alert(s)!',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => vm.markRemoteAlertsRead(),
                          child: const Text('Clear',
                              style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => vm.refreshRemoteData(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Refresh Status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => vm.deactivateParentDeviceMode(),
                        icon: const Icon(Icons.stop_rounded, size: 16),
                        label: const Text('Stop Monitoring'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: config.isEnabled
                        ? () => vm.activateParentDeviceMode()
                        : null,
                    icon: const Icon(Icons.notifications_active_rounded,
                        size: 18),
                    label: const Text(
                      'Activate Parent Mode & Push Notifications',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showChangePinDialog(BuildContext context, StudyPlannerViewModel vm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Change Master PIN', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter new 4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.length == 4) {
                vm.updateParentPin(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Security PIN successfully updated!'),
                    backgroundColor: Color(0xFF047857),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context, StudyPlannerViewModel vm) {
    final phoneController =
        TextEditingController(text: vm.parentalConfig.fatherPhone ?? '');
    final emailController =
        TextEditingController(text: vm.parentalConfig.fatherEmail ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Father's Contact Details",
          style: GoogleFonts.lora(fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the father\'s mobile number and email ID. '
                'Real-time alerts, lockdown notices, and SMS links are routed to these contacts.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Father's Mobile Number",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+91 9876543210 or 9876543210',
                  prefixIcon: Icon(Icons.phone_rounded, color: Color(0xFF0284C7)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Father's Email ID",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'e.g. father@gmail.com',
                  prefixIcon: Icon(Icons.email_rounded, color: Color(0xFF7C3AED)),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              final email = emailController.text.trim();
              if (phone.isNotEmpty || email.isNotEmpty) {
                vm.updateFatherCredentials(
                  phone: phone,
                  email: email,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Father's contact updated: ${phone.isNotEmpty ? phone : email}"),
                    backgroundColor: const Color(0xFF047857),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Contacts'),
          ),
        ],
      ),
    );
  }
}
