import 'package:flutter_test/flutter_test.dart';
import 'package:smart_study_planner/domain/models/focus_shield.dart';
import 'package:smart_study_planner/domain/services/social_media_blocker_service.dart';
import 'package:smart_study_planner/data/repositories/study_repository.dart';
import 'package:smart_study_planner/data/services/storage_service.dart';
import 'package:smart_study_planner/ui/features/home/study_planner_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusShield & SocialMediaBlockerService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('BlockedApp defaults contain core social media and serializes cleanly', () {
      final apps = BlockedApp.defaultApps;
      expect(apps.isNotEmpty, isTrue);
      expect(apps.any((a) => a.id == 'instagram'), isTrue);
      expect(apps.any((a) => a.id == 'youtube'), isTrue);
      expect(apps.any((a) => a.id == 'tiktok'), isTrue);
      expect(apps.any((a) => a.id == 'x_twitter'), isTrue);
      expect(apps.any((a) => a.id == 'reddit'), isTrue);
      expect(apps.any((a) => a.id == 'discord'), isTrue);

      final insta = apps.firstWhere((a) => a.id == 'instagram');
      final json = insta.toJson();
      final reconstructed = BlockedApp.fromJson(json);

      expect(reconstructed.id, insta.id);
      expect(reconstructed.name, insta.name);
      expect(reconstructed.domains, insta.domains);
      expect(reconstructed.iconEmoji, insta.iconEmoji);
      expect(reconstructed.isEnabled, isTrue);
    });

    test('FocusShieldConfig serializes and deserializes correctly', () {
      final config = FocusShieldConfig(
        isShieldEnabled: true,
        strictMode: true,
        blockDesktopProcesses: true,
        blockedApps: BlockedApp.defaultApps,
        customUrls: const ['roblox.com', 'chess.com'],
        blockedAttemptsCount: 5,
      );

      final json = config.toJson();
      expect(json['isShieldEnabled'], isTrue);
      expect(json['strictMode'], isTrue);
      expect(json['blockedAttemptsCount'], 5);
      expect(json['customUrls'], contains('roblox.com'));

      final reconstructed = FocusShieldConfig.fromJson(json);
      expect(reconstructed.isShieldEnabled, isTrue);
      expect(reconstructed.strictMode, isTrue);
      expect(reconstructed.blockedAttemptsCount, 5);
      expect(reconstructed.customUrls, contains('roblox.com'));
      expect(reconstructed.blockedApps.length, BlockedApp.defaultApps.length);
    });

    test('SocialMediaBlockerService correctly detects social media URLs', () {
      final blocker = SocialMediaBlockerService();
      final config = FocusShieldConfig.defaultConfig();

      // Social media sites that MUST be blocked
      expect(blocker.isBlockedUrl('https://www.instagram.com/explore', config), isTrue);
      expect(blocker.isBlockedUrl('https://instagram.com/direct', config), isTrue);
      expect(blocker.isBlockedUrl('https://tiktok.com/@creator', config), isTrue);
      expect(blocker.isBlockedUrl('https://vm.tiktok.com/ZM123', config), isTrue);
      expect(blocker.isBlockedUrl('https://x.com/flutterdev', config), isTrue);
      expect(blocker.isBlockedUrl('https://twitter.com/home', config), isTrue);
      expect(blocker.isBlockedUrl('https://youtube.com/shorts/12345', config), isTrue);
      expect(blocker.isBlockedUrl('https://youtu.be/abcde', config), isTrue);
      expect(blocker.isBlockedUrl('https://reddit.com/r/flutter', config), isTrue);
      expect(blocker.isBlockedUrl('https://facebook.com/watch', config), isTrue);
      expect(blocker.isBlockedUrl('https://discord.gg/servers', config), isTrue);
      expect(blocker.isBlockedUrl('https://netflix.com/browse', config), isTrue);

      // Educational / Safe sites that MUST NOT be blocked
      expect(blocker.isBlockedUrl('https://flutter.dev', config), isFalse);
      expect(blocker.isBlockedUrl('https://dart.dev', config), isFalse);
      expect(blocker.isBlockedUrl('https://en.wikipedia.org/wiki/Calculus', config), isFalse);
      expect(blocker.isBlockedUrl('https://khanacademy.org/math', config), isFalse);
      expect(blocker.isBlockedUrl('https://github.com/flutter/flutter', config), isFalse);
    });

    test('Custom blocked domains and disabled apps behave properly in blocker', () {
      final blocker = SocialMediaBlockerService();

      // Custom domain added
      final customConfig = FocusShieldConfig.defaultConfig().copyWith(
        customUrls: ['roblox.com', 'steamcommunity.com'],
      );
      expect(blocker.isBlockedUrl('https://www.roblox.com/games', customConfig), isTrue);
      expect(blocker.isBlockedUrl('https://steamcommunity.com/market', customConfig), isTrue);

      // Disable YouTube in blocked apps
      final modifiedApps = BlockedApp.defaultApps.map((a) {
        if (a.id == 'youtube') return a.copyWith(isEnabled: false);
        return a;
      }).toList();
      final relaxedConfig = FocusShieldConfig.defaultConfig().copyWith(blockedApps: modifiedApps);

      expect(blocker.isBlockedUrl('https://youtube.com/watch?v=physics', relaxedConfig), isFalse);
      expect(blocker.isBlockedUrl('https://instagram.com/reels', relaxedConfig), isTrue);

      // Master switch disabled
      final disabledConfig = FocusShieldConfig.defaultConfig().copyWith(isShieldEnabled: false);
      expect(blocker.isBlockedUrl('https://instagram.com', disabledConfig), isFalse);
      expect(blocker.isBlockedUrl('https://tiktok.com', disabledConfig), isFalse);
    });

    test('PomodoroViewModel activates and deactivates shield along timer lifecycle', () async {
      final storage = StorageService();
      final repo = StudyRepository(storageService: storage);
      final vm = PomodoroViewModel(repository: repo);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Initial state: timer stopped
      expect(vm.isShieldActive, isFalse);
      expect(vm.shieldConfig.isShieldEnabled, isTrue);

      // Start focus timer
      vm.start();
      expect(vm.isRunning, isTrue);
      expect(vm.phase, PomodoroPhase.work);
      expect(vm.isShieldActive, isTrue);

      // Pause focus timer
      vm.pause();
      expect(vm.isRunning, isFalse);
      expect(vm.isShieldActive, isFalse);

      // Resume focus timer
      vm.start();
      expect(vm.isShieldActive, isTrue);

      // Switch to break phase
      vm.skipPhase();
      expect(vm.phase, PomodoroPhase.shortBreak);
      // Shield should be paused on break even if running
      vm.start();
      expect(vm.isShieldActive, isFalse);

      // Toggle custom domain
      await vm.addCustomBlockedDomain('distraction.tv');
      expect(vm.shieldConfig.customUrls, contains('distraction.tv'));

      await vm.removeCustomBlockedDomain('distraction.tv');
      expect(vm.shieldConfig.customUrls.contains('distraction.tv'), isFalse);

      // Record blocked attempt
      final initialAttempts = vm.shieldConfig.blockedAttemptsCount;
      await vm.recordBlockedAttempt();
      expect(vm.shieldConfig.blockedAttemptsCount, initialAttempts + 1);

      vm.dispose();
    });
  });
}
