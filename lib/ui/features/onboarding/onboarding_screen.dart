import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1: name
  final _nameController = TextEditingController();

  // Step 2: education type
  String? _educationType; // 'school' or 'college'

  // Step 3 (college): branch & course
  String? _branch;
  final _courseController = TextEditingController();

  // Step 4: subjects
  final List<String> _subjects = [];
  final _subjectController = TextEditingController();

  final _collegeBranches = [
    'Engineering & Tech',
    'Medical & Health',
    'Arts & Humanities',
    'Natural Sciences',
    'Commerce & Mgmt',
    'Law & Governance',
    'Architecture & Design',
    'Agriculture',
    'Other Studies',
  ];

  int get _totalPages => _educationType == 'college' ? 5 : 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<StudyPlannerViewModel>();
      if (vm.profile?.name.isNotEmpty == true && _nameController.text.isEmpty) {
        setState(() {
          _nameController.text = vm.profile!.name;
        });
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
      setState(() => _currentPage--);
    }
  }

  bool get _canProceed {
    switch (_currentPage) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _educationType != null;
      case 2:
        if (_educationType == 'school') return _subjects.isNotEmpty;
        return _branch != null;
      case 3:
        if (_educationType == 'college') return _subjects.isNotEmpty;
        return true;
      default:
        return true;
    }
  }

  Future<void> _finish() async {
    final viewModel = context.read<StudyPlannerViewModel>();
    final subjectColors = AppColors.subjectColors;

    final subjectList = _subjects.asMap().entries.map((e) {
      final color = subjectColors[e.key % subjectColors.length];
      return Subject(
        id: DateTime.now().millisecondsSinceEpoch.toString() + e.key.toString(),
        name: e.value,
        marks: 0,
        targetMarks: 85,
        studyHours: 0,
        color: '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        topics: [],
        priority: SubjectPriority.medium,
        difficulty: SubjectDifficulty.medium,
      );
    }).toList();

    final profile = UserProfile(
      name: _nameController.text.trim(),
      educationType: _educationType!,
      branch: _branch,
      course: _courseController.text.trim().isEmpty ? null : _courseController.text.trim(),
      subjects: subjectList,
    );

    await viewModel.saveProfile(profile);
    await viewModel.generateJourneyFromSubjects();
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _subjectController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _currentPage > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: _prevPage,
              )
            : null,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withAlpha(40)),
          ),
          child: Text(
            'Step ${_currentPage + 1} of $_totalPages',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: const Color(0xFFEADBCE),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 5,
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _buildPages(),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    final pages = <Widget>[
      _NamePage(controller: _nameController, onChanged: () => setState(() {})),
      _EducationTypePage(
        selected: _educationType,
        onSelect: (type) => setState(() {
          _educationType = type;
          _branch = null;
          _subjects.clear();
        }),
      ),
    ];

    if (_educationType == 'college') {
      pages.addAll([
        _BranchPage(
          branches: _collegeBranches,
          selected: _branch,
          courseController: _courseController,
          onSelect: (b) => setState(() => _branch = b),
        ),
        _SubjectsPage(
          subjects: _subjects,
          controller: _subjectController,
          onAdd: (s) => setState(() => _subjects.add(s)),
          onRemove: (i) => setState(() => _subjects.removeAt(i)),
          educationType: 'college',
        ),
      ]);
    } else {
      pages.add(
        _SubjectsPage(
          subjects: _subjects,
          controller: _subjectController,
          onAdd: (s) => setState(() => _subjects.add(s)),
          onRemove: (i) => setState(() => _subjects.removeAt(i)),
          educationType: 'school',
        ),
      );
    }

    pages.add(_ReviewPage(
      name: _nameController.text,
      educationType: _educationType ?? '',
      branch: _branch,
      course: _courseController.text,
      subjects: _subjects,
    ));

    return pages;
  }

  Widget _buildBottomButton() {
    final isLast = _currentPage == _totalPages - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canProceed ? (isLast ? _finish : _nextPage) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: const Color(0xFFDDD3C7),
            disabledForegroundColor: const Color(0xFF9C9184),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: _canProceed ? 2 : 0,
            shadowColor: AppColors.primary.withAlpha(100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast ? 'Begin Study Journey 📖' : 'Continue',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _canProceed ? Colors.white : const Color(0xFF9C9184),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                size: 18,
                color: _canProceed ? Colors.white : const Color(0xFF9C9184),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NamePage({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withAlpha(60)),
                ),
                child: const Text('👋', style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome aboard!',
            style: GoogleFonts.lora(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Let's personalize your daily learning workspace and focus habits.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'What should we call you?',
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Alex, Sophia, Rahul',
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationTypePage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _EducationTypePage({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Your Education Stage',
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select where you are currently studying.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _SelectionCard(
            emoji: '🏫',
            title: 'School',
            subtitle: 'Classes 1–12 / High School / Secondary boards',
            badge: 'Structured',
            isSelected: selected == 'school',
            onTap: () => onSelect('school'),
          ),
          const SizedBox(height: 16),
          _SelectionCard(
            emoji: '🎓',
            title: 'College / University',
            subtitle: 'Undergrad, Master\'s, Diploma & Research branches',
            badge: 'Specialized',
            isSelected: selected == 'college',
            onTap: () => onSelect('college'),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withAlpha(200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withAlpha(25)
                  : Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlpha(20)
                    : const Color(0xFFF3ECE0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withAlpha(50)
                      : AppColors.borderLight,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFC7BCAD),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchPage extends StatelessWidget {
  final List<String> branches;
  final String? selected;
  final TextEditingController courseController;
  final ValueChanged<String> onSelect;

  const _BranchPage({
    required this.branches,
    required this.selected,
    required this.courseController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Select Your Branch',
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your field of study or department.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: branches.map((b) {
              final isSelected = selected == b;
              return GestureDetector(
                onTap: () => onSelect(b),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.borderLight,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isSelected ? 20 : 6),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    b,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Degree / Course Name (Optional)',
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: courseController,
            style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. B.Tech Computer Science, BA English',
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.secondary, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectsPage extends StatelessWidget {
  final List<String> subjects;
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  final ValueChanged<int> onRemove;
  final String educationType;

  const _SubjectsPage({
    required this.subjects,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    required this.educationType,
  });

  @override
  Widget build(BuildContext context) {
    final schoolPresets = [
      'Mathematics',
      'Physics',
      'Chemistry',
      'Biology',
      'English',
      'Computer Science',
      'Social Studies',
    ];
    final collegePresets = [
      'Data Structures & Algorithms',
      'Operating Systems',
      'Database Systems (DBMS)',
      'Computer Networks',
      'Engineering Mathematics',
      'Software Engineering',
      'Web Development',
    ];
    final presets = educationType == 'school' ? schoolPresets : collegePresets;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Your Subjects',
            style: GoogleFonts.lora(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the subjects you study this semester to track marks, hurdles, and study hours.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Preset Chips Section
          Text(
            'Recommended for ${educationType == 'school' ? 'School' : 'College'} (Tap to add):',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final isEnrolled = subjects
                  .any((s) => s.toLowerCase() == preset.toLowerCase());
              return FilterChip(
                label: Text(preset),
                selected: isEnrolled,
                onSelected: (selected) {
                  if (selected) {
                    onAdd(preset);
                  } else {
                    final idx = subjects.indexWhere(
                        (s) => s.toLowerCase() == preset.toLowerCase());
                    if (idx != -1) onRemove(idx);
                  }
                },
                selectedColor: AppColors.primary.withAlpha(35),
                checkmarkColor: AppColors.primary,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isEnrolled ? FontWeight.w700 : FontWeight.w500,
                  color: isEnrolled ? AppColors.primary : AppColors.textPrimary,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isEnrolled ? AppColors.primary : AppColors.borderLight,
                    width: isEnrolled ? 1.5 : 1.0,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Custom Subject TextField
          Text(
            'Or add your own custom subject:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Calculus, Literature, Robotics',
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.book_rounded, color: AppColors.accent, size: 20),
                    ),
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      onAdd(v.trim());
                      controller.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    onAdd(controller.text.trim());
                    controller.clear();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
          if (subjects.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Enrolled Subjects (${subjects.length})',
              style: GoogleFonts.lora(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...subjects.asMap().entries.map((e) {
              final color = AppColors.subjectColors[e.key % AppColors.subjectColors.length];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(80), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        e.value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onRemove(e.key),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3ECE0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ReviewPage extends StatelessWidget {
  final String name;
  final String educationType;
  final String? branch;
  final String course;
  final List<String> subjects;

  const _ReviewPage({
    required this.name,
    required this.educationType,
    required this.branch,
    required this.course,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.secondary.withAlpha(60)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: AppColors.secondary),
                    SizedBox(width: 4),
                    Text(
                      'Ready to Focus',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your Study Profile',
            style: GoogleFonts.lora(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Everything is organized. You can modify targets anytime in Settings.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          _ReviewItem(icon: Icons.person_rounded, label: 'Student', value: name, color: AppColors.primary),
          _ReviewItem(
            icon: Icons.school_rounded,
            label: 'Stage',
            value: educationType == 'school' ? 'School' : 'College / University',
            color: AppColors.secondary,
          ),
          if (branch != null)
            _ReviewItem(icon: Icons.category_rounded, label: 'Branch', value: branch!, color: AppColors.accent),
          if (course.isNotEmpty)
            _ReviewItem(icon: Icons.menu_book_rounded, label: 'Program', value: course, color: const Color(0xFF2563EB)),
          const SizedBox(height: 14),
          Text(
            'Subjects to Master (${subjects.length})',
            style: GoogleFonts.lora(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subjects.asMap().entries.map((e) {
              final color = AppColors.subjectColors[e.key % AppColors.subjectColors.length];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withAlpha(100), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      e.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReviewItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withAlpha(50)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textSecondary)),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
