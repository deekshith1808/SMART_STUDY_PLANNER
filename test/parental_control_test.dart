import 'package:flutter_test/flutter_test.dart';
import 'package:smart_study_planner/domain/models/parental_control.dart';
import 'package:smart_study_planner/domain/models/user_profile.dart';

void main() {
  group('Parental Control Domain Models Test', () {
    test('ParentalControlConfig initializes with sensible defaults and serializes cleanly', () {
      const config = ParentalControlConfig();

      expect(config.isEnabled, false);
      expect(config.parentPin, '1234');
      expect(config.autoLockOnExamDays, true);
      expect(config.lockDaysBeforeExam, 1);
      expect(config.blockedApps.contains('Instagram'), true);
      expect(config.blockedApps.contains('YouTube / Shorts'), true);

      final json = config.toJson();
      final restored = ParentalControlConfig.fromJson(json);

      expect(restored.isEnabled, config.isEnabled);
      expect(restored.parentPin, config.parentPin);
      expect(restored.autoLockOnExamDays, config.autoLockOnExamDays);
      expect(restored.lockDaysBeforeExam, config.lockDaysBeforeExam);
      expect(restored.blockedApps.length, config.blockedApps.length);
    });

    test('DistractionBreachLog serializes and deserializes accurately', () {
      final now = DateTime.now();
      final log = DistractionBreachLog(
        id: '123456',
        timestamp: now,
        reason: 'Child left study app during exam lockdown',
        subject: 'Mathematics',
      );

      final json = log.toJson();
      final restored = DistractionBreachLog.fromJson(json);

      expect(restored.id, '123456');
      expect(restored.reason, log.reason);
      expect(restored.subject, 'Mathematics');
      expect(restored.timestamp.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('ChildLiveStatus correctly calculates progress and tracks breaches', () {
      final now = DateTime.now();
      final status = ChildLiveStatus(
        studentName: 'Alex',
        isStudyingNow: true,
        currentSubject: 'Physics',
        currentPhase: 'Focusing',
        sessionSecondsRemaining: 1200,
        todayStudyMinutes: 90,
        todayTargetMinutes: 180,
        lastActiveTime: now,
        isLockdownActive: true,
        activeExamReason: 'Physics Midterm is TOMORROW! ⏳',
        breachCount: 1,
        breachLogs: [
          DistractionBreachLog(
            id: '1',
            timestamp: now,
            reason: 'Switched to YouTube',
            subject: 'Physics',
          ),
        ],
      );

      expect(status.todayProgress, 0.5);
      expect(status.isStudyingNow, true);
      expect(status.isLockdownActive, true);
      expect(status.breachCount, 1);

      final json = status.toJson();
      final restored = ChildLiveStatus.fromJson(json);

      expect(restored.studentName, 'Alex');
      expect(restored.todayStudyMinutes, 90);
      expect(restored.breachLogs.length, 1);
      expect(restored.breachLogs.first.reason, 'Switched to YouTube');
    });

    test('Parent phone number is preserved in config and breach logs generate valid SMS & WhatsApp links', () {
      const config = ParentalControlConfig(parentContact: '+1234567890');
      expect(config.parentPhoneNumber, '+1234567890');

      final configJson = config.toJson();
      final restoredConfig = ParentalControlConfig.fromJson(configJson);
      expect(restoredConfig.parentPhoneNumber, '+1234567890');

      final breach = DistractionBreachLog(
        id: '2',
        timestamp: DateTime.now(),
        reason: 'Child opened TikTok',
        subject: 'Chemistry',
        parentPhoneNumber: '+1234567890',
      );

      expect(breach.parentPhoneNumber, '+1234567890');
      expect(breach.smsUri, isNotNull);
      expect(breach.smsUri!.startsWith('sms:+1234567890?body='), true);
      expect(breach.whatsappUri, isNotNull);
      expect(breach.whatsappUri!.startsWith('https://wa.me/1234567890?text='), true);

      final breachJson = breach.toJson();
      final restoredBreach = DistractionBreachLog.fromJson(breachJson);
      expect(restoredBreach.parentPhoneNumber, '+1234567890');
    });

    test('UserProfile & ParentalControlConfig correctly preserve and link father email and phone', () {
      const profile = UserProfile(
        name: 'John Doe',
        educationType: 'school',
        subjects: [],
        fatherPhone: '+919876543210',
        fatherEmail: 'father.doe@gmail.com',
        fatherName: 'Robert Doe',
      );

      expect(profile.fatherPhone, '+919876543210');
      expect(profile.fatherEmail, 'father.doe@gmail.com');
      expect(profile.fatherName, 'Robert Doe');

      final profileJson = profile.toJson();
      final restoredProfile = UserProfile.fromJson(profileJson);
      expect(restoredProfile.fatherPhone, '+919876543210');
      expect(restoredProfile.fatherEmail, 'father.doe@gmail.com');
      expect(restoredProfile.fatherName, 'Robert Doe');

      const config = ParentalControlConfig(
        parentContact: '+919876543210',
        parentEmail: 'father.doe@gmail.com',
      );

      expect(config.fatherPhone, '+919876543210');
      expect(config.fatherEmail, 'father.doe@gmail.com');

      final configJson = config.toJson();
      final restoredConfig = ParentalControlConfig.fromJson(configJson);
      expect(restoredConfig.fatherPhone, '+919876543210');
      expect(restoredConfig.fatherEmail, 'father.doe@gmail.com');
    });
  });
}
