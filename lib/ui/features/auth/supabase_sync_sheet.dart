import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/data/services/supabase_service.dart';

class SupabaseSyncSheet extends StatefulWidget {
  const SupabaseSyncSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SupabaseSyncSheet(),
    );
  }

  @override
  State<SupabaseSyncSheet> createState() => _SupabaseSyncSheetState();
}

class _SupabaseSyncSheetState extends State<SupabaseSyncSheet> {
  final _supabase = SupabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (!SupabaseConfig.isConfigured) {
        setState(() {
          _errorMessage =
              'Supabase URL & Key are not configured yet in lib/data/services/supabase_service.dart.';
          _isLoading = false;
        });
        return;
      }

      if (_isSignUp) {
        final res = await _supabase.signUp(email: email, password: password);
        if (res?.user != null) {
          setState(() {
            _successMessage = 'Account created successfully! You are signed in.';
          });
        }
      } else {
        final res = await _supabase.signIn(email: email, password: password);
        if (res?.user != null) {
          setState(() {
            _successMessage = 'Welcome back! Signed in successfully.';
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBackup(StudyPlannerViewModel vm) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      if (vm.profile != null) {
        await _supabase.syncProfile(vm.profile!);
      }
      await _supabase.syncSessions(vm.sessions);
      await _supabase.syncTasks(vm.tasks);
      await _supabase.syncNotes(vm.notes);
      await _supabase.syncJourney(vm.journeyProgress);

      setState(() {
        _successMessage = 'All study data, streaks & levels synced to Supabase!';
      });
    } catch (e) {
      setState(() => _errorMessage = 'Sync failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore(StudyPlannerViewModel vm) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final remoteProfile = await _supabase.fetchProfile();
      if (remoteProfile != null) {
        await vm.saveProfile(remoteProfile);
      }
      final remoteJourney = await _supabase.fetchJourney();
      if (remoteJourney != null) {
        await vm.completeJourneyNode(''); // trigger refresh
      }
      await vm.loadData();

      setState(() {
        _successMessage = 'Data successfully restored from your Supabase cloud!';
      });
    } catch (e) {
      setState(() => _errorMessage = 'Restore failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vm = context.watch<StudyPlannerViewModel>();
    final isConfigured = SupabaseConfig.isConfigured;
    final user = _supabase.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2835) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFD4C8B8),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header with Supabase Logo & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3ECF8E).withAlpha(25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF3ECF8E).withAlpha(90),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Text('⚡', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Supabase Cloud Sync',
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF2D2620),
                          ),
                        ),
                        Text(
                          user != null
                              ? 'Logged in as ${user.email}'
                              : (isConfigured ? 'Ready to Connect' : 'Local Offline Mode'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: user != null
                                ? const Color(0xFF047857)
                                : (isConfigured ? const Color(0xFFD97706) : const Color(0xFF796F65)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isConfigured
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isConfigured
                          ? const Color(0xFF059669)
                          : const Color(0xFFD97706),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConfigured
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isConfigured ? 'Supabase Active' : 'Setup Needed',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isConfigured
                              ? const Color(0xFF047857)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Error or Success Alerts
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF059669)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: Color(0xFF059669), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF065F46),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // If user is already authenticated: Show Cloud Sync Dashboard
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF283548) : const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_done_rounded,
                            color: Color(0xFF047857), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Connected',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF2D2620),
                                ),
                              ),
                              Text(
                                user.email ?? 'No email',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF796F65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _supabase.signOut();
                            setState(() {});
                          },
                          child: Text(
                            'Sign Out',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFDC2626),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _handleBackup(vm),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC2410C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                            label: const Text('Backup Data'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : () => _handleRestore(vm),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: isDark ? Colors.white24 : const Color(0xFFE8DFD3),
                              ),
                            ),
                            icon: const Icon(Icons.cloud_download_rounded, size: 18),
                            label: const Text('Restore Cloud'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // If not signed in: Auth Form
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSignUp = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isSignUp
                              ? const Color(0xFFC2410C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Sign In',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: !_isSignUp ? Colors.white : const Color(0xFF796F65),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isSignUp = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isSignUp
                              ? const Color(0xFFC2410C)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _isSignUp ? Colors.white : const Color(0xFF796F65),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Email Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF283548) : const Color(0xFFFAF7F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF283548) : const Color(0xFFFAF7F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC2410C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isSignUp ? 'Create Supabase Account' : 'Sign In with Supabase',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
              ),
            ],

            const SizedBox(height: 24),

            // How to Connect Supabase Help Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF283548) : const Color(0xFFF3ECE0),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Where to put your Supabase Keys:',
                        style: GoogleFonts.lora(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF2D2620),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1. Open lib/data/services/supabase_service.dart\n'
                    '2. Replace supabaseUrl & supabaseAnonKey from your project settings.\n'
                    '3. Run supabase_schema.sql in your Supabase SQL Editor.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? Colors.white70 : const Color(0xFF6B6258),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
