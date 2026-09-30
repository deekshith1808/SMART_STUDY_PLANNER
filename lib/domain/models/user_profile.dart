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

class Subject {
  final String id;
  final String name;
  final double marks; // marks out of 100
  final double targetMarks;
  final int studyHours; // total hours studied
  final String color; // hex color string
  final List<String> topics;
  final int priority; // 1-5

  const Subject({
    required this.id,
    required this.name,
    required this.marks,
    required this.targetMarks,
    required this.studyHours,
    required this.color,
    required this.topics,
    required this.priority,
  });

  Subject copyWith({
    String? name,
    double? marks,
    double? targetMarks,
    int? studyHours,
    String? color,
    List<String>? topics,
    int? priority,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      marks: marks ?? this.marks,
      targetMarks: targetMarks ?? this.targetMarks,
      studyHours: studyHours ?? this.studyHours,
      color: color ?? this.color,
      topics: topics ?? this.topics,
      priority: priority ?? this.priority,
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
        'priority': priority,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        marks: (json['marks'] as num? ?? 0).toDouble(),
        targetMarks: (json['targetMarks'] as num? ?? 80).toDouble(),
        studyHours: json['studyHours'] as int? ?? 0,
        color: json['color'] ?? '#4CAF50',
        topics: List<String>.from(json['topics'] as List<dynamic>? ?? []),
        priority: json['priority'] as int? ?? 3,
      );
}
