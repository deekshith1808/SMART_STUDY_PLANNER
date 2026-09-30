import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/focus_shield.dart';
import '../../ui/features/home/study_planner_view_model.dart';
import '../../ui/features/pomodoro/social_media_blocked_dialog.dart';

class SocialMediaBlockerService {
  static final SocialMediaBlockerService _instance = SocialMediaBlockerService._internal();
  factory SocialMediaBlockerService() => _instance;
  SocialMediaBlockerService._internal();

  /// Checks if a given URL string points to a blocked social media site or custom domain.
  bool isBlockedUrl(String urlString, FocusShieldConfig config) {
    if (!config.isShieldEnabled) return false;
    final normalized = _normalizeUrl(urlString);
    if (normalized.isEmpty) return false;

    // Check built-in apps that are enabled
    for (final app in config.blockedApps) {
      if (!app.isEnabled) continue;
      for (final domain in app.domains) {
        final normDomain = domain.trim().toLowerCase();
        if (normDomain.isEmpty) continue;
        if (normalized == normDomain ||
            normalized.endsWith('.$normDomain') ||
            normalized.contains('/$normDomain/') ||
            normalized.contains(normDomain)) {
          return true;
        }
      }
    }

    // Check custom domains
    for (final custom in config.customUrls) {
      final normCustom = custom.trim().toLowerCase();
      if (normCustom.isEmpty) continue;
      if (normalized.contains(normCustom)) {
        return true;
      }
    }

    return false;
  }

  /// Finds the matching BlockedApp for a given URL, if any.
  BlockedApp? findBlockedAppForUrl(String urlString, FocusShieldConfig config) {
    final normalized = _normalizeUrl(urlString);
    if (normalized.isEmpty) return null;

    for (final app in config.blockedApps) {
      if (!app.isEnabled) continue;
      for (final domain in app.domains) {
        final normDomain = domain.trim().toLowerCase();
        if (normDomain.isEmpty) continue;
        if (normalized == normDomain ||
            normalized.endsWith('.$normDomain') ||
            normalized.contains(normDomain)) {
          return app;
        }
      }
    }

    // Custom match
    for (final custom in config.customUrls) {
      final normCustom = custom.trim().toLowerCase();
      if (normCustom.isNotEmpty && normalized.contains(normCustom)) {
        return BlockedApp(
          id: 'custom',
          name: custom,
          domains: [custom],
          processNames: const [],
          iconEmoji: '🛡️',
          category: 'Custom Rule',
          isEnabled: true,
        );
      }
    }

    return null;
  }

  /// Safely attempts to launch a URL.
  /// If the focus timer is actively running and the URL is a blocked social media platform,
  /// it intercepts the launch, logs the shielded attempt, and opens the warning modal.
  Future<bool> tryLaunchUrlGuarded({
    required BuildContext context,
    required String url,
    required PomodoroViewModel pomodoroVm,
  }) async {
    final isFocusActive = pomodoroVm.isRunning && pomodoroVm.phase == PomodoroPhase.work;
    final isBlocked = isBlockedUrl(url, pomodoroVm.shieldConfig);

    if (isFocusActive && isBlocked) {
      pomodoroVm.recordBlockedAttempt();
      final blockedApp = findBlockedAppForUrl(url, pomodoroVm.shieldConfig);

      if (context.mounted) {
        await showDialog<bool>(
          context: context,
          barrierDismissible: !pomodoroVm.shieldConfig.strictMode,
          builder: (_) => SocialMediaBlockedDialog(
            url: url,
            blockedApp: blockedApp,
            pomodoroVm: pomodoroVm,
          ),
        );
      }
      return false;
    }

    // If not blocked or focus timer is not active, launch URL normally
    try {
      if (await canLaunchUrlString(url)) {
        return await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[SocialMediaBlocker] Failed to launch $url: $e');
    }
    return false;
  }

  /// On Windows/Desktop, detects running background processes of blocked social apps.
  Future<List<String>> detectRunningBlockedProcesses(FocusShieldConfig config) async {
    if (!kIsWeb && Platform.isWindows && config.isShieldEnabled && config.blockDesktopProcesses) {
      try {
        final result = await Process.run('tasklist', ['/fo', 'csv', '/nh']);
        if (result.exitCode == 0) {
          final output = result.stdout.toString().toLowerCase();
          final detected = <String>[];

          for (final app in config.blockedApps) {
            if (!app.isEnabled) continue;
            for (final proc in app.processNames) {
              final normProc = proc.trim().toLowerCase();
              if (normProc.isNotEmpty && output.contains('"$normProc"')) {
                detected.add(app.name);
                break;
              }
            }
          }
          return detected;
        }
      } catch (e) {
        debugPrint('[SocialMediaBlocker] Process check failed: $e');
      }
    }
    return [];
  }

  /// Closes a running blocked process on Windows desktop.
  Future<bool> killBlockedProcess(String processName) async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final result = await Process.run('taskkill', ['/F', '/IM', processName]);
        return result.exitCode == 0;
      } catch (e) {
        debugPrint('[SocialMediaBlocker] Kill process error: $e');
      }
    }
    return false;
  }

  String _normalizeUrl(String raw) {
    try {
      var s = raw.trim().toLowerCase();
      if (!s.startsWith('http://') && !s.startsWith('https://')) {
        s = 'https://$s';
      }
      final uri = Uri.tryParse(s);
      return uri?.host.isNotEmpty == true ? uri!.host : raw.trim().toLowerCase();
    } catch (_) {
      return raw.trim().toLowerCase();
    }
  }
}
