import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_study_planner/data/services/supabase_service.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsSignUp;

  const LoginScreen({
    super.key,
    this.initialIsSignUp = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _supabase = SupabaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late bool _isSignUp;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
    if (SupabaseConfig.isConfigured && !SupabaseService.isInitialized) {
      SupabaseService.initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth(StudyPlannerViewModel vm) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    if (_isSignUp && name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
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
              'Supabase URL & Anon Key not configured in lib/data/services/supabase_service.dart.';
          _isLoading = false;
        });
        return;
      }

      if (!SupabaseService.isInitialized) {
        await SupabaseService.initialize();
      }

      if (_isSignUp) {
        final res = await _supabase.signUp(email: email, password: password);
        if (res?.session != null || res?.user != null) {
          // Initialize user profile in database
          final currentProfile = vm.profile;
          final userProfile = UserProfile(
            name: name,
            educationType: currentProfile?.educationType ?? 'college',
            branch: currentProfile?.branch,
            course: currentProfile?.course,
            subjects: currentProfile?.subjects ?? [],
          );
          await vm.saveProfile(userProfile);
          await vm.syncWithSupabase();

          setState(() {
            _successMessage =
                'Account created! Your subjects, topics, and study history are stored in Supabase.';
          });

          await Future.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;

          if (userProfile.subjects.isEmpty) {
            context.go('/onboarding');
          } else {
            context.go('/home');
          }
        }
      } else {
        // Sign in
        final res = await _supabase.signIn(email: email, password: password);
        if (res?.user != null) {
          // Restore all past data: subjects, custom topics, pomodoro sessions, tasks, notes!
          await vm.syncWithSupabase();

          setState(() {
            _successMessage =
                'Welcome back! Your subjects and past history have been restored.';
          });

          await Future.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;

          if (vm.profile == null || vm.profile!.subjects.isEmpty) {
            context.go('/onboarding');
          } else {
            context.go('/home');
          }
        }
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        setState(() {
          _errorMessage = _isSignUp
              ? 'Could not create account: Check email and password requirements.'
              : 'Invalid email or password. If you just created this account, check your email to confirm, or ensure password is correct.';
        });
      } else if (msg.contains('rate limit')) {
        setState(() {
          _errorMessage =
              'Email rate limit reached. Turn off "Confirm email" in Supabase Dashboard > Authentication > Providers > Email for instant sign-ins.';
        });
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleContinueAsGuest(StudyPlannerViewModel vm) {
    // Guest mode: offline local storage
    if (vm.profile != null && vm.profile!.subjects.isNotEmpty) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vm = context.watch<StudyPlannerViewModel>();

    final warmBg = isDark ? const Color(0xFF161514) : const Color(0xFFFAF7F2);
    final cardBg = isDark ? const Color(0xFF242220) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF3ECE4) : const Color(0xFF2D2620);
    final textSecondary = isDark ? const Color(0xFFA69E96) : const Color(0xFF796F65);
    final accentTerracotta = isDark ? const Color(0xFFF97316) : const Color(0xFFC2410C);

    return Scaffold(
      backgroundColor: warmBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _handleContinueAsGuest(vm),
            icon: const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFD97706)),
            label: Text(
              'Skip as Guest',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand Icon & Header
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: accentTerracotta.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentTerracotta.withAlpha(80),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text('🦉', style: const TextStyle(fontSize: 34)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Welcome to Spark',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your subject details, custom journey levels, and study histories safely stored in the cloud.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.45,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Switch between Sign In and Create Account
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E2C2A) : const Color(0xFFEDE5DA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isSignUp = false;
                          _errorMessage = null;
                          _successMessage = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSignUp
                                ? cardBg
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isSignUp
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Sign In',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight:
                                  !_isSignUp ? FontWeight.w800 : FontWeight.w600,
                              color: !_isSignUp ? accentTerracotta : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _isSignUp = true;
                          _errorMessage = null;
                          _successMessage = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSignUp
                                ? cardBg
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isSignUp
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            'Create Account',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight:
                                  _isSignUp ? FontWeight.w800 : FontWeight.w600,
                              color: _isSignUp ? accentTerracotta : textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Alert Messages (Error / Success)
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

              // Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 10),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field (only on Sign Up)
                    if (_isSignUp) ...[
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'e.g. Alex Johnson',
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              size: 20, color: accentTerracotta),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2C2A28)
                              : const Color(0xFFFAF7F2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFE8DFD3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'student@example.com',
                        prefixIcon: Icon(Icons.email_outlined,
                            size: 20, color: accentTerracotta),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2A28)
                            : const Color(0xFFFAF7F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE8DFD3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            size: 20, color: accentTerracotta),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: textSecondary,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2C2A28)
                            : const Color(0xFFFAF7F2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE8DFD3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary Email Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _handleEmailAuth(vm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentTerracotta,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        shadowColor: accentTerracotta.withAlpha(120),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isSignUp
                                      ? Icons.cloud_upload_rounded
                                      : Icons.login_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isSignUp
                                      ? 'Create Account & Save My Data'
                                      : 'Sign In & Restore My Subjects',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // OR Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark ? Colors.white24 : const Color(0xFFD4C8B8),
                      thickness: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR TRY OFFLINE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark ? Colors.white24 : const Color(0xFFD4C8B8),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Guest Option Button
              OutlinedButton(
                onPressed: () => _handleContinueAsGuest(vm),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFD4C8B8),
                    width: 1.5,
                  ),
                  backgroundColor: cardBg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🚀', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Continue as Guest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Quick offline access • No account needed',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        size: 16, color: textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Cloud Features Highlights
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF282522)
                      : const Color(0xFFF3ECE0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE8DFD3),
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureBullet(
                      icon: '☁️',
                      title: 'Automatic Supabase Database Backup',
                      desc:
                          'Subjects, custom topics, Pomodoro sessions, and notes are preserved.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureBullet(
                      icon: '🎯',
                      title: 'Topics as Journey Levels',
                      desc:
                          'Transform your syllabus topics into Duolingo-style stepping stones.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureBullet(
                      icon: '📅',
                      title: 'Exam Date & Countdown',
                      desc:
                          'Keep your target exam deadline in sight with readiness tracking.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBullet({
    required String icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF2D2620),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 1.3,
                  color: isDark ? Colors.white60 : const Color(0xFF796F65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
