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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const StudySmartApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);

class StudySmartApp extends StatelessWidget {
  const StudySmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();
    final repository = StudyRepository(storageService: storageService);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudyPlannerViewModel(repository: repository)),
        ChangeNotifierProvider(create: (_) => PomodoroViewModel(repository: repository)),
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
