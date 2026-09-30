class StudySession {
  final String id;
  final String subjectId;
  final String subjectName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String sessionType; // 'pomodoro', 'normal'
  final String? notes;

  const StudySession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.sessionType,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'sessionType': sessionType,
        'notes': notes,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] ?? '',
        subjectId: json['subjectId'] ?? json['subject_id'] ?? '',
        subjectName: json['subjectName'] ?? json['subject_name'] ?? '',
        startTime: DateTime.parse((json['startTime'] ?? json['start_time']) as String),
        endTime: DateTime.parse((json['endTime'] ?? json['end_time']) as String),
        durationMinutes: (json['durationMinutes'] ?? json['duration_minutes']) as int? ?? 0,
        sessionType: json['sessionType'] ?? json['session_type'] ?? 'normal',
        notes: json['notes'] as String?,
      );
}

class ScheduledTask {
  final String id;
  final String title;
  final String subjectId;
  final String subjectName;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final bool isCompleted;
  final String priority; // 'low', 'medium', 'high'
  final String? description;

  const ScheduledTask({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.subjectName,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.isCompleted,
    required this.priority,
    this.description,
  });

  ScheduledTask copyWith({bool? isCompleted}) {
    return ScheduledTask(
      id: id,
      title: title,
      subjectId: subjectId,
      subjectName: subjectName,
      scheduledDate: scheduledDate,
      startTime: startTime,
      endTime: endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority,
      description: description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'scheduledDate': scheduledDate.toIso8601String(),
        'startTime': startTime,
        'endTime': endTime,
        'isCompleted': isCompleted,
        'priority': priority,
        'description': description,
      };

  factory ScheduledTask.fromJson(Map<String, dynamic> json) => ScheduledTask(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        subjectId: json['subjectId'] ?? json['subject_id'] ?? '',
        subjectName: json['subjectName'] ?? json['subject_name'] ?? '',
        scheduledDate: DateTime.parse((json['scheduledDate'] ?? json['scheduled_date']) as String),
        startTime: json['startTime'] ?? json['start_time'] ?? '',
        endTime: json['endTime'] ?? json['end_time'] ?? '',
        isCompleted: (json['isCompleted'] ?? json['is_completed']) as bool? ?? false,
        priority: json['priority'] ?? 'medium',
        description: json['description'] as String?,
      );
}

class QuickNote {
  final String id;
  final String title;
  final String content;
  final String subjectId;
  final String subjectName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuickNote({
    required this.id,
    required this.title,
    required this.content,
    required this.subjectId,
    required this.subjectName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory QuickNote.fromJson(Map<String, dynamic> json) => QuickNote(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        subjectId: json['subjectId'] ?? json['subject_id'] ?? '',
        subjectName: json['subjectName'] ?? json['subject_name'] ?? '',
        createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
        updatedAt: DateTime.parse((json['updatedAt'] ?? json['updated_at'] ?? json['createdAt'] ?? json['created_at']) as String),
      );
}
