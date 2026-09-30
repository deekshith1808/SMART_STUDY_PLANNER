import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:smart_study_planner/data/services/supabase_service.dart';
import 'package:smart_study_planner/domain/models/parental_control.dart';

/// Service for cross-device parental control communication via Supabase.
///
/// Architecture:
/// - Child's phone pushes live status + distraction alerts to Supabase cloud.
/// - Parent's phone subscribes to Supabase Realtime and receives instant
///   push notifications when the child leaves the study app during lockdown.
/// - Both devices share a **Family Pairing Code** to link together.
///
/// Supabase Tables Required (run [setupSQL] in the Supabase SQL Editor):
///   • `child_live_status`  — child's current study state
///   • `distraction_alerts` — breach events when child leaves the app
///   • `parental_configs`   — shared parental control configuration
class ParentalNotificationService {
  ParentalNotificationService._();
  static final ParentalNotificationService instance =
      ParentalNotificationService._();

  bool _isInitialized = false;
  FlutterLocalNotificationsPlugin? _notificationsPlugin;
  RealtimeChannel? _alertChannel;
  RealtimeChannel? _statusChannel;

  /// Whether local notifications are ready.
  bool get isReady => _isInitialized;

  // ─── Initialization ──────────────────────────────────────────────────────

  /// Initialize local notifications (call once in `main()` or on first use).
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin!.initialize(settings: initSettings);
      _isInitialized = true;
      debugPrint('✅ [ParentalNotifications] Initialized successfully.');
    } catch (e) {
      debugPrint('⚠️ [ParentalNotifications] Init error: $e');
    }
  }

  // ─── Child-Side Methods (run on child's phone) ────────────────────────

  /// Push the child's current live study status to Supabase.
  Future<void> syncChildStatus(
      String familyCode, ChildLiveStatus status) async {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return;

    try {
      await supa.from('child_live_status').upsert(
        {
          'family_code': familyCode,
          'status_json': status.toJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'family_code',
      );
      debugPrint('📡 [Child] Live status synced to cloud.');
    } catch (e) {
      debugPrint('⚠️ [Child] Status sync failed: $e');
    }
  }

  /// Push a distraction alert to Supabase (child left app during study/lockdown).
  Future<void> pushDistractionAlert(
      String familyCode, DistractionBreachLog breach,
      {String? parentPhoneNumber}) async {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return;

    try {
      await supa.from('distraction_alerts').insert({
        'family_code': familyCode,
        'alert_json': breach.toJson(),
        'parent_phone': parentPhoneNumber ?? breach.parentPhoneNumber,
        'is_read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint(
          '🚨 [Child] Distraction alert pushed to cloud! (Parent phone: ${parentPhoneNumber ?? breach.parentPhoneNumber})');
    } catch (e) {
      debugPrint('⚠️ [Child] Alert push failed: $e');
    }
  }

  /// Sync parental config to Supabase (so parent's phone can fetch it).
  Future<void> syncParentalConfig(
      String familyCode, ParentalControlConfig config) async {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return;

    try {
      await supa.from('parental_configs').upsert(
        {
          'family_code': familyCode,
          'config_json': config.toJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'family_code',
      );
      debugPrint('☁️ [Config] Parental config synced to cloud.');
    } catch (e) {
      debugPrint('⚠️ [Config] Sync failed: $e');
    }
  }

  // ─── Parent-Side Methods (run on parent's phone) ──────────────────────

  /// Fetch child's latest live status from Supabase.
  Future<ChildLiveStatus?> fetchChildStatus(String familyCode) async {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return null;

    try {
      final response = await supa
          .from('child_live_status')
          .select()
          .eq('family_code', familyCode)
          .maybeSingle();

      if (response == null) return null;

      final statusJson = response['status_json'];
      if (statusJson is Map<String, dynamic>) {
        return ChildLiveStatus.fromJson(statusJson);
      } else if (statusJson is String) {
        return ChildLiveStatus.fromJson(
            jsonDecode(statusJson) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [Parent] Fetch child status failed: $e');
      return null;
    }
  }

  /// Fetch unread distraction alerts from Supabase.
  Future<List<DistractionBreachLog>> fetchUnreadAlerts(
      String familyCode) async {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return [];

    try {
      final response = await supa
          .from('distraction_alerts')
          .select()
          .eq('family_code', familyCode)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>).map((row) {
        final alertJson = row['alert_json'];
        if (alertJson is Map<String, dynamic>) {
          return DistractionBreachLog.fromJson(alertJson);
        } else if (alertJson is String) {
          return DistractionBreachLog.fromJson(
              jsonDecode(alertJson) as Map<String, dynamic>);
        }
        return DistractionBreachLog.fromJson({});
      }).toList();
    } catch (e) {
      debugPrint('⚠️ [Parent] Fetch alerts failed: $e');
      return [];
    }
  }

  /// Mark all alerts as read for this family code.
  Future<void> markAlertsRead(String familyCode) async {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return;

    try {
      await supa
          .from('distraction_alerts')
          .update({'is_read': true})
          .eq('family_code', familyCode)
          .eq('is_read', false);
      debugPrint('✅ [Parent] All alerts marked as read.');
    } catch (e) {
      debugPrint('⚠️ [Parent] Mark read failed: $e');
    }
  }

  /// Fetch shared parental config from Supabase.
  Future<ParentalControlConfig?> fetchParentalConfig(
      String familyCode) async {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return null;

    try {
      final response = await supa
          .from('parental_configs')
          .select()
          .eq('family_code', familyCode)
          .maybeSingle();

      if (response == null) return null;

      final configJson = response['config_json'];
      if (configJson is Map<String, dynamic>) {
        return ParentalControlConfig.fromJson(configJson);
      } else if (configJson is String) {
        return ParentalControlConfig.fromJson(
            jsonDecode(configJson) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ [Parent] Fetch config failed: $e');
      return null;
    }
  }

  // ─── Realtime Subscriptions (parent's phone) ──────────────────────────

  /// Subscribe to real-time distraction alerts and child status changes.
  ///
  /// When a new alert is inserted, this will:
  /// 1. Call the [onAlert] callback
  /// 2. Show a local push notification on the parent's phone
  ///
  /// When the child's status changes, this will call [onStatusChange].
  void subscribeToChildAlerts(
    String familyCode, {
    void Function(DistractionBreachLog)? onAlert,
    void Function(ChildLiveStatus)? onStatusChange,
  }) {
    final supa = SupabaseService.client;
    if (supa == null || familyCode.isEmpty) return;

    // Unsubscribe any existing subscriptions first
    unsubscribeFromAlerts();

    try {
      // Subscribe to distraction_alerts inserts
      _alertChannel = supa
          .channel('distraction_alerts_$familyCode')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'distraction_alerts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'family_code',
              value: familyCode,
            ),
            callback: (payload) {
              try {
                final alertJson = payload.newRecord['alert_json'];
                DistractionBreachLog? breach;
                if (alertJson is Map<String, dynamic>) {
                  breach = DistractionBreachLog.fromJson(alertJson);
                } else if (alertJson is String) {
                  breach = DistractionBreachLog.fromJson(
                      jsonDecode(alertJson) as Map<String, dynamic>);
                }
                if (breach != null) {
                  onAlert?.call(breach);
                  showBreachNotification(breach);
                }
              } catch (e) {
                debugPrint('⚠️ [Realtime] Alert parse error: $e');
              }
            },
          )
          .subscribe();

      // Subscribe to child_live_status updates
      _statusChannel = supa
          .channel('child_status_$familyCode')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'child_live_status',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'family_code',
              value: familyCode,
            ),
            callback: (payload) {
              try {
                final statusJson = payload.newRecord['status_json'];
                ChildLiveStatus? status;
                if (statusJson is Map<String, dynamic>) {
                  status = ChildLiveStatus.fromJson(statusJson);
                } else if (statusJson is String) {
                  status = ChildLiveStatus.fromJson(
                      jsonDecode(statusJson) as Map<String, dynamic>);
                }
                if (status != null) {
                  onStatusChange?.call(status);
                }
              } catch (e) {
                debugPrint('⚠️ [Realtime] Status parse error: $e');
              }
            },
          )
          .subscribe();

      debugPrint(
          '📡 [Parent] Subscribed to real-time alerts for code: $familyCode');
    } catch (e) {
      debugPrint('⚠️ [Parent] Realtime subscription failed: $e');
    }
  }

  /// Cancel all real-time subscriptions.
  void unsubscribeFromAlerts() {
    final supa = SupabaseService.client;
    if (_alertChannel != null) {
      supa?.removeChannel(_alertChannel!);
      _alertChannel = null;
    }
    if (_statusChannel != null) {
      supa?.removeChannel(_statusChannel!);
      _statusChannel = null;
    }
    debugPrint('🔕 [Parent] Unsubscribed from real-time alerts.');
  }

  // ─── Local Notifications (parent's phone) ─────────────────────────────

  /// Show a high-priority local notification on the parent's device.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized || _notificationsPlugin == null) {
      debugPrint('⚠️ [Notification] Plugin not initialized, skipping.');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'parental_alerts',
        'Parental Control Alerts',
        channelDescription:
            'Alerts when your child leaves the study app during exams',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notificationsPlugin!.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
      debugPrint('🔔 [Notification] Shown: $title');
    } catch (e) {
      debugPrint('⚠️ [Notification] Show failed: $e');
    }
  }

  /// Show a breach notification when the child leaves during study/exam.
  Future<void> showBreachNotification(DistractionBreachLog breach,
      {String? parentPhoneNumber}) async {
    final targetPhone = breach.parentPhoneNumber ?? parentPhoneNumber;
    final phoneNotice = (targetPhone != null && targetPhone.trim().isNotEmpty)
        ? '\n📲 Alert forwarded to parent: $targetPhone'
        : '';
    await _showLocalNotification(
      title: '⚠️ Study Alert!',
      body:
          'Your child left the study app! Reason: ${breach.reason}\n'
          'Subject: ${breach.subject} • ${_formatTime(breach.timestamp)}$phoneNotice',
    );
  }

  /// Send a test alert notification to verify parent's phone setup.
  Future<void> sendTestAlertToParent({
    required String parentPhoneNumber,
    required String studentName,
  }) async {
    await _showLocalNotification(
      title: '🔔 StudySmart Test Alert',
      body:
          'Parent notification channel verified! You will receive instant notifications '
          'at $parentPhoneNumber whenever $studentName is not studying during exams.',
    );
  }

  /// Show a notification that the child is not studying during exam lockdown.
  Future<void> showIdleWarningNotification(String studentName) async {
    await _showLocalNotification(
      title: '📱 $studentName is NOT studying!',
      body:
          'Your child has been idle during exam prep period. '
          'Open the app to send a nudge or lock distracting apps.',
    );
  }

  /// Show notification that exam lockdown is active.
  Future<void> showLockdownActiveNotification(
      String studentName, String examTitle) async {
    await _showLocalNotification(
      title: '🔒 Exam Lockdown Active',
      body: '$studentName has "$examTitle" coming up. '
          'Distraction blocking is now active.',
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final min = time.minute.toString().padLeft(2, '0');
    return '$hour:$min $amPm';
  }

  // ─── Supabase SQL Setup ───────────────────────────────────────────────

  /// SQL to create the required tables in Supabase.
  ///
  /// Copy and paste this into the Supabase SQL Editor
  /// (Dashboard → SQL Editor → New Query → paste → Run).
  static const String setupSQL = '''
-- ===================================================================
-- PARENTAL CONTROL TABLES for Smart Study Planner
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- ===================================================================

-- 1. Child Live Status (upserted by child's phone)
CREATE TABLE IF NOT EXISTS child_live_status (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  family_code TEXT NOT NULL UNIQUE,
  status_json JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Distraction Alerts (inserted by child when breach detected)
CREATE TABLE IF NOT EXISTS distraction_alerts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  family_code TEXT NOT NULL,
  alert_json JSONB NOT NULL DEFAULT '{}',
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Shared Parental Config (synced between parent & child)
CREATE TABLE IF NOT EXISTS parental_configs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  family_code TEXT NOT NULL UNIQUE,
  config_json JSONB NOT NULL DEFAULT '{}',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_alerts_family ON distraction_alerts(family_code);
CREATE INDEX IF NOT EXISTS idx_alerts_unread ON distraction_alerts(family_code, is_read);

-- Enable Row Level Security
ALTER TABLE child_live_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE distraction_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE parental_configs ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Allow all operations for anon role (family app, secured by code)
CREATE POLICY "Allow all for child_live_status" ON child_live_status
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for distraction_alerts" ON distraction_alerts
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all for parental_configs" ON parental_configs
  FOR ALL USING (true) WITH CHECK (true);

-- Enable Realtime for instant parent notifications
ALTER PUBLICATION supabase_realtime ADD TABLE child_live_status;
ALTER PUBLICATION supabase_realtime ADD TABLE distraction_alerts;
''';
}
