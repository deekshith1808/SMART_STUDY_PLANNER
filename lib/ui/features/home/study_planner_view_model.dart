import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';

enum PomodoroPhase { work, shortBreak, longBreak }

class PomodoroViewModel extends ChangeNotifier {
  PomodoroViewModel({required this._repository}) {
    _loadSettings();
  }

  final StudyRepository _repository;
  Timer? _timer;

  // Pomodoro settings (editable)
  int workMinutes = 25;
  int shortBreakMinutes = 5;
  int longBreakMinutes = 15;
  int sessionsBeforeLongBreak = 4;

  // State
  PomodoroPhase _phase = PomodoroPhase.work;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  int _completedSessions = 0;
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  PomodoroPhase get phase => _phase;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  int get completedSessions => _completedSessions;
  String? get selectedSubjectId => _selectedSubjectId;
  String? get selectedSubjectName => _selectedSubjectName;

  String get formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    final totalSeconds = _totalSeconds;
    return (_secondsRemaining / totalSeconds).clamp(0.0, 1.0);
  }

  int get _totalSeconds {
    switch (_phase) {
      case PomodoroPhase.work:
        return workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return longBreakMinutes * 60;
    }
  }

  String get phaseLabel {
    switch (_phase) {
      case PomodoroPhase.work:
        return 'Focus Time';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  Color get phaseColor {
    switch (_phase) {
      case PomodoroPhase.work:
        return const Color(0xFFC2410C);
      case PomodoroPhase.shortBreak:
        return const Color(0xFF047857);
      case PomodoroPhase.longBreak:
        return const Color(0xFFD97706);
    }
  }

  void selectSubject(String? id, String? name) {
    _selectedSubjectId = id;
    _selectedSubjectName = name;
    notifyListeners();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _secondsRemaining = _totalSeconds;
    notifyListeners();
  }

  void skipPhase() {
    _timer?.cancel();
    _isRunning = false;
    _advancePhase();
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      notifyListeners();
    } else {
      _timer?.cancel();
      _isRunning = false;
      _handlePhaseComplete();
    }
  }

  void _handlePhaseComplete() {
    if (_phase == PomodoroPhase.work) {
      _completedSessions++;
      _logSession();
    }
    _advancePhase();
    notifyListeners();
  }

  void _advancePhase() {
    switch (_phase) {
      case PomodoroPhase.work:
        if (_completedSessions % sessionsBeforeLongBreak == 0 && _completedSessions > 0) {
          _phase = PomodoroPhase.longBreak;
        } else {
          _phase = PomodoroPhase.shortBreak;
        }
        break;
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        _phase = PomodoroPhase.work;
        break;
    }
    _secondsRemaining = _totalSeconds;
  }

  void _logSession() {
    if (_selectedSubjectId == null) return;
    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: _selectedSubjectId!,
      subjectName: _selectedSubjectName ?? 'Unknown',
      startTime: DateTime.now().subtract(Duration(minutes: workMinutes)),
      endTime: DateTime.now(),
      durationMinutes: workMinutes,
      sessionType: 'pomodoro',
    );
    _repository.addSession(session);
    _repository.addXp(25);
  }

  Future<void> updateSettings({
    required int work,
    required int shortBreak,
    required int longBreak,
    required int sessionsBefore,
  }) async {
    workMinutes = work;
    shortBreakMinutes = shortBreak;
    longBreakMinutes = longBreak;
    sessionsBeforeLongBreak = sessionsBefore;
    _secondsRemaining = _phase == PomodoroPhase.work
        ? work * 60
        : _phase == PomodoroPhase.shortBreak
            ? shortBreak * 60
            : longBreak * 60;
    await _repository.savePomodoroSettings({
      'workMinutes': work,
      'shortBreak': shortBreak,
      'longBreak': longBreak,
      'sessionsBeforeLongBreak': sessionsBefore,
    });
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.getPomodoroSettings();
    workMinutes = settings['workMinutes'] ?? 25;
    shortBreakMinutes = settings['shortBreak'] ?? 5;
    longBreakMinutes = settings['longBreak'] ?? 15;
    sessionsBeforeLongBreak = settings['sessionsBeforeLongBreak'] ?? 4;
    _secondsRemaining = workMinutes * 60;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class StudyPlannerViewModel extends ChangeNotifier {
  StudyPlannerViewModel({required this._repository}) {
    loadData();
  }

  final StudyRepository _repository;

  UserProfile? _profile;
  List<StudySession> _sessions = [];
  List<ScheduledTask> _tasks = [];
  List<QuickNote> _notes = [];
  JourneyProgress? _journeyProgress;
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  bool _isDarkMode = false;

  UserProfile? get profile => _profile;
  List<StudySession> get sessions => List.unmodifiable(_sessions);
  List<ScheduledTask> get tasks => List.unmodifiable(_tasks);
  List<QuickNote> get notes => List.unmodifiable(_notes);
  JourneyProgress get journeyProgress => _journeyProgress ?? JourneyProgress.defaultProgress();
  bool get isLoading => _isLoading;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isDarkMode => _isDarkMode;

  List<ScheduledTask> get todayTasks {
    final today = DateTime.now();
    return _tasks.where((t) =>
      t.scheduledDate.year == today.year &&
      t.scheduledDate.month == today.month &&
      t.scheduledDate.day == today.day
    ).toList();
  }

  List<ScheduledTask> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();

  int get totalStudyHoursThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _sessions
        .where((s) => s.startTime.isAfter(weekStart))
        .fold(0, (sum, s) => sum + s.durationMinutes) ~/
        60;
  }

  Map<String, int> get subjectStudyMinutes {
    final map = <String, int>{};
    for (final session in _sessions) {
      map[session.subjectName] = (map[session.subjectName] ?? 0) + session.durationMinutes;
    }
    return map;
  }

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _profile = await _repository.getProfile();
    _sessions = await _repository.getSessions();
    _tasks = await _repository.getTasks();
    _notes = await _repository.getNotes();
    _journeyProgress = await _repository.getJourneyProgress();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _repository.saveProfile(profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> addSubject(Subject subject) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      subjects: [..._profile!.subjects, subject],
    );
    await saveProfile(updated);
  }

  Future<void> updateSubject(Subject subject) async {
    if (_profile == null) return;
    final updatedSubjects = _profile!.subjects.map((s) => s.id == subject.id ? subject : s).toList();
    final updated = _profile!.copyWith(subjects: updatedSubjects);
    await saveProfile(updated);
  }

  Future<void> deleteSubject(String subjectId) async {
    if (_profile == null) return;
    final updatedSubjects = _profile!.subjects.where((s) => s.id != subjectId).toList();
    final updated = _profile!.copyWith(subjects: updatedSubjects);
    await saveProfile(updated);
  }

  Future<void> addTask(ScheduledTask task) async {
    await _repository.addTask(task);
    _tasks = await _repository.getTasks();
    notifyListeners();
  }

  Future<void> toggleTaskComplete(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final willComplete = !task.isCompleted;
    await _repository.updateTask(task.copyWith(isCompleted: willComplete));
    if (willComplete) {
      _journeyProgress = await _repository.addXp(15);
    }
    _tasks = await _repository.getTasks();
    notifyListeners();
  }

  Future<void> completeJourneyNode(String nodeId) async {
    _journeyProgress = await _repository.completeJourneyNode(nodeId);
    notifyListeners();
  }

  Future<void> addXp(int xp) async {
    _journeyProgress = await _repository.addXp(xp);
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    await _repository.deleteTask(taskId);
    _tasks = await _repository.getTasks();
    notifyListeners();
  }

  Future<void> addNote(QuickNote note) async {
    await _repository.addNote(note);
    _notes = await _repository.getNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    await _repository.deleteNote(noteId);
    _notes = await _repository.getNotes();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _repository.clearAll();
    _profile = null;
    _sessions = [];
    _tasks = [];
    _notes = [];
    notifyListeners();
  }
}
