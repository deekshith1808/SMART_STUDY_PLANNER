import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/data/services/storage_service.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';
import 'package:smart_study_planner/domain/utils/subject_validator.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AcademicSubjectValidator Tests', () {
    test('Recognizes standard STEM and Humanities subjects', () {
      expect(AcademicSubjectValidator.isAcademicSubject('Physics'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('Mathematics'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('Organic Chemistry'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('Linear Algebra'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('Computer Science'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('Microbiology'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('World History'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('Macroeconomics'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('Data Structures & Algorithms'), isTrue);
      expect(AcademicSubjectValidator.isAcademicSubject('English Literature'), isTrue);
    });

    test('Flags non-academic entries and gibberish', () {
      expect(AcademicSubjectValidator.isAcademicSubject(''), isFalse);
      expect(AcademicSubjectValidator.isAcademicSubject('   '), isFalse);
      expect(AcademicSubjectValidator.isAcademicSubject('asdfghjk'), isFalse);
      expect(AcademicSubjectValidator.isAcademicSubject('zzzzzz'), isFalse);
      expect(AcademicSubjectValidator.isAcademicSubject('random pizza party'), isFalse);
      expect(AcademicSubjectValidator.isAcademicSubject('buy grocery items today'), isFalse);
    });
  });

  group('Pomodoro Long Break Locking & 2-Session Hint Tests', () {
    late StorageService storage;
    late StudyRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      repository = StudyRepository(storageService: storage);
    });

    test('Locks long break until 2 focus sessions are finished and displays clear hint', () {
      final vm = PomodoroViewModel(repository: repository);

      // Initially 0 sessions
      expect(vm.completedSessions, 0);
      expect(vm.isLongBreakAvailable, isFalse);
      expect(vm.sessionsUntilLongBreak, 2);
      expect(vm.longBreakHint, contains('only exists after 2 sessions'));
      expect(vm.longBreakHint, contains('0/2 completed'));

      // Attempting to select long break when locked fails
      final switched = vm.selectPhase(PomodoroPhase.longBreak);
      expect(switched, isFalse);
      expect(vm.phase, PomodoroPhase.work);

      // Can still select short break
      final switchedShort = vm.selectPhase(PomodoroPhase.shortBreak);
      expect(switchedShort, isTrue);
      expect(vm.phase, PomodoroPhase.shortBreak);
    });
  });

  group('Dynamic Level, Streak & Hours Calculation Tests', () {
    test('Computes dynamic level correctly from XP, succeeded levels, and hours', () {
      final List<JourneyNode> nodes = [
        const JourneyNode(
          id: 'n1',
          title: 'Lesson 1',
          description: '',
          subjectName: 'Physics',
          type: NodeType.lesson,
          status: NodeStatus.completed,
          xpReward: 30,
          stage: 1,
          horizontalOffset: 0.0,
        ),
        const JourneyNode(
          id: 'n2',
          title: 'Lesson 2',
          description: '',
          subjectName: 'Physics',
          type: NodeType.lesson,
          status: NodeStatus.completed,
          xpReward: 30,
          stage: 1,
          horizontalOffset: 0.0,
        ),
        const JourneyNode(
          id: 'n3',
          title: 'Lesson 3',
          description: '',
          subjectName: 'Physics',
          type: NodeType.lesson,
          status: NodeStatus.active,
          xpReward: 30,
          stage: 1,
          horizontalOffset: 0.0,
        ),
      ];

      // XP: 160 (~/ 80 = 2), succeeded: 2, hours: 4.0 (~/ 2 = 2) => level: 2 + 2 + 2 = 6
      final progress = JourneyProgress(
        totalXp: 160,
        currentStreak: 3,
        totalHours: 4.0,
        nodes: nodes,
      );

      expect(progress.succeededLevelsCount, 2);
      expect(progress.level, 6);
      expect(progress.levelTitle, 'Scholar of Eminence');
    });

    test('Calculates real dynamic streak from consecutive study dates', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      // 3 consecutive days
      final streak3 = JourneyProgress.calculateStreakFromSessions(
        studyDates: [today, yesterday, twoDaysAgo],
      );
      expect(streak3, 3);

      // Broken streak: today and 4 days ago (gap in between)
      final fourDaysAgo = today.subtract(const Duration(days: 4));
      final streakBroken = JourneyProgress.calculateStreakFromSessions(
        studyDates: [today, fourDaysAgo],
      );
      expect(streakBroken, 1);
    });
  });

  group('JourneyNode Thematic Icons Tests', () {
    test('Provides appropriate icons based on subject and node type', () {
      const quantumNode = JourneyNode(
        id: 'p1',
        title: 'Quantum Mechanics',
        description: '',
        subjectName: 'Physics',
        type: NodeType.lesson,
        status: NodeStatus.active,
        xpReward: 30,
        stage: 1,
        horizontalOffset: 0.0,
      );
      expect(quantumNode.displayIcon, '⚛️');

      const mathNode = JourneyNode(
        id: 'm1',
        title: 'Derivatives',
        description: '',
        subjectName: 'Calculus',
        type: NodeType.practice,
        status: NodeStatus.locked,
        xpReward: 30,
        stage: 1,
        horizontalOffset: 0.0,
      );
      expect(mathNode.displayIcon, '♾️');

      const hurdleNode = JourneyNode(
        id: 'h1',
        title: 'Final Exam Castle',
        description: '',
        subjectName: 'General',
        type: NodeType.hurdle,
        status: NodeStatus.locked,
        xpReward: 100,
        stage: 1,
        horizontalOffset: 0.0,
      );
      expect(hurdleNode.displayIcon, '🏰');
    });
  });
}
