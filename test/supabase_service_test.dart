import 'package:flutter_test/flutter_test.dart';
import 'package:smart_study_planner/data/services/supabase_service.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';

void main() {
  group('Supabase Service & Config Tests', () {
    test('SupabaseConfig correctly detects default placeholder credentials', () {
      expect(SupabaseConfig.isConfigured, isFalse);
      expect(SupabaseService.client, isNull);
      expect(SupabaseService.isInitialized, isFalse);
    });

    test('SupabaseService.initialize() safely handles unconfigured mode without crashing', () async {
      // Must complete without error
      await expectLater(SupabaseService.initialize(), completes);
    });

    test('ScheduledTask converts snake_case database rows cleanly', () {
      final dbRow = {
        'id': 'task-123',
        'title': 'Read Chapter 4',
        'subject_id': 'sub-phy',
        'subject_name': 'Physics',
        'scheduled_date': '2026-10-01T09:00:00.000Z',
        'start_time': '09:00',
        'end_time': '10:30',
        'is_completed': true,
        'priority': 'high',
        'description': 'Solve numerical problems',
      };

      final task = ScheduledTask.fromJson(dbRow);
      expect(task.id, 'task-123');
      expect(task.title, 'Read Chapter 4');
      expect(task.subjectId, 'sub-phy');
      expect(task.subjectName, 'Physics');
      expect(task.startTime, '09:00');
      expect(task.endTime, '10:30');
      expect(task.isCompleted, isTrue);
      expect(task.priority, 'high');
      expect(task.description, 'Solve numerical problems');
    });

    test('QuickNote converts snake_case database rows cleanly', () {
      final dbRow = {
        'id': 'note-456',
        'title': 'Formula Sheet',
        'content': 'E = mc^2',
        'subject_id': 'sub-phy',
        'subject_name': 'Physics',
        'created_at': '2026-09-30T10:00:00.000Z',
        'updated_at': '2026-09-30T10:30:00.000Z',
      };

      final note = QuickNote.fromJson(dbRow);
      expect(note.id, 'note-456');
      expect(note.title, 'Formula Sheet');
      expect(note.content, 'E = mc^2');
      expect(note.subjectId, 'sub-phy');
      expect(note.subjectName, 'Physics');
    });

    test('StudySession converts snake_case database rows cleanly', () {
      final dbRow = {
        'id': 'session-789',
        'subject_id': 'sub-math',
        'subject_name': 'Calculus',
        'start_time': '2026-09-30T08:00:00.000Z',
        'end_time': '2026-09-30T08:25:00.000Z',
        'duration_minutes': 25,
        'session_type': 'pomodoro',
        'notes': 'Focused deep work',
      };

      final session = StudySession.fromJson(dbRow);
      expect(session.id, 'session-789');
      expect(session.subjectId, 'sub-math');
      expect(session.durationMinutes, 25);
      expect(session.sessionType, 'pomodoro');
      expect(session.notes, 'Focused deep work');
    });
  });
}
