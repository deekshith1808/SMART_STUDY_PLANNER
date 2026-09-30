import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/study_session.dart';
import '../../domain/models/learning_journey.dart';

class StorageService {
  static const _profileKey = 'user_profile';
  static const _sessionsKey = 'study_sessions';
  static const _tasksKey = 'scheduled_tasks';
  static const _notesKey = 'quick_notes';
  static const _pomodoroSettingsKey = 'pomodoro_settings';
  static const _journeyKey = 'learning_journey_progress';

  // User Profile
  Future<UserProfile?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_profileKey);
    if (jsonStr == null) return null;
    return UserProfile.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // Study Sessions
  Future<List<StudySession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_sessionsKey);
    if (jsonStr == null) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => StudySession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveSessions(List<StudySession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionsKey, jsonEncode(sessions.map((s) => s.toJson()).toList()));
  }

  // Scheduled Tasks
  Future<List<ScheduledTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_tasksKey);
    if (jsonStr == null) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTasks(List<ScheduledTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  // Quick Notes
  Future<List<QuickNote>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_notesKey);
    if (jsonStr == null) return [];
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => QuickNote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveNotes(List<QuickNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notesKey, jsonEncode(notes.map((n) => n.toJson()).toList()));
  }

  // Pomodoro Settings
  Future<Map<String, int>> loadPomodoroSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pomodoroSettingsKey);
    if (jsonStr == null) {
      return {'workMinutes': 25, 'shortBreak': 5, 'longBreak': 15, 'sessionsBeforeLongBreak': 4};
    }
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> savePomodoroSettings(Map<String, int> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pomodoroSettingsKey, jsonEncode(settings));
  }

  // Learning Journey & Duolingo Levels
  Future<JourneyProgress> loadJourneyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_journeyKey);
    if (jsonStr == null) return JourneyProgress.defaultProgress();
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return JourneyProgress.fromJson(map);
    } catch (_) {
      return JourneyProgress.defaultProgress();
    }
  }

  Future<void> saveJourneyProgress(JourneyProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_journeyKey, jsonEncode(progress.toJson()));
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
