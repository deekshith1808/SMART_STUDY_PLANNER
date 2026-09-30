enum NodeType { lesson, practice, quiz, chest, hurdle }

enum NodeStatus { completed, active, locked }

class JourneyNode {
  final String id;
  final String title;
  final String description;
  final String subjectName;
  final NodeType type;
  final NodeStatus status;
  final int xpReward;
  final int stars; // 0 to 3
  final int stage;
  final double horizontalOffset; // -0.6 to 0.6 for zigzag path

  const JourneyNode({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectName,
    required this.type,
    required this.status,
    required this.xpReward,
    this.stars = 0,
    required this.stage,
    required this.horizontalOffset,
  });

  JourneyNode copyWith({
    String? title,
    String? description,
    String? subjectName,
    NodeType? type,
    NodeStatus? status,
    int? xpReward,
    int? stars,
    int? stage,
    double? horizontalOffset,
  }) {
    return JourneyNode(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectName: subjectName ?? this.subjectName,
      type: type ?? this.type,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      stars: stars ?? this.stars,
      stage: stage ?? this.stage,
      horizontalOffset: horizontalOffset ?? this.horizontalOffset,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subjectName': subjectName,
        'type': type.name,
        'status': status.name,
        'xpReward': xpReward,
        'stars': stars,
        'stage': stage,
        'horizontalOffset': horizontalOffset,
      };

  factory JourneyNode.fromJson(Map<String, dynamic> json) => JourneyNode(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        subjectName: json['subjectName'] as String,
        type: NodeType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => NodeType.lesson,
        ),
        status: NodeStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => NodeStatus.locked,
        ),
        xpReward: json['xpReward'] as int? ?? 30,
        stars: json['stars'] as int? ?? 0,
        stage: json['stage'] as int? ?? 1,
        horizontalOffset: (json['horizontalOffset'] as num?)?.toDouble() ?? 0.0,
      );
}

class ExamHurdle {
  final String id;
  final String title;
  final String subjectName;
  final DateTime examDate;
  final double targetScore;
  final int requiredNodes;
  final int completedNodes;
  final bool isPassed;

  const ExamHurdle({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.examDate,
    required this.targetScore,
    required this.requiredNodes,
    required this.completedNodes,
    this.isPassed = false,
  });

  bool get isUnlocked => completedNodes >= requiredNodes;
  double get readiness => (completedNodes / (requiredNodes == 0 ? 1 : requiredNodes)).clamp(0.0, 1.0);
  int get daysRemaining => examDate.difference(DateTime.now()).inDays.clamp(0, 365);

  ExamHurdle copyWith({
    String? title,
    String? subjectName,
    DateTime? examDate,
    double? targetScore,
    int? requiredNodes,
    int? completedNodes,
    bool? isPassed,
  }) {
    return ExamHurdle(
      id: id,
      title: title ?? this.title,
      subjectName: subjectName ?? this.subjectName,
      examDate: examDate ?? this.examDate,
      targetScore: targetScore ?? this.targetScore,
      requiredNodes: requiredNodes ?? this.requiredNodes,
      completedNodes: completedNodes ?? this.completedNodes,
      isPassed: isPassed ?? this.isPassed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectName': subjectName,
        'examDate': examDate.toIso8601String(),
        'targetScore': targetScore,
        'requiredNodes': requiredNodes,
        'completedNodes': completedNodes,
        'isPassed': isPassed,
      };

  factory ExamHurdle.fromJson(Map<String, dynamic> json) => ExamHurdle(
        id: json['id'] as String,
        title: json['title'] as String,
        subjectName: json['subjectName'] as String,
        examDate: DateTime.tryParse(json['examDate'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 7)),
        targetScore: (json['targetScore'] as num?)?.toDouble() ?? 95.0,
        requiredNodes: json['requiredNodes'] as int? ?? 5,
        completedNodes: json['completedNodes'] as int? ?? 0,
        isPassed: json['isPassed'] as bool? ?? false,
      );
}

class JourneyProgress {
  final int totalXp;
  final int currentStreak;
  final DateTime? lastStudyDate;
  final bool hasStreakShield;
  final List<JourneyNode> nodes;
  final ExamHurdle hurdle;

  const JourneyProgress({
    required this.totalXp,
    required this.currentStreak,
    this.lastStudyDate,
    this.hasStreakShield = true,
    required this.nodes,
    required this.hurdle,
  });

  int get level => (totalXp ~/ 120) + 1;

  String get levelTitle {
    if (level <= 1) return 'Novice Scholar';
    if (level <= 2) return 'Focus Apprentice';
    if (level <= 3) return 'Mastery Seeker';
    if (level <= 4) return 'Syllabus Crusher';
    return 'Exam Champion';
  }

