import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/data/services/supabase_service.dart';
import 'package:smart_study_planner/ui/features/auth/supabase_sync_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_study_planner/ui/features/pomodoro/focus_shield_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: context.watch<StudyPlannerViewModel>(),
      builder: (context, _) {
        final vm = context.read<StudyPlannerViewModel>();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          maxChildSize: 0.92,
          builder: (_, ctrl) => Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 14, bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFD6CBC0),
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                            style: GoogleFonts.lora(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
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
                          subtitle: vm.profile?.name.isNotEmpty == true
                              ? vm.profile!.name
                              : 'Tap to set learner name',
                          iconColor: AppColors.primary,
                          trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                          onTap: () => _showEditNameDialog(context, vm),
                        ),
                        const Divider(height: 1, indent: 64, color: AppColors.borderLight),
                        _SettingsTile(
                          icon: Icons.school_outlined,
                          title: 'Education Stage',
                          subtitle: vm.profile != null
                              ? '${vm.profile!.educationType == 'college' ? 'College' : 'School'}${vm.profile!.branch != null ? ' · ${vm.profile!.branch}' : ''}${vm.profile!.course != null ? ' (${vm.profile!.course})' : ''}'
                              : 'Tap to configure education stage',
                          iconColor: AppColors.secondary,
                          trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.secondary),
                          onTap: () => _showEditEducationDialog(context, vm),
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
                          title: 'Realistic OLED Dark Mode',
                          subtitle: 'Midnight black with electric blue & purple accents',
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
                      title: 'Cloud Sync & Account Isolation',
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
                        if (vm.isAuthenticated) ...[
                          const Divider(height: 1, indent: 64, color: AppColors.borderLight),
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign Out Account',
                            subtitle: 'Switch accounts cleanly without mixing data',
                            iconColor: const Color(0xFFE11D48),
                            onTap: () async {
                              await vm.onSignOut();
                              if (context.mounted) {
                                Navigator.pop(context);
                                context.go('/login');
                              }
                            },
                          ),
                        ],
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
        ),
      );
    },
  );
}

  void _showEditNameDialog(BuildContext context, StudyPlannerViewModel vm) {
    final controller = TextEditingController(text: vm.profile?.name ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Learner Name', style: GoogleFonts.lora(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            labelText: 'Learner Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && vm.profile != null) {
                await vm.saveProfile(vm.profile!.copyWith(name: newName));
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditEducationDialog(BuildContext context, StudyPlannerViewModel vm) {
    String currentType = vm.profile?.educationType ?? 'college';
    String? currentBranch = vm.profile?.branch;
    final courseController = TextEditingController(text: vm.profile?.course ?? '');
    final branches = [
      'Engineering & Tech',
      'Medical & Health',
      'Arts & Humanities',
      'Natural Sciences',
      'Commerce & Mgmt',
      'Law & Governance',
      'Other Studies',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Education Stage & Details',
                      style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text('Education Stage:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('School 🏫')),
                      selected: currentType == 'school',
                      onSelected: (val) {
                        if (val) setModalState(() => currentType = 'school');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('College 🎓')),
                      selected: currentType == 'college',
                      onSelected: (val) {
                        if (val) setModalState(() => currentType = 'college');
                      },
                    ),
                  ),
                ],
              ),
              if (currentType == 'college') ...[
                const SizedBox(height: 16),
                Text('Branch / Stream:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: branches.map((b) {
                    final sel = currentBranch == b;
                    return ChoiceChip(
                      label: Text(b, style: const TextStyle(fontSize: 12)),
                      selected: sel,
                      onSelected: (val) {
                        if (val) setModalState(() => currentBranch = b);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(
                    labelText: 'Course / Degree Name (Optional)',
                    hintText: 'e.g. B.Tech Computer Science, B.Sc Physics',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (vm.profile != null) {
                      await vm.saveProfile(vm.profile!.copyWith(
                        educationType: currentType,
                        branch: currentType == 'college' ? currentBranch : null,
                        course: currentType == 'college' && courseController.text.trim().isNotEmpty
                            ? courseController.text.trim()
                            : null,
                      ));
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Education Details'),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: isDark
              ? AppColors.glassCardDecoration(
                  isDark: true,
                  borderColor: const Color(0x338B5CF6),
                  glowColor: const Color(0x188B5CF6),
                  borderRadius: 18,
                )
              : BoxDecoration(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? (isDark ? AppColors.darkPrimary : AppColors.primary);

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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkPrimary : AppColors.primary;

    return ListTile(
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
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        activeThumbColor: isDark ? const Color(0xFF38BDF8) : AppColors.primary,
        activeTrackColor: isDark ? const Color(0x6038BDF8) : AppColors.primary.withAlpha(50),
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
