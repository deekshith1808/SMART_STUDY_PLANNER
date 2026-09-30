enum SubjectPriority {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case SubjectPriority.high:
        return 'High';
      case SubjectPriority.medium:
        return 'Medium';
      case SubjectPriority.low:
        return 'Low';
    }
  }

  double get weightMultiplier {
    switch (this) {
      case SubjectPriority.high:
        return 3.0;
      case SubjectPriority.medium:
        return 2.0;
      case SubjectPriority.low:
        return 1.0;
    }
  }

  int get stars {
    switch (this) {
      case SubjectPriority.high:
        return 3;
      case SubjectPriority.medium:
        return 2;
      case SubjectPriority.low:
        return 1;
    }
  }

  static SubjectPriority fromDynamic(dynamic value) {
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'high') return SubjectPriority.high;
      if (v == 'low') return SubjectPriority.low;
      return SubjectPriority.medium;
    } else if (value is num) {
      if (value >= 4) return SubjectPriority.high;
      if (value <= 2) return SubjectPriority.low;
      return SubjectPriority.medium;
    }
    return SubjectPriority.medium;
  }
}

enum SubjectDifficulty {
  hard,
  medium,
  easy;

  String get label {
    switch (this) {
      case SubjectDifficulty.hard:
        return 'Hard';
      case SubjectDifficulty.medium:
        return 'Medium';
      case SubjectDifficulty.easy:
        return 'Easy';
    }
  }

  double get weightMultiplier {
    switch (this) {
      case SubjectDifficulty.hard:
        return 1.5;
      case SubjectDifficulty.medium:
        return 1.2;
      case SubjectDifficulty.easy:
        return 1.0;
    }
  }

  static SubjectDifficulty fromDynamic(dynamic value) {
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'hard') return SubjectDifficulty.hard;
      if (v == 'easy') return SubjectDifficulty.easy;
      return SubjectDifficulty.medium;
    }
    return SubjectDifficulty.medium;
  }
}

class UserProfile {
  final String name;
  final String educationType; // 'school' or 'college'
  final String? branch; // for college: Engineering, Arts, Science, etc.
  final String? course; // specific course
  final List<Subject> subjects;

  const UserProfile({
    required this.name,
    required this.educationType,
    this.branch,
    this.course,
    required this.subjects,
  });

