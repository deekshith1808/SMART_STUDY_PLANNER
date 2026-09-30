import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/data/services/supabase_service.dart';
import 'package:smart_study_planner/ui/features/auth/supabase_sync_sheet.dart';
import 'package:smart_study_planner/ui/features/pomodoro/focus_shield_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          maxChildSize: 0.92,
          builder: (_, ctrl) => Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 8),
                decoration: BoxDecoration(color: const Color(0xFFD6CBC0), borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  children: [
                    Row(
                      children: [
                        Text(
                          'Student Preferences ⚙️',
                          style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Profile section
                    _SettingsSection(
                      title: 'Student Identity',
                      children: [
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Learner Name',
                          subtitle: vm.profile?.name ?? 'Not set',
                          iconColor: AppColors.primary,
                          onTap: () {},
                        ),
                        const Divider(height: 1, indent: 64, color: AppColors.borderLight),
                        _SettingsTile(
                          icon: Icons.school_outlined,
                          title: 'Education Stage',
                          subtitle: vm.profile != null
                              ? '${vm.profile!.educationType == 'college' ? 'College' : 'School'}${vm.profile!.branch != null ? ' · ${vm.profile!.branch}' : ''}'
                              : 'Not set',
                          iconColor: AppColors.secondary,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Appearance section
                    _SettingsSection(
                      title: 'Display & Ambiance',
                      children: [
                        _SettingsToggle(
                          icon: Icons.dark_mode_outlined,
                          title: 'Roasted Charcoal Dark Mode',
                          subtitle: 'Cozy dark palette for evening study',
                          value: vm.isDarkMode,
                          onChanged: (_) => vm.toggleDarkMode(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Focus Shield & Social Media Blocker
                    _SettingsSection(
                      title: 'Focus Shield & Anti-Distraction',
                      children: [
                        Consumer<PomodoroViewModel>(
                          builder: (context, pomodoroVm, _) {
                            final config = pomodoroVm.shieldConfig;
                            final enabledApps = config.blockedApps.where((a) => a.isEnabled).length;
                            return _SettingsTile(
                              icon: Icons.shield_rounded,
                              title: 'Social Media Blocker',
                              subtitle: config.isShieldEnabled
                                  ? 'Active during focus • $enabledApps apps guarded • ${config.blockedAttemptsCount} shielded'
                                  : 'Disabled • Tap to configure',
                              iconColor: const Color(0xFFDC2626),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: config.isShieldEnabled ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: config.isShieldEnabled ? const Color(0xFFFECACA) : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Text(
                                  config.isShieldEnabled ? 'Guarded 🛡️' : 'Off',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: config.isShieldEnabled ? const Color(0xFF991B1B) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              onTap: () => FocusShieldSheet.show(context, pomodoroVm),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Study tips section
                    _SettingsSection(
                      title: 'Mindful Learning Principles',
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _studyTips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(tip.emoji, style: const TextStyle(fontSize: 16)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      tip.tip,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Cloud Sync section
                    _SettingsSection(
                      title: 'Cloud Sync & Supabase',
                      children: [
                        _SettingsTile(
                          icon: Icons.cloud_sync_rounded,
                          title: 'Supabase Cloud Sync',
                          subtitle: SupabaseService().currentUser != null
                              ? 'Logged in as ${SupabaseService().currentUser?.email}'
                              : (SupabaseConfig.isConfigured
                                  ? 'Connected • Tap to sign in or backup data'
                                  : 'Offline Mode • Tap to configure credentials'),
                          iconColor: AppColors.secondary,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (SupabaseConfig.isConfigured && SupabaseService().currentUser != null)
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  SupabaseService().currentUser != null ? 'Synced' : 'Setup',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: (SupabaseConfig.isConfigured && SupabaseService().currentUser != null)
                                        ? const Color(0xFF065F46)
                                        : const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                          onTap: () => SupabaseSyncSheet.show(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    // Data management
                    _SettingsSection(
                      title: 'Data & Storage',
                      children: [
                        _SettingsTile(
                          icon: Icons.delete_outline_rounded,
                          title: 'Reset Study Data',
                          subtitle: 'Clear all tasks, notes and start fresh',
                          iconColor: AppColors.error,
                          onTap: () => _showResetDialog(context, vm),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        'StudySmart • Handcrafted for calm focus',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showResetDialog(BuildContext context, StudyPlannerViewModel vm) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset All Data?', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: Text(
          'This will erase all your subjects, tasks, sticky notes, and recorded study hours. This action cannot be reversed.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await vm.clearAll();
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close settings bottom sheet
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        activeThumbColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withAlpha(50),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _StudyTip {
  final String emoji;
  final String tip;
  const _StudyTip(this.emoji, this.tip);
}

final _studyTips = [
  const _StudyTip('🧠', 'Active Recall: Testing yourself on paper yields 2x higher retention than passive reading.'),
  const _StudyTip('☕', 'Spaced Repetition: Review a concept at 1 day, 3 days, and 7 days for long-term mastery.'),
  const _StudyTip('🌱', 'Interleaved Practice: Mix two related topics in one study block to sharpen conceptual distinction.'),
  const _StudyTip('💧', 'Hydration & Rhythm: Even mild dehydration drops brain focus by 12%. Keep a warm mug or glass close.'),
  const _StudyTip('✍️', 'Handwritten Cues: Writing notes or formulas activates the brain’s motor memory centers.'),
  const _StudyTip('🌙', 'Sleep Consolidation: The hippocampus processes and stores daytime learning during deep rest.'),
];
