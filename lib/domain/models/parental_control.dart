class ParentalControlConfig {
  final bool isEnabled;
  final String parentPin;
  final String familyPairingCode;
  final bool autoLockOnExamDays;
  final int lockDaysBeforeExam; // 1 = tomorrow, 2 = within 2 days, 3 = within 3 days
  final bool isEmergencyLockActive;
  final List<String> blockedApps;
  final bool strictFocusEnforcement;
  final int dailyStudyTargetMinutes;
  final String? parentContact;
  final String? parentEmail;
  final String? lastParentNudge;
  final DateTime? lastParentNudgeTime;

  const ParentalControlConfig({
    this.isEnabled = false,
    this.parentPin = '1234',
    this.familyPairingCode = 'STUDY-8421',
    this.autoLockOnExamDays = true,
    this.lockDaysBeforeExam = 1,
    this.isEmergencyLockActive = false,
    this.blockedApps = const [
      'Instagram',
      'YouTube / Shorts',
      'TikTok / Reels',
      'Snapchat',
      'Mobile Games (FreeFire / PUBG)',
      'Netflix / OTT Apps',
      'Twitter / X',
      'Discord',
    ],
    this.strictFocusEnforcement = true,
    this.dailyStudyTargetMinutes = 180,
    this.parentContact,
    this.parentEmail,
    this.lastParentNudge,
    this.lastParentNudgeTime,
  });

  String? get parentPhoneNumber => parentContact;
  String? get fatherPhone => parentContact;
  String? get fatherEmail => parentEmail;

  ParentalControlConfig copyWith({
    bool? isEnabled,
    String? parentPin,
    String? familyPairingCode,
    bool? autoLockOnExamDays,
    int? lockDaysBeforeExam,
    bool? isEmergencyLockActive,
    List<String>? blockedApps,
    bool? strictFocusEnforcement,
    int? dailyStudyTargetMinutes,
    String? parentContact,
    String? parentPhoneNumber,
    String? parentEmail,
    String? fatherPhone,
    String? fatherEmail,
    String? lastParentNudge,
    DateTime? lastParentNudgeTime,
  }) {
    return ParentalControlConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      parentPin: parentPin ?? this.parentPin,
      familyPairingCode: familyPairingCode ?? this.familyPairingCode,
      autoLockOnExamDays: autoLockOnExamDays ?? this.autoLockOnExamDays,
      lockDaysBeforeExam: lockDaysBeforeExam ?? this.lockDaysBeforeExam,
      isEmergencyLockActive: isEmergencyLockActive ?? this.isEmergencyLockActive,
      blockedApps: blockedApps ?? this.blockedApps,
      strictFocusEnforcement: strictFocusEnforcement ?? this.strictFocusEnforcement,
      dailyStudyTargetMinutes: dailyStudyTargetMinutes ?? this.dailyStudyTargetMinutes,
      parentContact: fatherPhone ?? parentPhoneNumber ?? parentContact ?? this.parentContact,
      parentEmail: fatherEmail ?? parentEmail ?? this.parentEmail,
      lastParentNudge: lastParentNudge ?? this.lastParentNudge,
      lastParentNudgeTime: lastParentNudgeTime ?? this.lastParentNudgeTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'isEnabled': isEnabled,
        'parentPin': parentPin,
        'familyPairingCode': familyPairingCode,
        'autoLockOnExamDays': autoLockOnExamDays,
        'lockDaysBeforeExam': lockDaysBeforeExam,
        'isEmergencyLockActive': isEmergencyLockActive,
        'blockedApps': blockedApps,
        'strictFocusEnforcement': strictFocusEnforcement,
        'dailyStudyTargetMinutes': dailyStudyTargetMinutes,
        'parentContact': parentContact,
        'parentEmail': parentEmail,
        'lastParentNudge': lastParentNudge,
        'lastParentNudgeTime': lastParentNudgeTime?.toIso8601String(),
      };

  factory ParentalControlConfig.fromJson(Map<String, dynamic> json) {
    return ParentalControlConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      parentPin: json['parentPin'] as String? ?? '1234',
      familyPairingCode: json['familyPairingCode'] as String? ?? 'STUDY-8421',
      autoLockOnExamDays: json['autoLockOnExamDays'] as bool? ?? true,
      lockDaysBeforeExam: json['lockDaysBeforeExam'] as int? ?? 1,
      isEmergencyLockActive: json['isEmergencyLockActive'] as bool? ?? false,
      blockedApps: (json['blockedApps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Instagram',
            'YouTube / Shorts',
            'TikTok / Reels',
            'Snapchat',
            'Mobile Games (FreeFire / PUBG)',
            'Netflix / OTT Apps',
            'Twitter / X',
            'Discord',
          ],
      strictFocusEnforcement: json['strictFocusEnforcement'] as bool? ?? true,
      dailyStudyTargetMinutes: json['dailyStudyTargetMinutes'] as int? ?? 180,
      parentContact: (json['parentPhoneNumber'] ?? json['fatherPhone'] ?? json['parentPhone'] ?? json['parentContact']) as String?,
      parentEmail: (json['parentEmail'] ?? json['fatherEmail']) as String?,
      lastParentNudge: json['lastParentNudge'] as String?,
      lastParentNudgeTime: json['lastParentNudgeTime'] != null
          ? DateTime.tryParse(json['lastParentNudgeTime'] as String)
          : null,
    );
  }
}

