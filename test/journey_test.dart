import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_study_planner/data/services/storage_service.dart';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';

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
  });
}
