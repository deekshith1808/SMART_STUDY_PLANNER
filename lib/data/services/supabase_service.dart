import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/study_session.dart';
import '../../domain/models/learning_journey.dart';

class SupabaseConfig {
  /// Supabase Project credentials
  static const String supabaseUrl = 'https://yzzfrqbfhcfjfmcpaekx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6emZycWJmaGNmamZtY3BhZWt4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3MzU2NDMsImV4cCI6MjEwNjMxMTY0M30.sSFARVoi2eAQdVVYFAGVxN91bjG5hDV0W6kDVNZvd5U';

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty &&
      !supabaseUrl.contains('YOUR_SUPABASE_URL') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
}

class SupabaseService {
  static SupabaseClient? get client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isInitialized => client != null;

  /// Safe initialization that never crashes if offline or unconfigured
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('ℹ️ [Supabase] Running in local offline mode (Credentials not configured yet).');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      debugPrint('✅ [Supabase] Initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ [Supabase] Initialization warning: $e');
    }
  }

  // ─── Authentication ────────────────────────────────────────────────────────
  User? get currentUser => client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  Stream<AuthState>? get authStateChanges => client?.auth.onAuthStateChange;

  Future<AuthResponse?> signUp({
    required String email,
    required String password,
  }) async {
    final supa = client;
    if (supa == null) return null;
    return await supa.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final supa = client;
    if (supa == null) return null;
    return await supa.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await client?.auth.signOut();
  }

  // ─── Cloud Sync: Profile ───────────────────────────────────────────────────
  Future<void> syncProfile(UserProfile profile) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return;

    await supa.from('profiles').upsert({
      'id': user.id,
      'name': profile.name,
      'education_type': profile.educationType,
      'branch': profile.branch,
      'course': profile.course,
      'subjects': profile.subjects.map((s) => s.toJson()).toList(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<UserProfile?> fetchProfile() async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return null;

    final response =
        await supa.from('profiles').select().eq('id', user.id).maybeSingle();
    if (response == null) return null;

    return UserProfile(
      name: response['name'] ?? '',
      educationType: response['education_type'] ?? 'school',
      branch: response['branch'],
      course: response['course'],
      subjects: (response['subjects'] as List<dynamic>? ?? [])
          .map((s) => Subject.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // ─── Cloud Sync: Sessions ──────────────────────────────────────────────────
  Future<void> syncSessions(List<StudySession> sessions) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null || sessions.isEmpty) return;

    final rows = sessions.map((s) => {
          'id': s.id,
          'user_id': user.id,
          'subject_id': s.subjectId,
          'subject_name': s.subjectName,
          'start_time': s.startTime.toIso8601String(),
          'end_time': s.endTime.toIso8601String(),
          'duration_minutes': s.durationMinutes,
          'session_type': s.sessionType,
        }).toList();

    await supa.from('study_sessions').upsert(rows);
  }

  Future<List<StudySession>> fetchSessions() async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return [];

    final response = await supa
        .from('study_sessions')
        .select()
        .eq('user_id', user.id)
        .order('start_time', ascending: true);

    return (response as List<dynamic>)
        .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Cloud Sync: Tasks ─────────────────────────────────────────────────────
  Future<void> syncTasks(List<ScheduledTask> tasks) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null || tasks.isEmpty) return;

    final rows = tasks.map((t) => {
          'id': t.id,
          'user_id': user.id,
          'title': t.title,
          'subject_id': t.subjectId,
          'subject_name': t.subjectName,
          'scheduled_date': t.scheduledDate.toIso8601String(),
          'start_time': t.startTime,
          'end_time': t.endTime,
          'is_completed': t.isCompleted,
          'priority': t.priority,
          'description': t.description,
        }).toList();

    await supa.from('scheduled_tasks').upsert(rows);
  }

  Future<List<ScheduledTask>> fetchTasks() async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return [];

    final response =
        await supa.from('scheduled_tasks').select().eq('user_id', user.id);

    return (response as List<dynamic>)
        .map((e) => ScheduledTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Cloud Sync: Notes ─────────────────────────────────────────────────────
  Future<void> syncNotes(List<QuickNote> notes) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null || notes.isEmpty) return;

    final rows = notes.map((n) => {
          'id': n.id,
          'user_id': user.id,
          'title': n.title,
          'content': n.content,
          'subject_id': n.subjectId,
          'subject_name': n.subjectName,
          'created_at': n.createdAt.toIso8601String(),
          'updated_at': n.updatedAt.toIso8601String(),
        }).toList();

    await supa.from('quick_notes').upsert(rows);
  }

  Future<List<QuickNote>> fetchNotes() async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return [];

    final response =
        await supa.from('quick_notes').select().eq('user_id', user.id);

    return (response as List<dynamic>)
        .map((e) => QuickNote.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Cloud Sync: Duolingo Learning Journey ────────────────────────────────
  Future<void> syncJourney(JourneyProgress progress) async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return;

    await supa.from('journey_progress').upsert({
      'user_id': user.id,
      'total_xp': progress.totalXp,
      'current_streak': progress.currentStreak,
      'last_study_date': progress.lastStudyDate?.toIso8601String(),
      'has_streak_shield': progress.hasStreakShield,
      'nodes_json': progress.nodes.map((n) => n.toJson()).toList(),
      'hurdle_json': progress.hurdle.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<JourneyProgress?> fetchJourney() async {
    final supa = client;
    final user = currentUser;
    if (supa == null || user == null) return null;

    final response = await supa
        .from('journey_progress')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;

    final nodesList = (response['nodes_json'] as List<dynamic>? ?? [])
        .map((e) => JourneyNode.fromJson(e as Map<String, dynamic>))
        .toList();

    final hurdleMap = response['hurdle_json'] as Map<String, dynamic>?;

    return JourneyProgress(
      totalXp: response['total_xp'] as int? ?? 0,
      currentStreak: response['current_streak'] as int? ?? 0,
      lastStudyDate: response['last_study_date'] != null
          ? DateTime.tryParse(response['last_study_date'] as String)
          : null,
      hasStreakShield: response['has_streak_shield'] as bool? ?? true,
      nodes: nodesList.isNotEmpty
          ? nodesList
          : JourneyProgress.defaultProgress().nodes,
      hurdle: hurdleMap != null
          ? ExamHurdle.fromJson(hurdleMap)
          : JourneyProgress.defaultProgress().hurdle,
    );
  }
}
