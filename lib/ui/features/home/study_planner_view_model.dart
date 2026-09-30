import 'package:flutter/material.dart';
import 'dart:async';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';
import 'package:smart_study_planner/domain/models/study_session.dart';
import 'package:smart_study_planner/domain/models/learning_journey.dart';
import 'package:smart_study_planner/domain/models/parental_control.dart';
import 'package:smart_study_planner/data/services/parental_notification_service.dart';

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

  void Function({
    required bool isStudying,
    String? subject,
    String? phase,
    int? secondsRemaining,
  })? onStudyStateChanged;

  void _notifyStateChange() {
    onStudyStateChanged?.call(
      isStudying: _isRunning && _phase == PomodoroPhase.work,
      subject: _selectedSubjectName,
      phase: _isRunning
          ? (_phase == PomodoroPhase.work ? 'Focusing' : 'Break')
          : (_secondsRemaining == _totalSeconds ? 'Idle' : 'Paused'),
      secondsRemaining: _secondsRemaining,
    );
  }

  void selectSubject(String? id, String? name) {
    _selectedSubjectId = id;
    _selectedSubjectName = name;
    _notifyStateChange();
    notifyListeners();
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    _notifyStateChange();
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    _notifyStateChange();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _secondsRemaining = _totalSeconds;
    _notifyStateChange();
    notifyListeners();
  }

  void skipPhase() {
    _timer?.cancel();
    _isRunning = false;
    _advancePhase();
    _notifyStateChange();
    notifyListeners();
  }

  void _tick(Timer timer) {
    if (_secondsRemaining > 0) {
      _secondsRemaining--;
      if (_secondsRemaining % 5 == 0) {
        _notifyStateChange();
      }
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
    _notifyStateChange();
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
  ParentalControlConfig _parentalConfig = const ParentalControlConfig();
  List<DistractionBreachLog> _breachLogs = [];
  bool _isCurrentlyStudying = false;
  String? _liveCurrentSubject;
  String _livePhase = 'Idle';
  int _liveSecondsRemaining = 0;
  DateTime? _lastActiveTime;
  bool _isParentModeActive = false;
  bool _isLoading = true;
  int _selectedTabIndex = 0;
  bool _isDarkMode = false;
  Timer? _cloudSyncTimer;
  bool _isCloudSyncEnabled = false;
  bool _isParentDevice = false; // true = parent's separate phone
  ChildLiveStatus? _remoteChildStatus; // from Supabase for parent device
  List<DistractionBreachLog> _unreadRemoteAlerts = [];

  final ParentalNotificationService _notificationService =
      ParentalNotificationService.instance;

  UserProfile? get profile => _profile;
  List<StudySession> get sessions => List.unmodifiable(_sessions);
  List<ScheduledTask> get tasks => List.unmodifiable(_tasks);
  List<QuickNote> get notes => List.unmodifiable(_notes);
  JourneyProgress get journeyProgress => _journeyProgress ?? JourneyProgress.defaultProgress();
  ParentalControlConfig get parentalConfig => _parentalConfig;
  List<DistractionBreachLog> get breachLogs => List.unmodifiable(_breachLogs);
  bool get isParentModeActive => _isParentModeActive;
  String? get liveCurrentSubject => _liveCurrentSubject;
  bool get isCurrentlyStudying => _isCurrentlyStudying;
  String get livePhase => _livePhase;
  int get liveSecondsRemaining => _liveSecondsRemaining;
  bool get isLoading => _isLoading;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isDarkMode => _isDarkMode;
  bool get isCloudSyncEnabled => _isCloudSyncEnabled;
  bool get isParentDevice => _isParentDevice;
  ChildLiveStatus? get remoteChildStatus => _remoteChildStatus;
  List<DistractionBreachLog> get unreadRemoteAlerts =>
      List.unmodifiable(_unreadRemoteAlerts);

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
    _parentalConfig = await _repository.getParentalConfig();
    _breachLogs = await _repository.getBreachLogs();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _repository.saveProfile(profile);
    _profile = profile;

    // Automatically bind father's credentials to parental control
    if ((profile.fatherPhone != null && profile.fatherPhone!.trim().isNotEmpty) ||
        (profile.fatherEmail != null && profile.fatherEmail!.trim().isNotEmpty)) {
      _parentalConfig = _parentalConfig.copyWith(
        parentContact: profile.fatherPhone?.trim(),
        parentEmail: profile.fatherEmail?.trim(),
        isEnabled: true,
      );
      await _repository.saveParentalConfig(_parentalConfig);
      await enableCloudSync();
      _syncConfigToCloud();
    }

    notifyListeners();
  }

  Future<void> updateFatherCredentials({
    required String phone,
    required String email,
    String? name,
  }) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        fatherPhone: phone.trim(),
        fatherEmail: email.trim(),
        fatherName: name?.trim(),
      );
      await _repository.saveProfile(_profile!);
    }

    _parentalConfig = _parentalConfig.copyWith(
      parentContact: phone.trim(),
      parentEmail: email.trim(),
      isEnabled: true,
    );
    await _repository.saveParentalConfig(_parentalConfig);
    await enableCloudSync();
    _syncConfigToCloud();
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
    _breachLogs = [];
    notifyListeners();
  }

  // ─── Parental Control Logic & Live State ─────────────────────────────

  bool get isExamLockdownActive {
    if (!_parentalConfig.isEnabled) return false;
    if (_parentalConfig.isEmergencyLockActive) return true;

    if (_parentalConfig.autoLockOnExamDays) {
      final upcoming = activeOrUpcomingExam;
      if (upcoming != null) {
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? get activeOrUpcomingExam {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final windowDays = _parentalConfig.lockDaysBeforeExam;

    // 1. Check Learning Journey Hurdle
    final hurdle = _journeyProgress?.hurdle;
    if (hurdle != null && !hurdle.isPassed) {
      final hurdleDate = DateTime(
        hurdle.examDate.year,
        hurdle.examDate.month,
        hurdle.examDate.day,
      );
      final daysDiff = hurdleDate.difference(todayStart).inDays;
      if (daysDiff >= 0 && daysDiff <= windowDays) {
        return {
          'title': hurdle.title,
          'subject': hurdle.subjectName,
          'date': hurdle.examDate,
          'isToday': daysDiff == 0,
          'isTomorrow': daysDiff == 1,
          'daysRemaining': daysDiff,
          'type': 'hurdle',
        };
      }
    }

    // 2. Check Tasks for exams or tests
    for (final task in _tasks) {
      final lowerTitle = task.title.toLowerCase();
      final isExam = lowerTitle.contains('exam') ||
          lowerTitle.contains('test') ||
          task.priority == 'high';
      if (isExam && !task.isCompleted) {
        final taskDate = DateTime(
          task.scheduledDate.year,
          task.scheduledDate.month,
          task.scheduledDate.day,
        );
        final daysDiff = taskDate.difference(todayStart).inDays;
        if (daysDiff >= 0 && daysDiff <= windowDays) {
          return {
            'title': task.title,
            'subject': task.subjectName,
            'date': task.scheduledDate,
            'isToday': daysDiff == 0,
            'isTomorrow': daysDiff == 1,
            'daysRemaining': daysDiff,
            'type': 'task',
          };
        }
      }
    }

    return null;
  }

  ChildLiveStatus get childLiveStatus {
    final now = DateTime.now();
    final todaySessions = _sessions.where((s) =>
        s.startTime.year == now.year &&
        s.startTime.month == now.month &&
        s.startTime.day == now.day);
    final todayMins =
        todaySessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final examInfo = activeOrUpcomingExam;
    String? examReason;
    if (examInfo != null) {
      if (examInfo['isToday'] == true) {
        examReason = '${examInfo['title']} is TODAY! 🎯';
      } else if (examInfo['isTomorrow'] == true) {
        examReason = '${examInfo['title']} is TOMORROW! ⏳';
      } else {
        examReason =
            '${examInfo['title']} in ${examInfo['daysRemaining']} days 📅';
      }
    }

    return ChildLiveStatus(
      studentName: _profile?.name.isNotEmpty == true ? _profile!.name : 'Student',
      isStudyingNow: _isCurrentlyStudying,
      currentSubject: _liveCurrentSubject,
      currentPhase: _livePhase,
      sessionSecondsRemaining: _liveSecondsRemaining,
      todayStudyMinutes: todayMins,
      todayTargetMinutes: _parentalConfig.dailyStudyTargetMinutes,
      lastActiveTime: _lastActiveTime ?? now,
      isLockdownActive: isExamLockdownActive,
      activeExamReason: examReason,
      breachCount: _breachLogs.length,
      breachLogs: List.unmodifiable(_breachLogs),
      activeNudge: _parentalConfig.lastParentNudge,
    );
  }

  void setParentMode(bool active) {
    _isParentModeActive = active;
    notifyListeners();
  }

  void updateLiveStudyState({
    required bool isStudying,
    String? subject,
    String? phase,
    int? secondsRemaining,
  }) {
    _isCurrentlyStudying = isStudying;
    if (subject != null) _liveCurrentSubject = subject;
    if (phase != null) _livePhase = phase;
    if (secondsRemaining != null) _liveSecondsRemaining = secondsRemaining;
    _lastActiveTime = DateTime.now();
    notifyListeners();

    // Sync to cloud every 30 seconds (on every other minute-boundary tick)
    if (_isCloudSyncEnabled &&
        _parentalConfig.familyPairingCode.isNotEmpty &&
        secondsRemaining != null &&
        secondsRemaining % 30 == 0) {
      _notificationService.syncChildStatus(
        _parentalConfig.familyPairingCode,
        childLiveStatus,
      );
    }
  }

  bool verifyParentPin(String pin) {
    return _parentalConfig.parentPin == pin.trim();
  }

  Future<void> updateParentPin(String newPin) async {
    _parentalConfig = _parentalConfig.copyWith(parentPin: newPin.trim());
    await _repository.saveParentalConfig(_parentalConfig);
    notifyListeners();
  }

  Future<void> setParentalControlsEnabled(bool enabled) async {
    _parentalConfig = _parentalConfig.copyWith(isEnabled: enabled);
    await _repository.saveParentalConfig(_parentalConfig);
    if (enabled) {
      await enableCloudSync();
    }
    _syncConfigToCloud();
    notifyListeners();
  }

  Future<void> toggleEmergencyLock(bool active) async {
    _parentalConfig = _parentalConfig.copyWith(isEmergencyLockActive: active);
    await _repository.saveParentalConfig(_parentalConfig);
    _syncConfigToCloud();
    notifyListeners();
  }

  Future<void> updateExamLockSettings({
    required bool autoLock,
    required int daysBefore,
  }) async {
    _parentalConfig = _parentalConfig.copyWith(
      autoLockOnExamDays: autoLock,
      lockDaysBeforeExam: daysBefore,
    );
    await _repository.saveParentalConfig(_parentalConfig);
    notifyListeners();
  }

  Future<void> toggleBlockedApp(String appName) async {
    final updatedList = List<String>.from(_parentalConfig.blockedApps);
    if (updatedList.contains(appName)) {
      updatedList.remove(appName);
    } else {
      updatedList.add(appName);
    }
    _parentalConfig = _parentalConfig.copyWith(blockedApps: updatedList);
    await _repository.saveParentalConfig(_parentalConfig);
    notifyListeners();
  }

  Future<void> addBlockedApp(String appName) async {
    final trimmed = appName.trim();
    if (trimmed.isEmpty) return;
    final updatedList = List<String>.from(_parentalConfig.blockedApps);
    if (!updatedList.contains(trimmed)) {
      updatedList.add(trimmed);
      _parentalConfig = _parentalConfig.copyWith(blockedApps: updatedList);
      await _repository.saveParentalConfig(_parentalConfig);
      notifyListeners();
    }
  }

  Future<void> sendParentNudge(String message) async {
    _parentalConfig = _parentalConfig.copyWith(
      lastParentNudge: message,
      lastParentNudgeTime: DateTime.now(),
    );
    await _repository.saveParentalConfig(_parentalConfig);
    notifyListeners();
  }

  Future<void> dismissNudge() async {
    _parentalConfig = _parentalConfig.copyWith(lastParentNudge: null);
    await _repository.saveParentalConfig(_parentalConfig);
    notifyListeners();
  }

  Future<void> recordDistractionBreach({
    required String reason,
    required String subject,
  }) async {
    final log = DistractionBreachLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      reason: reason,
      subject: subject,
      parentPhoneNumber: _parentalConfig.parentPhoneNumber,
    );
    await _repository.logDistractionBreach(log);
    _breachLogs = await _repository.getBreachLogs();
    notifyListeners();

    // 🚨 Push alert to cloud so parent's phone gets an instant notification
    if (_isCloudSyncEnabled && _parentalConfig.familyPairingCode.isNotEmpty) {
      _notificationService.pushDistractionAlert(
        _parentalConfig.familyPairingCode,
        log,
        parentPhoneNumber: _parentalConfig.parentPhoneNumber,
      );
      // Also sync updated live status
      _notificationService.syncChildStatus(
        _parentalConfig.familyPairingCode,
        childLiveStatus,
      );
    }
  }

  Future<void> updateParentPhoneNumber(String phone) async {
    _parentalConfig = _parentalConfig.copyWith(parentContact: phone.trim());
    await _repository.saveParentalConfig(_parentalConfig);
    _syncConfigToCloud();
    notifyListeners();
  }

  Future<void> sendTestParentAlert() async {
    final phone = _parentalConfig.parentPhoneNumber ?? 'Registered Parent Phone';
    final name = _profile?.name.isNotEmpty == true ? _profile!.name : 'Student';
    await _notificationService.sendTestAlertToParent(
      parentPhoneNumber: phone,
      studentName: name,
    );
  }

  Future<void> clearBreachLogs() async {
    await _repository.clearBreachLogs();
    _breachLogs = [];
    notifyListeners();
  }

  Future<void> setDailyTargetMinutes(int minutes) async {
    _parentalConfig = _parentalConfig.copyWith(dailyStudyTargetMinutes: minutes);
    await _repository.saveParentalConfig(_parentalConfig);
    notifyListeners();
  }

  Future<void> updateFamilyPairingCode(String code) async {
    _parentalConfig = _parentalConfig.copyWith(
      familyPairingCode: code.trim().toUpperCase(),
    );
    await _repository.saveParentalConfig(_parentalConfig);
    notifyListeners();
  }

  // ─── Cloud Sync & Cross-Device Notifications ─────────────────────────

  /// Enable cloud sync for cross-device parental control.
  /// Call this after parental controls are enabled.
  Future<void> enableCloudSync() async {
    if (_isCloudSyncEnabled) return;

    await _notificationService.initialize();
    _isCloudSyncEnabled = true;

    // Sync current config and status to cloud
    final code = _parentalConfig.familyPairingCode;
    if (code.isNotEmpty) {
      _notificationService.syncParentalConfig(code, _parentalConfig);
      _notificationService.syncChildStatus(code, childLiveStatus);
    }
    notifyListeners();
  }

  /// Disable cloud sync.
  void disableCloudSync() {
    _isCloudSyncEnabled = false;
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = null;
    _notificationService.unsubscribeFromAlerts();
    notifyListeners();
  }

  /// Activate parent device mode (on parent's separate phone).
  /// This starts real-time subscriptions so the parent gets instant
  /// push notifications when the child leaves the study app.
  Future<void> activateParentDeviceMode() async {
    _isParentDevice = true;
    await enableCloudSync();

    final code = _parentalConfig.familyPairingCode;
    if (code.isEmpty) return;

    // Subscribe to real-time alerts from child's phone
    _notificationService.subscribeToChildAlerts(
      code,
      onAlert: (breach) {
        _unreadRemoteAlerts.insert(0, breach);
        notifyListeners();
      },
      onStatusChange: (status) {
        _remoteChildStatus = status;
        notifyListeners();
      },
    );

    // Fetch initial data
    await refreshRemoteData();

    // Start periodic refresh every 60 seconds as fallback
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => refreshRemoteData(),
    );

    notifyListeners();
  }

  /// Deactivate parent device mode.
  void deactivateParentDeviceMode() {
    _isParentDevice = false;
    _remoteChildStatus = null;
    _unreadRemoteAlerts = [];
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = null;
    _notificationService.unsubscribeFromAlerts();
    notifyListeners();
  }

  /// Fetch latest data from cloud (called periodically on parent's phone).
  Future<void> refreshRemoteData() async {
    final code = _parentalConfig.familyPairingCode;
    if (code.isEmpty) return;

    final status = await _notificationService.fetchChildStatus(code);
    if (status != null) {
      _remoteChildStatus = status;
    }

    _unreadRemoteAlerts =
        await _notificationService.fetchUnreadAlerts(code);

    // Fetch remote config updates
    final remoteConfig =
        await _notificationService.fetchParentalConfig(code);
    if (remoteConfig != null &&
        remoteConfig.isEnabled != _parentalConfig.isEnabled) {
      _parentalConfig = remoteConfig;
      await _repository.saveParentalConfig(_parentalConfig);
    }

    notifyListeners();
  }

  /// Mark all remote alerts as read.
  Future<void> markRemoteAlertsRead() async {
    final code = _parentalConfig.familyPairingCode;
    if (code.isEmpty) return;

    await _notificationService.markAlertsRead(code);
    _unreadRemoteAlerts = [];
    notifyListeners();
  }

  /// Sync config to cloud after any local config change (for parent device).
  Future<void> _syncConfigToCloud() async {
    if (_isCloudSyncEnabled &&
        _parentalConfig.familyPairingCode.isNotEmpty) {
      _notificationService.syncParentalConfig(
        _parentalConfig.familyPairingCode,
        _parentalConfig,
      );
    }
  }

  /// Get the child's effective live status — local if same device, remote if parent device.
  ChildLiveStatus get effectiveLiveStatus =>
      _isParentDevice && _remoteChildStatus != null
          ? _remoteChildStatus!
          : childLiveStatus;
  /// Authenticate and identify the father on the Welcome board using
  /// Father's Email ID and Mobile Number (plus Master PIN).
  Future<bool> loginAsFather({
    required String email,
    required String phone,
    String? pin,
  }) async {
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();
    final cleanPin = (pin ?? '').trim();

    // Verify PIN if provided
    if (cleanPin.isNotEmpty && !verifyParentPin(cleanPin)) {
      return false;
    }

    // Save and link father credentials
    await updateFatherCredentials(
      phone: cleanPhone,
      email: cleanEmail,
    );

    // Activate Parent Device Mode so this phone showcases parental control
    await activateParentDeviceMode();

    notifyListeners();
    return true;
  }

  /// Student entry mode: ensures parental controls are hidden on the student's device.
  void setStudentMode() {
    _isParentDevice = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _cloudSyncTimer?.cancel();
    _notificationService.unsubscribeFromAlerts();
    super.dispose();
  }
}
