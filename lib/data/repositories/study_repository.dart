import 'package:smart_study_planner/data/services/storage_service.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';

class StudyRepository {
  StudyRepository({required StorageService storageService})
      : _storage = storageService;

  final StorageService _storage;

  void setUserId(String? userId) => _storage.setUserId(userId);
  Future<void> clearUserCache([String? userId]) => _storage.clearUserCache(userId);

  // Profile
  Future<UserProfile?> getProfile() => _storage.loadProfile();
  Future<void> saveProfile(UserProfile profile) => _storage.saveProfile(profile);

  // Sessions
  Future<List<StudySession>> getSessions() => _storage.loadSessions();
  Future<void> saveSessions(List<StudySession> sessions) => _storage.saveSessions(sessions);
  Future<void> addSession(StudySession session) async {
    final sessions = await _storage.loadSessions();
    sessions.add(session);
    await _storage.saveSessions(sessions);
  }

  // Tasks
  Future<List<ScheduledTask>> getTasks() => _storage.loadTasks();
  Future<void> saveTasks(List<ScheduledTask> tasks) => _storage.saveTasks(tasks);
  Future<void> addTask(ScheduledTask task) async {
    final tasks = await _storage.loadTasks();
    tasks.add(task);
    await _storage.saveTasks(tasks);
  }

  Future<void> updateTask(ScheduledTask updatedTask) async {
    final tasks = await _storage.loadTasks();
    final index = tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await _storage.saveTasks(tasks);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await _storage.loadTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await _storage.saveTasks(tasks);
  }

  // Notes
  Future<List<QuickNote>> getNotes() => _storage.loadNotes();
  Future<void> saveNotes(List<QuickNote> notes) => _storage.saveNotes(notes);
  Future<void> addNote(QuickNote note) async {
    final notes = await _storage.loadNotes();
    notes.add(note);
    await _storage.saveNotes(notes);
  }

  Future<void> deleteNote(String noteId) async {
    final notes = await _storage.loadNotes();
    notes.removeWhere((n) => n.id == noteId);
    await _storage.saveNotes(notes);
  }

  // Pomodoro settings
  Future<Map<String, int>> getPomodoroSettings() => _storage.loadPomodoroSettings();
  Future<void> savePomodoroSettings(Map<String, int> settings) => _storage.savePomodoroSettings(settings);

  // Learning Journey & Duolingo Levels
  Future<JourneyProgress> getJourneyProgress() => _storage.loadJourneyProgress();
  Future<void> saveJourneyProgress(JourneyProgress progress) => _storage.saveJourneyProgress(progress);

  Future<JourneyProgress> completeJourneyNode(String nodeId) async {
    final progress = await _storage.loadJourneyProgress();
    final nodeIndex = progress.nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex == -1) return progress;

    final targetNode = progress.nodes[nodeIndex];
    if (targetNode.status == NodeStatus.completed) return progress;

    final updatedNodes = List<JourneyNode>.from(progress.nodes);
    // Mark target as completed
    updatedNodes[nodeIndex] = targetNode.copyWith(
      status: NodeStatus.completed,
      stars: 3,
    );

    // Unlock the next locked node in line if exists
    for (int i = nodeIndex + 1; i < updatedNodes.length; i++) {
      if (updatedNodes[i].status == NodeStatus.locked) {
        updatedNodes[i] = updatedNodes[i].copyWith(status: NodeStatus.active);
        break;
      }
    }

    // Check if hurdle should increment
    final completedCount = updatedNodes.where((n) => n.status == NodeStatus.completed).length;
    final updatedHurdle = progress.hurdle.copyWith(
      completedNodes: completedCount,
      isPassed: completedCount >= progress.hurdle.requiredNodes,
    );

    final updatedProgress = progress.copyWith(
      totalXp: progress.totalXp + targetNode.xpReward,
      nodes: updatedNodes,
      hurdle: updatedHurdle,
      lastStudyDate: DateTime.now(),
    );

    await _storage.saveJourneyProgress(updatedProgress);
    return updatedProgress;
  }

  Future<JourneyProgress> addXp(int xp) async {
    final progress = await _storage.loadJourneyProgress();
    final updated = progress.copyWith(
      totalXp: progress.totalXp + xp,
      lastStudyDate: DateTime.now(),
    );
    await _storage.saveJourneyProgress(updated);
    return updated;
  }

  Future<void> clearAll() => _storage.clearAll();
}