class DistractionBreachLog {
  final String id;
  final DateTime timestamp;
  final String reason;
  final String subject;
  final String? parentPhoneNumber;

  const DistractionBreachLog({
    required this.id,
    required this.timestamp,
    required this.reason,
    required this.subject,
    this.parentPhoneNumber,
  });

  /// URL to trigger native SMS to parent with breach notification details
  String? get smsUri {
    if (parentPhoneNumber == null || parentPhoneNumber!.trim().isEmpty) return null;
    final cleanPhone = parentPhoneNumber!.replaceAll(RegExp(r'[^0-9+]'), '');
    final msg = Uri.encodeComponent(
      '⚠️ [StudySmart Alert] Your child left the study app during focus/exam period!\nReason: $reason\nSubject: $subject',
    );
    return 'sms:$cleanPhone?body=$msg';
  }

  /// URL to open WhatsApp with prefilled message to parent
  String? get whatsappUri {
    if (parentPhoneNumber == null || parentPhoneNumber!.trim().isEmpty) return null;
    final cleanPhone = parentPhoneNumber!.replaceAll(RegExp(r'[^0-9]'), '');
    final msg = Uri.encodeComponent(
      '⚠️ *[StudySmart Guardian Alert]*\nYour child left the study app!\n*Reason:* $reason\n*Subject:* $subject',
    );
    return 'https://wa.me/$cleanPhone?text=$msg';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'reason': reason,
        'subject': subject,
        if (parentPhoneNumber != null) 'parentPhoneNumber': parentPhoneNumber,
      };

  factory DistractionBreachLog.fromJson(Map<String, dynamic> json) =>
      DistractionBreachLog(
        id: json['id'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String)
            : DateTime.now(),
        reason: json['reason'] as String? ?? 'Left app during focus session',
        subject: json['subject'] as String? ?? 'General Study',
        parentPhoneNumber: (json['parentPhoneNumber'] ?? json['parent_phone']) as String?,
      );
}

class ChildLiveStatus {
  final String studentName;
  final bool isStudyingNow;
  final String? currentSubject;
  final String currentPhase; // 'Focusing', 'Short Break', 'Long Break', 'Idle'
  final int sessionSecondsRemaining;
  final int todayStudyMinutes;
  final int todayTargetMinutes;
  final DateTime lastActiveTime;
  final bool isLockdownActive;
  final String? activeExamReason;
  final int breachCount;
  final List<DistractionBreachLog> breachLogs;
  final String? activeNudge;

  const ChildLiveStatus({
    required this.studentName,
    required this.isStudyingNow,
    this.currentSubject,
    required this.currentPhase,
    required this.sessionSecondsRemaining,
    required this.todayStudyMinutes,
    required this.todayTargetMinutes,
    required this.lastActiveTime,
    required this.isLockdownActive,
    this.activeExamReason,
    this.breachCount = 0,
    this.breachLogs = const [],
    this.activeNudge,
  });

  double get todayProgress => (todayStudyMinutes / (todayTargetMinutes == 0 ? 1 : todayTargetMinutes)).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'studentName': studentName,
        'isStudyingNow': isStudyingNow,
        'currentSubject': currentSubject,
        'currentPhase': currentPhase,
        'sessionSecondsRemaining': sessionSecondsRemaining,
        'todayStudyMinutes': todayStudyMinutes,
        'todayTargetMinutes': todayTargetMinutes,
        'lastActiveTime': lastActiveTime.toIso8601String(),
        'isLockdownActive': isLockdownActive,
        'activeExamReason': activeExamReason,
        'breachCount': breachCount,
        'breachLogs': breachLogs.map((b) => b.toJson()).toList(),
        'activeNudge': activeNudge,
      };

  factory ChildLiveStatus.fromJson(Map<String, dynamic> json) => ChildLiveStatus(
        studentName: json['studentName'] as String? ?? 'Student',
        isStudyingNow: json['isStudyingNow'] as bool? ?? false,
        currentSubject: json['currentSubject'] as String?,
        currentPhase: json['currentPhase'] as String? ?? 'Idle',
        sessionSecondsRemaining: json['sessionSecondsRemaining'] as int? ?? 0,
        todayStudyMinutes: json['todayStudyMinutes'] as int? ?? 0,
        todayTargetMinutes: json['todayTargetMinutes'] as int? ?? 180,
        lastActiveTime: json['lastActiveTime'] != null
            ? DateTime.parse(json['lastActiveTime'] as String)
            : DateTime.now(),
        isLockdownActive: json['isLockdownActive'] as bool? ?? false,
        activeExamReason: json['activeExamReason'] as String?,
        breachCount: json['breachCount'] as int? ?? 0,
        breachLogs: (json['breachLogs'] as List<dynamic>?)
                ?.map((e) => DistractionBreachLog.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        activeNudge: json['activeNudge'] as String?,
      );
}
