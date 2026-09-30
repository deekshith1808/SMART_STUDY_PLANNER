import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_study_planner/data/services/storage_service.dart';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pomodoro & Subject Hub Integration Tests', () {
    late StorageService storage;
    late StudyRepository repository;
    late PomodoroViewModel pomodoroVm;
    late StudyPlannerViewModel studyVm;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      repository = StudyRepository(storageService: storage);
      pomodoroVm = PomodoroViewModel(repository: repository);
      studyVm = StudyPlannerViewModel(repository: repository);
      await studyVm.loadData();
    });

    test('PomodoroViewModel selectSubject updates selection and resets specific topic', () {
      expect(pomodoroVm.selectedSubjectId, isNull);
      expect(pomodoroVm.selectedSubjectName, isNull);
      expect(pomodoroVm.selectedTopic, isNull);

      pomodoroVm.selectSubject('sub_physics', 'Physics');
      expect(pomodoroVm.selectedSubjectId, 'sub_physics');
      expect(pomodoroVm.selectedSubjectName, 'Physics');

      pomodoroVm.selectTopic('Optics');
      expect(pomodoroVm.selectedTopic, 'Optics');

      // Switching subject should reset specific topic
      pomodoroVm.selectSubject('sub_math', 'Math');
      expect(pomodoroVm.selectedSubjectId, 'sub_math');
      expect(pomodoroVm.selectedSubjectName, 'Math');
      expect(pomodoroVm.selectedTopic, isNull);
    });

    test('StudyPlannerViewModel manages subject topics, exam dates, and tasks', () async {
      final initialSubject = Subject(
        id: 'sub_phys',
        name: 'Physics',
        marks: 78.0,
        targetMarks: 95.0,
        studyHours: 10,
        color: '#3B82F6',
        priority: SubjectPriority.high,
        topics: ['Mechanics'],
      );

      await studyVm.addSubject(initialSubject);
      expect(studyVm.profile?.subjects.any((s) => s.id == 'sub_phys'), isTrue);

      // Add syllabus topic
      await studyVm.addSubjectTopic('sub_phys', 'Electromagnetism');
      final updatedSubject = studyVm.profile?.subjects.firstWhere((s) => s.id == 'sub_phys');
      expect(updatedSubject?.topics.contains('Electromagnetism'), isTrue);
      expect(updatedSubject?.topics.length, 2);

      // Update exam date
      final examDate = DateTime.now().add(const Duration(days: 45));
      await studyVm.updateSubjectExamDate('sub_phys', examDate);
      final withExam = studyVm.profile?.subjects.firstWhere((s) => s.id == 'sub_phys');
      expect(withExam?.examDate, isNotNull);
      expect(withExam?.examDate?.day, examDate.day);

      // Add Task for subject
      final task = ScheduledTask(
        id: 'task_phys_1',
        title: 'Revise Faraday Law',
        subjectId: 'sub_phys',
        subjectName: 'Physics',
        scheduledDate: DateTime.now(),
        startTime: '5:00 PM',
        endTime: '6:00 PM',
        isCompleted: false,
        priority: 'high',
      );
      await studyVm.addTask(task);
      final physTasks = studyVm.tasks.where((t) => t.subjectId == 'sub_phys').toList();
      expect(physTasks.length, 1);
      expect(physTasks.first.title, 'Revise Faraday Law');

      // Add Note for subject
      final note = QuickNote(
        id: 'note_phys_1',
        title: 'Maxwell Equations',
        content: 'Gauss Law, Ampere Law, Faraday Law',
        subjectId: 'sub_phys',
        subjectName: 'Physics',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await studyVm.addNote(note);
      final physNotes = studyVm.notes.where((n) => n.subjectId == 'sub_phys').toList();
      expect(physNotes.length, 1);
      expect(physNotes.first.title, 'Maxwell Equations');

      // Remove topic
      await studyVm.removeSubjectTopic('sub_phys', 'Mechanics');
      final afterRemoval = studyVm.profile?.subjects.firstWhere((s) => s.id == 'sub_phys');
      expect(afterRemoval?.topics.contains('Mechanics'), isFalse);
      expect(afterRemoval?.topics.contains('Electromagnetism'), isTrue);
    });
  });
}
