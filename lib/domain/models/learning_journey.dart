import 'user_profile.dart';

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
  int get daysRemaining {
    final now = DateTime.now();
    final target = DateTime(examDate.year, examDate.month, examDate.day);
    final current = DateTime(now.year, now.month, now.day);
    return target.difference(current).inDays.clamp(0, 365);
  }

  String get formattedExamDate {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[examDate.month - 1]} ${examDate.day}, ${examDate.year}';
  }

  String get daysRemainingText {
    final now = DateTime.now();
    final target = DateTime(examDate.year, examDate.month, examDate.day);
    final current = DateTime(now.year, now.month, now.day);
    final diff = target.difference(current).inDays;
    if (diff < 0) return 'Concluded';
    if (diff == 0) return 'Today!';
    if (diff == 1) return 'Tomorrow';
    return '$diff Days Left';
  }

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
  final List<ExamHurdle> hurdles;

  JourneyProgress({
    required this.totalXp,
    required this.currentStreak,
    this.lastStudyDate,
    this.hasStreakShield = true,
    required this.nodes,
    List<ExamHurdle>? hurdles,
    ExamHurdle? hurdle,
  }) : hurdles = hurdles ?? (hurdle != null ? [hurdle] : const []);

  ExamHurdle get hurdle =>
      activeHurdle ?? (hurdles.isNotEmpty ? hurdles.first : _defaultHurdle());

  ExamHurdle? get activeHurdle {
    if (hurdles.isEmpty) return null;
    final upcoming = hurdles.where((h) => h.daysRemaining >= 0).toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    if (upcoming.isNotEmpty) return upcoming.first;
    return hurdles.first;
  }

  List<ExamHurdle> get sortedHurdles {
    final list = List<ExamHurdle>.from(hurdles);
    list.sort((a, b) => a.examDate.compareTo(b.examDate));
    return list;
  }

  static ExamHurdle _defaultHurdle() => ExamHurdle(
        id: 'hurdle_default',
        title: 'Semester Final Exam',
        subjectName: 'Core Subjects',
        examDate: DateTime.now().add(const Duration(days: 7)),
        targetScore: 90.0,
        requiredNodes: 5,
        completedNodes: 0,
      );

  int get level => (totalXp ~/ 120) + 1;

  String get levelTitle {
    if (level <= 1) return 'Novice Scholar';
    if (level <= 2) return 'Focus Apprentice';
    if (level <= 3) return 'Mastery Seeker';
    if (level <= 4) return 'Syllabus Crusher';
    if (level <= 5) return 'Exam Grandmaster';
    return 'Scholar of Eminence';
  }

  int get xpForNextLevel => (level * 120) - totalXp;
  double get levelProgress => ((totalXp % 120) / 120.0).clamp(0.0, 1.0);

  JourneyProgress copyWith({
    int? totalXp,
    int? currentStreak,
    DateTime? lastStudyDate,
    bool? hasStreakShield,
    List<JourneyNode>? nodes,
    List<ExamHurdle>? hurdles,
    ExamHurdle? hurdle,
  }) {
    return JourneyProgress(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      hasStreakShield: hasStreakShield ?? this.hasStreakShield,
      nodes: nodes ?? this.nodes,
      hurdles: hurdles ?? (hurdle != null ? [hurdle] : this.hurdles),
    );
  }

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'currentStreak': currentStreak,
        'lastStudyDate': lastStudyDate?.toIso8601String(),
        'hasStreakShield': hasStreakShield,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'hurdles': hurdles.map((h) => h.toJson()).toList(),
        'hurdle': hurdle.toJson(),
      };

  factory JourneyProgress.fromJson(Map<String, dynamic> json) {
    final hurdlesList = (json['hurdles'] as List<dynamic>? ?? [])
        .map((e) => ExamHurdle.fromJson(e as Map<String, dynamic>))
        .toList();

    if (hurdlesList.isEmpty && json['hurdle'] != null) {
      hurdlesList.add(ExamHurdle.fromJson(json['hurdle'] as Map<String, dynamic>));
    }

    if (hurdlesList.isEmpty) {
      hurdlesList.add(_defaultHurdle());
    }

    return JourneyProgress(
      totalXp: json['totalXp'] as int? ?? 120,
      currentStreak: json['currentStreak'] as int? ?? 1,
      lastStudyDate: json['lastStudyDate'] != null
          ? DateTime.tryParse(json['lastStudyDate'] as String)
          : null,
      hasStreakShield: json['hasStreakShield'] as bool? ?? true,
      nodes: (json['nodes'] as List<dynamic>? ?? [])
          .map((e) => JourneyNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      hurdles: hurdlesList,
    );
  }

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

  static JourneyProgress fromSubjects(
    List<Subject> subjects, {
    DateTime? customExamDate,
    String? customTitle,
    List<JourneyNode>? existingCompletedNodes,
    int? existingXp,
    int? existingStreak,
    List<ExamHurdle>? existingHurdles,
  }) {
    final nodes = <JourneyNode>[];
    const offsets = [0.0, -0.45, 0.35, -0.4, 0.0, 0.45];
    int stage = 1;

    final completedTitles = existingCompletedNodes
            ?.where((n) => n.status == NodeStatus.completed)
            .map((n) => n.title.toLowerCase().trim())
            .toSet() ??
        {};

    for (int sIdx = 0; sIdx < subjects.length; sIdx++) {
      final subject = subjects[sIdx];
      for (int tIdx = 0; tIdx < subject.topics.length; tIdx++) {
        final topic = subject.topics[tIdx];
        final nodeIndex = nodes.length;
        final offset = offsets[nodeIndex % offsets.length];
        final type = (tIdx % 3 == 0)
            ? NodeType.lesson
            : (tIdx % 3 == 1 ? NodeType.practice : NodeType.quiz);

        final isAlreadyDone =
            completedTitles.contains(topic.toLowerCase().trim());

        nodes.add(JourneyNode(
          id: 'node_${subject.id}_$tIdx',
          title: topic,
          description:
              'Master $topic concepts, applications, and practice drills for ${subject.name}.',
          subjectName: subject.name,
          type: type,
          status: isAlreadyDone
              ? NodeStatus.completed
              : (nodeIndex == 0 ? NodeStatus.active : NodeStatus.locked),
          xpReward: 35 + ((nodeIndex % 4) * 10),
          stars: isAlreadyDone ? 3 : 0,
          stage: stage,
          horizontalOffset: offset,
        ));

        if (nodes.length % 3 == 0) stage++;
      }
    }

    if (nodes.isEmpty) {
      if (subjects.isNotEmpty) {
        for (int i = 0; i < subjects.length; i++) {
          final s = subjects[i];
          nodes.add(JourneyNode(
            id: 'node_${s.id}_core',
            title: '${s.name} Core Foundations',
            description:
                'Essential theorems, definitions and formulas for ${s.name}.',
            subjectName: s.name,
            type: NodeType.lesson,
            status: i == 0 ? NodeStatus.active : NodeStatus.locked,
            xpReward: 40,
            stars: 0,
            stage: (i ~/ 3) + 1,
            horizontalOffset: offsets[i % offsets.length],
          ));
        }
      } else {
        return JourneyProgress.defaultProgress();
      }
    }

    final hasActive = nodes.any((n) => n.status == NodeStatus.active);
    final allCompleted = nodes.every((n) => n.status == NodeStatus.completed);
    if (!hasActive && !allCompleted) {
      final firstLockedIndex =
          nodes.indexWhere((n) => n.status == NodeStatus.locked);
      if (firstLockedIndex != -1) {
        nodes[firstLockedIndex] =
            nodes[firstLockedIndex].copyWith(status: NodeStatus.active);
      }
    }

    // Build multiple hurdles for subjects with exam dates or custom hurdle
    final hurdleList = <ExamHurdle>[];
    if (existingHurdles != null && existingHurdles.isNotEmpty) {
      hurdleList.addAll(existingHurdles);
    } else {
      for (final s in subjects) {
        if (s.examDate != null) {
          final subjectNodes = nodes
              .where((n) => n.subjectName.toLowerCase() == s.name.toLowerCase())
              .toList();
          final reqNodes = subjectNodes.isNotEmpty ? subjectNodes.length : 3;
          final doneNodes = subjectNodes
              .where((n) => n.status == NodeStatus.completed)
              .length;

          hurdleList.add(ExamHurdle(
            id: 'hurdle_${s.id}',
            title: '${s.name} Exam Hurdle',
            subjectName: s.name,
            examDate: s.examDate!,
            targetScore: s.targetMarks,
            requiredNodes: reqNodes,
            completedNodes: doneNodes,
            isPassed: doneNodes >= reqNodes,
          ));
        }
      }

      if (hurdleList.isEmpty) {
        DateTime examDate = customExamDate ??
            DateTime.now().add(const Duration(days: 14));
        final completedCount =
            nodes.where((n) => n.status == NodeStatus.completed).length;

        hurdleList.add(ExamHurdle(
          id: 'hurdle_${DateTime.now().millisecondsSinceEpoch}',
          title: customTitle ??
              (subjects.isNotEmpty
                  ? '${subjects.first.name} Final Exam'
                  : 'Semester Final Exam'),
          subjectName:
              subjects.isNotEmpty ? subjects.first.name : 'Core Subjects',
          examDate: examDate,
          targetScore: subjects.isNotEmpty ? subjects.first.targetMarks : 90.0,
          requiredNodes: nodes.length,
          completedNodes: completedCount,
          isPassed: completedCount >= nodes.length,
        ));
      }
    }

    hurdleList.sort((a, b) => a.examDate.compareTo(b.examDate));

    final completedCount =
        nodes.where((n) => n.status == NodeStatus.completed).length;
    final totalXp = existingXp ?? ((completedCount * 35) + 120);
    final streak = existingStreak ?? 3;

    return JourneyProgress(
      totalXp: totalXp,
      currentStreak: streak,
      lastStudyDate: DateTime.now(),
      hasStreakShield: true,
      nodes: nodes,
      hurdles: hurdleList,
    );
  }
}
