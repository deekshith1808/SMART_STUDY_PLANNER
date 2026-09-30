import 'package:flutter_test/flutter_test.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';

void main() {
  test('JourneyNode displayIcon returns proper icons', () {
    final subPhysics = Subject(
      id: 'sub_physics',
      name: 'Physics',
      marks: 75,
      studyHours: 0,
      targetMarks: 90,
      examDate: DateTime.now().add(const Duration(days: 10)),
      color: '#C2410C',
      topics: const [],
    );
    final subEnglish = Subject(
      id: 'sub_english',
      name: 'English Literature',
      marks: 80,
      studyHours: 0,
      targetMarks: 85,
      examDate: DateTime.now().add(const Duration(days: 12)),
      color: '#047857',
      topics: const [],
    );

    final journey = JourneyProgress.fromSubjects([subEnglish, subPhysics]);
    for (final node in journey.nodes) {
      // ignore: avoid_print
      print('NODE: id=${node.id}, title="${node.title}", subject="${node.subjectName}", icon="${node.icon}", displayIcon="${node.displayIcon}"');
      expect(node.displayIcon.isNotEmpty, isTrue);
    }
  });
}
