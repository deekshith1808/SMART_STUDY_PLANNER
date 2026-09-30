class BlockedApp {
  final String id;
  final String name;
  final List<String> domains;
  final List<String> processNames;
  final String iconEmoji;
  final String category;
  final bool isEnabled;

  const BlockedApp({
    required this.id,
    required this.name,
    required this.domains,
    required this.processNames,
    required this.iconEmoji,
    this.category = 'Social Media',
    this.isEnabled = true,
  });

  BlockedApp copyWith({
    String? id,
    String? name,
    List<String>? domains,
    List<String>? processNames,
    String? iconEmoji,
    String? category,
    bool? isEnabled,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      name: name ?? this.name,
      domains: domains ?? this.domains,
      processNames: processNames ?? this.processNames,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      category: category ?? this.category,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'domains': domains,
        'processNames': processNames,
        'iconEmoji': iconEmoji,
        'category': category,
        'isEnabled': isEnabled,
      };

  factory BlockedApp.fromJson(Map<String, dynamic> json) => BlockedApp(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'App',
        domains: (json['domains'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        processNames: (json['processNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        iconEmoji: json['iconEmoji'] as String? ?? '📱',
        category: json['category'] as String? ?? 'Social Media',
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  static List<BlockedApp> get defaultApps => [
        const BlockedApp(
          id: 'instagram',
          name: 'Instagram',
          domains: ['instagram.com', 'instagr.am', 'threads.net'],
          processNames: ['Instagram.exe', 'Instagram'],
          iconEmoji: '📸',
          category: 'Social Media',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'youtube',
          name: 'YouTube & Shorts',
          domains: ['youtube.com', 'youtu.be', 'm.youtube.com'],
          processNames: ['YouTube.exe'],
          iconEmoji: '▶️',
          category: 'Video & Entertainment',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'tiktok',
          name: 'TikTok',
          domains: ['tiktok.com', 'vm.tiktok.com'],
          processNames: ['TikTok.exe', 'TikTok'],
          iconEmoji: '🎵',
          category: 'Short Videos',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'x_twitter',
          name: 'X (Twitter)',
          domains: ['x.com', 'twitter.com', 't.co'],
          processNames: ['Twitter.exe', 'X.exe'],
          iconEmoji: '🐦',
          category: 'Social Media',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'facebook',
          name: 'Facebook',
          domains: ['facebook.com', 'fb.com', 'fb.watch', 'm.facebook.com'],
          processNames: ['Facebook.exe'],
          iconEmoji: '👤',
          category: 'Social Media',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'reddit',
          name: 'Reddit',
          domains: ['reddit.com', 'redd.it', 'old.reddit.com'],
          processNames: ['Reddit.exe'],
          iconEmoji: '🤖',
          category: 'Forums & Social',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'snapchat',
          name: 'Snapchat',
          domains: ['snapchat.com', 'web.snapchat.com'],
          processNames: ['Snapchat.exe'],
          iconEmoji: '👻',
          category: 'Social Media',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'discord',
          name: 'Discord',
          domains: ['discord.com', 'discord.gg', 'discordapp.com'],
          processNames: ['Discord.exe', 'discord.exe', 'Discord'],
          iconEmoji: '💬',
          category: 'Chat & Gaming',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'telegram',
          name: 'Telegram',
          domains: ['telegram.org', 'web.telegram.org', 't.me'],
          processNames: ['Telegram.exe', 'telegram.exe'],
          iconEmoji: '✈️',
          category: 'Messaging',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'netflix',
          name: 'Netflix',
          domains: ['netflix.com'],
          processNames: ['Netflix.exe'],
          iconEmoji: '🎬',
          category: 'Streaming',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'twitch',
          name: 'Twitch',
          domains: ['twitch.tv'],
          processNames: ['Twitch.exe'],
          iconEmoji: '🎮',
          category: 'Live Streaming',
          isEnabled: true,
        ),
        const BlockedApp(
          id: 'pinterest',
          name: 'Pinterest',
          domains: ['pinterest.com', 'pin.it'],
          processNames: ['Pinterest.exe'],
          iconEmoji: '📌',
          category: 'Social Media',
          isEnabled: true,
        ),
      ];
}

class FocusShieldConfig {
  final bool isShieldEnabled;
  final bool strictMode; // Requires 10s mindful breath to bypass
  final bool blockDesktopProcesses; // Monitors background Windows processes
  final List<BlockedApp> blockedApps;
  final List<String> customUrls;
  final int blockedAttemptsCount;

  const FocusShieldConfig({
    this.isShieldEnabled = true,
    this.strictMode = true,
    this.blockDesktopProcesses = true,
    this.blockedApps = const [],
    this.customUrls = const [],
    this.blockedAttemptsCount = 0,
  });

  FocusShieldConfig copyWith({
    bool? isShieldEnabled,
    bool? strictMode,
    bool? blockDesktopProcesses,
    List<BlockedApp>? blockedApps,
    List<String>? customUrls,
    int? blockedAttemptsCount,
  }) {
    return FocusShieldConfig(
      isShieldEnabled: isShieldEnabled ?? this.isShieldEnabled,
      strictMode: strictMode ?? this.strictMode,
      blockDesktopProcesses: blockDesktopProcesses ?? this.blockDesktopProcesses,
      blockedApps: blockedApps ?? this.blockedApps,
      customUrls: customUrls ?? this.customUrls,
      blockedAttemptsCount: blockedAttemptsCount ?? this.blockedAttemptsCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'isShieldEnabled': isShieldEnabled,
        'strictMode': strictMode,
        'blockDesktopProcesses': blockDesktopProcesses,
        'blockedApps': blockedApps.map((a) => a.toJson()).toList(),
        'customUrls': customUrls,
        'blockedAttemptsCount': blockedAttemptsCount,
      };

  factory FocusShieldConfig.fromJson(Map<String, dynamic> json) {
    List<BlockedApp> apps = [];
    if (json['blockedApps'] != null) {
      apps = (json['blockedApps'] as List<dynamic>)
          .map((e) => BlockedApp.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (apps.isEmpty) {
      apps = BlockedApp.defaultApps;
    }

    return FocusShieldConfig(
      isShieldEnabled: json['isShieldEnabled'] as bool? ?? true,
      strictMode: json['strictMode'] as bool? ?? true,
      blockDesktopProcesses: json['blockDesktopProcesses'] as bool? ?? true,
      blockedApps: apps,
      customUrls: (json['customUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      blockedAttemptsCount: json['blockedAttemptsCount'] as int? ?? 0,
    );
  }

  factory FocusShieldConfig.defaultConfig() => FocusShieldConfig(
        isShieldEnabled: true,
        strictMode: true,
        blockDesktopProcesses: true,
        blockedApps: BlockedApp.defaultApps,
        customUrls: const [],
        blockedAttemptsCount: 0,
      );
}
