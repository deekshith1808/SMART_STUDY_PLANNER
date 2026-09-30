import 'package:flutter_test/flutter_test.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/services/timetable_generator.dart';

void main() {
  group('TimetableGenerator & Priority Subjects Tests', () {
    test('SubjectPriority enum has expected multipliers and values', () {
      expect(SubjectPriority.high.weightMultiplier, 3.0);
      expect(SubjectPriority.medium.weightMultiplier, 2.0);
      expect(SubjectPriority.low.weightMultiplier, 1.0);

      expect(SubjectPriority.fromDynamic('high'), SubjectPriority.high);
      expect(SubjectPriority.fromDynamic('medium'), SubjectPriority.medium);
      expect(SubjectPriority.fromDynamic('low'), SubjectPriority.low);
      expect(SubjectPriority.fromDynamic(5), SubjectPriority.high);
      expect(SubjectPriority.fromDynamic(1), SubjectPriority.low);
    });

    test('High priority subject receives proportionally more study time than low priority', () {
      final highSubject = const Subject(
        id: 's_high',
        name: 'Calculus',
        marks: 70,
        targetMarks: 85,
        studyHours: 0,
        color: '#FF0000',
        topics: ['Integration', 'Derivatives'],
        priority: SubjectPriority.high,
        difficulty: SubjectDifficulty.medium,
      );

      final lowSubject = const Subject(
        id: 's_low',
        name: 'Ethics',
        marks: 70,
        targetMarks: 85,
        studyHours: 0,
        color: '#00FF00',
        topics: ['Philosophy', 'Case Studies'],
        priority: SubjectPriority.low,
        difficulty: SubjectDifficulty.medium,
      );

      final allocations = TimetableGenerator.computeAllocations(
        subjects: [highSubject, lowSubject],
        daysCount: 7,
        dailyStudyHours: 4.0,
        slotDurationMinutes: 60,
      );

      final highAlloc = allocations.firstWhere((a) => a.subject.id == 's_high');
      final lowAlloc = allocations.firstWhere((a) => a.subject.id == 's_low');

      expect(highAlloc.totalMinutes, greaterThan(lowAlloc.totalMinutes));
      expect(highAlloc.compositeWeight, greaterThan(lowAlloc.compositeWeight));
      expect(highAlloc.totalSlots, greaterThan(lowAlloc.totalSlots));
    });

    test('Subject difficulty (Hard vs Easy) impacts weight allocation', () {
      final hardSubject = const Subject(
        id: 's_hard',
        name: 'Quantum Physics',
        marks: 60,
        targetMarks: 90,
        studyHours: 0,
        color: '#0000FF',
        topics: ['Schrodinger Equation'],
        priority: SubjectPriority.medium,
        difficulty: SubjectDifficulty.hard,
      );

      final easySubject = const Subject(
        id: 's_easy',
        name: 'Art History',
        marks: 60,
        targetMarks: 90,
        studyHours: 0,
        color: '#FFFF00',
        topics: ['Renaissance'],
        priority: SubjectPriority.medium,
        difficulty: SubjectDifficulty.easy,
      );

      final hardWeight = TimetableGenerator.calculateSubjectWeight(hardSubject);
      final easyWeight = TimetableGenerator.calculateSubjectWeight(easySubject);

      expect(hardWeight, greaterThan(easyWeight));
    });

    test('Upcoming exam within 3 days awards urgency multiplier', () {
      final upcomingExamSubject = Subject(
        id: 's_exam',
        name: 'Organic Chemistry',
        marks: 75,
        targetMarks: 90,
        studyHours: 0,
        color: '#FFAA00',
        topics: ['Reactions'],
        priority: SubjectPriority.high,
        difficulty: SubjectDifficulty.hard,
        examDate: DateTime.now().add(const Duration(days: 2)),
      );

      final distantExamSubject = Subject(
        id: 's_no_exam',
        name: 'Organic Chemistry',
        marks: 75,
        targetMarks: 90,
        studyHours: 0,
        color: '#FFAA00',
        topics: ['Reactions'],
        priority: SubjectPriority.high,
        difficulty: SubjectDifficulty.hard,
        examDate: DateTime.now().add(const Duration(days: 30)),
      );

      final urgentWeight = TimetableGenerator.calculateSubjectWeight(upcomingExamSubject);
      final distantWeight = TimetableGenerator.calculateSubjectWeight(distantExamSubject);

      expect(urgentWeight, greaterThan(distantWeight));
    });

    test('Schedule generation assigns specific unfinished topics to scheduled tasks', () {
      final subject = const Subject(
        id: 's_math',
        name: 'Mathematics',
        marks: 80,
        targetMarks: 95,
        studyHours: 5,
        color: '#123456',
        topics: ['Vectors', 'Matrices', 'Complex Numbers'],
        completedTopics: ['Vectors'],
        priority: SubjectPriority.high,
        difficulty: SubjectDifficulty.medium,
      );

      final schedule = TimetableGenerator.generateSchedule(
        subjects: [subject],
        daysCount: 3,
        dailyStudyHours: 2.0,
        slotDurationMinutes: 60,
      );

      expect(schedule.isNotEmpty, isTrue);
      // Verify unfinished topics like Matrices and Complex Numbers are included in task titles
      final titles = schedule.map((t) => t.title).toList();
      expect(titles.any((t) => t.contains('Matrices') || t.contains('Complex Numbers')), isTrue);
    });

    test('Preserving completed tasks when regenerating schedule keeps completed tasks untouched', () {
      final completedTask = ScheduledTask(
        id: 'existing_completed',
        title: 'Completed Review',
        subjectId: 's_old',
        subjectName: 'Old Subject',
        scheduledDate: DateTime.now(),
        startTime: '08:00',
        endTime: '09:00',
        isCompleted: true,
        priority: 'high',
      );

      final subject = const Subject(
        id: 's_new',
        name: 'New Subject',
        marks: 80,
        targetMarks: 90,
        studyHours: 0,
        color: '#FF1122',
        topics: ['Topic 1'],
        priority: SubjectPriority.high,
      );

      final schedule = TimetableGenerator.generateSchedule(
        subjects: [subject],
        daysCount: 2,
        dailyStudyHours: 2.0,
        existingTasks: [completedTask],
        preserveCompleted: true,
      );

      expect(schedule.any((t) => t.id == 'existing_completed' && t.isCompleted), isTrue);
    });
  });
}
