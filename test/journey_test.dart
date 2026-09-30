import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_study_planner/data/services/storage_service.dart';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Duolingo Learning Journey & Exam Hurdle Tests', () {
    late StorageService storage;
    late StudyRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      repository = StudyRepository(storageService: storage);
    });

    test('Initializes with default journey, points, and streak', () async {
      final progress = await repository.getJourneyProgress();

      expect(progress.currentStreak, 5);
      expect(progress.totalXp, 385);
      expect(progress.level, 4);
      expect(progress.levelTitle, 'Syllabus Crusher');
      expect(progress.nodes.length, 6);
      expect(progress.hurdle.title, 'Midterm Semester Exam');
      expect(progress.hurdle.requiredNodes, 5);
      expect(progress.hurdle.isUnlocked, false);
    });

    test('Completing an active node awards XP, unlocks next node, and advances hurdle readiness', () async {
      final initial = await repository.getJourneyProgress();
      final activeNode = initial.nodes.firstWhere((n) => n.status == NodeStatus.active);
      expect(activeNode.id, 'node_3');

      final updated = await repository.completeJourneyNode('node_3');

      // Check node completed
      final completedNode = updated.nodes.firstWhere((n) => n.id == 'node_3');
      expect(completedNode.status, NodeStatus.completed);
      expect(completedNode.stars, 3);

      // Check XP incremented (+50 XP)
      expect(updated.totalXp, 385 + 50);

      // Check next node unlocked
      final nextNode = updated.nodes.firstWhere((n) => n.id == 'node_4');
      expect(nextNode.status, NodeStatus.active);

      // Check hurdle progress updated (was 2, now 3)
      expect(updated.hurdle.completedNodes, 3);
    });

    test('Hurdle unlocks when all required prerequisite nodes are completed', () {
      final hurdle = ExamHurdle(
        id: 'h1',
        title: 'Midterm',
        subjectName: 'Math',
        examDate: DateTime.now().add(const Duration(days: 4)),
        targetScore: 95.0,
        requiredNodes: 3,
        completedNodes: 3,
      );

      expect(hurdle.isUnlocked, true);
      expect(hurdle.readiness, 1.0);
    });

    test('ExamHurdle formats exam date and calculates days remaining correctly', () {
      final futureDate = DateTime.now().add(const Duration(days: 14));
      final hurdle = ExamHurdle(
        id: 'h2',
        title: 'Final Exam',
        subjectName: 'Computer Science',
        examDate: futureDate,
        targetScore: 90.0,
        requiredNodes: 4,
        completedNodes: 2,
      );

      expect(hurdle.daysRemaining, 14);
      expect(hurdle.daysRemainingText, '14 Days Left');
      expect(hurdle.formattedExamDate.isNotEmpty, true);
    });

    test('JourneyProgress.fromSubjects generates custom topic levels and incorporates subject exam dates', () {
      final examDate = DateTime.now().add(const Duration(days: 25));
      final subjects = [
        Subject(
          id: 'sub_1',
          name: 'Quantum Physics',
          marks: 75.0,
          targetMarks: 95.0,
          studyHours: 12,
          color: '#C2410C',
          examDate: examDate,
          priority: SubjectPriority.high,
          topics: ['Wave Mechanics', 'Schrodinger Equation', 'Quantum Tunneling'],
        ),
        Subject(
          id: 'sub_2',
          name: 'Linear Algebra',
          marks: 80.0,
          targetMarks: 90.0,
          studyHours: 10,
          color: '#047857',
          priority: SubjectPriority.medium,
          topics: ['Eigenvalues', 'Matrix Decomposition'],
        ),
      ];

      final journey = JourneyProgress.fromSubjects(subjects);

      // Total 5 topics across 2 subjects = 5 levels
      expect(journey.nodes.length, 5);
      expect(journey.nodes.first.title, 'Wave Mechanics');
      expect(journey.nodes.first.subjectName, 'Quantum Physics');
      expect(journey.nodes.first.status, NodeStatus.active);
      expect(journey.nodes[1].status, NodeStatus.locked);
      expect(journey.hurdle.examDate.year, examDate.year);
      expect(journey.hurdle.examDate.month, examDate.month);
      expect(journey.hurdle.examDate.day, examDate.day);
    });

    test('Multiple exam hurdles are ordered chronologically by sortedHurdles', () {
      final now = DateTime.now();
      final h1 = ExamHurdle(
        id: 'h_math',
        title: 'Maths Exam',
        subjectName: 'Maths',
        examDate: now.add(const Duration(days: 3)),
        targetScore: 90,
        requiredNodes: 5,
        completedNodes: 0,
      );
      final h2 = ExamHurdle(
        id: 'h_physics',
        title: 'Physics Exam',
        subjectName: 'Physics',
        examDate: now.add(const Duration(days: 1)),
        targetScore: 85,
        requiredNodes: 5,
        completedNodes: 0,
      );
      final h3 = ExamHurdle(
        id: 'h_chem',
        title: 'Chemistry Exam',
        subjectName: 'Chemistry',
        examDate: now.add(const Duration(days: 5)),
        targetScore: 88,
        requiredNodes: 5,
        completedNodes: 0,
      );

      final journey = JourneyProgress(
        currentStreak: 5,
        totalXp: 100,
        nodes: [],
        hurdle: h1,
        hurdles: [h1, h2, h3],
      );

      final sorted = journey.sortedHurdles;
      expect(sorted.length, 3);
      expect(sorted[0].subjectName, 'Physics'); // 1 day
      expect(sorted[1].subjectName, 'Maths');   // 3 days
      expect(sorted[2].subjectName, 'Chemistry'); // 5 days
    });

    test('Per-account isolation scopes data to the specific user profile', () async {
      storage.setUserId('user_deekshith');
      await storage.saveProfile(UserProfile(
        name: 'Deekshith',
        educationType: 'college',
        subjects: [
          Subject(
            id: 's1',
            name: 'Computer Science',
            marks: 95,
            targetMarks: 100,
            studyHours: 20,
            color: '#C2410C',
            priority: SubjectPriority.high,
            topics: ['Algorithms'],
          ),
        ],
      ));

      // Switch to another account
      storage.setUserId('user_sarah');
      final sarahProfile = await storage.loadProfile();
      // Should NOT see Deekshith's subjects
      expect(sarahProfile?.name, isNot('Deekshith'));

      await storage.saveProfile(UserProfile(
        name: 'Sarah',
        educationType: 'school',
        subjects: [
          Subject(
            id: 's2',
            name: 'Biology',
            marks: 88,
            targetMarks: 95,
            studyHours: 15,
            color: '#047857',
            priority: SubjectPriority.medium,
            topics: ['Genetics'],
          ),
        ],
      ));

      // Switch back to Deekshith
      storage.setUserId('user_deekshith');
      final deekshithProfile = await storage.loadProfile();
      expect(deekshithProfile?.name, 'Deekshith');
      expect(deekshithProfile?.subjects.first.name, 'Computer Science');
    });
  });
}

