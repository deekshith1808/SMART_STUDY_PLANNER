import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../home/study_planner_view_model.dart';

class FocusShieldSheet extends StatefulWidget {
  final PomodoroViewModel vm;
  const FocusShieldSheet({super.key, required this.vm});

  static Future<void> show(BuildContext context, PomodoroViewModel vm) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FocusShieldSheet(vm: vm),
    );
  }

  @override
  State<FocusShieldSheet> createState() => _FocusShieldSheetState();
}

class _FocusShieldSheetState extends State<FocusShieldSheet> {
  final TextEditingController _customDomainController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _customDomainController.dispose();
    super.dispose();
  }

  void _addCustomDomain() {
    final text = _customDomainController.text.trim();
    if (text.isNotEmpty) {
      widget.vm.addCustomBlockedDomain(text);
      _customDomainController.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.vm.shieldConfig;
    final filteredApps = config.blockedApps.where((app) {
      if (_searchQuery.isEmpty) return true;
      return app.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.domains.any((d) => d.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) => Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD6CBC0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Social Media Shield 🛡️',
                            style: GoogleFonts.lora(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Blocks apps & sites automatically during focus timer',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Shield Stats Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFEF2F2), Color(0xFFFFF7ED)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${config.blockedAttemptsCount} Distractions Shielded',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                            Text(
                              'Time saved by staying locked in deep focus sprints.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Master Shield Toggle
                _ToggleTile(
                  icon: Icons.power_settings_new_rounded,
                  iconColor: const Color(0xFFDC2626),
                  title: 'Enable Shield on Timer Start',
                  subtitle: 'Automatically activates blocker when focus phase begins',
                  value: config.isShieldEnabled,
                  onChanged: (val) {
                    widget.vm.toggleShield(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),

                // Strict Mode Toggle
                _ToggleTile(
                  icon: Icons.lock_clock_rounded,
                  iconColor: AppColors.primary,
                  title: 'Strict Mindful Lock',
                  subtitle: 'Requires 10s conscious breathing countdown to bypass',
                  value: config.strictMode,
                  onChanged: (val) {
                    widget.vm.toggleStrictMode(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),

                // Desktop Process Guardian Toggle
                _ToggleTile(
                  icon: Icons.computer_rounded,
                  iconColor: AppColors.secondary,
                  title: 'Desktop Windows Process Guardian',
                  subtitle: 'Detects & shields desktop apps (Discord, Telegram, WhatsApp)',
                  value: config.blockDesktopProcesses,
                  onChanged: (val) {
                    widget.vm.toggleDesktopProcessBlocking(val);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 20),

                // Add Custom Website/App Input
                Text(
                  'ADD CUSTOM WEBSITE OR APP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customDomainController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g., roblox.com, chess.com, news.ycombinator.com',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.link_rounded, size: 20, color: AppColors.primary),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.borderLight),
                          ),
                        ),
                        onSubmitted: (_) => _addCustomDomain(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addCustomDomain,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),

                // Custom Domains List
                if (config.customUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: config.customUrls.map((custom) {
                      return Chip(
                        backgroundColor: const Color(0xFFFEF2F2),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        avatar: const Text('🛡️', style: TextStyle(fontSize: 12)),
                        label: Text(
                          custom,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF991B1B)),
                        onDeleted: () {
                          widget.vm.removeCustomBlockedDomain(custom);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 20),

                // Search / Filter Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BLOCKED SOCIAL APPS (${config.blockedApps.where((a) => a.isEnabled).length}/${config.blockedApps.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final allEnabled = config.blockedApps.every((a) => a.isEnabled);
                        widget.vm.setAllAppsBlocked(!allEnabled);
                        setState(() {});
                      },
                      child: Text(
                        config.blockedApps.every((a) => a.isEnabled) ? 'Disable All' : 'Enable All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Search field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search social media apps...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Apps List
                Container(
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
                    children: filteredApps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final app = entry.value;
                      final isLast = index == filteredApps.length - 1;

                      return Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: app.isEnabled
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(app.iconEmoji, style: const TextStyle(fontSize: 20)),
                              ),
                            ),
                            title: Text(
                              app.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: app.isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                              ),
                            ),
                            subtitle: Text(
                              app.domains.join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: Switch(
                              activeThumbColor: const Color(0xFFDC2626),
                              activeTrackColor: const Color(0xFFFCA5A5),
                              value: app.isEnabled,
                              onChanged: (val) {
                                widget.vm.toggleBlockedApp(app.id, val);
                                setState(() {});
                              },
                            ),
                          ),
                          if (!isLast) const Divider(height: 1, indent: 64, color: AppColors.borderLight),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Switch(
          activeThumbColor: iconColor,
          activeTrackColor: iconColor.withAlpha(60),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