  UserProfile copyWith({
    String? name,
    String? educationType,
    String? branch,
    String? course,
    List<Subject>? subjects,
  }) {
    return UserProfile(
      name: name ?? this.name,
      educationType: educationType ?? this.educationType,
      branch: branch ?? this.branch,
      course: course ?? this.course,
      subjects: subjects ?? this.subjects,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'educationType': educationType,
        'branch': branch,
        'course': course,
        'subjects': subjects.map((s) => s.toJson()).toList(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? '',
        educationType: json['educationType'] ?? 'school',
        branch: json['branch'],
        course: json['course'],
        subjects: (json['subjects'] as List<dynamic>? ?? [])
            .map((s) => Subject.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

enum StudyMaterialType {
  pdf,
  image,
  document,
  link,
  note;

  String get label {
    switch (this) {
      case StudyMaterialType.pdf:
        return 'PDF Document';
      case StudyMaterialType.image:
        return 'Image / Diagram';
      case StudyMaterialType.document:
        return 'Document / Slides';
      case StudyMaterialType.link:
        return 'Web Link';
      case StudyMaterialType.note:
        return 'Study Note';
    }
  }

  static StudyMaterialType fromExtension(String? ext) {
    if (ext == null) return StudyMaterialType.document;
    final e = ext.toLowerCase().replaceAll('.', '');
    if (e == 'pdf') return StudyMaterialType.pdf;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].contains(e)) return StudyMaterialType.image;
    if (['doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', 'rtf', 'csv'].contains(e)) return StudyMaterialType.document;
    return StudyMaterialType.document;
  }
}

class StudyMaterial {
  final String id;
  final String title;
  final String? fileName;
  final String? filePath;
  final String? fileUrl;
  final String? content;
  final int? fileSizeBytes;
  final StudyMaterialType type;
  final DateTime uploadedAt;

  const StudyMaterial({
    required this.id,
    required this.title,
    this.fileName,
    this.filePath,
    this.fileUrl,
    this.content,
    this.fileSizeBytes,
    required this.type,
    required this.uploadedAt,
  });

  String get formattedSize {
    if (fileSizeBytes == null || fileSizeBytes! <= 0) return '';
    if (fileSizeBytes! < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes! < 1024 * 1024) return '${(fileSizeBytes! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'fileName': fileName,
        'filePath': filePath,
        'fileUrl': fileUrl,
        'content': content,
        'fileSizeBytes': fileSizeBytes,
        'type': type.name,
        'uploadedAt': uploadedAt.toIso8601String(),
      };

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled Material',
        fileName: json['fileName'] as String?,
        filePath: json['filePath'] as String?,
        fileUrl: json['fileUrl'] as String?,
        content: json['content'] as String?,
        fileSizeBytes: json['fileSizeBytes'] as int?,
        type: StudyMaterialType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => StudyMaterialType.document,
        ),
        uploadedAt: json['uploadedAt'] != null
            ? DateTime.tryParse(json['uploadedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class Subject {
  final String id;
  final String name;
  final double marks; // marks out of 100
  final double targetMarks;
  final int studyHours; // total hours studied
  final String color; // hex color string
  final List<String> topics;
  final List<String> completedTopics;
  final List<StudyMaterial> materials;
  final SubjectPriority priority; // high, medium, low
  final SubjectDifficulty difficulty; // hard, medium, easy
  final DateTime? examDate;

  const Subject({
    required this.id,
    required this.name,
    required this.marks,
    required this.targetMarks,
    required this.studyHours,
    required this.color,
    required this.topics,
    this.completedTopics = const [],
    this.materials = const [],
    this.priority = SubjectPriority.medium,
    this.difficulty = SubjectDifficulty.medium,
    this.examDate,
  });

  int get unfinishedTopicsCount =>
      topics.where((t) => !completedTopics.contains(t)).length;

  List<String> get unfinishedTopics =>
      topics.where((t) => !completedTopics.contains(t)).toList();

  int? get daysUntilExam {
    if (examDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate!.year, examDate!.month, examDate!.day);
    return target.difference(today).inDays;
  }

  Subject copyWith({
    String? name,
    double? marks,
    double? targetMarks,
    int? studyHours,
    String? color,
    List<String>? topics,
    List<String>? completedTopics,
    List<StudyMaterial>? materials,
    SubjectPriority? priority,
    SubjectDifficulty? difficulty,
    DateTime? examDate,
    bool clearExamDate = false,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      marks: marks ?? this.marks,
      targetMarks: targetMarks ?? this.targetMarks,
      studyHours: studyHours ?? this.studyHours,
      color: color ?? this.color,
      topics: topics ?? this.topics,
      completedTopics: completedTopics ?? this.completedTopics,
      materials: materials ?? this.materials,
      priority: priority ?? this.priority,
      difficulty: difficulty ?? this.difficulty,
      examDate: clearExamDate ? null : (examDate ?? this.examDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'marks': marks,
        'targetMarks': targetMarks,
        'studyHours': studyHours,
        'color': color,
        'topics': topics,
        'completedTopics': completedTopics,
        'materials': materials.map((m) => m.toJson()).toList(),
        'priority': priority.name,
        'difficulty': difficulty.name,
        'examDate': examDate?.toIso8601String(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        marks: (json['marks'] as num? ?? 0).toDouble(),
        targetMarks: (json['targetMarks'] as num? ?? 80).toDouble(),
        studyHours: json['studyHours'] as int? ?? 0,
        color: json['color'] ?? '#4CAF50',
        topics: List<String>.from(json['topics'] as List<dynamic>? ?? []),
        completedTopics: List<String>.from(json['completedTopics'] as List<dynamic>? ?? []),
        materials: (json['materials'] as List<dynamic>? ?? [])
            .map((m) => StudyMaterial.fromJson(m as Map<String, dynamic>))
            .toList(),
        priority: SubjectPriority.fromDynamic(json['priority']),
        difficulty: SubjectDifficulty.fromDynamic(json['difficulty']),
        examDate: json['examDate'] != null ? DateTime.tryParse(json['examDate'] as String) : null,
      );
}
