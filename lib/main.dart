import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:smart_study_planner/data/services/storage_service.dart';
import 'package:smart_study_planner/data/services/supabase_service.dart';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/ui/core/app_theme.dart';
import 'package:smart_study_planner/ui/features/welcome/welcome_screen.dart';
import 'package:smart_study_planner/ui/features/auth/login_screen.dart';
import 'package:smart_study_planner/ui/features/onboarding/onboarding_screen.dart';
import 'package:smart_study_planner/ui/features/home/home_screen.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';

import 'package:smart_study_planner/ui/features/parental/parent_dashboard_screen.dart';
import 'package:smart_study_planner/data/services/parental_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  await ParentalNotificationService.instance.initialize();
  runApp(const StudySmartApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/parent', builder: (context, state) => const ParentDashboardScreen()),
  ],
);

class StudySmartApp extends StatefulWidget {
  const StudySmartApp({super.key});

  @override
  State<StudySmartApp> createState() => _StudySmartAppState();
}

class _StudySmartAppState extends State<StudySmartApp> {
  late final StorageService _storageService;
  late final StudyRepository _repository;
  late final StudyPlannerViewModel _studyPlannerViewModel;
  late final PomodoroViewModel _pomodoroViewModel;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService();
    _repository = StudyRepository(storageService: _storageService);
    _studyPlannerViewModel = StudyPlannerViewModel(repository: _repository);
    _pomodoroViewModel = PomodoroViewModel(repository: _repository);
    _pomodoroViewModel.onStudyStateChanged = _studyPlannerViewModel.updateLiveStudyState;
  }

  @override
  void dispose() {
    _studyPlannerViewModel.dispose();
    _pomodoroViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _studyPlannerViewModel),
        ChangeNotifierProvider.value(value: _pomodoroViewModel),
      ],
      child: Consumer<StudyPlannerViewModel>(
        builder: (context, vm, _) {
          return MaterialApp.router(
            title: 'StudySmart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: vm.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