  int get xpForNextLevel => (level * 120) - totalXp;
  double get levelProgress => ((totalXp % 120) / 120.0).clamp(0.0, 1.0);

  JourneyProgress copyWith({
    int? totalXp,
    int? currentStreak,
    DateTime? lastStudyDate,
    bool? hasStreakShield,
    List<JourneyNode>? nodes,
    ExamHurdle? hurdle,
  }) {
    return JourneyProgress(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      hasStreakShield: hasStreakShield ?? this.hasStreakShield,
      nodes: nodes ?? this.nodes,
      hurdle: hurdle ?? this.hurdle,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
        'hasStreakShield': hasStreakShield,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'hurdle': hurdle.toJson(),
      };

  factory JourneyProgress.fromJson(Map<String, dynamic> json) => JourneyProgress(
        totalXp: json['totalXp'] as int? ?? 280,
        currentStreak: json['currentStreak'] as int? ?? 5,
        lastStudyDate: json['lastStudyDate'] != null
            ? DateTime.tryParse(json['lastStudyDate'] as String)
            : null,
        hasStreakShield: json['hasStreakShield'] as bool? ?? true,
        nodes: (json['nodes'] as List<dynamic>? ?? [])
            .map((e) => JourneyNode.fromJson(e as Map<String, dynamic>))
            .toList(),
        hurdle: json['hurdle'] != null
            ? ExamHurdle.fromJson(json['hurdle'] as Map<String, dynamic>)
            : ExamHurdle(
                id: 'hurdle_1',
                title: 'Midterm Semester Exam',
                subjectName: 'Core Sciences & Math',
                examDate: DateTime.now().add(const Duration(days: 6)),
                targetScore: 95.0,
                requiredNodes: 5,
                completedNodes: 2,
              ),
      );

  static JourneyProgress defaultProgress() {
    final now = DateTime.now();
    final examDate = now.add(const Duration(days: 6));
    final defaultNodes = [
      const JourneyNode(
        id: 'node_1',
        title: 'Core Fundamentals & Formulae',
        description: 'Review axiomatic definitions, notations, and quick theorems.',
        subjectName: 'Mathematics',
        type: NodeType.lesson,
        status: NodeStatus.completed,
        xpReward: 35,
        stars: 3,
        stage: 1,
        horizontalOffset: 0.0,
      ),
      const JourneyNode(
        id: 'node_2',
        title: 'Derivatives & Applications Practice',
        description: 'Solve 10 standard problem patterns and chain rule cases.',
        subjectName: 'Mathematics',
        type: NodeType.practice,
        status: NodeStatus.completed,
        xpReward: 40,
        stars: 3,
        stage: 1,
        horizontalOffset: -0.45,
      ),
      const JourneyNode(
        id: 'node_3',
        title: 'Speed Concept Check',
        description: 'Rapid 3-minute quiz testing tricky edge cases and common traps.',
        subjectName: 'Physics',
        type: NodeType.quiz,
        status: NodeStatus.active,
        xpReward: 50,
        stars: 0,
        stage: 1,
        horizontalOffset: 0.35,
      ),
      const JourneyNode(
        id: 'node_4',
        title: 'Mystery Study Chest',
        description: 'Unlock surprise XP bonus and a 24-hour streak freeze shield!',
        subjectName: 'General',
        type: NodeType.chest,
        status: NodeStatus.locked,
        xpReward: 60,
        stars: 0,
        stage: 2,
        horizontalOffset: 0.0,
      ),
      const JourneyNode(
        id: 'node_5',
        title: 'Advanced Thermodynamics Drills',
        description: 'Enthalpy, entropy, and heat engine problem solving sprints.',
        subjectName: 'Physics',
        type: NodeType.practice,
        status: NodeStatus.locked,
        xpReward: 45,
        stars: 0,
        stage: 2,
        horizontalOffset: -0.4,
      ),
      const JourneyNode(
        id: 'node_6',
        title: 'Pre-Exam Mock Sprint',
        description: 'Full timed diagnostic test mimicking real exam conditions.',
        subjectName: 'Chemistry',
        type: NodeType.quiz,
        status: NodeStatus.locked,
        xpReward: 70,
        stars: 0,
        stage: 2,
        horizontalOffset: 0.3,
      ),
    ];

    return JourneyProgress(
      totalXp: 385,
      currentStreak: 5,
      lastStudyDate: now,
      hasStreakShield: true,
      nodes: defaultNodes,
      hurdle: ExamHurdle(
        id: 'hurdle_1',
        title: 'Midterm Semester Exam',
        subjectName: 'Combined STEM Subjects',
        examDate: examDate,
        targetScore: 95.0,
        requiredNodes: 5,
        completedNodes: 2,
      ),
    );
  }
}
